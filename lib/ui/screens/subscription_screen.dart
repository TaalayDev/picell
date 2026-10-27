import 'package:confetti/confetti.dart';
import '../../providers/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/services/subscription_service.dart';
import 'package:picell/config/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../app/theme/theme.dart';
import '../../data/models/subscription_model.dart';
import '../../l10n/strings.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/ad/reward_video_ad_controller.dart';
import '../widgets/theme_selector.dart';
import '../widgets/pv/pv.dart';
import 'effect_store_screen.dart';
import '../widgets/notifications/app_notification.dart';

class SubscriptionOfferScreen extends ConsumerStatefulWidget {
  static Future<bool?> show(
    BuildContext context, {
    bool isPostCreation = false,
    SubscriptionFeature? featurePrompt,
  }) {
    final container = ProviderScope.containerOf(context, listen: false);
    container.read(analyticsProvider).logEvent(
      name: 'paywall_shown',
      parameters: {'feature': featurePrompt?.name ?? (isPostCreation ? 'post_creation' : 'menu')},
    );
    // The dashboard can switch the current offering to a RevenueCat Paywall.
    final service = container.read(subscriptionServiceProvider);
    if (service.usesRevenueCatPaywall) return service.presentPaywall();

    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => SubscriptionOfferScreen(
          isPostCreation: isPostCreation,
          featurePrompt: featurePrompt,
        ),
      ),
    );
  }

  final bool isPostCreation;
  final SubscriptionFeature? featurePrompt;

  const SubscriptionOfferScreen({
    super.key,
    this.isPostCreation = false,
    this.featurePrompt,
  });

  @override
  ConsumerState<SubscriptionOfferScreen> createState() => _SubscriptionOfferScreenState();
}

class _SubscriptionOfferScreenState extends ConsumerState<SubscriptionOfferScreen> {
  static const int _requiredTemporaryProAds = 1;
  static const String _temporaryProAdsWatchedKey = 'temporary_pro_ads_watched';

  late ConfettiController _confettiController;
  int? _selectedIndex;
  int _temporaryProAdsWatched = 0;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _supportsRewardedAds =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    if (_supportsRewardedAds) _loadTemporaryProAdProgress();

    // Start loading products if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final service = ref.read(subscriptionServiceProvider);
      if (service.products.isEmpty) {
        await service.loadProducts();
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _loadTemporaryProAdProgress() async {
    final preferences = await SharedPreferences.getInstance();
    final watched = preferences.getInt(_temporaryProAdsWatchedKey) ?? 0;

    if (mounted) {
      setState(() {
        _temporaryProAdsWatched = watched.clamp(0, _requiredTemporaryProAds - 1);
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  static const double _wideBreakpoint = 1100;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider).theme;
    final pv = context.pv;
    final offers = ref.watch(purchaseOffersProvider);
    final subscription = ref.watch(subscriptionStateProvider);
    final rewardAdState = _supportsRewardedAds ? ref.watch(rewardVideoAdProvider) : false;

    // Rebuild the UI when a purchase or restore finishes
    ref.listen(purchaseEventsStreamProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event == null) return;

      switch (event.outcome) {
        case PurchaseOutcome.failed:
          setState(() {
            _isLoading = false;
            _errorMessage = event.message ?? Strings.of(context).purchaseFailed;
          });
        case PurchaseOutcome.cancelled:
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
        case PurchaseOutcome.purchased:
        case PurchaseOutcome.restored:
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
          // A restore that found nothing is not worth celebrating.
          if (event.outcome == PurchaseOutcome.restored && !ref.read(subscriptionStateProvider).plan.isPaid) return;

          // Show success animation
          _confettiController.play();

          // Close the screen after a short delay on success
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) Navigator.of(context).pop(true);
          });
      }
    });

    final showBar = !kIsDemo && offers.any((offer) => offer.productId != null);
    return Scaffold(
      backgroundColor: pv.background,
      bottomNavigationBar: showBar ? _buildBottomBar(context, offers) : null,
      body: SafeArea(
        bottom: !showBar,
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= _wideBreakpoint;
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1160),
                      child: Padding(
                        padding: wide
                            ? const EdgeInsets.fromLTRB(32, 32, 32, 40)
                            : const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _pageChildren(context, offers, subscription, rewardAdState, wide),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Confetti effect for successful purchase
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.1,
                shouldLoop: false,
                colors: [theme.primaryColor, theme.accentColor, pv.ok, pv.warn, pv.accent],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _pageChildren(
    BuildContext context,
    List<PurchaseOffer> offers,
    UserSubscription subscription,
    bool adReady,
    bool wide,
  ) {
    final gap = wide ? 24.0 : 16.0;
    final owned = subscription.plan;
    final productsLoaded = ref.read(subscriptionServiceProvider).products.isNotEmpty;
    final loadingOffers = offers.isEmpty && !productsLoaded && !kIsWeb;
    final ultimateOwner = owned == SubscriptionPlan.ultimate;

    final children = <Widget>[
      _buildHeader(context, wide),
      if (widget.featurePrompt != null)
        _LockedFeatureTile(
            feature: widget.featurePrompt!,
            title: _getUpgradePromptTitle(context, widget.featurePrompt!),
            subtitle: _getUpgradePromptSubtitle(context, widget.featurePrompt!)),
      if (_errorMessage != null)
        _ErrorBanner(
          message: _errorMessage!,
          onRetry: () {
            final selected = offers.isEmpty ? null : offers[_effectiveSelectedIndex(offers)];
            if (selected?.productId != null) {
              _handlePurchase(selected!);
            } else {
              setState(() => _errorMessage = null);
            }
          },
        ),
      if (kIsWeb) const _StoreUnavailableBanner(),
      if (owned.isPaid) _buildCurrentPlanCard(context, owned),
      if (ultimateOwner) _OwnEverythingCard(subtitle: Strings.of(context).ultimateOwnedSubtitle),
      if (_supportsRewardedAds && !subscription.isPermanentPro && !kIsWeb) _buildAdCard(context, subscription, adReady),
      if (loadingOffers)
        _PlanSkeletons(wide: wide)
      else if (offers.isNotEmpty)
        _buildPlanCards(context, offers, subscription, wide),
      if (!(loadingOffers)) _buildRigSpotlight(context, offers, owned),
      if (!kIsWeb && !loadingOffers && !subscription.hasEntitlement(Entitlement.allEffects))
        Center(
          child: _LinkButton(
            key: const ValueKey('browse-effect-packs'),
            icon: Icons.storefront_outlined,
            label: Strings.of(context).browseEffectPacks,
            onTap: () => EffectStoreScreen.show(context),
          ),
        ),
      if (!loadingOffers) _buildFeatureComparison(context, wide),
      if (!kIsWeb && !owned.isPaid && !loadingOffers)
        Center(
          child: _LinkButton(
            key: const ValueKey('restore-purchases'),
            icon: Icons.restore,
            label: Strings.of(context).planRestorePurchases,
            onTap: _restore,
          ),
        ),
      if (!kIsDemo && !(offers.any((o) => o.productId != null))) _buildLinksRow(context),
    ];

    return [
      for (final (i, child) in children.indexed) ...[
        if (i > 0) SizedBox(height: gap),
        child,
      ],
    ];
  }

  void _restore() {
    ref.read(subscriptionStateProvider.notifier).restorePurchases();
    setState(() => _isLoading = true);
  }

  Widget _buildHeader(BuildContext context, bool wide) {
    final pv = context.pv;
    final s = Strings.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PvPressable(
          onTap: () => Navigator.of(context).maybePop(),
          builder: (context, hovered) => Semantics(
            button: true,
            label: MaterialLocalizations.of(context).closeButtonTooltip,
            child: Container(
              key: const ValueKey('plans-close'),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: pv.surfaceHigh,
                borderRadius: BorderRadius.circular(pv.buttonRadius),
                border: Border.all(
                    color: hovered ? pv.accent : pv.divider, width: pv.cardBorderWidth < 1 ? 1 : pv.cardBorderWidth),
              ),
              child: Icon(Icons.close, size: 24, color: pv.textPrimary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.chooseYourPlan, style: pv.pixelLabel(size: wide ? 28 : 22).copyWith(height: 1.2)),
                const SizedBox(height: 4),
                Text(
                  _supportsRewardedAds ? s.oneTimePurchaseTryAdsFirst : s.oneTimePurchaseLifetimeAccess,
                  style: pv.body(size: 14, color: pv.textSecondary, weight: FontWeight.w400).copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPlanCard(BuildContext context, SubscriptionPlan plan) {
    final pv = context.pv;
    final s = Strings.of(context);
    final isUltimate = plan == SubscriptionPlan.ultimate;
    return Container(
      key: const ValueKey('current-plan-card'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pv.cardDecoration(),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: _PlanEmblem(plan: plan),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.planCurrentPlanLabel,
                    style: pv.body(size: 12, color: pv.textSecondary, weight: FontWeight.w400)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(_planName(context, plan), style: pv.pixelLabel(size: 17))),
                    const SizedBox(width: 4),
                    Icon(Icons.check_circle, size: 20, color: pv.ok),
                  ],
                ),
                Text(
                  s.currentPlan(_planName(context, plan)),
                  style: pv.body(size: 12, color: pv.textSecondary, weight: FontWeight.w400),
                ),
                if (!isUltimate)
                  Text(s.proOwnedSubtitle, style: pv.body(size: 12, color: pv.textSecondary, weight: FontWeight.w400)),
              ],
            ),
          ),
          if (!kIsWeb) ...[
            _LinkButton(
              key: const ValueKey('restore-purchases-owner'),
              label: s.planRestorePurchases,
              onTap: _restore,
            ),
            _LinkButton(
              key: const ValueKey('open-customer-center'),
              icon: Icons.manage_accounts_outlined,
              label: s.managePurchases,
              onTap: () => ref.read(subscriptionServiceProvider).presentCustomerCenter(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdCard(BuildContext context, UserSubscription subscription, bool adReady) {
    final pv = context.pv;
    final s = Strings.of(context);
    final active = subscription.hasTemporaryPro;
    final remaining = subscription.temporaryProAccess?.remainingTime ?? Duration.zero;
    String two(int v) => v.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: pv.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(color: pv.surfaceHigh, borderRadius: BorderRadius.circular(pv.chipRadius.clamp(4, 12))),
            child: Icon(Icons.smart_display_outlined, size: 24, color: pv.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(active ? s.proAccessActive : s.tryProForFreeExclaim,
                    style: pv.body(size: 14, weight: FontWeight.w600)),
                Text(s.watchAdUnlockProOneHour,
                    style: pv.body(size: 12, color: pv.textSecondary, weight: FontWeight.w400)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (active)
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration:
                  BoxDecoration(gradient: pv.gradient, borderRadius: BorderRadius.circular(pv.chipRadius.clamp(4, 16))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: pv.ink),
                  const SizedBox(width: 4),
                  Text('${two(remaining.inMinutes)}:${two(remaining.inSeconds % 60)}',
                      style: pv.mono(size: 13, color: pv.ink, weight: FontWeight.w700)),
                ],
              ),
            )
          else
            PvPressable(
              onTap: adReady && !_isLoading ? _watchAdForTemporaryPro : null,
              builder: (context, hovered) {
                final enabled = adReady && !_isLoading;
                final color = enabled ? pv.primary : pv.textSecondary;
                return Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hovered && enabled ? pv.primary : null,
                    borderRadius: BorderRadius.circular(pv.buttonRadius),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Text(s.watchAd, style: pv.pixelLabel(size: 13, color: hovered && enabled ? pv.ink : color)),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlanCards(BuildContext context, List<PurchaseOffer> offers, UserSubscription subscription, bool wide) {
    final selected = _effectiveSelectedIndex(offers);
    // Phones lead with Ultimate; the wide layout reads Free to Ultimate.
    final order = [for (var i = 0; i < offers.length; i++) i];
    if (!wide) order.sort((a, b) => offers[b].plan.index.compareTo(offers[a].plan.index));

    Widget card(int i) {
      final offer = offers[i];
      final isUltimate = offer.plan == SubscriptionPlan.ultimate;
      return _PlanCard(
        key: ValueKey('plan-card-${offer.plan.name}'),
        offer: offer,
        name: _planName(context, offer.plan),
        features: _offerFeatures(context, offer),
        note: offer.isUpgrade ? _offerDescription(context, offer) : null,
        selected: selected == i,
        current: offer.plan == SubscriptionPlan.free && !subscription.plan.isPaid,
        wide: wide,
        onTap: _isLoading ? null : () => setState(() => _selectedIndex = i),
        topInset: wide ? (isUltimate ? 12 : 32) : (isUltimate ? 12 : 0),
      );
    }

    final cards = [for (final i in order) card(i)];
    final content = wide
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (n, c) in cards.indexed) ...[
                  if (n > 0) const SizedBox(width: 20),
                  Expanded(child: c),
                ],
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (n, c) in cards.indexed) ...[
                if (n > 0) const SizedBox(height: 16),
                c,
              ],
            ],
          );
    return Opacity(
      opacity: _isLoading ? 0.7 : 1,
      child: Semantics(container: true, child: content),
    );
  }

  Widget _buildRigSpotlight(BuildContext context, List<PurchaseOffer> offers, SubscriptionPlan owned) {
    final pv = context.pv;
    final s = Strings.of(context);
    final selectedPlan = offers.isEmpty ? SubscriptionPlan.free : offers[_effectiveSelectedIndex(offers)].plan;
    final unlocked = owned != SubscriptionPlan.free || selectedPlan != SubscriptionPlan.free;
    return Container(
      key: const ValueKey('pro-rig-feature'),
      padding: const EdgeInsets.all(16),
      decoration: pv.cardDecoration(color: pv.surfaceHigh),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: pv.surface,
              borderRadius: BorderRadius.circular(pv.buttonRadius),
              border: Border.all(color: pv.divider),
            ),
            alignment: Alignment.center,
            child: SizedBox(
              width: 56,
              height: 56,
              child: CustomPaint(painter: _PixelPainter.rig(pv)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(s.whatsNewBoneRigTitle, style: pv.pixelLabel(size: 16)),
                    PvChip(label: s.rigExperimental, icon: Icons.science_outlined, color: pv.warn, dense: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text(s.whatsNewBoneRigBody,
                    style: pv.body(size: 13, color: pv.textSecondary, weight: FontWeight.w400).copyWith(height: 1.4)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(unlocked ? Icons.lock_open : Icons.lock_outline, size: 18, color: pv.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        owned != SubscriptionPlan.free ? s.planUnlockedWithYourPlan : s.planUnlocksWithPro,
                        style: pv.body(size: 13, weight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureComparison(BuildContext context, bool wide) {
    final pv = context.pv;
    final s = Strings.of(context);
    final rows = <_FeatureComparisonItem>[
      _FeatureComparisonItem(
        icon: Icons.inventory_2_outlined,
        title: s.featureProjects,
        free: s.freeProjectsCount(SubscriptionFeatureConfig.maxProjects[SubscriptionPlan.free]!),
        pro: s.unlimitedProjects,
        ultimate: s.unlimitedProjects,
      ),
      _FeatureComparisonItem(
        icon: Icons.grid_on,
        title: s.featureCanvasSize,
        free: s.freeCanvasSizeUpTo(SubscriptionFeatureConfig.maxCanvasSize[SubscriptionPlan.free]!),
        pro: s.proCanvasSizeUpTo,
        ultimate: s.proCanvasSizeUpTo,
      ),
      _FeatureComparisonItem(
        icon: Icons.format_paint,
        title: s.featureToolsEffects,
        free: s.basicTools,
        pro: s.offerAllToolsTemplates,
        ultimate: s.offerAllToolsTemplates,
      ),
      _FeatureComparisonItem(
        icon: Icons.auto_awesome,
        title: s.featureEffectPacks,
        free: s.effectsStarterSet,
        pro: s.effectsPlusBasicFilters,
        ultimate: s.effectsAllIncludingFuture,
      ),
      _FeatureComparisonItem(
        icon: Icons.download,
        title: s.featureExportFormats,
        free: s.pngJpegFormats,
        pro: s.allFormatsVideoGif,
        ultimate: s.allFormatsVideoGif,
      ),
      _FeatureComparisonItem(
        icon: Icons.account_tree_outlined,
        title: s.whatsNewBoneRigTitle,
        free: false,
        pro: true,
        ultimate: true,
      ),
      if (_supportsRewardedAds)
        _FeatureComparisonItem(
          icon: Icons.ads_click,
          title: s.featureAds,
          free: s.watchAdsForProFeatures,
          pro: s.noAds,
          ultimate: s.noAds,
        ),
      _FeatureComparisonItem(
        icon: Icons.cloud_upload,
        title: s.featureCloudBackup,
        free: false,
        pro: s.cloudAddonAvailable,
        ultimate: true,
      ),
      _FeatureComparisonItem(
        icon: Icons.support_agent,
        title: s.featurePrioritySupport,
        free: false,
        pro: true,
        ultimate: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.planComparisonTitle, style: pv.pixelLabel(size: 16)),
        const SizedBox(height: 12),
        _ComparisonTable(
          rows: rows,
          headers: [s.free, s.planPro, s.planUltimate],
          wide: wide,
        ),
      ],
    );
  }

  Widget _buildLinksRow(BuildContext context) {
    final pv = context.pv;
    final s = Strings.of(context);
    return Column(
      children: [
        Text(
          s.oneTimePurchaseLifetimeAccess,
          textAlign: TextAlign.center,
          style: pv.body(size: 12, color: pv.textSecondary, weight: FontWeight.w400).copyWith(height: 1.4),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _LinkButton(label: s.termsOfService, onTap: () => launchUrlString(Constants.termsOfServiceUrl)),
            Text('·', style: pv.body(size: 13, color: pv.textSecondary)),
            _LinkButton(label: s.privacyPolicy, onTap: () => launchUrlString(Constants.privacyPolicyUrl)),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, List<PurchaseOffer> offers) {
    final pv = context.pv;
    final s = Strings.of(context);
    final selectedIndex = _effectiveSelectedIndex(offers);
    final selected = selectedIndex >= 0 && selectedIndex < offers.length ? offers[selectedIndex] : null;
    final isFree = selected == null || selected.plan == SubscriptionPlan.free;
    final upgrade = selected?.isUpgrade ?? false;
    final enabled = !isFree && !kIsWeb;
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;

    final summary = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(upgrade ? s.planUpgradeToLabel : s.planSelectedLabel,
                  style: pv.body(size: 12, color: pv.textSecondary, weight: FontWeight.w400)),
              Text(selected == null ? '' : _planName(context, selected.plan),
                  style: pv.pixelLabel(size: 16).copyWith(height: 1.2)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(isFree ? s.free : (selected.price ?? ''),
                style: pv.mono(size: 22, weight: FontWeight.w700).copyWith(height: 1.1)),
            if (!isFree)
              Text(upgrade ? s.planUpgradeNote : s.planOneTime,
                  style: pv.body(size: 12, color: pv.textSecondary, weight: FontWeight.w400)),
          ],
        ),
      ],
    );

    final button = kIsWeb
        ? Row(
            children: [
              Icon(Icons.phone_iphone, size: 20, color: pv.warn),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(s.planOpenAppToPurchase,
                      style: pv.body(size: 13, color: pv.textSecondary, weight: FontWeight.w400))),
            ],
          )
        : _PurchaseButton(
            key: const ValueKey('purchase-button'),
            label: _isLoading ? s.planProcessing : _purchaseButtonLabel(context, selected),
            enabled: enabled,
            busy: _isLoading,
            onPressed: enabled && !_isLoading ? () => _handlePurchase(selected) : null,
          );

    final caption = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _isLoading ? s.planConfirmingWithStore : s.oneTimePurchaseLifetimeAccess,
          textAlign: TextAlign.center,
          style: pv.body(size: 12, color: pv.textSecondary, weight: FontWeight.w400).copyWith(height: 1.4),
        ),
        if (!kIsDemo)
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _LinkButton(label: s.termsOfService, onTap: () => launchUrlString(Constants.termsOfServiceUrl)),
              Text('·', style: pv.body(size: 13, color: pv.textSecondary)),
              _LinkButton(label: s.privacyPolicy, onTap: () => launchUrlString(Constants.privacyPolicyUrl)),
            ],
          ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: pv.surface,
        border: Border(top: BorderSide(color: pv.divider)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, -6))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: wide
              ? const EdgeInsets.symmetric(horizontal: 32, vertical: 12)
              : const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: wide
                  ? IntrinsicHeight(
                      child: Row(
                      children: [
                        Expanded(child: summary),
                        const SizedBox(width: 24),
                        SizedBox(width: 340, child: button),
                        const SizedBox(width: 24),
                        Expanded(child: caption),
                      ],
                    ))
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [summary, const SizedBox(height: 12), button, const SizedBox(height: 4), caption],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _watchAdForTemporaryPro() async {
    final rewardController = ref.read(rewardVideoAdProvider.notifier);

    setState(() => _isLoading = true);

    try {
      final rewardEarned = await rewardController.showAdIfLoaded();

      if (rewardEarned) {
        final completedAds = _temporaryProAdsWatched + 1;
        final preferences = await SharedPreferences.getInstance();

        if (completedAds >= _requiredTemporaryProAds) {
          await preferences.remove(_temporaryProAdsWatchedKey);
          ref.read(subscriptionStateProvider.notifier).grantTemporaryProAccess();

          if (mounted) {
            setState(() => _temporaryProAdsWatched = 0);
            AppNotification.success(
              context,
              Strings.of(context).proAccessGrantedOneHour,
              duration: const Duration(seconds: 3),
            );
          }
        } else {
          await preferences.setInt(
            _temporaryProAdsWatchedKey,
            completedAds,
          );

          if (mounted) {
            setState(() => _temporaryProAdsWatched = completedAds);
            AppNotification.info(
              context,
              Strings.of(context).adCompletedStartNext(completedAds, _requiredTemporaryProAds),
              duration: const Duration(seconds: 3),
            );
          }
        }
      } else if (mounted) {
        AppNotification.warning(
          context,
          Strings.of(context).videoAdNotCompleted,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotification.error(
          context,
          Strings.of(context).failedToLoadVideoAd(e.toString()),
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _planName(BuildContext context, SubscriptionPlan plan) {
    final s = Strings.of(context);
    return switch (plan) {
      SubscriptionPlan.free => s.free,
      SubscriptionPlan.pro => s.planPro,
      SubscriptionPlan.ultimate => s.planUltimate,
    };
  }

  String _offerDescription(BuildContext context, PurchaseOffer offer) {
    final s = Strings.of(context);
    return switch (offer.plan) {
      SubscriptionPlan.free => s.freePlanDescription,
      SubscriptionPlan.pro => s.proPlanDescription,
      SubscriptionPlan.ultimate => offer.isUpgrade ? s.ultimateUpgradeDescription : s.ultimatePlanDescription,
    };
  }

  List<String> _offerFeatures(BuildContext context, PurchaseOffer offer) {
    final s = Strings.of(context);
    return switch (offer.plan) {
      SubscriptionPlan.free => [
          s.freeProjectsCount(SubscriptionFeatureConfig.maxProjects[SubscriptionPlan.free]!),
          s.basicTools,
          s.freeCanvasSizeUpTo(SubscriptionFeatureConfig.maxCanvasSize[SubscriptionPlan.free]!),
          s.pngJpegFormats,
          s.offerStarterEffects,
          if (_supportsRewardedAds) s.watchAdsForTemporaryAccess,
        ],
      SubscriptionPlan.pro => [
          s.unlimitedProjects,
          s.offerAllToolsTemplates,
          s.whatsNewBoneRigTitle,
          s.proCanvasSizeUpTo,
          s.allFormatsVideoGif,
          s.offerBasicFiltersPack,
          if (_supportsRewardedAds) s.noAds,
          s.offerNoWatermarks,
        ],
      SubscriptionPlan.ultimate => [
          s.offerEverythingInPro,
          s.offerAllEffectPacks,
          s.offerCloudSync,
        ],
    };
  }

  String _purchaseButtonLabel(BuildContext context, PurchaseOffer? offer) {
    final s = Strings.of(context);
    if (offer == null || offer.plan == SubscriptionPlan.free) return s.continueWithFree;
    if (offer.isUpgrade) return s.upgradeToUltimate;
    return s.getPlan(_planName(context, offer.plan));
  }

  /// The explicit selection, or the highlighted offer until the user picks one.
  int _effectiveSelectedIndex(List<PurchaseOffer> offers) {
    if (_selectedIndex != null) return _selectedIndex!;
    final popular = offers.indexWhere((offer) => offer.isMostPopular);
    return popular != -1 ? popular : offers.length - 1;
  }

  Future<void> _handlePurchase(PurchaseOffer offer) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(subscriptionStateProvider.notifier).purchase(offer.productId!);
      // Purchase state will be handled by the listener
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  String _getUpgradePromptTitle(BuildContext context, SubscriptionFeature feature) {
    final s = Strings.of(context);
    switch (feature) {
      case SubscriptionFeature.maxProjects:
        return s.unlockUnlimitedProjects;
      case SubscriptionFeature.maxCanvasSize:
        return s.unlockLargerCanvasSizes;
      case SubscriptionFeature.exportFormats:
        return s.unlockAllExportFormats;
      case SubscriptionFeature.advancedTools:
        return s.unlockAdvancedTools;
      case SubscriptionFeature.cloudBackup:
        return s.enableCloudBackup;
      case SubscriptionFeature.noWatermark:
        return s.removeWatermark;
      case SubscriptionFeature.prioritySupport:
        return s.getPrioritySupport;
      case SubscriptionFeature.effects:
        return s.unlockSpecialEffects;
      case SubscriptionFeature.templates:
        return s.unlockTemplates;
      case SubscriptionFeature.proTheme:
        return s.unlockProTheme;
    }
  }

  String _getUpgradePromptSubtitle(BuildContext context, SubscriptionFeature feature) {
    final s = Strings.of(context);
    if (!_supportsRewardedAds) {
      return switch (feature) {
        SubscriptionFeature.maxProjects => s.unlimitedProjects,
        SubscriptionFeature.maxCanvasSize => s.proCanvasSizeUpTo,
        SubscriptionFeature.exportFormats => s.allFormatsVideoGif,
        SubscriptionFeature.advancedTools => s.offerAllToolsTemplates,
        SubscriptionFeature.cloudBackup => s.upgradePromptCloudBackupSubtitle,
        SubscriptionFeature.noWatermark => s.upgradePromptNoWatermarkSubtitle,
        SubscriptionFeature.prioritySupport => s.upgradePromptPrioritySupportSubtitle,
        SubscriptionFeature.effects => s.unlockSpecialEffects,
        SubscriptionFeature.templates => s.unlockTemplates,
        SubscriptionFeature.proTheme => s.unlockProTheme,
      };
    }
    switch (feature) {
      case SubscriptionFeature.maxProjects:
        return s.upgradePromptMaxProjectsSubtitle;
      case SubscriptionFeature.maxCanvasSize:
        return s.upgradePromptMaxCanvasSizeSubtitle;
      case SubscriptionFeature.exportFormats:
        return s.upgradePromptExportFormatsSubtitle;
      case SubscriptionFeature.advancedTools:
        return s.upgradePromptAdvancedToolsSubtitle;
      case SubscriptionFeature.cloudBackup:
        return s.upgradePromptCloudBackupSubtitle;
      case SubscriptionFeature.noWatermark:
        return s.upgradePromptNoWatermarkSubtitle;
      case SubscriptionFeature.prioritySupport:
        return s.upgradePromptPrioritySupportSubtitle;
      // These three mirror the original implementation, which returned the
      // same "Unlock X" text for both the title and the subtitle.
      case SubscriptionFeature.effects:
        return s.unlockSpecialEffects;
      case SubscriptionFeature.templates:
        return s.unlockTemplates;
      case SubscriptionFeature.proTheme:
        return s.unlockProTheme;
    }
  }
}

// Helper class for feature comparison
class _FeatureComparisonItem {
  final IconData icon;
  final String title;

  // String or bool
  final Object free;
  final Object pro;
  final Object ultimate;

  _FeatureComparisonItem({
    required this.icon,
    required this.title,
    required this.free,
    required this.pro,
    required this.ultimate,
  });
}

/// Top-right pixel notch shared by the Best value ribbon and the buy button.
class _PixelNotchClipper extends CustomClipper<Path> {
  const _PixelNotchClipper();

  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(w - 9, 0)
      ..lineTo(w - 9, 3)
      ..lineTo(w - 6, 3)
      ..lineTo(w - 6, 6)
      ..lineTo(w - 3, 6)
      ..lineTo(w - 3, 9)
      ..lineTo(w, 9)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Pixel-grid art: layers of colored rects on an n x n grid.
class _PixelPainter extends CustomPainter {
  _PixelPainter(this.grid, this.layers);

  /// Free, Pro and Ultimate emblems.
  factory _PixelPainter.emblem(PvTokens pv, SubscriptionPlan plan) {
    const gem = [
      [3, 1, 4, 1],
      [2, 2, 6, 1],
      [1, 3, 8, 2],
      [2, 5, 6, 1],
      [3, 6, 4, 1],
      [4, 7, 2, 1],
    ];
    return switch (plan) {
      SubscriptionPlan.free => _PixelPainter(10, [
          (
            pv.divider,
            const [
              [1, 1, 8, 8]
            ]
          ),
          (
            pv.surfaceHigh,
            const [
              [2, 2, 6, 6]
            ]
          ),
          (
            pv.textSecondary,
            const [
              [4, 3, 2, 4],
              [3, 4, 4, 2]
            ]
          ),
        ]),
      SubscriptionPlan.pro => _PixelPainter(10, [
          (pv.primary, gem),
          (
            pv.accent,
            const [
              [3, 1, 2, 1],
              [2, 2, 2, 1],
              [1, 3, 2, 1]
            ]
          ),
          (
            pv.ink.withValues(alpha: 0.25),
            const [
              [5, 5, 3, 1],
              [5, 6, 2, 1]
            ]
          ),
        ]),
      SubscriptionPlan.ultimate => _PixelPainter(10, [
          (pv.primary, gem),
          (
            pv.accent,
            const [
              [3, 1, 2, 1],
              [2, 2, 2, 1],
              [1, 3, 2, 1],
              [6, 5, 2, 1],
              [5, 6, 2, 1],
              [8, 0, 1, 1],
              [0, 7, 1, 1],
              [9, 6, 1, 1]
            ]
          ),
        ]),
    };
  }

  /// The small bone-rigged character on the Bone Rig strip.
  factory _PixelPainter.rig(PvTokens pv) => _PixelPainter(16, [
        (
          pv.primary,
          const [
            [5, 1, 6, 5],
            [5, 6, 6, 5],
            [3, 6, 2, 4],
            [11, 6, 2, 4],
            [5, 11, 2, 4],
            [9, 11, 2, 4]
          ]
        ),
        (
          pv.accent,
          const [
            [7, 3, 2, 2],
            [7, 7, 2, 2],
            [3, 9, 2, 2],
            [11, 9, 2, 2],
            [5, 12, 2, 2],
            [9, 12, 2, 2]
          ]
        ),
        (
          pv.background,
          const [
            [6, 3, 1, 1],
            [9, 3, 1, 1]
          ]
        ),
      ]);

  final int grid;
  final List<(Color, List<List<num>>)> layers;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.shortestSide / grid;
    final paint = Paint()..isAntiAlias = false;
    for (final (color, rects) in layers) {
      paint.color = color;
      for (final r in rects) {
        canvas.drawRect(Rect.fromLTWH(r[0] * cell, r[1] * cell, r[2] * cell, r[3] * cell), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PixelPainter old) => old.grid != grid || old.layers != layers;
}

class _PlanEmblem extends StatelessWidget {
  const _PlanEmblem({required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PixelPainter.emblem(context.pv, plan), size: Size.infinite);
}

/// Quiet text button with a 44dp touch target.
class _LinkButton extends StatelessWidget {
  const _LinkButton({super.key, required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    return PvPressable(
      onTap: onTap,
      builder: (context, hovered) {
        final color = hovered ? pv.accent : pv.primary;
        return Semantics(
          button: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: hovered ? pv.surfaceHigh : null,
              borderRadius: BorderRadius.circular(pv.buttonRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20, color: color), const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    label,
                    style: pv.body(size: 14, color: color, weight: FontWeight.w600).copyWith(
                          decoration: icon == null ? TextDecoration.underline : null,
                          decorationColor: color,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LockedFeatureTile extends StatelessWidget {
  const _LockedFeatureTile({required this.feature, required this.title, required this.subtitle});

  final SubscriptionFeature feature;
  final String title;
  final String subtitle;

  IconData get _icon => switch (feature) {
        SubscriptionFeature.maxProjects => Icons.inventory_2_outlined,
        SubscriptionFeature.maxCanvasSize => Icons.grid_on,
        SubscriptionFeature.exportFormats => Icons.download,
        SubscriptionFeature.advancedTools => Icons.format_paint,
        SubscriptionFeature.cloudBackup => Icons.cloud_upload,
        SubscriptionFeature.noWatermark => Icons.branding_watermark_outlined,
        SubscriptionFeature.prioritySupport => Icons.support_agent,
        SubscriptionFeature.effects => Icons.auto_awesome,
        SubscriptionFeature.templates => Icons.dashboard_outlined,
        SubscriptionFeature.proTheme => Icons.palette_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    return Container(
      key: const ValueKey('locked-feature-tile'),
      padding: const EdgeInsets.all(12),
      decoration: pv.cardDecoration(color: pv.surfaceHigh).copyWith(border: Border.all(color: pv.primary)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(gradient: pv.gradient, borderRadius: BorderRadius.circular(pv.chipRadius.clamp(4, 14))),
            child: Icon(_icon, size: 26, color: pv.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: pv.pixelLabel(size: 15).copyWith(height: 1.25)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: pv.body(size: 13, color: pv.textSecondary, weight: FontWeight.w400).copyWith(height: 1.4)),
              ],
            ),
          ),
          Icon(Icons.lock_outline, size: 22, color: pv.primary),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('plans-error'),
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: BoxDecoration(
          color: Color.alphaBlend(pv.err.withValues(alpha: 0.14), pv.surface),
          borderRadius: BorderRadius.circular(pv.cardRadius),
          border: Border.all(color: pv.err, width: 2),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Icon(Icons.error, size: 24, color: pv.err),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 150, maxWidth: 560),
              child: Text(message, style: pv.body(size: 14, weight: FontWeight.w500).copyWith(height: 1.4)),
            ),
            PvPressable(
              onTap: onRetry,
              builder: (context, hovered) => Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: hovered ? pv.err : null,
                  borderRadius: BorderRadius.circular(pv.buttonRadius),
                  border: Border.all(color: pv.err, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 20, color: hovered ? pv.background : pv.textPrimary),
                    const SizedBox(width: 4),
                    Text(Strings.of(context).planRetry,
                        style: pv.pixelLabel(size: 13, color: hovered ? pv.background : pv.textPrimary)),
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

class _StoreUnavailableBanner extends StatelessWidget {
  const _StoreUnavailableBanner();

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final s = Strings.of(context);
    return Container(
      key: const ValueKey('store-unavailable'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pv.cardDecoration(color: pv.surfaceHigh),
      child: Row(
        children: [
          Icon(Icons.storefront_outlined, size: 24, color: pv.warn),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${s.planStoreUnavailableTitle} ', style: pv.body(size: 14, weight: FontWeight.w700)),
                  TextSpan(
                      text: s.planStoreUnavailableBody,
                      style: pv.body(size: 14, color: pv.textSecondary, weight: FontWeight.w400)),
                ],
              ),
              style: const TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnEverythingCard extends StatelessWidget {
  const _OwnEverythingCard({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    return Container(
      key: const ValueKey('own-everything'),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: pv.cardDecoration().copyWith(border: Border.all(color: pv.primary, width: 2)),
      child: Column(
        children: [
          Icon(Icons.verified, size: 36, color: pv.ok),
          const SizedBox(height: 8),
          Text(Strings.of(context).planOwnEverything, style: pv.pixelLabel(size: 20), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: pv.body(size: 14, color: pv.textSecondary, weight: FontWeight.w400).copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanSkeletons extends StatelessWidget {
  const _PlanSkeletons({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    Widget card() => Container(
          height: wide ? 420 : 210,
          padding: const EdgeInsets.all(16),
          decoration: pv.cardDecoration(),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                PvShimmerBox(width: 40, height: 40, radius: 8),
                SizedBox(width: 12),
                PvShimmerBox(width: 90, height: 16, radius: 6),
              ]),
              SizedBox(height: 12),
              PvShimmerBox(width: 120, height: 28, radius: 6),
              SizedBox(height: 12),
              PvShimmerBox(height: 12, radius: 6),
              SizedBox(height: 12),
              PvShimmerBox(width: 200, height: 12, radius: 6),
              SizedBox(height: 12),
              PvShimmerBox(width: 240, height: 12, radius: 6),
            ],
          ),
        );
    return wide
        ? Row(children: [
            for (var i = 0; i < 3; i++) ...[if (i > 0) const SizedBox(width: 20), Expanded(child: card())]
          ])
        : Column(children: [
            for (var i = 0; i < 3; i++) ...[if (i > 0) const SizedBox(height: 16), card()]
          ]);
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    super.key,
    required this.offer,
    required this.name,
    required this.features,
    required this.selected,
    required this.current,
    required this.wide,
    required this.onTap,
    required this.topInset,
    this.note,
  });

  final PurchaseOffer offer;
  final String name;
  final List<String> features;
  final String? note;
  final bool selected;

  /// Free plan marker for people who have not bought anything.
  final bool current;
  final bool wide;
  final VoidCallback? onTap;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final s = Strings.of(context);
    final ultimate = offer.plan == SubscriptionPlan.ultimate;
    final borderWidth = ultimate ? 2.0 : (pv.cardBorderWidth < 1 ? 1.0 : pv.cardBorderWidth);
    final animate = !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    final shadow = pv.cardDecoration().boxShadow ?? const <BoxShadow>[];

    Widget card(bool hovered) {
      final ring = <BoxShadow>[
        if (selected && ultimate) BoxShadow(color: pv.primary, spreadRadius: 4),
        if (selected && ultimate) BoxShadow(color: pv.background, spreadRadius: 2),
        if (selected && !ultimate) BoxShadow(color: pv.primary, spreadRadius: 2),
        ...shadow,
      ];
      final outerRadius = BorderRadius.circular(pv.cardRadius);
      final innerRadius = BorderRadius.circular((pv.cardRadius - borderWidth).clamp(0, 100));
      return AnimatedContainer(
        duration: animate ? const Duration(milliseconds: 150) : Duration.zero,
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          gradient: ultimate ? pv.gradient : null,
          color: ultimate ? null : (hovered ? pv.accent : pv.divider),
          borderRadius: outerRadius,
          boxShadow: ring,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(ultimate ? (wide ? 20 : 16) : 16, ultimate ? (wide ? 28 : 24) : 16,
              ultimate ? (wide ? 20 : 16) : 16, ultimate ? (wide ? 20 : 16) : 16),
          decoration: BoxDecoration(color: pv.surface, borderRadius: innerRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(width: ultimate ? 48 : 40, height: ultimate ? 48 : 40, child: _PlanEmblem(plan: offer.plan)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: pv.pixelLabel(size: ultimate ? 20 : 17).copyWith(height: 1.2)),
                        if (current) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: PvChip(label: s.planCurrentChip, icon: Icons.check, color: pv.ok, dense: true),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  selected
                      ? Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(color: pv.primary, shape: BoxShape.circle),
                          child: Icon(Icons.check, size: 20, color: pv.ink),
                        )
                      : Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, border: Border.all(color: pv.textSecondary, width: 2)),
                        ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 8,
                children: [
                  Text(
                    offer.plan == SubscriptionPlan.free ? s.free : (offer.price ?? ''),
                    style: pv.mono(size: ultimate ? 32 : 26, weight: FontWeight.w700).copyWith(height: 1.1),
                  ),
                  if (offer.plan != SubscriptionPlan.free)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(s.planOneTime,
                          style: pv.body(size: 12, color: pv.textSecondary, weight: FontWeight.w400)),
                    ),
                ],
              ),
              if (note != null) ...[
                const SizedBox(height: 4),
                Text(note!, style: pv.body(size: 12, color: pv.textSecondary, weight: FontWeight.w400)),
              ],
              const SizedBox(height: 12),
              Divider(height: 1, thickness: 1, color: pv.divider),
              const SizedBox(height: 12),
              for (final (i, feature) in features.indexed) ...[
                if (i > 0) const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(Icons.check, size: 18, color: pv.ok),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(feature, style: pv.body(size: 14, weight: FontWeight.w400).copyWith(height: 1.4))),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: topInset),
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        button: true,
        label: name,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            PvPressable(onTap: onTap, builder: (context, hovered) => card(hovered)),
            if (offer.isMostPopular)
              Positioned(
                top: -12,
                right: 16,
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: const _PixelNotchClipper(),
                    child: Container(
                      height: 24,
                      padding: const EdgeInsets.only(left: 10, right: 14),
                      decoration: BoxDecoration(
                        gradient: pv.gradient,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(pv.chipRadius.clamp(2, 12)),
                          bottomLeft: Radius.circular(pv.chipRadius.clamp(2, 12)),
                          bottomRight: Radius.circular(pv.chipRadius.clamp(2, 12)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: pv.ink),
                          const SizedBox(width: 4),
                          Text(s.bestValue, style: pv.pixelLabel(size: 12, color: pv.ink).copyWith(letterSpacing: 0.5)),
                        ],
                      ),
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

class _PurchaseButton extends StatelessWidget {
  const _PurchaseButton(
      {super.key, required this.label, required this.enabled, required this.busy, required this.onPressed});

  final String label;
  final bool enabled;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final active = enabled || busy;
    final fg = active ? pv.ink : pv.textSecondary;
    final radius = Radius.circular(pv.buttonRadius);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: ClipPath(
        clipper: const _PixelNotchClipper(),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            height: 56,
            decoration: BoxDecoration(
              gradient: active ? pv.gradient : null,
              color: active ? null : pv.surfaceHigh,
              borderRadius: BorderRadius.only(topLeft: radius, bottomLeft: radius, bottomRight: radius),
            ),
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (busy) ...[
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: fg)),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: pv.pixelLabel(size: 17, color: fg).copyWith(letterSpacing: 0.5, height: 1.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Plan comparison: a pinned label column beside columns that scroll
/// sideways when the screen is too narrow for all three plans.
class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.rows, required this.headers, required this.wide});

  final List<_FeatureComparisonItem> rows;
  final List<String> headers;
  final bool wide;

  static const double _labelWidth = 120;
  static const double _minCell = 112;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final highlight = Color.alphaBlend(pv.primary.withValues(alpha: 0.12), pv.surface);
    final scale = MediaQuery.textScalerOf(context);
    final rowHeight = (scale.scale(13) * 3 + 24).clamp(60.0, 140.0);
    final headHeight = (scale.scale(13) * 2 + 24).clamp(48.0, 100.0);

    Widget cell(Object value, {required bool last, required bool ultimate}) {
      final Widget child;
      if (value is bool) {
        child = value
            ? Icon(Icons.check, size: 22, color: pv.ok, semanticLabel: 'Included')
            : Text('–', style: pv.mono(size: 16, color: pv.textSecondary), semanticsLabel: 'Not included');
      } else {
        child = Text(value as String,
            textAlign: TextAlign.center, style: pv.body(size: 13, weight: FontWeight.w400).copyWith(height: 1.3));
      }
      return Container(
        height: rowHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: ultimate ? highlight : null,
          border: Border(bottom: last ? BorderSide.none : BorderSide(color: pv.divider)),
        ),
        child: child,
      );
    }

    return Container(
      decoration: pv.cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = ((constraints.maxWidth - _labelWidth) / 3).clamp(_minCell, double.infinity);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _labelWidth,
                child: Column(
                  children: [
                    Container(
                      height: headHeight,
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: pv.divider, width: 2))),
                    ),
                    for (final (i, row) in rows.indexed)
                      Container(
                        height: rowHeight,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border:
                              Border(bottom: i == rows.length - 1 ? BorderSide.none : BorderSide(color: pv.divider)),
                        ),
                        child: Text(row.title, style: pv.body(size: 13, weight: FontWeight.w600).copyWith(height: 1.3)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: cellWidth * 3,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            for (final (i, h) in headers.indexed)
                              Container(
                                width: cellWidth,
                                height: headHeight,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: i == 2 ? highlight : null,
                                  border: Border(bottom: BorderSide(color: i == 2 ? pv.primary : pv.divider, width: 2)),
                                ),
                                child: Text(h,
                                    textAlign: TextAlign.center, style: pv.pixelLabel(size: 13).copyWith(height: 1.2)),
                              ),
                          ],
                        ),
                        for (final (i, row) in rows.indexed)
                          Row(
                            children: [
                              SizedBox(
                                  width: cellWidth, child: cell(row.free, last: i == rows.length - 1, ultimate: false)),
                              SizedBox(
                                  width: cellWidth, child: cell(row.pro, last: i == rows.length - 1, ultimate: false)),
                              SizedBox(
                                  width: cellWidth,
                                  child: cell(row.ultimate, last: i == rows.length - 1, ultimate: true)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
