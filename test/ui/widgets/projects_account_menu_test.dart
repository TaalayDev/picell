import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/app/theme/theme.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/providers/auth_provider.dart';
import 'package:picell/ui/widgets/project/projects_account_menu.dart';

class _Auth extends Auth {
  _Auth(this.signedIn);
  final bool signedIn;
  bool loggedOut = false;

  @override
  AuthState build() => AuthState(isSignedIn: signedIn);

  @override
  Future<void> signOut() async {
    loggedOut = true;
    state = const AuthState();
  }
}

void main() {
  for (final signedIn in [false, true]) {
    testWidgets('account menu for ${signedIn ? 'signed-in user' : 'guest'}', (tester) async {
      final auth = _Auth(signedIn);
      var aboutOpened = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith(() => auth)],
          child: MaterialApp(
            theme: AppTheme.defaultTheme.themeData,
            localizationsDelegates: Strings.localizationsDelegates,
            supportedLocales: Strings.supportedLocales,
            home: Scaffold(
              appBar: AppBar(actions: [
                ProjectsAccountMenu(onPlans: () {}, onFeedback: () {}, onAbout: () => aboutOpened++),
              ]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('About'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('projects-account-menu')));
      await tester.pumpAndSettle();
      expect(find.text('Plans'), findsOneWidget);
      expect(find.text('Feedback'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      if (signedIn) {
        expect(find.text('Delete Account'), findsOneWidget);
        expect(find.text('Sign in to continue'), findsNothing);
        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();
        expect(auth.loggedOut, isTrue);
      } else {
        expect(find.text('Sign in to continue'), findsOneWidget);
        expect(find.text('Logout'), findsNothing);
        expect(find.text('Delete Account'), findsNothing);
        await tester.tap(find.text('About'));
        await tester.pumpAndSettle();
        expect(aboutOpened, 1);
      }
    });
  }
}
