import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/app/theme/theme.dart';
import 'package:picell/app/theme/flagship/flagship_extensions.dart';
import 'package:picell/ui/widgets/animated_background.dart';

void main() {
  testWidgets('Studio Dark theme builds and renders without error', (tester) async {
    final theme = AppTheme.fromType(ThemeType.studioDark);

    expect(theme.type, ThemeType.studioDark);
    expect(theme.isDark, true);
    expect(theme.flagship, isNotNull);
    expect(theme.flagship!.isFlagship, true);
    expect(ThemeType.studioDark.isLocked, false);
    expect(ThemeType.studioDark.displayName, 'Studio Dark');

    await tester.pumpWidget(
      MaterialApp(
        theme: theme.themeData,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              expect(context.isFlagship, true);
              return AnimatedBackground(
                appTheme: theme,
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 5));

    expect(tester.takeException(), isNull);
  });
}
