import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picell/core/services/error_report_service.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportAdapter implements HttpClientAdapter {
  int status = 503;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({'success': status == 201}),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json']
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalStorage storage;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Picell',
      packageName: 'app.picell',
      version: '1.2',
      buildNumber: '34',
      buildSignature: '',
    );
    storage = await LocalStorage.init();
  });

  setUp(() {
    storage.setString(ErrorReportService.storageKey, '[]');
  });

  test('redacts credentials, URLs, email and home paths, limits Unicode safely',
      () {
    final text = ErrorReportService.sanitize(
      'Bearer abc password=123 token=xyz https://example.com?a=secret '
      'person@example.com /Users/name/project.dart',
      4000,
    );
    expect(text, isNot(contains('abc')));
    expect(text, contains('password=[redacted]'));
    expect(text, isNot(contains('xyz')));
    expect(text, isNot(contains('person@example.com')));
    expect(text, isNot(contains('/Users/name')));
    expect(ErrorReportService.sanitize('😀😀😀', 2), '😀😀');
  });

  test(
      'retains offline reports, retries after restart, deduplicates and clears on success',
      () async {
    final adapter = ReportAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    final reporter = ErrorReportService(dio: dio);
    await reporter.initialize(storage);
    reporter.report(StateError('frame save failed'), StackTrace.current,
        operation: 'editor.updateFrame');
    reporter.report(StateError('frame save failed'), StackTrace.current,
        operation: 'editor.updateFrame');
    await reporter.flush();
    expect(jsonDecode(storage.getString(ErrorReportService.storageKey)!),
        hasLength(1));
    expect(adapter.requests, hasLength(1));
    final firstId = adapter.requests.first.data['report_id'];
    reporter.dispose();

    adapter.status = 201;
    final restarted = ErrorReportService(dio: dio);
    await restarted.initialize(storage);
    await restarted.flush();
    expect(adapter.requests.last.data['report_id'], firstId);
    expect(
        jsonDecode(storage.getString(ErrorReportService.storageKey)!), isEmpty);
    restarted.dispose();
  });

  test('failed reporting never replaces the original operation error',
      () async {
    final reporter = ErrorReportService();
    final error = StateError('cannot create project');
    await expectLater(
        reporter.guard('project.create', () => Future<void>.error(error)),
        throwsA(same(error)));
    reporter.dispose();
  });

  test('offline queue is bounded and rejected payloads are discarded',
      () async {
    final adapter = ReportAdapter();
    final reporter = ErrorReportService(
        dio: Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..httpClientAdapter = adapter);
    await reporter.initialize(storage);
    for (var i = 0; i < 40; i++) {
      reporter.report(StateError('error $i'), StackTrace.current,
          operation: 'editor.save');
    }
    await reporter.flush();
    expect(jsonDecode(storage.getString(ErrorReportService.storageKey)!),
        hasLength(30));
    adapter.status = 422;
    await reporter.flush();
    expect(
        jsonDecode(storage.getString(ErrorReportService.storageKey)!), isEmpty);
    reporter.dispose();
  });
}
