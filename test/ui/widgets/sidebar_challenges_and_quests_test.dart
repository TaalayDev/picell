import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/app/theme/theme.dart';
import 'package:picell/data/models/challenge_models.dart';
import 'package:picell/data/models/progression_model.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/providers/challenges_provider.dart';
import 'package:picell/providers/progression_provider.dart';
import 'package:picell/ui/widgets/challenges/sidebar_challenges_and_quests.dart';

class _NoChallenges extends CurrentChallengesNotifier {
  @override
  Future<CurrentChallenges?> build() async => null;
}

class _Progression extends ProgressionNotifier {
  final quest = QuestCatalog.dailyPool.first;
  String? claimed;

  @override
  ProgressionState build() => ProgressionState(
        dailyQuestIds: [quest.id],
        progress: {'daily:${quest.id}': quest.target},
      );

  @override
  bool claim(Quest quest) {
    claimed = quest.id;
    return true;
  }
}

void main() {
  testWidgets('sidebar fits 248px, claims quests, and scrolls to all quests', (tester) async {
    final progression = _Progression();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentChallengesProvider.overrideWith(_NoChallenges.new),
          progressionProvider.overrideWith(() => progression),
        ],
        child: MaterialApp(
          theme: AppTheme.defaultTheme.themeData,
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 248,
              height: 350,
              child: SidebarChallengesAndQuests(onStartDrawing: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Daily quests'), findsOneWidget);
    final colors = AppTheme.defaultTheme.themeData.colorScheme;
    final heading = tester.widget<Text>(find.text('Daily quests'));
    final title = tester.widget<Text>(find
        .descendant(
          of: find.byKey(ValueKey('sidebar-quest-${progression.quest.id}')),
          matching: find.byType(Text),
        )
        .first);
    final progress = tester.widget<Text>(find.text('${progression.quest.target} / ${progression.quest.target}'));
    expect(heading.style?.color, colors.onSurface);
    expect(title.style?.color, colors.onSurface);
    expect(progress.style?.color, colors.onSurface.withValues(alpha: 0.7));
    double contrast(Color foreground) {
      final light = foreground.computeLuminance();
      final dark = colors.surface.computeLuminance();
      return (light + 0.05) / (dark + 0.05);
    }

    expect(contrast(heading.style!.color!), greaterThanOrEqualTo(4.5));
    await tester.tap(find.text('Claim'));
    expect(progression.claimed, progression.quest.id);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('sidebar-open-quests')),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
