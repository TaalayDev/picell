import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/providers/app_settings_provider.dart';

void main() {
  test('missing or malformed remote settings keep mobile banners disabled', () {
    for (final json in [
      null,
      {},
      {'mobile_bottom_banner_enabled': 'true'},
      {'mobile_bottom_banner_enabled': 1}
    ]) {
      expect(AppSettings.fromJson(json).mobileBottomBannerEnabled, isFalse);
    }
    expect(
        AppSettings.fromJson({'mobile_bottom_banner_enabled': true})
            .mobileBottomBannerEnabled,
        isTrue);
  });

  test(
      'defaults disabled until loaded, supports remote disabling, and fails closed',
      () async {
    final first = Completer<AppSettings>();
    var load = () => first.future;
    final notifier = AppSettingsNotifier(() => load());
    addTearDown(notifier.dispose);
    expect(notifier.state.mobileBottomBannerEnabled, isFalse);
    first.complete(const AppSettings(mobileBottomBannerEnabled: true));
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.mobileBottomBannerEnabled, isTrue);
    load = () async => const AppSettings();
    await notifier.refresh();
    expect(notifier.state.mobileBottomBannerEnabled, isFalse);
    load = () async => const AppSettings(mobileBottomBannerEnabled: true);
    await notifier.refresh();
    expect(notifier.state.mobileBottomBannerEnabled, isTrue);
    load = () => Future<AppSettings>.error(Exception('offline'));
    await notifier.refresh();
    expect(notifier.state.mobileBottomBannerEnabled, isFalse);
  });

  test('a request completing after disposal cannot update state', () async {
    final pending = Completer<AppSettings>();
    final notifier = AppSettingsNotifier(() => pending.future);
    notifier.dispose();
    pending.complete(const AppSettings(mobileBottomBannerEnabled: true));
    await Future<void>.delayed(Duration.zero);
  });
}
