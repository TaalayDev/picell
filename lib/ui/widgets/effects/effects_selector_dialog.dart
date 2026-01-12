import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/models/subscription_model.dart';
import '../../../pixel/effects/effects.dart';
import '../../../providers/subscription_provider.dart';
import '../../screens/subscription_screen.dart';
import '../animated_background.dart';
import '../subscription/feature_gate.dart';

class EffectSelectorDialog extends ConsumerStatefulWidget {
  final Function(Effect) onEffectSelected;

  const EffectSelectorDialog({
    super.key,
    required this.onEffectSelected,
  });

  @override
  ConsumerState<EffectSelectorDialog> createState() => _EffectSelectorDialogState();
}

class _EffectSelectorDialogState extends ConsumerState<EffectSelectorDialog> {
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;

  final _categories = [
    'All',
    'Color & Tone',
    'Blur & Sharpen',
    'Artistic',
    'Animation',
    'Nature',
    'Particles',
    'Distortion',
    'Textures',
    'Special FX',
  ];

  List<EffectType> get _filteredEffects {
    const allEffects = EffectType.values;

    // First filter by category
    List<EffectType> categoryFiltered;

    switch (_selectedCategoryIndex) {
      case 1: // Color & Tone
        categoryFiltered = [
          EffectType.brightness,
          EffectType.contrast,
          EffectType.invert,
          EffectType.grayscale,
          EffectType.sepia,
          EffectType.colorBalance,
          EffectType.threshold,
          EffectType.gradient,
          EffectType.paletteReduction,
        ];
        break;
      case 2: // Blur & Sharpen
        categoryFiltered = [
          EffectType.blur,
          EffectType.sharpen,
          EffectType.pixelate,
        ];
        break;
      case 3: // Artistic
        categoryFiltered = [
          EffectType.emboss,
          EffectType.vignette,
          EffectType.outline,
          EffectType.dithering,
          EffectType.watercolor,
          EffectType.halftone,
          EffectType.oilPaint,
          EffectType.stainedGlass,
        ];
        break;
      case 4: // Animation
        categoryFiltered = [
          EffectType.pulse,
          EffectType.wave,
          EffectType.rotate,
          EffectType.float,
          EffectType.simpleFloat,
          EffectType.physicsFloat,
          EffectType.shake,
          EffectType.quickShake,
          EffectType.cameraShake,
          EffectType.jello,
        ];
        break;
      case 5: // Nature
        categoryFiltered = [
          EffectType.fire,
          EffectType.wood,
          EffectType.rain,
          EffectType.stone,
          EffectType.mountainRange,
          EffectType.forest,
          EffectType.ocean,
          EffectType.clouds,
          EffectType.treeBark,
          EffectType.leafVenation,
          EffectType.fog,
        ];
        break;
      case 6: // Particles
        categoryFiltered = [
          EffectType.sparkle,
          EffectType.particle,
          EffectType.explosion,
          EffectType.glow,
        ];
        break;
      case 7: // Distortion
        categoryFiltered = [
          EffectType.glitch,
          EffectType.dissolve,
          EffectType.fadeDissolve,
          EffectType.melt,
          EffectType.wipe,
        ];
        break;
      case 8: // Textures
        categoryFiltered = [
          EffectType.crystal,
          EffectType.metal,
          EffectType.noise,
        ];
        break;
      case 9: // Special FX
        categoryFiltered = [
          EffectType.city,
        ];
        break;
      default: // All
        categoryFiltered = allEffects;
    }

    // Then filter by search
    if (_searchQuery.isEmpty) {
      return categoryFiltered;
    }

    return categoryFiltered.where((type) {
      final name = type.toString().split('.').last;
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final subscriptionState = ref.watch(subscriptionStateProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: isMobile ? double.infinity : 600,
        height: isMobile ? double.infinity : 500,
        child: AnimatedBackground(
          child: Container(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Select Effect',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the close button
                  ],
                ),

                const Divider(),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search effects...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                // Categories
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedCategoryIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(_categories[index]),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategoryIndex = index;
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Effects grid
                Expanded(
                  child: _filteredEffects.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_list_off,
                                size: 48,
                                color: Theme.of(context).disabledColor,
                              ),
                              const SizedBox(height: 16),
                              const Text('No effects match your search'),
                            ],
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isMobile ? 2 : 3,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 150,
                          ),
                          itemCount: _filteredEffects.length,
                          itemBuilder: (context, index) {
                            final effectType = _filteredEffects[index];
                            final effect = EffectsManager.createEffect(effectType);
                            final name = effect.getName(context);
                            final hasProAccess = subscriptionState.hasFeatureAccess(SubscriptionFeature.advancedTools);

                            return _buildEffectCard(context, name, effectType, effect, hasProAccess);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEffectCard(
    BuildContext context,
    String name,
    EffectType type,
    Effect effect,
    bool hasProAccess,
  ) {
    final color = effect.getColor(context);
    final icon = effect.getIcon(size: 28, color: color);
    final isPremium = effect.isPremium;
    final isLocked = isPremium && !hasProAccess;

    final content = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (isLocked) {
            _showUpgradePrompt(context);
          } else {
            widget.onEffectSelected(effect);
            Navigator.of(context).pop();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.2),
                child: icon,
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                effect.getDescription(context),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );

    if (isLocked) {
      return ProBadge(child: content);
    }

    return content;
  }

  void _showUpgradePrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Premium Effect'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This effect is available in the Pro version.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Pro features include:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('• Advanced effects and tools'),
            Text('• Unlimited projects'),
            Text('• Cloud backup'),
            Text('• Priority support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close the effects dialog too
              SubscriptionOfferScreen.show(
                context,
                featurePrompt: SubscriptionFeature.advancedTools,
              );
            },
            icon: const Icon(Icons.upgrade),
            label: const Text('Upgrade to Pro'),
          ),
        ],
      ),
    );
  }
}
