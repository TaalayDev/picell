import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/core/services/analytics_service.dart';
import 'package:picell/core/utils/api_client.dart';
import 'package:picell/data/models/api_models.dart';
import 'package:picell/data/models/auth_api_models.dart';
import 'package:picell/data/models/subscription_model.dart';
import 'package:picell/data/models/trial_model.dart';
import 'package:picell/pixel/effects/effect_pack_catalog.dart';
import 'package:picell/providers/auth_provider.dart';
import 'package:picell/providers/progression_provider.dart';
import 'package:picell/providers/providers.dart';
import 'package:picell/providers/trial_provider.dart';

class _SignedIn extends Auth {
  @override
  AuthState build() => const AuthState(isSignedIn: true, apiUser: ApiUser(id: 7, username: 'u'));
}

class _SignedOut extends Auth {
  @override
  AuthState build() => const AuthState();
}

/// Answers /trials and /trials/claim like the server: one rig project.
class _FakeApi implements ApiClient {
  final grants = <Map<String, dynamic>>[];
  final claimBodies = <Map<String, dynamic>>[];

  @override
  Future<ApiResponse<T>> request<T>(
    String url,
    String method, {
    required T Function(dynamic data)? converter,
    Map<String, dynamic>? params,
    dynamic data,
    Options? options,
  }) async {
    if (url == '/api/v1/trials') {
      return ApiResponse<T>(success: true, data: converter!({'trials': grants}), timestamp: 0);
    }
    final body = Map<String, dynamic>.from(data as Map);
    claimBodies.add(body);
    final existing = grants.where((g) => g['kind'] == body['kind'] && g['subject'] == (body['subject'] ?? body['kind']));
    if (existing.isNotEmpty && existing.first['project_key'] != body['project_key']) {
      return ApiResponse<T>(success: false, error: 'used', details: {'code': 'already_used'}, timestamp: 0);
    }
    final status = existing.isEmpty ? 'granted' : 'existing';
    if (existing.isEmpty) {
      grants.add({
        'kind': body['kind'],
        'subject': body['subject'] ?? body['kind'],
        'tier': body['tier'],
        'project_key': body['project_key'],
        'started_at': '2026-11-10T12:00:00Z',
        'expires_at': null,
      });
    }
    return ApiResponse<T>(success: true, data: converter!({'status': status}), timestamp: 0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Analytics implements AnalyticsService {
  final events = <(String, Map<String, Object>)>[];

  /// Compact form for assertions: `name kind/subject[/reason]`.
  List<String> get summary => [
        for (final (name, props) in events)
          '$name ${[props['kind'], props['subject'], props['reason']].whereType<String>().join('/')}',
      ];

  @override
  Future<void> logEvent({required String name, Map<String, Object>? parameters}) async =>
      events.add((name, parameters ?? const {}));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _analytics = _Analytics();

ProviderContainer _container(_FakeApi api, {bool signedIn = true, String? device = 'dev-1'}) {
  _analytics.events.clear();
  final container = ProviderContainer(overrides: [
    analyticsProvider.overrideWithValue(_analytics),
    apiClientProvider.overrideWithValue(api),
    authProvider.overrideWith(() => signedIn ? _SignedIn() : _SignedOut()),
    deviceIdLoaderProvider.overrideWithValue(() async => device),
  ]);
  addTearDown(container.dispose);
  container.listen(trialsProvider, (_, __) {});
  return container;
}

void main() {
  const projectA = '11111111-1111-4111-8111-111111111111';
  const projectB = '22222222-2222-4222-8222-222222222222';

  test('signed-out users must sign in before claiming', () async {
    final api = _FakeApi();
    final container = _container(api, signedIn: false);
    expect(await container.read(trialsProvider.notifier).claimRig(projectA), TrialClaimResult.notSignedIn);
    expect(api.claimBodies, isEmpty);
  });

  test('the claim carries the device id and unlocks only that project', () async {
    final api = _FakeApi();
    final container = _container(api);
    final trials = container.read(trialsProvider.notifier);

    expect(await trials.claimRig(projectA), TrialClaimResult.granted);
    expect(api.claimBodies.single['app_user_id'], 'dev-1');
    expect(container.read(trialsProvider).hasRigTrialFor(projectA), isTrue);
    expect(container.read(trialsProvider).hasRigTrialFor(projectB), isFalse);

    expect(await trials.claimRig(projectA), TrialClaimResult.existing);
    expect(await trials.claimRig(projectB), TrialClaimResult.alreadyUsed);
  });

  test('a pack trial unlocks the pack only while its project is open', () async {
    final api = _FakeApi();
    final container = _container(api);
    expect(await container.read(trialsProvider.notifier).claimPack(EffectPackId.artistic, projectA), TrialClaimResult.granted);

    final access = packTrialAccessProvider(EffectPackId.artistic);
    container.listen(access, (_, __) {});
    expect(container.read(access), isFalse);
    container.read(currentProjectKeyProvider.notifier).state = projectA;
    expect(container.read(access), isTrue);
    container.read(currentProjectKeyProvider.notifier).state = projectB;
    expect(container.read(access), isFalse);
  });

  test('no device id means trials are unavailable', () async {
    final container = _container(_FakeApi(), device: null);
    expect(await container.read(trialsProvider.notifier).claimRig(projectA), TrialClaimResult.unavailable);
  });

  test('starts and refusals are logged; re-claiming a running trial is not a new start', () async {
    final container = _container(_FakeApi());
    final trials = container.read(trialsProvider.notifier);

    await trials.claimRig(projectA);
    await trials.claimRig(projectA);
    await trials.claimRig(projectB);
    await trials.claimPack(EffectPackId.artistic, projectA);
    await trials.claimPlan(SubscriptionPlan.ultimate);

    expect(_analytics.summary, [
      'trial_started rig/rig',
      'trial_claim_failed rig/rig/already_used',
      'trial_started pack/artistic',
      'trial_started plan/ultimate',
    ]);
  });

  test('a signed-out claim is logged with its reason', () async {
    final container = _container(_FakeApi(), signedIn: false);
    await container.read(trialsProvider.notifier).claimPlan(SubscriptionPlan.pro);
    expect(_analytics.summary, ['trial_claim_failed plan/pro/not_signed_in']);
  });
}
