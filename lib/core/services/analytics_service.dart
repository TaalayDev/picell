import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../../config/constants.dart';
import '../../data/storage/local_storage.dart';

/// First-party, anonymous usage analytics. Events are queued locally and sent
/// in batches to the backend; failures are silent and never reported as errors.
/// Nothing is recorded when the user has opted out ([LocalStorage.analyticsEnabled]).
class AnalyticsService {
  static const storageKey = 'pending_analytics_events';
  static const maxQueue = 500;
  static const batchSize = 20;
  static const sessionTimeout = Duration(minutes: 30);
  static final _propKey = RegExp(r'^[a-z][a-z0-9_]{0,31}$');

  AnalyticsService(this._storage, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: Constants.baseUrl,
              connectTimeout: const Duration(seconds: 5),
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ));

  final LocalStorage _storage;
  final Dio _dio;
  final List<Map<String, dynamic>> _queue = [];
  String _version = 'unknown';
  String _plan = 'free';
  String? _sessionId;
  DateTime? _foregroundSince;
  DateTime? _backgroundSince;
  Duration _foregroundTotal = Duration.zero;
  Future<void>? _flushFuture;
  Timer? _timer;

  /// Analytics are never collected or sent from debug builds.
  @visibleForTesting
  static bool disabledInDebug = kDebugMode;

  bool get enabled => !disabledInDebug && _storage.analyticsEnabled;

  /// Current subscription tier: `free`, `pro` or `ultimate`.
  set plan(String value) => _plan = value;

  Future<void> start() async {
    try {
      final saved = jsonDecode(_storage.getString(storageKey) ?? '[]') as List;
      _queue.addAll(saved.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
      if (_queue.length > maxQueue) _queue.removeRange(0, _queue.length - maxQueue);
    } catch (_) {}
    try {
      final info = await PackageInfo.fromPlatform();
      _version = '${info.version}+${info.buildNumber}';
    } catch (_) {}
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => unawaited(flush()));
    _beginSession();
    unawaited(flush());
  }

  void dispose() => _timer?.cancel();

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    _record(name, parameters);
    if (_queue.length >= batchSize) unawaited(flush());
  }

  /// Call from the app's lifecycle observer.
  void onLifecycle(AppLifecycleState state) {
    final now = DateTime.now();
    switch (state) {
      case AppLifecycleState.resumed:
        final away = _backgroundSince;
        _backgroundSince = null;
        if (away != null && now.difference(away) > sessionTimeout) {
          _beginSession();
        } else {
          _foregroundSince ??= now;
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_backgroundSince != null) return;
        _backgroundSince = now;
        _endSession(now);
        unawaited(flush());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _beginSession() {
    _sessionId = const Uuid().v4();
    _foregroundTotal = Duration.zero;
    _foregroundSince = DateTime.now();
    _record('session_start', null);
  }

  /// Emitted on every pause with the cumulative foreground time; the server
  /// keeps the latest value, so a session survives the app being killed.
  void _endSession(DateTime now) {
    final since = _foregroundSince;
    if (since != null) _foregroundTotal += now.difference(since);
    _foregroundSince = null;
    _record('session_end', {'duration_s': _foregroundTotal.inSeconds});
  }

  void _record(String name, Map<String, Object?>? parameters) {
    try {
      if (!enabled) return;
      final props = sanitizeProps(parameters);
      _queue.add({
        'name': name,
        'session_id': _sessionId,
        'ts': DateTime.now().toUtc().toIso8601String(),
        if (props.isNotEmpty) 'props': props,
      });
      if (_queue.length > maxQueue) _queue.removeAt(0);
      _persist();
    } catch (_) {}
  }

  /// The backend rejects a whole batch for one bad prop, so keep only flat,
  /// small scalar values with well-formed keys.
  @visibleForTesting
  static Map<String, Object> sanitizeProps(Map<String, Object?>? input) {
    final result = <String, Object>{};
    input?.forEach((key, value) {
      if (result.length >= 10 || !_propKey.hasMatch(key)) return;
      if (value is bool || value is int || value is double) {
        result[key] = value!;
      } else if (value is String) {
        result[key] = String.fromCharCodes(value.runes.take(64));
      }
    });
    return result;
  }

  void _persist() {
    try {
      _storage.setString(storageKey, jsonEncode(_queue));
    } catch (_) {}
  }

  /// Drops queued events and stops recording; used when the user opts out.
  void clear() {
    _queue.clear();
    _persist();
  }

  Future<void> flush() {
    if (!enabled) {
      if (_queue.isNotEmpty) clear();
      return Future<void>.value();
    }
    return _flushFuture ??= _send().whenComplete(() => _flushFuture = null);
  }

  Future<void> _send() async {
    while (_queue.isNotEmpty && enabled) {
      final batch = _queue.take(50).toList();
      try {
        final token = _storage.token;
        await _dio.post('/api/v1/analytics/batch',
            data: {
              'installation_id': _storage.installationId,
              'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
              'app_version': _version,
              'plan': _plan,
              'locale': PlatformDispatcher.instance.locale.toLanguageTag(),
              'events': batch,
            },
            options: Options(headers: {if (token != null) 'Authorization': 'Bearer $token'}));
      } on DioException catch (error) {
        final status = error.response?.statusCode;
        // Rejected payloads can never succeed; offline / 5xx / 429 retry later.
        if (status == null || status >= 500 || status == 429 || status == 401) break;
      } catch (_) {
        break;
      }
      // The queue may have changed (opt-out, overflow) while the request ran.
      final sent = Set<Map<String, dynamic>>.identity()..addAll(batch);
      _queue.removeWhere(sent.contains);
      _persist();
    }
  }
}
