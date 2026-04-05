import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../data/models/subscription_model.dart';
import '../../providers/subscription_provider.dart';
import '../screens/subscription_screen.dart';
import 'animated_background.dart';
import 'theme_selector.dart';

// Flagship theme types — lazily computed once.
final _flagshipTypes = ThemeType.values
    .where((t) => AppTheme.fromType(t).flagship != null)
    .toList();

class ThemeSelectorBottomSheet extends HookConsumerWidget {
  const ThemeSelectorBottomSheet({super.key});

  /// Shows a dialog on desktop (width ≥ 800) or a bottom sheet on mobile.
  static Future<void> show(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 800) {
      return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => const _ThemeSelectorDialog(),
      );
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ThemeSelectorBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => _ThemeSelectorContent(
        scrollController: scrollController,
        showHandle: true,
        isDialog: false,
      ),
    );
  }
}

class _ThemeSelectorDialog extends HookConsumerWidget {
  const _ThemeSelectorDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 760),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _ThemeSelectorContent(
            scrollController: scrollController,
            showHandle: false,
            isDialog: true,
          ),
        ),
      ),
    );
  }
}

class _ThemeSelectorContent extends HookConsumerWidget {
  final ScrollController scrollController;
  final bool showHandle;
  final bool isDialog;

  const _ThemeSelectorContent({
    required this.scrollController,
    required this.showHandle,
    required this.isDialog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeManager = ref.watch(themeProvider);
    final currentTheme = themeManager.theme;
    final subscription = ref.watch(subscriptionStateProvider);

    final unlockedThemeTypes = useState(
      ThemeType.values.where((type) => !type.isLocked || subscription.isPro).toList(),
    );

    final selectedTheme = useState<ThemeType?>(null);
    final previewTheme = selectedTheme.value != null
        ? AppTheme.fromType(selectedTheme.value!)
        : currentTheme;

    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;

    // Flagship themes are always treated as unlocked.
    final effectiveUnlocked = [
      ...unlockedThemeTypes.value,
      ..._flagshipTypes,
    ];

    return AnimatedBackground(
      intensity: 0.3,
      enableAnimation: true,
      child: Container(
        decoration: BoxDecoration(
          color: previewTheme.surface.withValues(alpha: 0.95),
          borderRadius: showHandle
              ? const BorderRadius.vertical(top: Radius.circular(20))
              : BorderRadius.circular(20),
          border: Border.all(
            color: previewTheme.divider.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Handle bar — bottom sheet only
            if (showHandle)
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: previewTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.palette_outlined,
                      color: previewTheme.primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Theme',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: previewTheme.textPrimary,
                          ),
                        ),
                        Text(
                          selectedTheme.value != null
                              ? 'Previewing ${selectedTheme.value!.displayName}'
                              : 'Current: ${currentTheme.type.displayName}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: previewTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selectedTheme.value != null) ...[
                    if (!isSmallScreen) ...[
                      TextButton(
                        onPressed: () => selectedTheme.value = null,
                        child: Text('Cancel',
                            style:
                                TextStyle(color: previewTheme.textSecondary)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    OutlinedButton(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => ThemeShowcase(theme: previewTheme),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: previewTheme.primaryColor),
                        foregroundColor: previewTheme.primaryColor,
                      ),
                      child: const Text('Preview'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final type = selectedTheme.value!;
                        if (type.isLocked && !subscription.isPro) {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const SubscriptionOfferScreen(),
                          ));
                          return;
                        }
                        themeManager.setTheme(type);
                        Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: previewTheme.primaryColor,
                        foregroundColor: previewTheme.onPrimary,
                      ),
                      child: const Text('Apply'),
                    ),
                  ] else
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: previewTheme.textSecondary),
                    ),
                ],
              ),
            ),

            // ── Pro promo banner ─────────────────────────────────────────
            if (!subscription.isPro) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      previewTheme.primaryColor.withValues(alpha: 0.1),
                      previewTheme.accentColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: previewTheme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(MaterialCommunityIcons.crown,
                        color: previewTheme.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Unlock Premium Themes',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: previewTheme.textPrimary)),
                          Text('Get access to all themes with Pro',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: previewTheme.textSecondary)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        SubscriptionOfferScreen.show(context);
                      },
                      child: Text('Get Pro',
                          style: TextStyle(
                              color: previewTheme.primaryColor,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Theme grid ───────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✦ Flagship — always free, shown first
                    _ThemeList(
                      title: Row(
                        children: [
                          Text(
                            '✦ Flagship',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: previewTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: previewTheme.primaryColor
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: previewTheme.primaryColor
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'FREE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: previewTheme.primaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      themes: _flagshipTypes,
                      currentTheme: currentTheme,
                      selectedTheme: selectedTheme,
                      unlockedThemes: effectiveUnlocked,
                      subscription: subscription,
                      previewTheme: previewTheme,
                    ),

                    const SizedBox(height: 8),

                    // Free themes (non-flagship)
                    _ThemeList(
                      title: Text('Free Themes',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: previewTheme.textPrimary)),
                      themes: ThemeType.values
                          .where((t) =>
                              !t.isLocked && !_flagshipTypes.contains(t))
                          .toList(),
                      currentTheme: currentTheme,
                      selectedTheme: selectedTheme,
                      unlockedThemes: unlockedThemeTypes.value,
                      subscription: subscription,
                      previewTheme: previewTheme,
                    ),

                    // Premium themes (non-flagship)
                    _ThemeList(
                      title: Text('Premium Themes',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: previewTheme.textPrimary)),
                      themes: ThemeType.values
                          .where((t) =>
                              t.isLocked && !_flagshipTypes.contains(t))
                          .toList(),
                      currentTheme: currentTheme,
                      selectedTheme: selectedTheme,
                      unlockedThemes: unlockedThemeTypes.value,
                      subscription: subscription,
                      previewTheme: previewTheme,
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeList extends ConsumerWidget {
  final Widget title;
  final List<ThemeType> themes;
  final AppTheme currentTheme;
  final ValueNotifier<ThemeType?> selectedTheme;
  final List<ThemeType> unlockedThemes;
  final UserSubscription subscription;
  final AppTheme previewTheme;

  const _ThemeList({
    super.key,
    required this.title,
    required this.themes,
    required this.currentTheme,
    required this.selectedTheme,
    required this.unlockedThemes,
    required this.subscription,
    required this.previewTheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (themes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 600 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: themes.length,
              itemBuilder: (context, index) {
                final themeType = themes[index];
                final theme = AppTheme.fromType(themeType);
                final isLocked =
                    !unlockedThemes.contains(themeType) && !subscription.isPro;
                final isSelected = selectedTheme.value == themeType;
                final isCurrent =
                    currentTheme.type == themeType && selectedTheme.value == null;

                return ThemePreviewCard(
                  themeType: themeType,
                  theme: theme,
                  isLocked: isLocked,
                  isSelected: isSelected,
                  isCurrent: isCurrent,
                  onTap: () {
                    selectedTheme.value = isSelected ? null : themeType;
                  },
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class ThemePreviewCard extends HookWidget {
  final ThemeType themeType;
  final AppTheme theme;
  final bool isLocked;
  final bool isSelected;
  final bool isCurrent;
  final VoidCallback onTap;

  const ThemePreviewCard({
    super.key,
    required this.themeType,
    required this.theme,
    required this.isLocked,
    required this.isSelected,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : isCurrent
                    ? theme.accentColor
                    : theme.divider,
            width: isSelected || isCurrent ? 3 : 1,
          ),
          boxShadow: [
            if (isSelected || isCurrent)
              BoxShadow(
                color: (isSelected ? theme.primaryColor : theme.accentColor).withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.background,
                      Color.lerp(theme.background, theme.primaryColor, 0.1)!,
                      Color.lerp(theme.background, theme.accentColor, 0.05)!,
                    ],
                  ),
                ),
              ),

              // Mini animated background
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: AnimatedBackground(
                  intensity: 0.5,
                  enableAnimation: false,
                  appTheme: theme,
                  child: Container(color: Colors.transparent),
                ),
              ),

              // Overlay for better contrast
              // Container(
              //   decoration: BoxDecoration(
              //     gradient: LinearGradient(
              //       begin: Alignment.topCenter,
              //       end: Alignment.bottomCenter,
              //       colors: [
              //         Colors.transparent,
              //         theme.background.withValues(alpha:0.8),
              //       ],
              //     ),
              //   ),
              // ),

              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row with status icons
                    Row(
                      children: [
                        if (isLocked)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              MaterialCommunityIcons.crown,
                              size: 16,
                              color: Colors.orange,
                            ),
                          ),
                        // Flagship badge
                        Builder(builder: (context) {
                          final flagship = theme.flagship;
                          if (flagship == null || !flagship.isFlagship) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            margin: EdgeInsets.only(left: isLocked ? 4 : 0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: flagship.badgeColor.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              flagship.badgeLabel,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: flagship.badgeTextColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          );
                        }),
                        const Spacer(),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.accentColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Current',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.onAccent,
                              ),
                            ),
                          ),
                        if (isSelected && !isCurrent)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.check,
                              size: 16,
                              color: theme.onPrimary,
                            ),
                          ),
                      ],
                    ),

                    const Spacer(),

                    // Theme name
                    Text(
                      themeType.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Color indicators
                    Row(
                      children: [
                        _buildColorDot(theme.primaryColor),
                        const SizedBox(width: 4),
                        _buildColorDot(theme.accentColor),
                        const SizedBox(width: 4),
                        _buildColorDot(theme.surface),
                        const Spacer(),
                        Text(
                          theme.isDark ? 'Dark' : 'Light',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Lock overlay
              if (isLocked)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Icon(
                      MaterialCommunityIcons.lock,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhanced Theme Showcase Dialog
class ThemeShowcase extends StatelessWidget {
  final AppTheme theme;

  const ThemeShowcase({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 700,
          maxHeight: 600,
        ),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with animated background
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.8),
                    theme.accentColor.withValues(alpha: 0.6),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Mini animated background
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: AnimatedBackground(
                      appTheme: theme,
                      intensity: 0.8,
                      enableAnimation: true,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  // Header content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.palette,
                          color: theme.onPrimary,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                theme.type.displayName,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.onPrimary,
                                ),
                              ),
                              Text(
                                '${theme.isDark ? 'Dark' : 'Light'} Theme Preview',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.onPrimary.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: theme.onPrimary),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ThemeSection(
                        title: 'Primary Colors',
                        theme: theme,
                        children: [
                          _ColorBox('Primary', theme.primaryColor),
                          _ColorBox('Primary Variant', theme.primaryVariant),
                          _ColorBox('On Primary', theme.onPrimary),
                          _ColorBox('Accent', theme.accentColor),
                          _ColorBox('On Accent', theme.onAccent),
                        ],
                      ),
                      _ThemeSection(
                        title: 'Background Colors',
                        theme: theme,
                        children: [
                          _ColorBox('Background', theme.background),
                          _ColorBox('Surface', theme.surface),
                          _ColorBox('Surface Variant', theme.surfaceVariant),
                        ],
                      ),
                      _ThemeSection(
                        title: 'Text Colors',
                        theme: theme,
                        children: [
                          _ColorBox('Text Primary', theme.textPrimary),
                          _ColorBox('Text Secondary', theme.textSecondary),
                          _ColorBox('Text Disabled', theme.textDisabled),
                        ],
                      ),
                      _ThemeSection(
                        title: 'UI Elements',
                        theme: theme,
                        children: [
                          _ButtonsRow(theme),
                          const SizedBox(height: 16),
                          _InputsRow(theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  final String title;
  final AppTheme theme;
  final List<Widget> children;

  const _ThemeSection({
    required this.title,
    required this.theme,
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: theme.divider),
        ),
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
          style: const TextStyle(fontSize: 12),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: theme.onPrimary,
          ),
          child: const Text('Elevated'),
        ),
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: theme.onPrimary,
          ),
          child: const Text('Filled'),
        ),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: theme.primaryColor),
            foregroundColor: theme.primaryColor,
          ),
          child: const Text('Outlined'),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: theme.primaryColor,
          ),
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
            decoration: InputDecoration(
              labelText: 'Input field',
              hintText: 'Enter text',
              labelStyle: TextStyle(color: theme.textSecondary),
              hintStyle: TextStyle(color: theme.textDisabled),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.primaryColor),
              ),
            ),
            style: TextStyle(color: theme.textPrimary),
          ),
        ),
        Checkbox(
          value: true,
          onChanged: (_) {},
          activeColor: theme.primaryColor,
        ),
        Radio<bool>(
          value: true,
          groupValue: true,
          onChanged: (_) {},
          activeColor: theme.primaryColor,
        ),
        Switch(
          value: true,
          onChanged: (_) {},
          activeColor: theme.primaryColor,
        ),
        SizedBox(
          width: 200,
          child: Slider(
            value: 0.7,
            onChanged: (_) {},
            activeColor: theme.primaryColor,
            inactiveColor: theme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

Widget _buildColorDot(Color color) {
  return Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.3),
        width: 1,
      ),
    ),
  );
}
