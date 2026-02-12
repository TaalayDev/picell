import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/utils/cursor_manager.dart';
import '../widgets/version_text.dart';
import 'projects_screen.dart';

import '../widgets/theme_selector.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final List<PixelSquare> _squares = [];
  final List<PixelDot> _dots = [];
  final int _gridSize = 10;
  final math.Random _random = math.Random();
  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _createSquares();
    _createDots();

    _controller.forward();

    _init();
  }

  void _createSquares() {
    for (int i = 0; i < 40; i++) {
      _squares.add(PixelSquare(
        position: Offset(
          _random.nextDouble() * _gridSize * 2 - _gridSize,
          _random.nextDouble() * _gridSize * 2 - _gridSize,
        ),
        size: 0.2 + _random.nextDouble() * 0.2,
        animationDelay: _random.nextDouble() * 0.5,
        rotationSpeed: _random.nextDouble() * 0.3,
      ));
    }
  }

  void _createDots() {
    for (int i = 0; i < 100; i++) {
      _dots.add(PixelDot(
        position: Offset(
          _random.nextDouble() * _gridSize * 4 - _gridSize * 2,
          _random.nextDouble() * _gridSize * 4 - _gridSize * 2,
        ),
        size: 0.05 + _random.nextDouble() * 0.05,
        animationDelay: _random.nextDouble() * 0.5,
        speed: 0.01 + _random.nextDouble() * 0.05,
      ));
    }
  }

  Future<void> _init() async {
    await CursorManager.instance.init();

    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 3000));

    // Simulate loading for a smoother experience
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted || _navigating) return;

    setState(() {
      _navigating = true;
    });

    // Navigate to next screen
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ProjectsScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider).theme;

    return Scaffold(
      backgroundColor: theme.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedOpacity(
                      opacity: _fadeAnimation.value,
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        'PICELL',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: theme.textPrimary,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: theme.primaryColor.withOpacity(0.6),
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedOpacity(
                      opacity: _fadeAnimation.value,
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        'CREATE • ANIMATE • PIXELATE',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 2,
                          color: theme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    AnimatedOpacity(
                      opacity: _fadeAnimation.value,
                      duration: const Duration(milliseconds: 500),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _fadeAnimation.value,
                  duration: const Duration(milliseconds: 500),
                  child: Center(
                    child: VersionTextBuilder(builder: (context, version, isLoading) {
                      if (isLoading) {
                        return const SizedBox();
                      }

                      return Text(
                        version,
                        style: TextStyle(
                          color: theme.textSecondary.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PixelSquare {
  final Offset position;
  final double size;
  final double animationDelay;
  final double rotationSpeed;

  PixelSquare({
    required this.position,
    required this.size,
    required this.animationDelay,
    required this.rotationSpeed,
  });
}

class PixelDot {
  final Offset position;
  final double size;
  final double animationDelay;
  final double speed;

  PixelDot({
    required this.position,
    required this.size,
    required this.animationDelay,
    required this.speed,
  });
}

class PixelLogoPainter extends CustomPainter {
  final double animation;
  final List<PixelSquare> squares;
  final Color primaryColor;
  final Color secondaryColor;
  final bool brightBackground;

  PixelLogoPainter({
    required this.animation,
    required this.squares,
    required this.primaryColor,
    required this.secondaryColor,
    required this.brightBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final gridSize = size.width / 10;

    // Draw pixel art logo
    final logoPixels = [
      // P
      [1, 1, 1, 1, 0],
      [1, 0, 0, 1, 0],
      [1, 0, 0, 1, 0],
      [1, 1, 1, 1, 0],
      [1, 0, 0, 0, 0],
      [1, 0, 0, 0, 0],

      // V
      [0, 1, 0, 0, 0, 1, 0],
      [0, 1, 0, 0, 0, 1, 0],
      [0, 1, 0, 0, 0, 1, 0],
      [0, 0, 1, 0, 1, 0, 0],
      [0, 0, 1, 0, 1, 0, 0],
      [0, 0, 0, 1, 0, 0, 0],
    ];

    final paint = Paint();

    // Calculate the starting position for the logo
    final startX = centerX - (logoPixels[0].length * gridSize) / 2;
    final startY = centerY - (logoPixels.length * gridSize) / 2;

    for (int y = 0; y < logoPixels.length; y++) {
      for (int x = 0; x < logoPixels[y].length; x++) {
        if (logoPixels[y][x] == 1) {
          final delayFactor = 0.7 + (x + y) / (logoPixels.length + logoPixels[0].length) * 0.3;
          final animationProgress = math.max(0, math.min(1, (animation - 0.3) / delayFactor));

          // Determine pixel color with alternating pattern
          final isEven = (x + y) % 2 == 0;
          paint.color = isEven
              ? primaryColor.withOpacity(animationProgress.toDouble())
              : secondaryColor.withOpacity(animationProgress.toDouble());

          // Calculate pixel position
          final pixelX = startX + x * gridSize;
          final pixelY = startY + y * gridSize;

          // Draw pixel with slight scaling effect
          final scale = 0.9 + animationProgress * 0.1;
          final pixelSize = gridSize * scale;
          final offset = (gridSize - pixelSize) / 2;

          canvas.drawRect(
            Rect.fromLTWH(pixelX + offset, pixelY + offset, pixelSize, pixelSize),
            paint,
          );
        }
      }
    }

    // Draw animated squares
    for (final square in squares) {
      final squareAnimation = math.max(0, math.min(1, animation - square.animationDelay));

      if (squareAnimation > 0) {
        final squareOpacity = math.sin(squareAnimation * math.pi) * 0.6;

        paint.color = primaryColor.withOpacity(squareOpacity * 0.3);

        // Calculate square position with rotation around the center
        final angle = square.rotationSpeed * animation * math.pi * 2;
        final distance = square.position.distance * gridSize * 3 * squareAnimation;

        final dx = math.cos(angle) * distance;
        final dy = math.sin(angle) * distance;

        final squareX = centerX + dx;
        final squareY = centerY + dy;
        final squareSize = gridSize * square.size;

        canvas.drawRect(
          Rect.fromLTWH(squareX, squareY, squareSize, squareSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PixelLogoPainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}

class PixelBackgroundPainter extends CustomPainter {
  final List<PixelDot> dots;
  final double animation;
  final Color color;

  PixelBackgroundPainter({
    required this.dots,
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final paint = Paint()..color = color;

    for (final dot in dots) {
      final dotAnimation = math.max(0, math.min(1, animation - dot.animationDelay));

      if (dotAnimation > 0) {
        // Pulsating effect
        final pulse = (math.sin(animation * 3 + dot.animationDelay * 10) + 1) / 2;
        final dotOpacity = 0.3 + pulse * 0.7;

        paint.color = color.withOpacity(dotOpacity * 0.5);

        // Moving outward
        final angle = dot.position.direction;
        final distance = dot.position.distance * size.width / 4 * (0.2 + dotAnimation * 0.8);
        final speed = dot.speed * animation * 100;

        final dx = math.cos(angle) * (distance + speed);
        final dy = math.sin(angle) * (distance + speed);

        final dotX = centerX + dx;
        final dotY = centerY + dy;
        final dotSize = size.width * dot.size * (0.5 + pulse * 0.5);

        // Only draw dots within the screen
        if (dotX > -dotSize && dotX < size.width + dotSize && dotY > -dotSize && dotY < size.height + dotSize) {
          canvas.drawCircle(
            Offset(dotX, dotY),
            dotSize,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(PixelBackgroundPainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}
