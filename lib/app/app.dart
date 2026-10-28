import 'package:flutter/material.dart';
import '../mcp/mcp_control.dart';
import '../core/services/subscription_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/ui/widgets/ad_wrapper.dart';

import '../core/utils/locale_manager.dart';
import '../core/services/push_notification_service.dart';
import '../providers/app_settings_provider.dart';
import '../providers/push_notifications_provider.dart';
import '../ui/widgets/notifications/push_notifications.dart';
import '../providers/providers.dart';
import '../l10n/strings.dart';
import '../providers/challenges_provider.dart';
import '../providers/feedback_chat_provider.dart';
import '../providers/progression_provider.dart';
import '../providers/subscription_provider.dart';
import '../ui/screens.dart';
import '../ui/widgets/progression/progression_notifications.dart';
import '../ui/widgets/theme_selector.dart';

class PixelVerseApp extends ConsumerStatefulWidget {
  const PixelVerseApp({super.key});

  @override
  ConsumerState<PixelVerseApp> createState() => _PixelVerseAppState();
}

class _PixelVerseAppState extends ConsumerState<PixelVerseApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _incrementSessionCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(analyticsProvider).onLifecycle(state);
    if (state == AppLifecycleState.resumed) {
      _incrementSessionCount();
      if (PushNotificationService.supported) {
        ref.read(appSettingsProvider.notifier).refresh();
        ref.read(pushNotificationsProvider).refresh();
      }
      ref.read(progressionProvider.notifier).checkIn();
      ref.read(serverRewardsProvider).sync();
      ref.read(feedbackRepliesProvider.notifier).check();
    }
  }

  void _incrementSessionCount() async {
    final reviewService = ref.read(inAppReviewProvider);
    await reviewService.incrementSessionCount();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = ref.watch(themeProvider);
    final appTheme = themeManager.theme;

    final subscription = ref.watch(subscriptionStateProvider);
    ref.read(analyticsProvider).plan = subscription.plan.name;
    ref.listen(purchaseEventsStreamProvider, (_, next) {
      final event = next.valueOrNull;
      if (event?.outcome == PurchaseOutcome.purchased) {
        ref.read(analyticsProvider).logEvent(
          name: 'purchase',
          parameters: {'product': event?.productId ?? 'unknown'},
        );
      }
    });

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        theme: appTheme.themeData,
        darkTheme: appTheme.themeData,
        themeMode: appTheme.isDark ? ThemeMode.dark : ThemeMode.light,
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => Strings.of(context).appName,
        supportedLocales: Strings.supportedLocales,
        localizationsDelegates: Strings.localizationsDelegates,
        locale: _getLocale(ref),
        home: const PushNotifications(child: ProgressionNotifications(child: ProjectsScreen())),
        builder: (context, child) {
          return McpControl(navigatorKey: _navigatorKey, child: AdWrapper(child: child!));
        },
      ),
    );
  }

  Locale _getLocale(WidgetRef ref) {
    final localeManager = LocaleManager();
    if (localeManager.isLocaleSet) {
      localeManager.initLocale();
      return localeManager.locale;
    }
    return Strings.supportedLocales.first;
  }
}
