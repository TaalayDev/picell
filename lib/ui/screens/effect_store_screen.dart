import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/services/subscription_service.dart';

import '../../data/models/progression_model.dart';
import '../../data/models/subscription_model.dart';
import '../../l10n/strings.dart';
import '../../pixel/effects/effect_pack_catalog.dart';
import '../../pixel/effects/effects.dart';
import '../../providers/ad/reward_video_ad_controller.dart';
import '../../providers/progression_provider.dart';
import '../../providers/subscription_provider.dart';
import '../widgets/effects/effect_icon_preview.dart';
import '../widgets/effects/effect_pack_l10n.dart';
import '../widgets/notifications/app_notification.dart';
import '../widgets/progression/quests_view.dart';
import 'subscription_screen.dart';

enum EffectStoreTab { packs, quests }

/// Layout limits shared by the store screens so they read well from phones
/// to wide desktop windows.
class _StoreLayout {
  _StoreLayout._();

  /// Content never stretches wider than this; wider windows center it.
  static const double maxContentWidth = 1200;

  /// From this width the pack page shows purchase actions in a side panel.
  static const double sidePanelBreakpoint = 840;

  static const double sidePanelWidth = 340;

  /// Below this width app bar actions collapse to icons.
  static const double compactWidth = 420;

  static const double gridSpacing = 16;

  /// Horizontal padding that keeps content at most [maxContentWidth] wide.
  static double horizontalPadding(double width, {double maxWidth = maxContentWidth}) =>
      math.max(16, (width - maxWidth) / 2);

  /// Number of columns so that no column is narrower than [minItemWidth].
  static int columnsFor(double width, double minItemWidth, {int min = 1, int max = 8}) =>
      ((width + gridSpacing) / (minItemWidth + gridSpacing)).floor().clamp(min, max);
}

/// Browse, buy and earn effect packs, separately from the Pro/Ultimate plans.
class EffectStoreScreen extends ConsumerWidget {
  const EffectStoreScreen({super.key, this.initialTab = EffectStoreTab.packs});

  final EffectStoreTab initialTab;

  /// Opens the store, or a single pack's page when [pack] is given.
  static Route<void> route({EffectPackId? pack, EffectStoreTab tab = EffectStoreTab.packs}) {
    return MaterialPageRoute<void>(
      builder: (_) => pack == null ? EffectStoreScreen(initialTab: tab) : EffectPackScreen(packId: pack),
    );
  }

  static Future<void> show(BuildContext context, {EffectPackId? pack, EffectStoreTab tab = EffectStoreTab.packs}) {
    return Navigator.of(context).push(route(pack: pack, tab: tab));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final claimable = ref.watch(progressionProvider.select((state) => state.claimableCount));
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < _StoreLayout.compactWidth;
    final wide = width >= _StoreLayout.sidePanelBreakpoint;

    return DefaultTabController(
      length: EffectStoreTab.values.length,
      initialIndex: initialTab.index,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.effectStoreTitle),
          actions: [
            Builder(
              builder: (context) => WalletChip(
                onTap: () => DefaultTabController.of(context).animateTo(EffectStoreTab.quests.index),
              ),
            ),
            if (!kIsWeb)
              compact
                  ? IconButton(
                      tooltip: s.restore,
                      icon: const Icon(Icons.restore),
                      onPressed: () => ref.read(subscriptionStateProvider.notifier).restorePurchases(),
                    )
                  : TextButton(
                      onPressed: () => ref.read(subscriptionStateProvider.notifier).restorePurchases(),
                      child: Text(s.restore),
                    ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            // Full-width tabs look lost on desktop; keep them together there.
            isScrollable: wide,
            tabAlignment: wide ? TabAlignment.center : null,
            tabs: [
              Tab(text: s.storeTabPacks),
              Tab(
                child: Badge(
                  isLabelVisible: claimable > 0,
                  label: Text('$claimable'),
                  child: Text(s.storeTabQuests),
                ),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PacksTab(),
            QuestsView(),
          ],
        ),
      ),
    );
  }
}

/// Whether [packId] is owned for good, through a purchase or gems.
bool _ownsPackPermanently(WidgetRef ref, EffectPackId packId) {
  if (ref.watch(subscriptionStateProvider.select((sub) => sub.ownsEffectPack(packId)))) return true;
  return ref.watch(progressionProvider.select((state) => state.earnedPacks.contains(packId)));
}

class _PacksTab extends ConsumerWidget {
  const _PacksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAllEffects = ref.watch(subscriptionStateProvider).hasEntitlement(Entitlement.allEffects);
    final owned = {for (final id in EffectPackId.values) id: _ownsPackPermanently(ref, id)};

    // Paid packs the user can still buy come first, the free pack last.
    final packs = EffectPackId.values.toList()
      ..sort((a, b) {
        int rank(EffectPackId id) => id == EffectPackId.free ? 2 : (owned[id]! ? 1 : 0);
        return rank(a).compareTo(rank(b));
      });

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = _StoreLayout.horizontalPadding(constraints.maxWidth);
        final contentWidth = constraints.maxWidth - horizontal * 2;
        final columns = _StoreLayout.columnsFor(contentWidth, _EffectPackCard.minWidth, max: 4);
        final cardWidth = (contentWidth - _StoreLayout.gridSpacing * (columns - 1)) / columns;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 8),
              sliver: SliverToBoxAdapter(
                child: hasAllEffects ? const _AllPacksUnlockedBanner() : const _UltimateBanner(),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: _StoreLayout.gridSpacing,
                  crossAxisSpacing: _StoreLayout.gridSpacing,
                  // Sized from the real card width and text scale, so large
                  // system fonts never clip the text.
                  mainAxisExtent: _EffectPackCard.heightFor(cardWidth, MediaQuery.textScalerOf(context)),
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _EffectPackCard(
                    key: ValueKey('effect-pack-${packs[index].name}'),
                    packId: packs[index],
                  ),
                  childCount: packs.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Store price of a pack, or null while products load or if the store lacks it.
String? _packPrice(WidgetRef ref, EffectPackId packId) {
  ref.watch(productsStreamProvider);
  final productId = SubscriptionProductIds.pack(packId);
  if (productId == null) return null;
  return ref.read(subscriptionServiceProvider).getProductDetails(productId)?.priceString;
}

class _UltimateBanner extends StatelessWidget {
  const _UltimateBanner();

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => SubscriptionOfferScreen.show(context, featurePrompt: SubscriptionFeature.effects),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(MaterialCommunityIcons.crown, color: colors.onPrimaryContainer, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.effectStoreUltimateTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.effectStoreUltimateSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllPacksUnlockedBanner extends StatelessWidget {
  const _AllPacksUnlockedBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: colors.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              Strings.of(context).effectStoreAllUnlocked,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colors.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _EffectPackCard extends ConsumerWidget {
  const _EffectPackCard({super.key, required this.packId});

  final EffectPackId packId;

  static const double minWidth = 300;
  static const int _previewCount = 4;
  static const double _padding = 12;
  static const double _previewGap = 6;

  /// Card margins, previews, and the title, description and count lines.
  static double heightFor(double width, TextScaler textScaler) {
    final innerWidth = width - 8 - _padding * 2;
    final previewSize = (innerWidth - _previewGap * (_previewCount - 1)) / _previewCount;
    return 8 + _padding * 2 + previewSize + textScaler.scale(104);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final pack = EffectPackCatalog.forId(packId);
    final secondaryText = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    final owned = _ownsPackPermanently(ref, packId);
    final onTrial = !owned && ref.watch(effectPackAccessProvider(packId));
    final price = _packPrice(ref, packId);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => EffectStoreScreen.show(context, pack: packId),
        child: Padding(
          padding: const EdgeInsets.all(_padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (final (index, type) in pack.types.take(_previewCount).indexed) ...[
                      if (index > 0) const SizedBox(width: _previewGap),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: EffectIconPreview(
                              key: ValueKey('pack-preview-${type.name}'),
                              effect: EffectsManager.createEffect(type),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      packId.localizedName(context),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PackStatusChip(
                    label: owned ? (pack.isFree ? s.free : s.effectPackOwned) : (onTrial ? s.packTrialActive : price),
                    // Without a store price, show what the pack costs this user in gems.
                    coins: owned || onTrial || price != null ? null : ref.watch(progressionProvider).packPrice(packId),
                    owned: owned || onTrial,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                packId.localizedDescription(context),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: secondaryText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    s.effectCount(pack.types.length),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: secondaryText),
                  ),
                  if (packId == EffectPackId.basicFilters && !owned) ...[
                    const SizedBox(width: 8),
                    _PackStatusChip(label: s.effectPackIncludedInPro, owned: false, dense: true),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackStatusChip extends StatelessWidget {
  const _PackStatusChip({this.label, this.coins, required this.owned, this.dense = false});

  final String? label;
  final int? coins;
  final bool owned;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = owned ? colors.secondaryContainer : colors.primary.withValues(alpha: 0.12);
    final foreground = owned ? colors.onSecondaryContainer : colors.primary;
    final textStyle = (dense ? Theme.of(context).textTheme.labelSmall : Theme.of(context).textTheme.labelMedium)
        ?.copyWith(fontWeight: FontWeight.bold);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 10, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (owned) ...[
            Icon(Icons.check, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          if (coins != null)
            GemAmount(coins!, color: foreground, style: textStyle)
          else
            Text(label ?? '', style: textStyle?.copyWith(color: foreground)),
        ],
      ),
    );
  }
}

/// All effects of one pack, with a buy button when it is not owned yet.
class EffectPackScreen extends ConsumerStatefulWidget {
  const EffectPackScreen({super.key, required this.packId});

  final EffectPackId packId;

  @override
  ConsumerState<EffectPackScreen> createState() => _EffectPackScreenState();
}

class _EffectPackScreenState extends ConsumerState<EffectPackScreen> {
  late final List<Effect> _effects = [
    for (final type in EffectPackCatalog.forId(widget.packId).types) EffectsManager.createEffect(type),
  ];
  bool _isBuying = false;

  /// Null for the free pack, which is always owned and never bought.
  String? get _productId => SubscriptionProductIds.pack(widget.packId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = ref.read(subscriptionServiceProvider);
      if (service.products.isEmpty) service.loadProducts();
    });
  }

  Future<void> _buy() async {
    setState(() => _isBuying = true);
    try {
      final productId = _productId;
      if (productId == null) return;
      await ref.read(subscriptionStateProvider.notifier).purchase(productId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBuying = false);
      AppNotification.error(context, Strings.of(context).purchaseFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final packName = widget.packId.localizedName(context);
    final owned = _ownsPackPermanently(ref, widget.packId);
    final price = _packPrice(ref, widget.packId);
    final accessible = {
      for (final effect in _effects)
        if (ref.watch(effectAccessProvider(effect.type))) effect.type,
    };

    ref.listen(subscriptionStateProvider.select((sub) => sub.ownsEffectPack(widget.packId)), (previous, next) {
      if (previous == false && next) {
        setState(() => _isBuying = false);
        AppNotification.success(context, s.effectPackPurchased(packName));
      }
    });
    ref.listen(purchaseEventsStreamProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event == null || event.productId != _productId || !_isBuying) return;
      if (event.outcome == PurchaseOutcome.cancelled || event.outcome == PurchaseOutcome.failed) {
        setState(() => _isBuying = false);
        if (event.outcome == PurchaseOutcome.failed) AppNotification.error(context, s.purchaseFailed);
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final sidePanel = !owned && constraints.maxWidth >= _StoreLayout.sidePanelBreakpoint;
        final horizontal = _StoreLayout.horizontalPadding(constraints.maxWidth);

        final grid = _buildEffectGrid(
          context,
          accessible: accessible,
          // The side panel already shows the description.
          showHeader: !sidePanel,
          horizontalPadding: sidePanel ? 16 : horizontal,
        );

        return Scaffold(
          appBar: AppBar(title: Text(packName)),
          body: sidePanel
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal - 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: grid),
                      SizedBox(
                        width: _StoreLayout.sidePanelWidth,
                        child: _buildSidePanel(context, price),
                      ),
                    ],
                  ),
                )
              : grid,
          bottomNavigationBar: owned || sidePanel ? null : _buildBottomBar(context, price),
        );
      },
    );
  }

  Widget _buildEffectGrid(
    BuildContext context, {
    required Set<EffectType> accessible,
    required bool showHeader,
    required double horizontalPadding,
  }) {
    final s = Strings.of(context);
    final colors = Theme.of(context).colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth - horizontalPadding * 2;
        final columns = _StoreLayout.columnsFor(contentWidth, 120, min: 3);
        final tileWidth = (contentWidth - _StoreLayout.gridSpacing * (columns - 1)) / columns;
        // A square preview plus up to two lines of the effect name.
        final tileHeight = tileWidth + 6 + textScaler.scale(36);

        return CustomScrollView(
          slivers: [
            if (showHeader)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.packId.localizedDescription(context),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colors.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.effectCount(_effects.length),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 24),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: _StoreLayout.gridSpacing,
                  crossAxisSpacing: _StoreLayout.gridSpacing,
                  mainAxisExtent: tileHeight,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final effect = _effects[index];
                    final locked = !accessible.contains(effect.type);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: InkWell(
                            key: ValueKey('pack-effect-tile-${effect.type.name}'),
                            onTap: locked ? () => _unlockEffect(effect) : null,
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: EffectIconPreview(
                                    key: ValueKey('pack-effect-${effect.type.name}'),
                                    effect: effect,
                                  ),
                                ),
                                if (locked)
                                  Positioned(
                                    left: 4,
                                    right: 4,
                                    bottom: 4,
                                    child: _CoinPriceTag(coins: CoinPrices.effect(effect.type)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          effect.getName(context),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                  childCount: _effects.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _unlockEffect(Effect effect) async {
    final s = Strings.of(context);
    final price = CoinPrices.effect(effect.type);
    final name = effect.getName(context);
    if (ref.read(progressionProvider).coins < price) {
      _showNotEnoughCoins();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(s.unlockEffectConfirm(name, price)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(s.cancel)),
          FilledButton(
            key: const ValueKey('confirm-unlock-effect'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.unlockAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (ref.read(progressionProvider.notifier).buyEffect(effect.type)) {
      AppNotification.success(context, s.effectUnlocked(name));
    }
  }

  void _unlockPackWithCoins() {
    final s = Strings.of(context);
    if (ref.read(progressionProvider.notifier).buyPack(widget.packId)) {
      AppNotification.success(context, s.effectPackPurchased(widget.packId.localizedName(context)));
    } else {
      _showNotEnoughCoins();
    }
  }

  Future<void> _startTrial() async {
    final earned = await ref.read(rewardVideoAdProvider.notifier).showAdIfLoaded();
    if (!earned || !mounted) return;
    ref.read(progressionProvider.notifier).startPackTrial(widget.packId);
  }

  void _showNotEnoughCoins() {
    final s = Strings.of(context);
    AppNotification.warning(
      context,
      s.notEnoughCoins,
      actionLabel: s.storeTabQuests,
      onAction: () => Navigator.of(context).pushReplacement(EffectStoreScreen.route(tab: EffectStoreTab.quests)),
    );
  }

  /// Pack summary and purchase options beside the grid on wide screens.
  Widget _buildSidePanel(BuildContext context, String? price) {
    final s = Strings.of(context);
    final colors = Theme.of(context).colorScheme;
    final pack = EffectPackCatalog.forId(widget.packId);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 24),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.packId.localizedName(context),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.packId.localizedDescription(context),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                s.effectCount(pack.types.length),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 20),
              ..._buildPurchaseActions(context, price),
            ],
          ),
        ),
      ),
    );
  }

  /// Purchase options pinned under the grid on phones and narrow windows.
  Widget _buildBottomBar(BuildContext context, String? price) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            // Tablets in portrait: keep buttons a comfortable width.
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildPurchaseActions(context, price),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPurchaseActions(BuildContext context, String? price) {
    final s = Strings.of(context);
    final progression = ref.watch(progressionProvider);
    // Owned effects of this pack and the first-pack discount lower it.
    final coinPrice = progression.packPrice(widget.packId);
    final basePrice = CoinPrices.pack(widget.packId);
    final credit = progression.packCredit(widget.packId);
    final isGoal = progression.goalPack == widget.packId;
    final onTrial = ref.watch(effectPackAccessProvider(widget.packId));
    final adReady = ref.watch(rewardVideoAdProvider);
    final colors = Theme.of(context).colorScheme;
    final noteStyle = Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w600);

    return [
      FilledButton(
        key: const ValueKey('buy-effect-pack'),
        onPressed: price == null || _isBuying ? null : _buy,
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        child: _isBuying
            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(price == null ? s.effectPackUnavailable : s.effectPackBuyFor(price)),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        key: const ValueKey('unlock-pack-with-coins'),
        onPressed: _unlockPackWithCoins,
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
        child: Text(s.unlockForCoins(coinPrice)),
      ),
      if (coinPrice < basePrice) ...[
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              s.unlockForCoins(basePrice),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
            ),
            if (progression.firstPackDiscountAvailable) Text(s.packFirstDiscount, style: noteStyle),
            if (credit > 0) Text(s.packPriceCredit(credit), style: noteStyle),
          ],
        ),
      ],
      const SizedBox(height: 4),
      TextButton.icon(
        key: const ValueKey('toggle-savings-goal'),
        onPressed: () => ref.read(progressionProvider.notifier).setGoal(isGoal ? null : widget.packId),
        icon: Icon(isGoal ? Icons.savings : Icons.savings_outlined),
        label: Text(isGoal ? s.savingsGoalActive : s.savingsGoalSet),
      ),
      // Secondary links share a line when there is room.
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (onTrial)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: _PackStatusChip(label: s.packTrialActive, owned: true),
            )
          else if (adReady)
            TextButton.icon(
              key: const ValueKey('start-pack-trial'),
              onPressed: _startTrial,
              icon: const Icon(Icons.play_circle_outline),
              label: Text(s.tryPackForAnHour),
            ),
          TextButton(
            onPressed: () => SubscriptionOfferScreen.show(context, featurePrompt: SubscriptionFeature.effects),
            child: Text(s.effectStoreUltimateTitle),
          ),
        ],
      ),
    ];
  }
}

class _CoinPriceTag extends StatelessWidget {
  const _CoinPriceTag({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          GemAmount(
            coins,
            color: Colors.white,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
