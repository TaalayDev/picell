import 'package:equatable/equatable.dart';

import '../../pixel/effects/effect_pack_catalog.dart';
import '../../pixel/effects/effects.dart';

/// Tier shown to the user, derived from the products they own.
enum SubscriptionPlan {
  free,
  pro,
  ultimate;

  bool get isPaid => this != SubscriptionPlan.free;
}

enum SubscriptionFeature {
  maxProjects,
  maxCanvasSize,
  exportFormats,
  advancedTools,
  cloudBackup,
  noWatermark,
  effects,
  templates,
  proTheme,
  prioritySupport,
}

/// Something a purchase unlocks. Products map to entitlements through
/// [ProductCatalog], so what a product includes can change without migrating
/// stored purchases.
///
/// Instances are canonical, so identity equality is value equality.
class Entitlement {
  const Entitlement._(this.name);

  final String name;

  /// Unlimited projects, large canvases, all tools and export formats,
  /// templates, pro themes, no ads and no watermark.
  static const pro = Entitlement._('pro');

  /// Cloud sync and backup.
  static const cloud = Entitlement._('cloud');

  /// Every effect pack, including packs released after the purchase.
  static const allEffects = Entitlement._('allEffects');

  static final Map<EffectPackId, Entitlement> _packs = {
    for (final pack in EffectPackId.values) pack: Entitlement._('pack:${pack.name}'),
  };

  factory Entitlement.pack(EffectPackId pack) => _packs[pack]!;

  @override
  String toString() => 'Entitlement($name)';
}

class SubscriptionProductIds {
  SubscriptionProductIds._();

  /// The original "Pro" one-time purchase. Everyone who bought it was promised
  /// everything forever, so it is the Ultimate product.
  static const String ultimate = 'com.pixelverse.app.pro.purchase';
  static const String pro = 'com.pixelverse.app.pro.core';

  /// Discounted Ultimate for existing Pro owners.
  static const String ultimateUpgrade = 'com.pixelverse.app.ultimate.upgrade';
  static const String cloudAddon = 'com.pixelverse.app.addon.cloud';

  static const String _packPrefix = 'com.pixelverse.app.pack.';

  static String pack(EffectPackId pack) => '$_packPrefix${_snakeCase(pack.name)}';

  static String _snakeCase(String value) =>
      value.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
}

class ProductCatalog {
  ProductCatalog._();

  static const Set<Entitlement> _ultimate = {
    Entitlement.pro,
    Entitlement.cloud,
    Entitlement.allEffects,
  };

  static final Map<String, Set<Entitlement>> entitlementsByProduct = Map.unmodifiable({
    SubscriptionProductIds.pro: {
      Entitlement.pro,
      Entitlement.pack(EffectPackId.basicFilters),
    },
    SubscriptionProductIds.ultimate: _ultimate,
    SubscriptionProductIds.ultimateUpgrade: _ultimate,
    SubscriptionProductIds.cloudAddon: const {Entitlement.cloud},
    for (final pack in EffectPackId.values)
      if (pack != EffectPackId.free) SubscriptionProductIds.pack(pack): {Entitlement.pack(pack)},
  });

  static Set<String> get allProductIds => entitlementsByProduct.keys.toSet();

  static bool isKnownProduct(String productId) => entitlementsByProduct.containsKey(productId);

  static Set<Entitlement> entitlementsFor(Iterable<String> productIds) => {
        for (final id in productIds) ...?entitlementsByProduct[id],
      };
}

class SubscriptionFeatureConfig {
  static const Map<SubscriptionPlan, int> maxProjects = {
    SubscriptionPlan.free: 10,
    SubscriptionPlan.pro: 999,
    SubscriptionPlan.ultimate: 999,
  };

  static const Map<SubscriptionPlan, int> maxCanvasSize = {
    SubscriptionPlan.free: 64,
    SubscriptionPlan.pro: 1024,
    SubscriptionPlan.ultimate: 1024,
  };

  static const List<String> _allExportFormats = ['PNG', 'JPEG', 'SVG', 'GIF', 'WEBP', 'MP4'];

  static const Map<SubscriptionPlan, List<String>> exportFormats = {
    SubscriptionPlan.free: ['PNG', 'JPEG'],
    SubscriptionPlan.pro: _allExportFormats,
    SubscriptionPlan.ultimate: _allExportFormats,
  };

  static T getFeatureValue<T>(SubscriptionFeature feature, SubscriptionPlan plan) {
    switch (feature) {
      case SubscriptionFeature.maxProjects:
        return maxProjects[plan] as T;
      case SubscriptionFeature.maxCanvasSize:
        return maxCanvasSize[plan] as T;
      case SubscriptionFeature.exportFormats:
        return exportFormats[plan] as T;
      case SubscriptionFeature.advancedTools:
      case SubscriptionFeature.cloudBackup:
      case SubscriptionFeature.noWatermark:
      case SubscriptionFeature.effects:
      case SubscriptionFeature.templates:
      case SubscriptionFeature.proTheme:
      case SubscriptionFeature.prioritySupport:
        return plan.isPaid as T;
    }
  }
}

/// A plan the paywall offers. Texts are localized by the paywall from [plan].
class PurchaseOffer extends Equatable {
  final SubscriptionPlan plan;

  /// Store product to buy; null for the free plan.
  final String? productId;
  final String? price;
  final bool isMostPopular;

  /// Discounted Ultimate for users who already own Pro.
  final bool isUpgrade;

  const PurchaseOffer({
    required this.plan,
    this.productId,
    this.price,
    this.isMostPopular = false,
    this.isUpgrade = false,
  });

  @override
  List<Object?> get props => [plan, productId, price, isMostPopular, isUpgrade];
}

// Temporary pro access from ads
class TemporaryProAccess extends Equatable {
  final DateTime startTime;
  final Duration duration;

  const TemporaryProAccess({
    required this.startTime,
    required this.duration,
  });

  DateTime get endTime => startTime.add(duration);
  bool get isActive => DateTime.now().isBefore(endTime);
  Duration get remainingTime => isActive ? endTime.difference(DateTime.now()) : Duration.zero;

  @override
  List<Object?> get props => [startTime, duration];

  factory TemporaryProAccess.fromJson(Map<String, dynamic> json) {
    return TemporaryProAccess(
      startTime: DateTime.parse(json['startTime'] as String),
      duration: Duration(milliseconds: json['duration'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'duration': duration.inMilliseconds,
    };
  }
}

/// The user's purchases and temporary access.
class UserSubscription extends Equatable {
  static const int _storageVersion = 2;

  /// Store products the user owns. Entitlements are derived from these.
  final Set<String> ownedProductIds;
  final bool isPurchasePending;
  final TemporaryProAccess? temporaryProAccess;

  const UserSubscription({
    this.ownedProductIds = const {},
    this.isPurchasePending = false,
    this.temporaryProAccess,
  });

  const UserSubscription.free()
      : ownedProductIds = const {},
        isPurchasePending = false,
        temporaryProAccess = null;

  /// Everything unlocked; used for debug builds and platforms without stores.
  const UserSubscription.unlocked()
      : ownedProductIds = const {SubscriptionProductIds.ultimate},
        isPurchasePending = false,
        temporaryProAccess = null;

  UserSubscription copyWith({
    Set<String>? ownedProductIds,
    bool? isPurchasePending,
    TemporaryProAccess? temporaryProAccess,
    bool clearTemporaryProAccess = false,
  }) {
    return UserSubscription(
      ownedProductIds: ownedProductIds ?? this.ownedProductIds,
      isPurchasePending: isPurchasePending ?? this.isPurchasePending,
      temporaryProAccess: clearTemporaryProAccess ? null : temporaryProAccess ?? this.temporaryProAccess,
    );
  }

  UserSubscription withProduct(String productId) => copyWith(
        ownedProductIds: {...ownedProductIds, productId},
        isPurchasePending: false,
      );

  Set<Entitlement> get entitlements => ProductCatalog.entitlementsFor(ownedProductIds);

  bool hasEntitlement(Entitlement entitlement) => entitlements.contains(entitlement);

  /// Tier owned permanently; temporary access does not change it.
  SubscriptionPlan get plan {
    final owned = entitlements;
    if (!owned.contains(Entitlement.pro)) return SubscriptionPlan.free;
    if (owned.contains(Entitlement.allEffects) && owned.contains(Entitlement.cloud)) {
      return SubscriptionPlan.ultimate;
    }
    return SubscriptionPlan.pro;
  }

  bool get isPermanentPro => hasEntitlement(Entitlement.pro);
  bool get hasTemporaryPro => temporaryProAccess?.isActive ?? false;

  /// Whether pro-level features (tools, formats, limits, no ads) are available.
  bool get isPro => isPermanentPro || hasTemporaryPro;

  bool ownsEffectPack(EffectPackId pack) {
    if (pack == EffectPackId.free) return true;
    final owned = entitlements;
    return owned.contains(Entitlement.allEffects) || owned.contains(Entitlement.pack(pack));
  }

  bool canUseEffect(EffectType type) {
    // Temporary access from ads keeps unlocking every effect, as before packs.
    return hasTemporaryPro || ownsEffectPack(EffectPackCatalog.packIdOf(type));
  }

  // Check if user has access to a specific feature
  bool hasFeatureAccess(SubscriptionFeature feature) {
    switch (feature) {
      case SubscriptionFeature.maxProjects:
      case SubscriptionFeature.maxCanvasSize:
      case SubscriptionFeature.exportFormats:
        return true; // Always available, with limits that depend on the plan
      case SubscriptionFeature.advancedTools:
      case SubscriptionFeature.noWatermark:
      case SubscriptionFeature.prioritySupport:
        return isPro;
      case SubscriptionFeature.templates:
      case SubscriptionFeature.proTheme:
        return isPermanentPro;
      case SubscriptionFeature.effects:
        return hasEntitlement(Entitlement.allEffects);
      case SubscriptionFeature.cloudBackup:
        return hasEntitlement(Entitlement.cloud);
    }
  }

  // Get feature limit based on current access level
  T getFeatureLimit<T>(SubscriptionFeature feature) {
    final effectivePlan = isPro && !plan.isPaid ? SubscriptionPlan.pro : plan;
    return SubscriptionFeatureConfig.getFeatureValue<T>(feature, effectivePlan);
  }

  Map<String, dynamic> toJson() {
    return {
      'version': _storageVersion,
      'ownedProductIds': ownedProductIds.toList(),
      'temporaryProAccess': temporaryProAccess?.toJson(),
    };
  }

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    TemporaryProAccess? temporaryAccess;
    final temporaryJson = json['temporaryProAccess'];
    if (temporaryJson is Map<String, dynamic>) {
      temporaryAccess = TemporaryProAccess.fromJson(temporaryJson);
      if (!temporaryAccess.isActive) temporaryAccess = null;
    }

    return UserSubscription(
      ownedProductIds: json['version'] == null
          ? _legacyOwnedProducts(json)
          : {...(json['ownedProductIds'] as List? ?? const []).cast<String>()},
      temporaryProAccess: temporaryAccess,
    );
  }

  /// Version 1 stored a single `plan`. Rewarded-ad access also wrote
  /// `plan: proPurchase`, but only real purchases have a purchase id.
  static Set<String> _legacyOwnedProducts(Map<String, dynamic> json) {
    final purchaseId = json['purchaseId'] as String?;
    final isLegacyPro = json['plan'] == 'proPurchase' &&
        json['status'] == 'purchased' &&
        purchaseId != null &&
        purchaseId.isNotEmpty;
    return isLegacyPro ? {SubscriptionProductIds.ultimate} : {};
  }

  @override
  List<Object?> get props => [ownedProductIds, isPurchasePending, temporaryProAccess];
}
