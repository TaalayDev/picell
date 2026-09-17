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
}
