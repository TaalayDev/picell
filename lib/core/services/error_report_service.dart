import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../../config/constants.dart';
import '../../data/storage/local_storage.dart';

/// Best-effort diagnostics. Uses its own transport so failures never recurse
/// through the app API client. Project contents and request bodies are excluded.
class ErrorReportService {
  static final instance = ErrorReportService();
  static const storageKey = 'pending_error_reports';
  final Dio _dio;
  final List<Map<String, dynamic>> _pending = [];
  final Map<String, DateTime> _recent = {};
  LocalStorage? _storage;
  String _version = 'unknown';
  Future<void>? _flushFuture;
  Timer? _timer;

  ErrorReportService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: Constants.baseUrl,
              connectTimeout: const Duration(seconds: 5),
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ));

  Future<void> initialize(LocalStorage storage) async {
    if (_storage != null) return;
    _storage = storage;
    try {
      final saved = jsonDecode(storage.getString(storageKey) ?? '[]') as List;
      _pending.addAll(saved
          .whereType<Map>()
          .take(30)
          .map((e) => Map<String, dynamic>.from(e)));
    } catch (_) {}
    if (_pending.length > 30) {
      _pending.removeRange(0, _pending.length - 30);
    }
    _persist();
    try {
      final info = await PackageInfo.fromPlatform();
      _version = '${info.version}+${info.buildNumber}';
    } catch (_) {}
    _timer =
        Timer.periodic(const Duration(minutes: 1), (_) => unawaited(flush()));
    if (_pending.isNotEmpty) unawaited(flush());
  }

  void installHandlers() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (previous != null) {
        previous(details);
      } else {
        FlutterError.presentError(details);
      }
      report(details.exception, details.stack ?? StackTrace.current,
          operation: 'flutter.${details.library ?? 'framework'}');
    };
    final previousPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack, operation: 'app.uncaught');
      if (previousPlatform != null) return previousPlatform(error, stack);
      // Keep the error visible in logs even though it has been handled.
      FlutterError.presentError(
          FlutterErrorDetails(exception: error, stack: stack));
      return true;
    };
  }

  static String sanitize(String text, int limit) {
    var value = text
        .replaceAll(RegExp(r'Bearer\s+[^\s,;]+', caseSensitive: false),
            'Bearer [redacted]')
        .replaceAllMapped(
            RegExp(r'(token|password|secret|api[_-]?key)\s*[:=]\s*[^\s,;]+',
                caseSensitive: false),
            (match) => '${match[1]}=[redacted]')
        .replaceAll(RegExp(r'https?://[^\s]+'), '[url]')
        .replaceAll(RegExp(r'[\w.+-]+@[\w.-]+\.[a-zA-Z]{2,}'), '[email]')
        .replaceAll(RegExp(r'/(Users|home)/[^/\s]+'), '/[user]');
    return String.fromCharCodes(value.runes.take(limit));
  }

  void report(Object error, StackTrace stack, {required String operation}) {
    try {
      final message = sanitize(error.toString(), 4000);
      final key = '$operation:$message';
      final now = DateTime.now();
      if (_recent[key] != null &&
          now.difference(_recent[key]!) < const Duration(minutes: 1)) {
        return;
      }
      _recent.removeWhere(
          (_, time) => now.difference(time) > const Duration(minutes: 1));
      if (_recent.length >= 100) return;
      _recent[key] = now;
      if (_pending.length >= 30) _pending.removeAt(0);
      _pending.add({
        'report_id': const Uuid().v4(),
        'operation': sanitize(operation, 120),
        'message': message,
        'stack_trace': sanitize(stack.toString(), 16000),
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'app_version': _version,
        'occurred_at': now.toUtc().toIso8601String(),
      });
      _persist();
      unawaited(flush());
    } catch (_) {}
  }

  Future<T> guard<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stack) {
      report(error, stack, operation: operation);
      rethrow;
    }
  }

  void _persist() {
    try {
      _storage?.setString(storageKey, jsonEncode(_pending));
    } catch (_) {}
  }

  Future<void> flush() {
    if (_storage == null) return Future<void>.value();
    return _flushFuture ??= _send().whenComplete(() => _flushFuture = null);
  }

  Future<void> _send() async {
    while (_pending.isNotEmpty) {
      final report = _pending.first;
      try {
        final token = _storage?.token;
        final response = await _dio.post('/api/v1/error-reports',
            data: report,
            options: Options(headers: {
              if (token != null) 'Authorization': 'Bearer $token'
            }));
        if (response.data is! Map || response.data['success'] != true) break;
      } on DioException catch (error) {
        // Invalid payloads cannot succeed on retry; transient failures can.
        if (error.response?.statusCode != 400 &&
            error.response?.statusCode != 413 &&
            error.response?.statusCode != 422) {
          break;
        }
      } catch (_) {
        break;
      }
      _pending.remove(report);
      _persist();
    }
  }

  void dispose() => _timer?.cancel();
}
