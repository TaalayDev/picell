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
  int _selectedIndex = 1; // Default to pro purchase
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
        title: Text(Strings.of(context).upgradeToPro),
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
                    if (subscription.hasTemporaryPro) _buildTemporaryProStatus(context, theme),
                    const SizedBox(height: 16),
                    if (_supportsRewardedAds) ...[
                      _buildTemporaryProSection(context, theme, rewardAdState),
                      const SizedBox(height: 24),
                    ],
                    _buildOfferCards(context, offers),
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
              if (!kIsDemo) _buildBottomBar(context, offers),
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

  Widget _buildFeatureComparison(BuildContext context, AppTheme theme) {
    final s = Strings.of(context);
    final features = [
      _FeatureComparisonItem(
        icon: Icons.inventory_2_outlined,
        title: s.featureProjects,
        free: s.freeProjectsCount(SubscriptionFeatureConfig.maxProjects[SubscriptionPlan.free]!),
        pro: s.unlimitedProjects,
      ),
      _FeatureComparisonItem(
        icon: Icons.grid_on,
        title: s.featureCanvasSize,
        free: s.freeCanvasSizeUpTo(SubscriptionFeatureConfig.maxCanvasSize[SubscriptionPlan.free]!),
        pro: s.proCanvasSizeUpTo,
      ),
      _FeatureComparisonItem(
        icon: Icons.format_paint,
        title: s.featureToolsEffects,
        free: s.basicTools,
        pro: s.advancedToolsEffectsTemplates,
      ),
      _FeatureComparisonItem(
        icon: Icons.download,
        title: s.featureExportFormats,
        free: s.pngJpegFormats,
        pro: s.allFormatsVideoGif,
      ),
      _FeatureComparisonItem(
        icon: Icons.play_circle_outline,
        title: s.featureTryProFeatures,
        free: s.watchAdsForTemporaryAccess,
        pro: s.unlimitedAccess,
      ),
      _FeatureComparisonItem(
        icon: MaterialCommunityIcons.advertisements,
        title: s.featureAds,
        free: s.watchAdsForProFeatures,
        pro: s.noAds,
      ),
      _FeatureComparisonItem(
        icon: Icons.cloud_upload,
        title: s.featureCloudBackup,
        free: false,
        pro: true,
      ),
      _FeatureComparisonItem(
        icon: Icons.support_agent,
        title: s.featurePrioritySupport,
        free: false,
        pro: true,
      ),
    ];

    return Column(
      children: [
        // Title
        Text(
          s.freeVsProFeatures,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 16),

        // Feature comparison table
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
              // Table header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 4,
                      child: Text(
                        s.featureColumnHeader,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          s.free,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          s.proColumnHeader,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Table rows
              ...List.generate(features.length, (index) {
                final feature = features[index];
                return Container(
                  decoration: BoxDecoration(
                    border: index < features.length - 1
                        ? Border(
                            top: BorderSide(
                            color: theme.divider.withValues(alpha: 0.3),
                          ))
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          feature.icon,
                          size: 24,
                          color: theme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: Text(
                            feature.title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: feature.free is bool
                              ? Center(
                                  child: Icon(
                                    feature.free ? Icons.check : Icons.close,
                                    color: feature.free ? Colors.green : Colors.red.shade300,
                                    size: 20,
                                  ),
                                )
                              : Text(
                                  feature.free as String,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: theme.textSecondary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: feature.pro is bool
                              ? Center(
                                  child: Icon(
                                    feature.pro ? Icons.check : Icons.close,
                                    color: feature.pro ? theme.primaryColor : Colors.red.shade300,
                                    size: 20,
                                  ),
                                )
                              : Text(
                                  feature.pro as String,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ],
                    ),
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

  Widget _buildOfferCards(BuildContext context, List<PurchaseOffer> offers) {
    if (offers.isEmpty) {
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
          final isSelected = _selectedIndex == index;

          return _PurchaseOfferCard(
            offer: offer,
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
    final selectedOffer = _selectedIndex < offers.length ? offers[_selectedIndex] : null;

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
                      selectedOffer.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedOffer.price,
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
                  selectedOffer?.plan == SubscriptionPlan.free
                      ? Strings.of(context).continueWithFree
                      : Strings.of(context).buyPro,
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
      await ref.read(subscriptionStateProvider.notifier).purchasePro();
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
  final dynamic free; // String or bool
  final dynamic pro; // String or bool

  _FeatureComparisonItem({
    required this.icon,
    required this.title,
    required this.free,
    required this.pro,
  });
}

// Purchase offer card widget
class _PurchaseOfferCard extends StatelessWidget {
  final PurchaseOffer offer;
  final bool isSelected;
  final VoidCallback onTap;

  const _PurchaseOfferCard({
    required this.offer,
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
                              offer.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              offer.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      if (offer.plan != SubscriptionPlan.free)
                        Text(
                          offer.price,
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
                  ...offer.features.map((feature) => Padding(
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
