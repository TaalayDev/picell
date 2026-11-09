import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'providers.dart';

class AppSettings {
  const AppSettings({
    this.mobileBottomBannerEnabled = false,
    this.trialsEnabled = false,
    this.trialProDays = 0,
    this.trialUltimateDays = 0,
  });

  final bool mobileBottomBannerEnabled;

  /// Release switch for free trials; off unless the server says otherwise.
  final bool trialsEnabled;

  /// Length of the Pro / Ultimate plan trial; 0 turns that trial off.
  final int trialProDays;
  final int trialUltimateDays;

  factory AppSettings.fromJson(dynamic json) {
    int days(String key) {
      final value = json is Map ? json[key] : null;
      return value is int ? value.clamp(0, 30) : 0;
    }

    return AppSettings(
      mobileBottomBannerEnabled: json is Map && json['mobile_bottom_banner_enabled'] == true,
      trialsEnabled: json is Map && json['trials_enabled'] == true,
      trialProDays: days('trial_pro_days'),
      trialUltimateDays: days('trial_ultimate_days'),
    );
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final client = ref.read(apiClientProvider);
  return AppSettingsNotifier(() async {
    // Bypass the API client's cache options so disabling ads takes effect promptly.
    final response = await client.request<AppSettings>(
      '/api/v1/app-settings',
      'GET',
      options: Options(
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8)),
      converter: AppSettings.fromJson,
    );
    return response.success
        ? response.data ?? const AppSettings()
        : const AppSettings();
  });
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier(this._load,
      {Duration refreshInterval = const Duration(minutes: 1)})
      : super(const AppSettings()) {
    unawaited(refresh());
    _timer = Timer.periodic(refreshInterval, (_) => unawaited(refresh()));
  }

  final Future<AppSettings> Function() _load;
  Timer? _timer;
  bool _fetching = false;

  Future<void> refresh() async {
    if (_fetching || !mounted) return;
    _fetching = true;
    try {
      final settings = await _load().timeout(const Duration(seconds: 10));
      if (mounted) state = settings;
    } catch (_) {
      // Offline, outdated backend, or malformed settings: do not display ads.
      if (mounted) state = const AppSettings();
    } finally {
      _fetching = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
