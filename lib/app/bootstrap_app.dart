import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/services/analytics_service.dart';
import '../core/utils/cursor_manager.dart';
import '../data/storage/local_storage.dart';
import '../firebase_options.dart';
import '../providers/providers.dart';
import 'app.dart';

const _splashBackground = Color(0xFF0D0F21);
const _splashCream = Color(0xFFFFF1C7);
const _splashCoral = Color(0xFFF35939);

/// Renders the first Flutter frame immediately, then performs application
/// startup work behind the branded splash screen.
class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  AnalyticsService? _analytics;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      await Future.wait([
        dotenv.load(fileName: '.env'),
        LocalStorage.init(),
      ]);

      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        unawaited(MobileAds.instance.initialize());
      }

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final analytics = AnalyticsService(FirebaseAnalytics.instance);
      await Future.wait([
        analytics.initializeAmplitude(dotenv.env['AMPLITUDE_API_KEY']),
        CursorManager.instance.init(),
      ]);

      if (!mounted) return;
      setState(() {
        _analytics = analytics;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Application bootstrap failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final analytics = _analytics;
    if (!_loading && analytics != null) {
      return ProviderScope(
        overrides: [analyticsProvider.overrideWithValue(analytics)],
        child: const PixelVerseApp(),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: _splashBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _splashCoral,
          brightness: Brightness.dark,
          surface: _splashBackground,
        ),
      ),
      home: _BootstrapSplash(
        error: _error,
        onRetry: _initialize,
      ),
    );
  }
}

class _BootstrapSplash extends StatefulWidget {
  const _BootstrapSplash({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  State<_BootstrapSplash> createState() => _BootstrapSplashState();
}

class _BootstrapSplashState extends State<_BootstrapSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.15),
                radius: 0.9,
                colors: [Color(0xFF202044), _splashBackground],
                stops: [0, 1],
              ),
            ),
          ),
          const _PixelStars(),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final value = Curves.easeInOut.transform(_controller.value);
                return Transform.scale(
                  scale: 0.98 + value * 0.025,
                  child: Opacity(opacity: 0.88 + value * 0.12, child: child),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 144,
                    height: 144,
                    filterQuality: FilterQuality.none,
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'PICELL',
                    style: TextStyle(
                      color: _splashCream,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 7,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'CREATE  •  ANIMATE  •  PIXELATE',
                    style: TextStyle(
                      color: _splashCream.withValues(alpha: 0.62),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 32,
            right: 32,
            bottom: 54,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: widget.error == null
                  ? const Column(
                      key: ValueKey('loading'),
                      children: [
                        SizedBox(
                          width: 118,
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            color: _splashCoral,
                            backgroundColor: Color(0x33FFF1C7),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Preparing your workspace',
                          style: TextStyle(
                            color: Color(0x99FFF1C7),
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey('error'),
                      children: [
                        const Text(
                          'Picell could not finish starting.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _splashCream, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: widget.onRetry,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PixelStars extends StatelessWidget {
  const _PixelStars();

  @override
  Widget build(BuildContext context) {
    const stars = <({double x, double y, double size, Color color})>[
      (x: 0.12, y: 0.18, size: 5, color: _splashCream),
      (x: 0.82, y: 0.15, size: 4, color: _splashCream),
      (x: 0.9, y: 0.43, size: 5, color: _splashCoral),
      (x: 0.16, y: 0.7, size: 4, color: _splashCoral),
      (x: 0.76, y: 0.76, size: 3, color: _splashCream),
    ];

    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          for (final star in stars)
            Positioned(
              left: constraints.maxWidth * star.x,
              top: constraints.maxHeight * star.y,
              child: ColoredBox(
                color: star.color.withValues(alpha: 0.7),
                child: SizedBox.square(dimension: star.size),
              ),
            ),
        ],
      ),
    );
  }
}
