import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';
import 'package:picell/ui/widgets/fields/ui_field_builder.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: Strings.localizationsDelegates,
      supportedLocales: Strings.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  testWidgets('UIFieldBuilder builds slider and displays value and limits', (tester) async {
    final values = <String, dynamic>{'radius': 15.0};
    dynamic changedValue;

    final fields = [
      const SliderField(
        key: 'radius',
        label: 'Blur Radius',
        description: 'Adjusts the blur kernel radius.',
        min: 0,
        max: 50,
      ),
    ];

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) => Column(
            children: UIFieldBuilder.buildAll(
              context: context,
              fields: fields,
              values: values,
              onChanged: (key, value) {
                changedValue = value;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blur Radius'), findsOneWidget);
    expect(find.text('15'), findsOneWidget); // Trailing badge
    expect(find.text('0'), findsOneWidget); // Min limit
    expect(find.text('50'), findsOneWidget); // Max limit

    // Test dragging slider triggers onChanged
    await tester.drag(find.byType(Slider), const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(changedValue, isNotNull);
  });

  testWidgets('Description popup opens on tap and shows description', (tester) async {
    final values = <String, dynamic>{'radius': 10.0};

    final fields = [
      const SliderField(
        key: 'radius',
        label: 'Blur Radius',
        description: 'Adjusts the blur kernel radius.',
        min: 0,
        max: 50,
      ),
    ];

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) => Column(
            children: UIFieldBuilder.buildAll(
              context: context,
              fields: fields,
              values: values,
              onChanged: (k, v) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The info icon button is present
    final infoIcon = find.byIcon(Icons.info_outline_rounded);
    expect(infoIcon, findsOneWidget);

    // Tap info icon to show popup
    await tester.tap(infoIcon);
    await tester.pumpAndSettle();

    // Description text is now visible in the popup
    expect(find.text('Adjusts the blur kernel radius.'), findsOneWidget);
    expect(find.byIcon(Icons.info_rounded), findsOneWidget);

    // Close button dismisses popup
    final closeIcon = find.byIcon(Icons.close_rounded);
    expect(closeIcon, findsOneWidget);
    await tester.tap(closeIcon);
    await tester.pumpAndSettle();

    // Description popup is closed
    expect(find.text('Adjusts the blur kernel radius.'), findsNothing);
  });

  testWidgets('UIFieldBuilder builds color field with swatch and hex', (tester) async {
    final values = <String, dynamic>{'tint': 0xFFFF5722};

    final fields = [
      const ColorField(
        key: 'tint',
        label: 'Tint Color',
        description: 'Choose a tint color.',
      ),
    ];

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) => Column(
            children: UIFieldBuilder.buildAll(
              context: context,
              fields: fields,
              values: values,
              onChanged: (k, v) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tint Color'), findsOneWidget);
    expect(find.text('#FF5722'), findsOneWidget);
    expect(find.byIcon(Icons.colorize_rounded), findsOneWidget);
  });

  testWidgets('UIFieldBuilder builds bool field and toggles on tap', (tester) async {
    final values = <String, dynamic>{'invert': false};
    dynamic toggledValue;

    final fields = [
      const BoolField(
        key: 'invert',
        label: 'Invert Colors',
        description: 'Inverts RGB channels.',
      ),
    ];

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) => Column(
            children: UIFieldBuilder.buildAll(
              context: context,
              fields: fields,
              values: values,
              onChanged: (key, value) {
                toggledValue = value;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Invert Colors'), findsOneWidget);

    // Tap the bool row to toggle
    await tester.tap(find.text('Invert Colors'));
    await tester.pumpAndSettle();

    expect(toggledValue, true);
  });

  testWidgets('UIFieldBuilder builds select field and options', (tester) async {
    final values = <String, dynamic>{'mode': 'fast'};
    dynamic selectedValue;

    final fields = [
      const SelectField<String>(
        key: 'mode',
        label: 'Rendering Mode',
        options: {
          'fast': 'Fast Mode',
          'quality': 'High Quality',
        },
      ),
    ];

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) => Column(
            children: UIFieldBuilder.buildAll(
              context: context,
              fields: fields,
              values: values,
              onChanged: (key, value) {
                selectedValue = value;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rendering Mode'), findsOneWidget);
    expect(find.text('Fast Mode'), findsOneWidget);

    // Open dropdown
    await tester.tap(find.text('Fast Mode'));
    await tester.pumpAndSettle();

    // Select High Quality
    await tester.tap(find.text('High Quality').last);
    await tester.pumpAndSettle();

    expect(selectedValue, 'quality');
  });

  testWidgets('UIFieldBuilder builds section header and group header', (tester) async {
    final values = <String, dynamic>{'dummy': 1.0};

    final fields = [
      const SectionField(
        label: 'Advanced Settings',
        description: 'Fine-tune advanced options.',
      ),
      const SliderField(
        key: 'dummy',
        label: 'Param',
        group: 'Group 1',
        min: 0,
        max: 10,
      ),
    ];

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) => Column(
            children: UIFieldBuilder.buildAll(
              context: context,
              fields: fields,
              values: values,
              onChanged: (k, v) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ADVANCED SETTINGS'), findsOneWidget);
    expect(find.text('Fine-tune advanced options.'), findsOneWidget);
    expect(find.text('Group 1'), findsOneWidget);
  });

  group('enhancements', () {
    Future<void> pump(
      WidgetTester tester,
      List<UIField> fields,
      Map<String, dynamic> values,
      void Function(String, dynamic) onChanged, {
      Map<String, dynamic>? defaults,
      bool collapsibleGroups = false,
      bool segmentedSelects = false,
    }) async {
      await tester.pumpWidget(buildTestableWidget(
        Builder(
          builder: (context) => Column(
            children: UIFieldBuilder.buildAll(
              context: context,
              fields: fields,
              values: values,
              onChanged: onChanged,
              defaults: defaults,
              collapsibleGroups: collapsibleGroups,
              segmentedSelects: segmentedSelects,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('a changed value offers a reset to its default', (tester) async {
      dynamic changed;
      await pump(
        tester,
        const [SliderField(key: 'radius', label: 'Radius', min: 0, max: 50)],
        {'radius': 15.0},
        (key, value) => changed = value,
        defaults: {'radius': 10.0},
      );
      await tester.tap(find.byIcon(Icons.restart_alt_rounded));
      expect(changed, 10.0);
    });

    testWidgets('no reset is offered at the default, or without defaults', (tester) async {
      await pump(
          tester, const [SliderField(key: 'radius', label: 'Radius', min: 0, max: 50)], {'radius': 10.0}, (_, __) {},
          defaults: {'radius': 10.0});
      expect(find.byIcon(Icons.restart_alt_rounded), findsNothing);
      await pump(
          tester, const [SliderField(key: 'radius', label: 'Radius', min: 0, max: 50)], {'radius': 15.0}, (_, __) {});
      expect(find.byIcon(Icons.restart_alt_rounded), findsNothing);
    });

    testWidgets('tapping a slider value lets you type an exact one, snapped to its steps', (tester) async {
      dynamic changed;
      await pump(
        tester,
        const [SliderField(key: 'count', label: 'Count', min: 0, max: 10, divisions: 5, isInteger: true)],
        {'count': 2},
        (key, value) => changed = value,
      );
      await tester.tap(find.text('2').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '7');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(changed, 8); // steps of 2: 7 is nearest to 8
    });

    testWidgets('a value typed out of range is clamped', (tester) async {
      dynamic changed;
      await pump(tester, const [SliderField(key: 'v', label: 'V', min: 0, max: 5)], {'v': 1.0},
          (key, value) => changed = value);
      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '99');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(changed, 5.0);
    });

    testWidgets('short selects become a segmented control when asked, long ones stay drop-downs', (tester) async {
      dynamic changed;
      final fields = [
        const SelectField<String>(key: 'facing', label: 'Facing', options: {'right': 'Right', 'left': 'Left'}),
        const SelectField<String>(
          key: 'mode',
          label: 'Mode',
          options: {'a': 'A very long option name', 'b': 'Another long option name'},
        ),
      ];
      await pump(tester, fields, {'facing': 'right', 'mode': 'a'}, (key, value) => changed = value,
          segmentedSelects: true);
      expect(find.byType(SegmentedButton<dynamic>), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<dynamic>), findsOneWidget);
      await tester.tap(find.text('Left'));
      await tester.pumpAndSettle();
      expect(changed, 'left');

      await pump(tester, fields, {'facing': 'right', 'mode': 'a'}, (_, __) {});
      expect(find.byType(SegmentedButton<dynamic>), findsNothing);
    });

    testWidgets('grouped fields fold away when groups are collapsible', (tester) async {
      await pump(
        tester,
        const [
          SliderField(key: 'a', label: 'Alpha', min: 0, max: 1, group: 'Look'),
          SliderField(key: 'b', label: 'Beta', min: 0, max: 1, group: 'Look'),
          SliderField(key: 'c', label: 'Gamma', min: 0, max: 1),
        ],
        {'a': 0.5, 'b': 0.5, 'c': 0.5},
        (_, __) {},
        collapsibleGroups: true,
      );
      expect(find.text('Alpha'), findsOneWidget);
      await tester.tap(find.text('Look'));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Beta'), findsNothing);
      expect(find.text('Gamma'), findsOneWidget); // ungrouped stays
      await tester.tap(find.text('Look'));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
    });
  });
}
