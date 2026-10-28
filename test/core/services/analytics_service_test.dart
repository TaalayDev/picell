import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picell/core/services/analytics_service.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Adapter implements HttpClientAdapter {
  int status = 201;
  final bodies = <Map<String, dynamic>>[];

  @override
  Future<ResponseBody> fetch(
      RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (status == 0) {
      throw DioException.connectionError(requestOptions: options, reason: 'offline');
    }
    bodies.add(Map<String, dynamic>.from(options.data as Map));
    return ResponseBody.fromString('{"success":true}', status, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalStorage storage;
  late _Adapter adapter;
  late AnalyticsService analytics;

  setUpAll(() async {
    AnalyticsService.disabledInDebug = false;
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
    storage.setString(AnalyticsService.storageKey, '[]');
    storage.analyticsEnabled = true;
    adapter = _Adapter();
    analytics =
        AnalyticsService(storage, dio: Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = adapter);
  });

  tearDown(() => analytics.dispose());

  test('sanitizeProps keeps only flat scalars with valid keys', () {
    final props = AnalyticsService.sanitizeProps({
      'width': 32,
      'Bad Key': 1,
      'nested': {'a': 1},
      'list': [1],
      'source': 'x' * 100,
      'flag': true,
      'missing': null,
    });
    expect(props.keys, unorderedEquals(['width', 'source', 'flag']));
    expect((props['source'] as String).length, 64);
  });

  test('sends a batch with session_start and clears the queue', () async {
    await analytics.start();
    await analytics.logEvent(name: 'project_created', parameters: {'width': 16, 'height': 16});
    await analytics.flush();

    final body = adapter.bodies.first;
    expect(body['installation_id'], storage.installationId);
    expect(body['plan'], 'free');
    final events = adapter.bodies.expand((b) => b['events'] as List).cast<Map>().toList();
    expect(events.map((e) => e['name']), ['session_start', 'project_created']);
    expect(events[1]['props'], {'width': 16, 'height': 16});
    expect(events[1]['session_id'], events[0]['session_id']);
    expect(jsonDecode(storage.getString(AnalyticsService.storageKey)!), isEmpty);
  });

  test('keeps events while offline and on 5xx, drops rejected batches', () async {
    await analytics.start();
    adapter.status = 0;
    await analytics.flush();
    expect(jsonDecode(storage.getString(AnalyticsService.storageKey)!), hasLength(1));

    adapter.status = 503;
    await analytics.flush();
    expect(jsonDecode(storage.getString(AnalyticsService.storageKey)!), hasLength(1));

    adapter.status = 422;
    await analytics.flush();
    expect(jsonDecode(storage.getString(AnalyticsService.storageKey)!), isEmpty);
  });

  test('pausing ends the session with foreground duration; a long absence starts a new one', () async {
    await analytics.start();
    analytics.onLifecycle(AppLifecycleState.paused);
    analytics.onLifecycle(AppLifecycleState.resumed);
    await analytics.flush();

    final events = (adapter.bodies.expand((b) => b['events'] as List)).cast<Map>().toList();
    expect(events.map((e) => e['name']), ['session_start', 'session_end']);
    expect(events[1]['props'], containsPair('duration_s', isA<int>()));
  });

  test('records nothing and drops the queue when opted out', () async {
    await analytics.start();
    storage.analyticsEnabled = false;
    await analytics.logEvent(name: 'export');
    await analytics.flush();
    expect(adapter.bodies, isEmpty);
    expect(jsonDecode(storage.getString(AnalyticsService.storageKey)!), isEmpty);
  });
}
