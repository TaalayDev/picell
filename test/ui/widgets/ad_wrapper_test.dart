import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/models/subscription_model.dart';
import 'package:picell/providers/app_settings_provider.dart';
import 'package:picell/providers/subscription_provider.dart';
import 'package:picell/ui/widgets/ad_banner.dart';
import 'package:picell/ui/widgets/ad_wrapper.dart';

class _FreeSubscription extends SubscriptionState {
  @override
  UserSubscription build() => const UserSubscription.free();
}

void main() {
  testWidgets(
      'mobile banner appears only when remotely enabled and is removed when disabled',
      (tester) async {
    var enabled = false;
    late AppSettingsNotifier settings;
    await tester.pumpWidget(ProviderScope(overrides: [
      appSettingsProvider.overrideWith((ref) => settings = AppSettingsNotifier(
            () async => AppSettings(mobileBottomBannerEnabled: enabled),
          )),
      subscriptionStateProvider.overrideWith(_FreeSubscription.new),
    ], child: const MaterialApp(home: AdWrapper(child: Text('Editor')))));
    await tester.pump();
    expect(find.byType(AdBanner), findsNothing);
    expect(find.byType(Column), findsNothing);
    enabled = true;
    await settings.refresh();
    await tester.pump();
    expect(find.byType(AdBanner), findsOneWidget);
    enabled = false;
    await settings.refresh();
    await tester.pump();
    expect(find.byType(AdBanner), findsNothing);
    expect(find.text('Editor'), findsOneWidget);
  }, variant: const TargetPlatformVariant({TargetPlatform.android}));

  testWidgets('Pro stays ad-free when banners are enabled', (tester) async {
    // The existing debug subscription provider returns Ultimate/unlocked.
    await tester.pumpWidget(ProviderScope(overrides: [
      appSettingsProvider.overrideWith((ref) => AppSettingsNotifier(
            () async => const AppSettings(mobileBottomBannerEnabled: true),
          )),
    ], child: const MaterialApp(home: AdWrapper(child: Text('Editor')))));
    await tester.pump();
    expect(find.byType(AdBanner), findsNothing);
  }, variant: const TargetPlatformVariant({TargetPlatform.android}));
}
