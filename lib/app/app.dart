import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/ui/widgets/ad_wrapper.dart';

import '../core/utils/locale_manager.dart';
import '../providers/providers.dart';
import '../l10n/strings.dart';
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
    if (state == AppLifecycleState.resumed) {
      _incrementSessionCount();
      ref.read(progressionProvider.notifier).checkIn();
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

    ref.watch(subscriptionStateProvider);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp(
        theme: appTheme.themeData,
        darkTheme: appTheme.themeData,
        themeMode: appTheme.isDark ? ThemeMode.dark : ThemeMode.light,
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => Strings.of(context).appName,
        supportedLocales: Strings.supportedLocales,
        localizationsDelegates: Strings.localizationsDelegates,
        locale: _getLocale(ref),
        home: const ProgressionNotifications(child: ProjectsScreen()),
        builder: (context, child) {
          return AdWrapper(child: child!);
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
