import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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
              TextButton(
                onPressed: () => ref.read(subscriptionStateProvider.notifier).restorePurchases(),
                child: Text(s.restore),
              ),
          ],
          bottom: TabBar(
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
        final columns = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 600 ? 2 : 1);
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: hasAllEffects ? const _AllPacksUnlockedBanner() : const _UltimateBanner(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 230,
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
  return ref.read(subscriptionServiceProvider).getProductDetails(SubscriptionProductIds.pack(packId))?.price;
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (final (index, type) in pack.types.take(4).indexed) ...[
                      if (index > 0) const SizedBox(width: 6),
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
                    // Without a store price, show what the pack costs in gems.
                    coins: owned || onTrial || price != null ? null : CoinPrices.pack(packId),
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

  String get _productId => SubscriptionProductIds.pack(widget.packId);

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
      await ref.read(subscriptionStateProvider.notifier).purchase(_productId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBuying = false);
      AppNotification.error(context, Strings.of(context).purchaseFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final colors = Theme.of(context).colorScheme;
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
    ref.listen(purchaseUpdatesStreamProvider, (previous, next) {
      final purchases = next.valueOrNull ?? const <PurchaseDetails>[];
      final ended = purchases.any(
        (p) => p.productID == _productId && (p.status == PurchaseStatus.error || p.status == PurchaseStatus.canceled),
      );
      if (ended && _isBuying) setState(() => _isBuying = false);
    });

    return Scaffold(
      appBar: AppBar(title: Text(packName)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = (constraints.maxWidth / 125).floor().clamp(3, 6);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final effect = _effects[index];
                      final locked = !accessible.contains(effect.type);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
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
      ),
      bottomNavigationBar: owned ? null : _buildBuyBar(context, price),
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

  Widget _buildBuyBar(BuildContext context, String? price) {
    final s = Strings.of(context);
    final coinPrice = CoinPrices.pack(widget.packId);
    final onTrial = ref.watch(effectPackAccessProvider(widget.packId));
    final adReady = ref.watch(rewardVideoAdProvider);
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                child: Text(s.unlockForCoins(coinPrice)),
              ),
              if (onTrial)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(child: _PackStatusChip(label: s.packTrialActive, owned: true)),
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
        ),
      ),
    );
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
