import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picell/config/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../config/assets.dart';
import '../../app/theme/theme.dart';
import '../../data/models/subscription_model.dart';
import '../../l10n/strings.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/ad/reward_video_ad_controller.dart';
import '../widgets/theme_selector.dart';
import 'effect_store_screen.dart';
import '../widgets/notifications/app_notification.dart';

class SubscriptionOfferScreen extends ConsumerStatefulWidget {
  static Future<bool?> show(
    BuildContext context, {
    bool isPostCreation = false,
    SubscriptionFeature? featurePrompt,
  }) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < 600) {
      return Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => SubscriptionOfferScreen(
            isPostCreation: isPostCreation,
            featurePrompt: featurePrompt,
          ),
        ),
      );
    }

    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 600,
          child: SubscriptionOfferScreen(
            isPostCreation: isPostCreation,
            featurePrompt: featurePrompt,
          ),
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
    _loadTemporaryProAdProgress();

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

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider).theme;
    final offers = ref.watch(purchaseOffersProvider);
    final subscription = ref.watch(subscriptionStateProvider);
    final rewardAdState = ref.watch(rewardVideoAdProvider);

    // Rebuild the UI when we get purchase updates
    ref.listen(purchaseUpdatesStreamProvider, (previous, next) {
      final purchases = next.valueOrNull ?? [];
      if (purchases.isEmpty) return;

      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.pending) {
          setState(() => _isLoading = true);
        } else if (purchase.status == PurchaseStatus.error) {
          setState(() {
            _isLoading = false;
            _errorMessage = purchase.error?.message ?? Strings.of(context).purchaseFailed;
          });
        } else if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });

          // Show success animation
          _confettiController.play();

          // Close the screen after a short delay on success
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) Navigator.of(context).pop(true);
          });
        } else if (purchase.status == PurchaseStatus.canceled) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.of(context).plansTitle),
        actions: [
          if (!_isLoading && !kIsWeb)
            TextButton(
              onPressed: () {
                ref.read(subscriptionStateProvider.notifier).restorePurchases();
                setState(() => _isLoading = true);
              },
              child: Text(Strings.of(context).restore),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    if (subscription.plan.isPaid) ...[
                      _buildCurrentPlanStatus(context, theme, subscription.plan),
                      const SizedBox(height: 16),
                    ],
                    if (subscription.hasTemporaryPro) _buildTemporaryProStatus(context, theme),
                    const SizedBox(height: 16),
                    if (_supportsRewardedAds) ...[
                      _buildTemporaryProSection(context, theme, rewardAdState),
                      const SizedBox(height: 24),
                    ],
                    _buildOfferCards(context, offers),
                    if (!subscription.hasEntitlement(Entitlement.allEffects))
                      Center(
                        child: TextButton.icon(
                          key: const ValueKey('browse-effect-packs'),
                          onPressed: () => EffectStoreScreen.show(context),
                          icon: const Icon(Icons.storefront_outlined),
                          label: Text(Strings.of(context).browseEffectPacks),
                        ),
                      ),
                    const SizedBox(height: 24),
                    _buildFeatureComparison(context, theme),
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade900),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (!kIsDemo) _buildTermsText(context),
                  ],
                ),
              ),
              if (!kIsDemo && offers.any((offer) => offer.productId != null)) _buildBottomBar(context, offers),
            ],
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
              colors: [
                theme.primaryColor,
                theme.accentColor,
                Colors.green,
                Colors.yellow,
                Colors.blue,
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTemporaryProStatus(BuildContext context, AppTheme theme) {
    final subscription = ref.watch(subscriptionStateProvider);
    final remainingTime = subscription.temporaryProAccess?.remainingTime;

    if (remainingTime == null || remainingTime <= Duration.zero) {
      return const SizedBox.shrink();
    }

    final minutes = remainingTime.inMinutes;
    final seconds = remainingTime.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.star,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Strings.of(context).proAccessActiveExclaim,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  Strings.of(context).temporaryProTimeRemaining(minutes, seconds),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().scale(
          duration: 600.ms,
          curve: Curves.elasticOut,
        );
  }

  Widget _buildTemporaryProSection(BuildContext context, AppTheme theme, bool adReady) {
    final subscription = ref.watch(subscriptionStateProvider);

    if (subscription.isPermanentPro) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.play_circle_fill,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                Strings.of(context).tryProForFreeExclaim,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Strings.of(context).watchAdUnlockProOneHour,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (!subscription.hasTemporaryPro) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _temporaryProAdsWatched / _requiredTemporaryProAds,
              backgroundColor: Colors.orange.withValues(alpha: 0.15),
              color: Colors.orange,
            ),
            const SizedBox(height: 6),
            Text(
              Strings.of(context).temporaryProAdsCompleted(_temporaryProAdsWatched, _requiredTemporaryProAds),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: adReady && !subscription.hasTemporaryPro && !_isLoading ? _watchAdForTemporaryPro : null,
              icon: Icon(
                subscription.hasTemporaryPro ? Icons.check_circle : (adReady ? Icons.play_arrow : Icons.refresh),
              ),
              label: Text(
                subscription.hasTemporaryPro
                    ? Strings.of(context).proAccessActive
                    : (adReady ? Strings.of(context).watchAd : Strings.of(context).loadingNextAd),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: subscription.hasTemporaryPro ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
          duration: 600.ms,
          delay: 200.ms,
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

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // App logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(Assets.images.logo),
          ),
        ).animate().scale(
              duration: 600.ms,
              curve: Curves.easeOutBack,
            ),

        const SizedBox(height: 16),

        // Headline
        Text(
          widget.featurePrompt != null
              ? _getUpgradePromptTitle(context, widget.featurePrompt!)
              : Strings.of(context).unlockPremiumPixelCreation,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(
              duration: 500.ms,
              delay: 200.ms,
            )
            .slideY(
              begin: 0.2,
              end: 0,
              curve: Curves.easeOutQuad,
            ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          widget.featurePrompt != null
              ? _getUpgradePromptSubtitle(context, widget.featurePrompt!)
              : Strings.of(context).oneTimePurchaseTryAdsFirst,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
              ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(
              duration: 500.ms,
              delay: 400.ms,
            ),
      ],
    );
  }

  Widget _buildCurrentPlanStatus(BuildContext context, AppTheme theme, SubscriptionPlan plan) {
    final s = Strings.of(context);
    final isUltimate = plan == SubscriptionPlan.ultimate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            isUltimate ? MaterialCommunityIcons.crown : MaterialCommunityIcons.star,
            color: theme.primaryColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.currentPlan(_planName(context, plan)),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  isUltimate ? s.ultimateOwnedSubtitle : s.proOwnedSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildFeatureComparison(BuildContext context, AppTheme theme) {
    final s = Strings.of(context);
    final features = [
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
        icon: MaterialCommunityIcons.advertisements,
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

    Widget headerChip(String label, {required bool highlighted}) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: highlighted ? theme.primaryColor.withValues(alpha: 0.2) : theme.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: highlighted ? FontWeight.bold : null,
                color: highlighted ? theme.primaryColor : null,
              ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    Widget valueCell(Object value, {required bool highlighted}) {
      if (value is bool) {
        return Center(
          child: Icon(
            value ? Icons.check : Icons.close,
            color: value ? (highlighted ? theme.primaryColor : Colors.green) : Colors.red.shade300,
            size: 20,
          ),
        );
      }
      return Text(
        value as String,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: highlighted ? theme.primaryColor : theme.textSecondary,
              fontWeight: highlighted ? FontWeight.bold : null,
            ),
        textAlign: TextAlign.center,
      );
    }

    return Column(
      children: [
        Text(
          s.planComparisonTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        s.featureColumnHeader,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(flex: 3, child: headerChip(s.free, highlighted: false)),
                    const SizedBox(width: 4),
                    Expanded(flex: 3, child: headerChip(s.planPro, highlighted: false)),
                    const SizedBox(width: 4),
                    Expanded(flex: 3, child: headerChip(s.planUltimate, highlighted: true)),
                  ],
                ),
              ),
              ...List.generate(features.length, (index) {
                final feature = features[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: theme.divider.withValues(alpha: 0.3)),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            Icon(feature.icon, size: 20, color: theme.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                feature.title,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(flex: 3, child: valueCell(feature.free, highlighted: false)),
                      const SizedBox(width: 4),
                      Expanded(flex: 3, child: valueCell(feature.pro, highlighted: false)),
                      const SizedBox(width: 4),
                      Expanded(flex: 3, child: valueCell(feature.ultimate, highlighted: true)),
                    ],
                  ),
                );
              }),
            ],
          ),
        )
            .animate()
            .fadeIn(
              duration: 800.ms,
              delay: 300.ms,
            )
            .slideY(
              begin: 0.3,
              end: 0,
              curve: Curves.easeOutQuad,
              duration: 800.ms,
              delay: 300.ms,
            ),
      ],
    );
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
          s.watchAdsForTemporaryAccess,
        ],
      SubscriptionPlan.pro => [
          s.unlimitedProjects,
          s.offerAllToolsTemplates,
          s.proCanvasSizeUpTo,
          s.allFormatsVideoGif,
          s.offerBasicFiltersPack,
          s.noAds,
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

  Widget _buildOfferCards(BuildContext context, List<PurchaseOffer> offers) {
    if (offers.isEmpty) {
      // Owners of Ultimate have nothing left to buy once products are loaded.
      final productsLoaded = ref.read(subscriptionServiceProvider).products.isNotEmpty;
      if (productsLoaded) return const SizedBox.shrink();
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Strings.of(context).chooseYourPlan,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...List.generate(offers.length, (index) {
          final offer = offers[index];
          final isSelected = _effectiveSelectedIndex(offers) == index;

          return _PurchaseOfferCard(
            offer: offer,
            title: _planName(context, offer.plan),
            description: _offerDescription(context, offer),
            features: _offerFeatures(context, offer),
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
            },
          )
              .animate()
              .fadeIn(
                duration: 600.ms,
                delay: Duration(milliseconds: 400 + index * 200),
              )
              .slideX(
                begin: 0.2,
                end: 0,
                duration: 600.ms,
                delay: Duration(milliseconds: 400 + index * 200),
                curve: Curves.easeOutQuad,
              );
        }),
      ],
    );
  }

  Widget _buildTermsText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Text(
            Strings.of(context).agreeToTermsAndPrivacy,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  launchUrlString(Constants.termsOfServiceUrl);
                },
                child: Text(
                  Strings.of(context).termsOfService,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                ' • ',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              InkWell(
                onTap: () {
                  launchUrlString(Constants.privacyPolicyUrl);
                },
                child: Text(
                  Strings.of(context).privacyPolicy,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Strings.of(context).oneTimePurchaseLifetimeAccess,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, List<PurchaseOffer> offers) {
    final selectedIndex = _effectiveSelectedIndex(offers);
    final selectedOffer = selectedIndex >= 0 && selectedIndex < offers.length ? offers[selectedIndex] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (selectedOffer != null && selectedOffer.plan != SubscriptionPlan.free)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _planName(context, selectedOffer.plan),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedOffer.price ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: selectedOffer?.plan == SubscriptionPlan.free || _isLoading
                    ? null
                    : () => _handlePurchase(selectedOffer!),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  _purchaseButtonLabel(context, selectedOffer),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

// Purchase offer card widget
class _PurchaseOfferCard extends StatelessWidget {
  final PurchaseOffer offer;
  final String title;
  final String description;
  final List<String> features;
  final bool isSelected;
  final VoidCallback onTap;

  const _PurchaseOfferCard({
    required this.offer,
    required this.title,
    required this.description,
    required this.features,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color:
              isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      if (offer.price != null)
                        Text(
                          offer.price!,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Feature list
                  ...features.map((feature) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            // "Best Value" tag
            if (offer.isMostPopular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Text(
                    Strings.of(context).bestValue,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),

            // Selection indicator
            if (isSelected)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 16,
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
