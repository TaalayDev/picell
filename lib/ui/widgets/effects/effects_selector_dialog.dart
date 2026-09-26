import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/models/layer.dart';
import '../../../data/models/subscription_model.dart';
import '../../../pixel/services/effect_stack_service.dart';
import '../../../pixel/effects/effects.dart';
import '../../../providers/subscription_provider.dart';
import '../../screens/subscription_screen.dart';
import '../animated_background.dart';
import '../subscription/feature_gate.dart';
import '../../../l10n/strings.dart';

class EffectSelectorDialog extends ConsumerStatefulWidget {
  final Function(Effect) onEffectSelected;
  final EffectWorkspace? initialWorkspace;
  final bool lockWorkspace;
  final AnimationKind? initialAnimationKind;
  final bool lockAnimationKind;
  final Layer? layer;

  const EffectSelectorDialog({
    super.key,
    required this.onEffectSelected,
    this.initialWorkspace,
    this.lockWorkspace = false,
    this.initialAnimationKind,
    this.lockAnimationKind = false,
    this.layer,
  });

  @override
  ConsumerState<EffectSelectorDialog> createState() =>
      _EffectSelectorDialogState();
}

class _EffectSelectorDialogState extends ConsumerState<EffectSelectorDialog> {
  String _searchQuery = '';
  EffectWorkspace? _selectedWorkspace;
  AnimationKind? _selectedAnimationKind;

  @override
  void initState() {
    super.initState();
    _selectedWorkspace = widget.initialWorkspace;
    _selectedAnimationKind = widget.initialAnimationKind;
  }

  @override
  void didUpdateWidget(covariant EffectSelectorDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialWorkspace != widget.initialWorkspace ||
        oldWidget.lockWorkspace != widget.lockWorkspace ||
        oldWidget.initialAnimationKind != widget.initialAnimationKind ||
        oldWidget.lockAnimationKind != widget.lockAnimationKind) {
      _selectedWorkspace = widget.initialWorkspace;
      _selectedAnimationKind = widget.initialAnimationKind;
      _searchQuery = '';
    }
  }

  String _animationKindLabel(
    BuildContext context,
    AnimationKind? animationKind,
  ) {
    final strings = Strings.of(context);
    return switch (animationKind) {
      null => strings.categoryAll,
      AnimationKind.transformer => strings.animationTransformers,
      AnimationKind.specialEffect => strings.animationSpecialEffects,
    };
  }

  List<EffectWorkspace?> get _workspaces => widget.lockWorkspace
      ? [widget.initialWorkspace]
      : [null, ...EffectWorkspace.values];

  String _workspaceLabel(BuildContext context, EffectWorkspace? workspace) {
    final strings = Strings.of(context);
    return switch (workspace) {
      null => strings.categoryAll,
      EffectWorkspace.filters => strings.effectWorkspaceFilters,
      EffectWorkspace.materials => strings.effectWorkspaceMaterials,
      EffectWorkspace.generators => strings.effectWorkspaceGenerators,
      EffectWorkspace.animation => strings.effectWorkspaceAnimation,
      EffectWorkspace.lighting => strings.effectWorkspaceLighting,
      EffectWorkspace.distortions => strings.effectWorkspaceDistortions,
    };
  }

  List<EffectType> get _filteredEffects {
    final workspaceFiltered = EffectType.values.where((type) {
      final descriptor = EffectCatalog.forType(type);
      if (_selectedWorkspace != null &&
          descriptor.workspace != _selectedWorkspace) {
        return false;
      }
      if (_selectedWorkspace == EffectWorkspace.animation &&
          _selectedAnimationKind != null &&
          descriptor.animationKind != _selectedAnimationKind) {
        return false;
      }
      return true;
    });

    if (_searchQuery.isEmpty) {
      return workspaceFiltered.toList();
    }

    return workspaceFiltered.where((type) {
      final query =
          _searchQuery.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final enumName = type.name.toLowerCase();
      final displayName = EffectsManager.createEffect(type)
          .getName(context)
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      return enumName.contains(query) || displayName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final subscriptionState = ref.watch(subscriptionStateProvider);
    final stackState =
        widget.layer == null ? null : EffectStackService.inspect(widget.layer!);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: isMobile ? double.infinity : 600,
        height: isMobile ? double.infinity : 500,
        child: AnimatedBackground(
          child: Container(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
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
                        Strings.of(context).selectEffect,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
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
                      hintText: Strings.of(context).searchEffects,
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

                if (!widget.lockWorkspace)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _workspaces.length,
                        itemBuilder: (context, index) {
                          final workspace = _workspaces[index];
                          final isSelected = _selectedWorkspace == workspace;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                _workspaceLabel(context, workspace),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedWorkspace = workspace;
                                    _selectedAnimationKind = null;
                                  });
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                if (_selectedWorkspace == EffectWorkspace.animation &&
                    !widget.lockAnimationKind)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final animationKind in <AnimationKind?>[
                            null,
                            ...AnimationKind.values,
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                key: ValueKey(
                                  'animation-kind-${animationKind?.name ?? 'all'}',
                                ),
                                label: Text(
                                  _animationKindLabel(context, animationKind),
                                ),
                                selected:
                                    _selectedAnimationKind == animationKind,
                                onSelected: (selected) {
                                  if (!selected) return;
                                  setState(() {
                                    _selectedAnimationKind = animationKind;
                                  });
                                },
                              ),
                            ),
                        ],
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
                              Text(Strings.of(context).noEffectsMatch),
                            ],
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isMobile ? 2 : 3,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 150,
                          ),
                          itemCount: _filteredEffects.length,
                          itemBuilder: (context, index) {
                            final effectType = _filteredEffects[index];
                            final effect =
                                EffectsManager.createEffect(effectType);
                            final name = effect.getName(context);
                            final hasProAccess =
                                subscriptionState.hasFeatureAccess(
                                    SubscriptionFeature.advancedTools);
                            final validation = stackState == null
                                ? const EffectStackAddValidation.allowed()
                                : EffectStackService.validateAddToState(
                                    stackState,
                                    effect,
                                  );

                            return _buildEffectCard(
                              context,
                              name,
                              effectType,
                              effect,
                              hasProAccess,
                              validation,
                            );
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
    EffectStackAddValidation validation,
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
          if (!validation.isAllowed) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(_validationMessage(context, validation)),
                ),
              );
            return;
          }
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
                backgroundColor: color.withValues(alpha: 0.2),
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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
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

    if (!validation.isAllowed) {
      return Tooltip(
        message: _validationMessage(context, validation),
        child: Opacity(opacity: 0.45, child: content),
      );
    }

    return content;
  }

  String _validationMessage(
    BuildContext context,
    EffectStackAddValidation validation,
  ) {
    final strings = Strings.of(context);
    return switch (validation.failure) {
      EffectStackAddFailure.requiresPixels => strings.effectRequiresPixels,
      EffectStackAddFailure.requiresEmptyLayer =>
        strings.effectRequiresEmptyLayer,
      EffectStackAddFailure.generatorAlreadyExists =>
        strings.effectGeneratorAlreadyAdded,
      null => '',
    };
  }

  void _showUpgradePrompt(BuildContext context) {
    final s = Strings.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Text(s.premiumEffect),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.proVersionStatus,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              s.proFeaturesInclude,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(s.featureBullet(s.featureAdvancedEffects)),
            Text(s.featureBullet(s.featureUnlimitedProjects)),
            Text(s.featureBullet(s.featureCloudBackup)),
            Text(s.featureBullet(s.featurePrioritySupport)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.maybeLater),
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
            label: Text(s.upgradeToPro),
          ),
        ],
      ),
    );
  }
}
