import 'package:equatable/equatable.dart';

import 'subscription_model.dart';

/// Result of asking the server for a trial.
enum TrialClaimResult {
  /// Newly granted.
  granted,

  /// Already granted for this very plan / project; nothing changed.
  existing,

  /// Spent on another project, or by another account on this device.
  alreadyUsed,

  /// The user must sign in first: trials belong to an account.
  notSignedIn,

  /// Trials are switched off, or the server could not be reached.
  unavailable;

  bool get isSuccess => this == granted || this == existing;
}

/// One trial the server has granted to the signed-in account.
class TrialGrantInfo extends Equatable {
  final String kind;
  final String subject;
  final String? tier;
  final String? projectKey;
  final DateTime startedAt;
  final DateTime? expiresAt;

  const TrialGrantInfo({
    required this.kind,
    required this.subject,
    this.tier,
    this.projectKey,
    required this.startedAt,
    this.expiresAt,
  });

  static const kindPlan = 'plan';
  static const kindRig = 'rig';
  static const kindPack = 'pack';

  factory TrialGrantInfo.fromJson(Map<String, dynamic> json) => TrialGrantInfo(
        kind: json['kind'] as String,
        subject: json['subject'] as String,
        tier: json['tier'] as String?,
        projectKey: json['project_key'] as String?,
        startedAt: DateTime.parse(json['started_at'] as String),
        expiresAt: json['expires_at'] == null ? null : DateTime.parse(json['expires_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'subject': subject,
        'tier': tier,
        'project_key': projectKey,
        'started_at': startedAt.toUtc().toIso8601String(),
        'expires_at': expiresAt?.toUtc().toIso8601String(),
      };

  @override
  List<Object?> get props => [kind, subject, tier, projectKey, startedAt, expiresAt];
}

/// The account's trials, as last reported by the server.
class TrialsState extends Equatable {
  final List<TrialGrantInfo> grants;

  const TrialsState({this.grants = const []});

  TrialGrantInfo? _find(String kind, [String? subject]) {
    for (final grant in grants) {
      if (grant.kind == kind && (subject == null || grant.subject == subject)) return grant;
    }
    return null;
  }

  /// The plan trial if one is running at [now].
  PlanTrial? planTrialAt(DateTime now) {
    final grant = _find(TrialGrantInfo.kindPlan);
    final end = grant?.expiresAt;
    if (grant == null || end == null || !now.isBefore(end)) return null;
    final tier = grant.tier == 'ultimate' ? SubscriptionPlan.ultimate : SubscriptionPlan.pro;
    return PlanTrial(tier: tier, endsAt: end);
  }

  bool get planTrialUsed => _find(TrialGrantInfo.kindPlan) != null;

  /// Project the rig trial was spent on, if any.
  String? get rigTrialProjectKey => _find(TrialGrantInfo.kindRig)?.projectKey;

  bool get rigTrialUsed => rigTrialProjectKey != null;

  String? packTrialProjectKey(String packName) => _find(TrialGrantInfo.kindPack, packName)?.projectKey;

  bool hasRigTrialFor(String? projectKey) => projectKey != null && rigTrialProjectKey == projectKey;

  bool hasPackTrialFor(String packName, String? projectKey) =>
      projectKey != null && packTrialProjectKey(packName) == projectKey;

  /// Soonest plan-trial end in the future, to schedule its expiry.
  DateTime? nextExpiryAfter(DateTime now) {
    final end = _find(TrialGrantInfo.kindPlan)?.expiresAt;
    return end != null && end.isAfter(now) ? end : null;
  }

  @override
  List<Object?> get props => [grants];
}
