import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../data/models/subscription_model.dart';
import '../data/models/trial_model.dart';
import '../data/storage/local_storage.dart';
import '../pixel/effects/effect_pack_catalog.dart';
import 'app_settings_provider.dart';
import 'auth_provider.dart';
import 'providers.dart';
import 'subscription_provider.dart';

/// Identifies this install to the server (RevenueCat appUserID), so a second
/// account on the same install cannot claim a trial again.
typedef DeviceIdLoader = Future<String?> Function();

Future<String?> _revenueCatAppUserId() async {
  try {
    return await Purchases.appUserID;
  } catch (_) {
    // Not configured (web, desktop, tests). Debug builds can still try the
    // server flow with a fixed id.
    return kDebugMode ? 'debug-device' : null;
  }
}

final deviceIdLoaderProvider = Provider<DeviceIdLoader>((ref) => _revenueCatAppUserId);

/// Trials the signed-in account has used, mirrored from the server and cached
/// per account so they keep working offline until they run out.
class TrialsNotifier extends StateNotifier<TrialsState> {
  TrialsNotifier(this._ref, this._userId) : super(const TrialsState()) {
    if (_userId != null) {
      _loadCache();
      unawaited(refresh());
    }
  }

  final Ref _ref;
  final int? _userId;
  Timer? _expiryTimer;

  String get _cacheKey => 'trials_v1_$_userId';

  bool get _signedIn => _userId != null;

  void _loadCache() {
    try {
      final raw = LocalStorage.instance.getString(_cacheKey);
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      _set(TrialsState(grants: [for (final item in list) TrialGrantInfo.fromJson(item as Map<String, dynamic>)]));
    } catch (e) {
      debugPrint('Failed to read trial cache: $e');
    }
  }

  void _set(TrialsState next) {
    if (!mounted) return;
    state = next;
    try {
      LocalStorage.instance.setString(_cacheKey, jsonEncode([for (final g in next.grants) g.toJson()]));
    } catch (_) {}
    _scheduleExpiry();
  }

  /// Rebuilds dependents the moment a running plan trial ends.
  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final end = state.nextExpiryAfter(DateTime.now());
    if (end == null) return;
    _expiryTimer = Timer(end.difference(DateTime.now()) + const Duration(seconds: 1), () {
      if (mounted) state = TrialsState(grants: state.grants);
    });
  }

  Future<void> refresh() async {
    if (!_signedIn) return;
    final response = await _ref.read(apiClientProvider).request<TrialsState>(
          '/api/v1/trials',
          'GET',
          converter: (data) => TrialsState(grants: [
            for (final item in (data as Map)['trials'] as List) TrialGrantInfo.fromJson(item as Map<String, dynamic>),
          ]),
        );
    // A failed refresh keeps the cached trials: offline use must not revoke them.
    if (response.success && response.data != null) _set(response.data!);
  }

  Future<TrialClaimResult> claimPlan(SubscriptionPlan tier) =>
      _claim({'kind': 'plan', 'tier': tier == SubscriptionPlan.ultimate ? 'ultimate' : 'pro'});

  Future<TrialClaimResult> claimRig(String projectKey) => _claim({'kind': 'rig', 'project_key': projectKey});

  Future<TrialClaimResult> claimPack(EffectPackId pack, String projectKey) =>
      _claim({'kind': 'pack', 'subject': pack.name, 'project_key': projectKey});

  Future<TrialClaimResult> _claim(Map<String, dynamic> body) async {
    if (!_signedIn) return TrialClaimResult.notSignedIn;
    final deviceId = await _ref.read(deviceIdLoaderProvider)();
    if (deviceId == null) return TrialClaimResult.unavailable;

    final response = await _ref.read(apiClientProvider).request<Map<String, dynamic>>(
          '/api/v1/trials/claim',
          'POST',
          data: {...body, 'app_user_id': deviceId},
          converter: (data) => Map<String, dynamic>.from(data as Map),
        );

    if (!response.success) {
      final details = response.details;
      final reason = details is Map ? details['code'] : null;
      return reason == 'already_used' ? TrialClaimResult.alreadyUsed : TrialClaimResult.unavailable;
    }
    await refresh();
    return response.data?['status'] == 'granted' ? TrialClaimResult.granted : TrialClaimResult.existing;
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }
}

/// Recreated when the account changes, so one account's trials never apply to
/// another. Kept alive: it owns the expiry timer and the offline cache.
final trialsProvider = StateNotifierProvider.autoDispose<TrialsNotifier, TrialsState>((ref) {
  ref.keepAlive();
  final userId = ref.watch(authProvider.select((auth) => auth.isSignedIn ? auth.apiUser?.id : null));
  return TrialsNotifier(ref, userId);
});

final planTrialProvider = Provider.autoDispose<PlanTrial?>((ref) {
  return ref.watch(trialsProvider).planTrialAt(DateTime.now());
});

/// The project open in the editor, so project-bound trials know what they apply to.
final currentProjectKeyProvider = StateProvider<String?>((ref) => null);

/// Days of free trial offered for [tier], or null when none is offered: trials
/// are off in the release settings, the user already owns a plan, or the plan
/// trial was used. Signed-out users are offered it too; claiming asks them to
/// sign in first.
final planTrialOfferProvider = Provider.autoDispose.family<int?, SubscriptionPlan>((ref, tier) {
  final settings = ref.watch(appSettingsProvider);
  if (!settings.trialsEnabled) return null;
  if (ref.watch(subscriptionStateProvider).plan.isPaid) return null;
  if (ref.watch(trialsProvider).planTrialUsed) return null;
  final days = tier == SubscriptionPlan.ultimate ? settings.trialUltimateDays : settings.trialProDays;
  return days > 0 ? days : null;
});
