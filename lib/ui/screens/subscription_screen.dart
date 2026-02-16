import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picell/config/constants.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../config/assets.dart';
import '../../app/theme/theme.dart';
import '../../data/models/subscription_model.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/ad/reward_video_ad_controller.dart';
import '../widgets/theme_selector.dart';

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
  late ConfettiController _confettiController;
  int _selectedIndex = 1; // Default to pro purchase
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );

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
            _errorMessage = purchase.error?.message ?? 'Purchase failed';
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
        title: const Text('Upgrade to Pro'),
        actions: [
          if (!_isLoading && !kIsWeb)
            TextButton(
              onPressed: () {
                ref.read(subscriptionStateProvider.notifier).restorePurchases();
                setState(() => _isLoading = true);
              },
              child: const Text('Restore'),
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
                    if (rewardAdState) ...[
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
              color: Colors.black.withOpacity(0.3),
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
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
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
                  'Pro Access Active!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Time remaining: ${minutes}m ${seconds}s',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
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
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                'Try Pro for Free!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Watch a short video ad to unlock Pro features for 45 minutes',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: adReady && !subscription.hasTemporaryPro ? () => _watchAdForTemporaryPro() : null,
              icon: Icon(
                subscription.hasTemporaryPro ? Icons.check_circle : (adReady ? Icons.play_arrow : Icons.refresh),
              ),
              label: Text(
                subscription.hasTemporaryPro
                    ? 'Pro Access Active'
                    : (adReady ? 'Watch Ad (45 min Pro)' : 'Loading Ad...'),
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
        ref.read(subscriptionStateProvider.notifier).grantTemporaryProAccess();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Pro access granted for 45 minutes!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video ad was not completed. Please try again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load video ad: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
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
                color: Colors.black.withOpacity(0.1),
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
              ? _getUpgradePromptTitle(widget.featurePrompt!)
              : 'Unlock Premium Pixel Creation',
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
              ? _getUpgradePromptSubtitle(widget.featurePrompt!)
              : 'One-time purchase • No recurring fees • Try with ads first',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
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
    final features = [
      _FeatureComparisonItem(
        icon: Icons.inventory_2_outlined,
        title: 'Projects',
        free: '${SubscriptionFeatureConfig.maxProjects[SubscriptionPlan.free]} projects',
        pro: 'Unlimited projects',
      ),
      _FeatureComparisonItem(
        icon: Icons.grid_on,
        title: 'Canvas Size',
        free:
            'Up to ${SubscriptionFeatureConfig.maxCanvasSize[SubscriptionPlan.free]}×${SubscriptionFeatureConfig.maxCanvasSize[SubscriptionPlan.free]} pixels',
        pro: 'Up to 1024×1024 pixels',
      ),
      _FeatureComparisonItem(
        icon: Icons.format_paint,
        title: 'Tools & Effects',
        free: 'Basic tools',
        pro: 'Advanced tools & effects & templates',
      ),
      _FeatureComparisonItem(
        icon: Icons.download,
        title: 'Export Formats',
        free: 'PNG, JPEG',
        pro: 'All formats including Video & GIF',
      ),
      _FeatureComparisonItem(
        icon: Icons.play_circle_outline,
        title: 'Try Pro Features',
        free: 'Watch ads for temporary access',
        pro: 'Unlimited access',
      ),
      _FeatureComparisonItem(
        icon: MaterialCommunityIcons.advertisements,
        title: 'Ads',
        free: 'Watch ads for pro features',
        pro: 'No ads',
      ),
      _FeatureComparisonItem(
        icon: Icons.cloud_upload,
        title: 'Cloud Backup',
        free: false,
        pro: true,
      ),
      _FeatureComparisonItem(
        icon: Icons.support_agent,
        title: 'Priority Support',
        free: false,
        pro: true,
      ),
    ];

    return Column(
      children: [
        // Title
        Text(
          'Free vs Pro Features',
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
                color: Colors.black.withOpacity(0.05),
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
                        'Feature',
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
                          'Free',
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
                          color: theme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Pro',
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
                            color: theme.divider.withOpacity(0.3),
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
          'Choose Your Plan',
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
            'By continuing, you agree to our Terms of Service and Privacy Policy.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                  'Terms of Service',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                ' • ',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              InkWell(
                onTap: () {
                  launchUrlString(Constants.privacyPolicyUrl);
                },
                child: Text(
                  'Privacy Policy',
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
            'One-time purchase • No recurring charges • Lifetime access',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
            color: Colors.black.withOpacity(0.05),
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
                  selectedOffer?.plan == SubscriptionPlan.free ? 'Continue with Free' : 'Buy Pro',
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

  String _getUpgradePromptTitle(SubscriptionFeature feature) {
    switch (feature) {
      case SubscriptionFeature.maxProjects:
        return 'Unlock Unlimited Projects';
      case SubscriptionFeature.maxCanvasSize:
        return 'Unlock Larger Canvas Sizes';
      case SubscriptionFeature.exportFormats:
        return 'Unlock All Export Formats';
      case SubscriptionFeature.advancedTools:
        return 'Unlock Advanced Tools';
      case SubscriptionFeature.cloudBackup:
        return 'Enable Cloud Backup';
      case SubscriptionFeature.noWatermark:
        return 'Remove Watermark';
      case SubscriptionFeature.prioritySupport:
        return 'Get Priority Support';
      case SubscriptionFeature.effects:
        return 'Unlock Special Effects';
      case SubscriptionFeature.templates:
        return 'Unlock Templates';
      case SubscriptionFeature.proTheme:
        return 'Unlock Pro Theme';
    }
  }

  String _getUpgradePromptSubtitle(SubscriptionFeature feature) {
    switch (feature) {
      case SubscriptionFeature.maxProjects:
        return 'You\'ve reached your free plan project limit • Watch an ad for temporary access or buy Pro';
      case SubscriptionFeature.maxCanvasSize:
        return 'Create pixel art at higher resolutions • Try with ads first';
      case SubscriptionFeature.exportFormats:
        return 'Export your art in more formats • Watch ad for temporary access';
      case SubscriptionFeature.advancedTools:
        return 'Access premium tools and effects • Try with video ads';
      case SubscriptionFeature.cloudBackup:
        return 'Never lose your pixel art creations';
      case SubscriptionFeature.noWatermark:
        return 'Export clean art without watermarks';
      case SubscriptionFeature.prioritySupport:
        return 'Get faster support for any issues';
      case SubscriptionFeature.effects:
        return 'Unlock Special Effects';
      case SubscriptionFeature.templates:
        return 'Unlock Templates';
      case SubscriptionFeature.proTheme:
        return 'Unlock Pro Theme';
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
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                    'BEST VALUE',
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
