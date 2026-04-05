import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../providers/ad/reward_video_ad_controller.dart';
import '../../providers/subscription_provider.dart';
import '../screens/subscription_screen.dart';
import 'dialogs/reward_dialog.dart';

final themeProvider = ChangeNotifierProvider((ref) => ThemeProvider());

class ThemeSelector extends HookConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeManager = ref.watch(themeProvider);
    final currentTheme = themeManager.theme;
    final subscription = ref.watch(subscriptionStateProvider);
    final isAdLoaded = ref.watch(rewardVideoAdProvider);

    final unlockedThemeTypes = useState(
      ThemeType.values.where((type) => !type.isLocked || subscription.isPro).toList(),
    );

    return PopupMenuButton<ThemeType>(
      tooltip: 'Theme Selector',
      icon: Icon(
        Icons.palette_outlined,
        color: currentTheme.activeIcon,
      ),
      position: PopupMenuPosition.under,
      itemBuilder: (context) => ThemeType.values.map((type) {
        final theme = AppTheme.fromType(type);
        final isLocked = !unlockedThemeTypes.value.contains(type);

        return PopupMenuItem(
          value: type,
          child: _ThemeMenuItem(
            themeType: type,
            isSelected: currentTheme.type == type,
            theme: theme,
            isLocked: isLocked,
          ),
        );
      }).toList(),
      onSelected: (type) {
        if (!unlockedThemeTypes.value.contains(type) && !subscription.isPro) {
          if (!isAdLoaded) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SubscriptionOfferScreen(),
              ),
            );
            return;
          }
          RewardDialog.show(
            context,
            title: 'Unlock ${type.displayName} Theme',
            subtitle: 'Watch a video ad to unlock this theme.',
            onRewardEarned: () {
              ref.read(themeProvider).setTheme(type);

              unlockedThemeTypes.value = [
                ...unlockedThemeTypes.value,
                type,
              ];

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${type.displayName} theme unlocked!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          );
          return;
        }

        themeManager.setTheme(type);
      },
    );
  }
}

class _ThemeMenuItem extends StatelessWidget {
  final ThemeType themeType;
  final bool isSelected;
  final AppTheme theme;
  final bool isLocked;

  const _ThemeMenuItem({
    required this.themeType,
    required this.isSelected,
    required this.theme,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: theme.primaryColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.isDark ? Colors.white38 : Colors.black38,
              width: 1,
            ),
          ),
          child: isLocked
              ? Icon(
                  MaterialCommunityIcons.crown,
                  size: 16,
                  color: theme.isDark ? Colors.white70 : Colors.black54,
                )
              : const SizedBox(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(themeType.displayName),
        ),
        if (isSelected) Icon(Icons.check, color: theme.primaryColor),
      ],
    );
  }
}

class ThemeShowcase extends ConsumerWidget {
  const ThemeShowcase({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeManager = ref.watch(themeProvider);
    final currentTheme = themeManager.theme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 700,
          maxHeight: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Theme: ${currentTheme.type.displayName}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ThemeSection(
                          title: 'Primary Colors',
                          children: [
                            _ColorBox('Primary', currentTheme.primaryColor),
                            _ColorBox('Primary Variant', currentTheme.primaryVariant),
                            _ColorBox('On Primary', currentTheme.onPrimary),
                            _ColorBox('Accent', currentTheme.accentColor),
                            _ColorBox('On Accent', currentTheme.onAccent),
                          ],
                        ),
                        _ThemeSection(
                          title: 'Background Colors',
                          children: [
                            _ColorBox('Background', currentTheme.background),
                            _ColorBox('Surface', currentTheme.surface),
                            _ColorBox('Surface Variant', currentTheme.surfaceVariant),
                          ],
                        ),
                        _ThemeSection(
                          title: 'Text Colors',
                          children: [
                            _ColorBox('Text Primary', currentTheme.textPrimary),
                            _ColorBox('Text Secondary', currentTheme.textSecondary),
                            _ColorBox('Text Disabled', currentTheme.textDisabled),
                          ],
                        ),
                        _ThemeSection(
                          title: 'Utility Colors',
                          children: [
                            _ColorBox('Error', currentTheme.error),
                            _ColorBox('Success', currentTheme.success),
                            _ColorBox('Warning', currentTheme.warning),
                          ],
                        ),
                        _ThemeSection(
                          title: 'UI Elements',
                          children: [
                            _ButtonsRow(currentTheme),
                            const SizedBox(height: 16),
                            _InputsRow(currentTheme),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ThemeSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
        const Divider(height: 32),
      ],
    );
  }
}

class _ColorBox extends StatelessWidget {
  final String label;
  final Color color;

  const _ColorBox(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    final textColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Column(
      children: [
        Container(
          width: 100,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}',
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ButtonsRow extends StatelessWidget {
  final AppTheme theme;

  const _ButtonsRow(this.theme);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () {},
          child: const Text('Elevated'),
        ),
        FilledButton(
          onPressed: () {},
          child: const Text('Filled'),
        ),
        OutlinedButton(
          onPressed: () {},
          child: const Text('Outlined'),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('Text'),
        ),
      ],
    );
  }
}

class _InputsRow extends StatelessWidget {
  final AppTheme theme;

  const _InputsRow(this.theme);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.start,
      children: [
        SizedBox(
          width: 200,
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Input field',
              hintText: 'Enter text',
            ),
          ),
        ),
        Checkbox(
          value: true,
          onChanged: (_) {},
        ),
        Radio<bool>(
          value: true,
          groupValue: true,
          onChanged: (_) {},
        ),
        Switch(
          value: true,
          onChanged: (_) {},
        ),
        SizedBox(
          width: 200,
          child: Slider(
            value: 0.7,
            onChanged: (_) {},
          ),
        ),
      ],
    );
  }
}
