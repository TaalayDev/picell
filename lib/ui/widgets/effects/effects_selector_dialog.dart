import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/models/layer.dart';
import '../../../data/models/subscription_model.dart';
import '../../../pixel/services/effect_stack_service.dart';
import '../../../pixel/effects/effect_pack_catalog.dart';
import '../../../pixel/effects/effects.dart';
import '../../../data/models/progression_model.dart';
import '../../../providers/progression_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../screens/effect_store_screen.dart';
import '../../screens/subscription_screen.dart';
import '../animated_background.dart';
import '../subscription/feature_gate.dart';
import '../../../l10n/strings.dart';
import 'effect_icon_preview.dart';
import '../notifications/app_notification.dart';

class EffectSelectorDialog extends ConsumerStatefulWidget {
  final Function(Effect) onEffectSelected;
  final EffectWorkspace? initialWorkspace;
  final bool lockWorkspace;
  final FilterKind? initialFilterKind;
  final bool lockFilterKind;
  final AnimationKind? initialAnimationKind;
  final bool lockAnimationKind;
  final Layer? layer;

  const EffectSelectorDialog({
    super.key,
    required this.onEffectSelected,
    this.initialWorkspace,
    this.lockWorkspace = false,
    this.initialFilterKind,
    this.lockFilterKind = false,
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
  FilterKind? _selectedFilterKind;
  AnimationKind? _selectedAnimationKind;

  @override
  void initState() {
    super.initState();
    _selectedWorkspace = widget.initialWorkspace;
    _selectedFilterKind = widget.initialFilterKind;
    _selectedAnimationKind = widget.initialAnimationKind;
  }

  @override
  void didUpdateWidget(covariant EffectSelectorDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialWorkspace != widget.initialWorkspace ||
        oldWidget.lockWorkspace != widget.lockWorkspace ||
        oldWidget.initialFilterKind != widget.initialFilterKind ||
        oldWidget.lockFilterKind != widget.lockFilterKind ||
        oldWidget.initialAnimationKind != widget.initialAnimationKind ||
        oldWidget.lockAnimationKind != widget.lockAnimationKind) {
      _selectedWorkspace = widget.initialWorkspace;
      _selectedFilterKind = widget.initialFilterKind;
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

  String _filterKindLabel(BuildContext context, FilterKind? filterKind) {
    final strings = Strings.of(context);
    return switch (filterKind) {
      null => strings.categoryAll,
      FilterKind.filter => strings.effectWorkspaceFilters,
      FilterKind.distortion => strings.effectWorkspaceDistortions,
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
    };
  }

  String _dialogTitle(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    switch (_selectedWorkspace) {
      case EffectWorkspace.filters:
        if (_selectedFilterKind == FilterKind.distortion) {
          return switch (lang) {
            'ru' => 'Выбор искажения',
            'zh' => '选择扭曲效果',
            'ja' => '歪み効果を選択',
            'ky' => 'Бузулуу тандаңыз',
            _ => 'Select Distortion',
          };
        }
        return switch (lang) {
          'ru' => 'Выбор фильтра',
          'zh' => '选择滤镜',
          'ja' => 'フィルターを選択',
          'ky' => 'Фильтр тандаңыз',
          _ => 'Select Filter',
        };
      case EffectWorkspace.materials:
        return switch (lang) {
          'ru' => 'Выбор материала',
          'zh' => '选择材质',
          'ja' => 'マテリアルを選択',
          'ky' => 'Материал тандаңыз',
          _ => 'Select Material',
        };
      case EffectWorkspace.generators:
        return switch (lang) {
          'ru' => 'Выбор генератора',
          'zh' => '选择生成器',
          'ja' => 'ジェネレーターを選択',
          'ky' => 'Генератор тандаңыз',
          _ => 'Select Generator',
        };
      case EffectWorkspace.animation:
        if (_selectedAnimationKind == AnimationKind.transformer) {
          return switch (lang) {
            'ru' => 'Выбор трансформации',
            'zh' => '选择变换效果',
            'ja' => 'トランスフォーマーを選択',
            'ky' => 'Трансформация тандаңыз',
            _ => 'Select Transformer',
          };
        } else if (_selectedAnimationKind == AnimationKind.specialEffect) {
          return switch (lang) {
            'ru' => 'Выбор спецэффекта',
            'zh' => '选择特效',
            'ja' => '特殊効果を選択',
            'ky' => 'Атайын эффект тандаңыз',
            _ => 'Select Special Effect',
          };
        }
        return switch (lang) {
          'ru' => 'Выбор анимации',
          'zh' => '选择动画效果',
          'ja' => 'アニメーションを選択',
          'ky' => 'Анимация тандаңыз',
          _ => 'Select Animation',
        };
      case EffectWorkspace.lighting:
        return switch (lang) {
          'ru' => 'Выбор освещения',
          'zh' => '选择光照效果',
          'ja' => 'ライティングを選択',
          'ky' => 'Жарыктандыруу тандаңыз',
          _ => 'Select Lighting',
        };
      case null:
        return Strings.of(context).selectEffect;
    }
  }

  String _searchHint(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    switch (_selectedWorkspace) {
      case EffectWorkspace.filters:
        if (_selectedFilterKind == FilterKind.distortion) {
          return switch (lang) {
            'ru' => 'Поиск искажений',
            'zh' => '搜索扭曲效果',
            'ja' => '歪み効果を検索',
            'ky' => 'Бузулууларды издөө',
            _ => 'Search distortions',
          };
        }
        return switch (lang) {
          'ru' => 'Поиск фильтров',
          'zh' => '搜索滤镜',
          'ja' => 'フィルターを検索',
          'ky' => 'Фильтрлерди издөө',
          _ => 'Search filters',
        };
      case EffectWorkspace.materials:
        return switch (lang) {
          'ru' => 'Поиск материалов',
          'zh' => '搜索材质',
          'ja' => 'マテリアルを検索',
          'ky' => 'Материалдарды издөө',
          _ => 'Search materials',
        };
      case EffectWorkspace.generators:
        return switch (lang) {
          'ru' => 'Поиск генераторов',
          'zh' => '搜索生成器',
          'ja' => 'ジェネレーターを検索',
          'ky' => 'Генераторлорду издөө',
          _ => 'Search generators',
        };
      case EffectWorkspace.animation:
        if (_selectedAnimationKind == AnimationKind.transformer) {
          return switch (lang) {
            'ru' => 'Поиск трансформаций',
            'zh' => '搜索变换效果',
            'ja' => 'トランスフォーマーを検索',
            'ky' => 'Трансформацияларды издөө',
            _ => 'Search transformers',
          };
        } else if (_selectedAnimationKind == AnimationKind.specialEffect) {
          return switch (lang) {
            'ru' => 'Поиск спецэффектов',
            'zh' => '搜索特效',
            'ja' => '特殊効果を検索',
            'ky' => 'Атайын эффекттерди издөө',
            _ => 'Search special effects',
          };
        }
        return switch (lang) {
          'ru' => 'Поиск анимаций',
          'zh' => '搜索动画效果',
          'ja' => 'アニメーション効果を検索',
          'ky' => 'Анимацияларды издөө',
          _ => 'Search animation effects',
        };
      case EffectWorkspace.lighting:
        return switch (lang) {
          'ru' => 'Поиск освещения',
          'zh' => '搜索光照效果',
          'ja' => 'ライティングを検索',
          'ky' => 'Жарыктандырууну издөө',
          _ => 'Search lighting',
        };
      case null:
        return Strings.of(context).searchEffects;
    }
  }

  List<EffectType> get _filteredEffects {
    final workspaceFiltered = EffectType.values.where((type) {
      final descriptor = EffectCatalog.forType(type);
      if (_selectedWorkspace != null &&
          descriptor.workspace != _selectedWorkspace) {
        return false;
      }
      if (_selectedWorkspace == EffectWorkspace.filters &&
          _selectedFilterKind != null &&
          descriptor.filterKind != _selectedFilterKind) {
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
    // Rebuild when purchases or earned unlocks change.
    ref.watch(subscriptionStateProvider);
    ref.watch(progressionProvider);
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
                        _dialogTitle(context),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('open-effect-store'),
                      tooltip: Strings.of(context).effectStoreTitle,
                      icon: const Icon(Icons.storefront_outlined),
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.push(EffectStoreScreen.route());
                      },
                    ),
                  ],
                ),

                const Divider(),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: _searchHint(context),
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
                                    _selectedFilterKind = null;
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

                if (_selectedWorkspace == EffectWorkspace.filters &&
                    !widget.lockFilterKind)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final filterKind in <FilterKind?>[
                            null,
                            ...FilterKind.values,
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                key: ValueKey(
                                  'filter-kind-${filterKind?.name ?? 'all'}',
                                ),
                                label: Text(
                                  _filterKindLabel(context, filterKind),
                                ),
                                selected: _selectedFilterKind == filterKind,
                                onSelected: (selected) {
                                  if (!selected) return;
                                  setState(() {
                                    _selectedFilterKind = filterKind;
                                  });
                                },
                              ),
                            ),
                        ],
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
                            mainAxisExtent: 220,
                          ),
                          itemCount: _filteredEffects.length,
                          itemBuilder: (context, index) {
                            final effectType = _filteredEffects[index];
                            final effect =
                                EffectsManager.createEffect(effectType);
                            final name = effect.getName(context);
                            final isLocked =
                                !ref.read(effectAccessProvider(effectType));
                            final descriptor =
                                EffectCatalog.forType(effectType);
                            final validation = (stackState == null ||
                                    descriptor.workspace ==
                                        EffectWorkspace.generators ||
                                    descriptor.workspace ==
                                        EffectWorkspace.animation)
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
                              isLocked,
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
    bool isLocked,
    EffectStackAddValidation validation,
  ) {

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
            AppNotification.warning(
              context,
              _validationMessage(context, validation),
            );
            return;
          }
          if (isLocked) {
            _showUpgradePrompt(context, type);
          } else {
            Navigator.of(context).pop();
            ref.read(progressionProvider.notifier).record(ProgressionEvent.effectAdded);
            widget.onEffectSelected(effect);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: EffectIconPreview(
                    key: ValueKey('effect-preview-${type.name}'),
                    effect: effect,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 3),
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

  void _showUpgradePrompt(BuildContext context, EffectType type) {
    final s = Strings.of(context);
    final pack = EffectPackCatalog.packIdOf(type);
    final inPro = pack == EffectPackId.basicFilters;
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
              inPro ? s.effectIncludedInPro : s.effectIncludedInUltimate,
              style: const TextStyle(fontSize: 16),
            ),
            if (!inPro) ...[
              const SizedBox(height: 12),
              Text(s.featureBullet(s.offerAllEffectPacks)),
              Text(s.featureBullet(s.offerEverythingInPro)),
              Text(s.featureBullet(s.offerCloudSync)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.maybeLater),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close the effects dialog too
              SubscriptionOfferScreen.show(
                context,
                featurePrompt: SubscriptionFeature.effects,
              );
            },
            child: Text(s.viewPlans),
          ),
          FilledButton.icon(
            key: const ValueKey('open-locked-effect-pack'),
            onPressed: () {
              final navigator = Navigator.of(context);
              navigator.pop();
              navigator.pop(); // Close the effects dialog too
              navigator.push(EffectStoreScreen.route(pack: pack));
            },
            icon: const Icon(Icons.storefront_outlined),
            label: Text(s.getPack),
          ),
        ],
      ),
    );
  }
}
