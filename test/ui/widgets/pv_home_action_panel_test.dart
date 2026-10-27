import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/app/theme/theme.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/ui/widgets/project/home/pv_home_action_panel.dart';
import 'package:picell/ui/widgets/project/home/pv_my_projects.dart';

void main() {
  for (final isPro in [false, true]) {
    testWidgets('${isPro ? 'Pro' : 'Free'} home card shows the right actions', (tester) async {
      var previewed = 0;
      int? pickedSize;
      var imported = 0;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.defaultTheme.themeData,
            localizationsDelegates: Strings.localizationsDelegates,
            supportedLocales: Strings.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 260,
                child: PvHomeActionPanel(
                  isPro: isPro,
                  onPreviewPro: () => previewed++,
                  onPickSize: (size) => pickedSize = size,
                  onImport: () => imported++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (isPro) {
        expect(find.byType(PvQuickCreatePanel), findsOneWidget);
        expect(find.byKey(const ValueKey('home-pro-preview')), findsNothing);
        await tester.tap(find.text('32×32'));
        expect(pickedSize, 32);
        await tester.tap(find.text('Import image or project file'));
        expect(imported, 1);
        expect(previewed, 0);
      } else {
        expect(find.byType(PvQuickCreatePanel), findsNothing);
        expect(find.text('PICELL PRO'), findsOneWidget);
        expect(find.text('Bone rigger'), findsOneWidget);
        await tester.tap(find.text('Upgrade to Pro'));
        expect(previewed, 1);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
