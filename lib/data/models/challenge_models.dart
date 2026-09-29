import 'package:equatable/equatable.dart';

import '../../config/constants.dart';

import 'project_api_models.dart';

/// How often a challenge runs; longer ones pay more and are judged.
enum ChallengeCadence { daily, weekly, monthly, seasonal }

/// A reward for a placement (1st, 2nd, 3rd) in a challenge.
class ChallengePlacementReward extends Equatable {
  const ChallengePlacementReward({required this.place, required this.gems, this.effectPack, this.badge});

  final int place;
  final int gems;

  /// An `EffectPackId` name, such as `vfxMagic`.
  final String? effectPack;
  final String? badge;

  factory ChallengePlacementReward.fromJson(Map<String, dynamic> json) => ChallengePlacementReward(
        place: json['place'] as int,
        gems: json['gems'] as int? ?? 0,
        effectPack: json['effect_pack'] as String?,
        badge: json['badge'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'place': place,
        'gems': gems,
        if (effectPack != null) 'effect_pack': effectPack,
        if (badge != null) 'badge': badge,
      };

  @override
  List<Object?> get props => [place, gems, effectPack, badge];
}

/// One of the signed-in user's entries in a challenge.
class ChallengeEntrySummary extends Equatable {
  const ChallengeEntrySummary({required this.projectId, required this.status, this.rejectionReason});

  final int projectId;

  /// `pending`, `accepted`, `rejected`, `withdrawn` or `winner`.
  final String status;

  /// Why a moderator rejected the entry, shown to its author.
  final String? rejectionReason;

  bool get counts => status != 'rejected' && status != 'withdrawn';

  factory ChallengeEntrySummary.fromJson(Map<String, dynamic> json) => ChallengeEntrySummary(
        projectId: json['project_id'] as int,
        status: json['status'] as String,
        rejectionReason: json['rejection_reason'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'project_id': projectId,
        'status': status,
        if (rejectionReason != null) 'rejection_reason': rejectionReason,
      };

  @override
  List<Object?> get props => [projectId, status, rejectionReason];
}

/// A winning entry, or an honorable mention when [place] is null.
class ChallengeWinner extends Equatable {
  const ChallengeWinner({required this.project, this.place});

  final ApiProject project;
  final int? place;

  bool get isMention => place == null;

  static ChallengeWinner? tryParse(Map<String, dynamic> json) {
    final project = json['project'];
    if (project is! Map<String, dynamic>) return null;
    try {
      return ChallengeWinner(
        project: ApiProject.fromJson(project),
        place: json['mention'] == true ? null : json['place'] as int?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [project.id, place];
}

/// A themed drawing challenge users enter by publishing a project with [tag].
class Challenge extends Equatable {
  const Challenge({
    required this.id,
    required this.cadence,
    required this.tag,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.endsAt,
    this.coverImageUrl,
    this.participationGems = 0,
    this.isCompetition = false,
    this.placements = const [],
    this.entryCount = 0,
    this.myEntries = const [],
    this.status = 'active',
    this.judgingEndsAt,
    this.maxEntriesPerUser = 3,
    this.requiredPack,
    this.winners = const [],
    this.myRewards = const [],
  });

  final int id;
  final ChallengeCadence cadence;
  final String tag;
  final String title;
  final String description;
  final String? coverImageUrl;
  final DateTime startsAt;
  final DateTime endsAt;
  /// Paid to every author whose entry is accepted.
  final int participationGems;

  /// Only competitions are judged and have [placements] and [winners];
  /// regular challenges reward every accepted entry the same.
  final bool isCompetition;
  final List<ChallengePlacementReward> placements;
  final int entryCount;
  final List<ChallengeEntrySummary> myEntries;

  /// `scheduled`, `active`, `judging`, `completed` or `cancelled`.
  final String status;

  /// When winners are due; null for daily challenges, which have none.
  final DateTime? judgingEndsAt;
  final int maxEntriesPerUser;

  /// An `EffectPackId` name entries must use an effect from, if any.
  final String? requiredPack;

  /// Placements (sorted) and mentions; filled once the challenge completes.
  final List<ChallengeWinner> winners;

  /// The signed-in user's rewards from this challenge (not revoked).
  final List<RewardGrant> myRewards;

  /// Whether one of the user's entries is accepted (or won).
  bool get hasAcceptedEntry => myEntries.any((entry) => entry.status == 'accepted' || entry.status == 'winner');

  bool get hasCover => coverImageUrl?.isNotEmpty ?? false;

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  /// Whether the user has an entry that still counts.
  bool get joined => myEntries.any((entry) => entry.counts);

  /// The biggest gem prize, or the participation reward when nobody wins.
  int get topGems => placements.fold(participationGems, (best, reward) => reward.gems > best ? reward.gems : best);

  /// Parses one challenge; null when the server sends a cadence this app
  /// version does not know, so newer challenge kinds are skipped, not fatal.
  static Challenge? tryParse(Map<String, dynamic> json) {
    final cadence = ChallengeCadence.values.where((value) => value.name == json['cadence']).firstOrNull;
    if (cadence == null) return null;
    final rewards = json['rewards'] as Map<String, dynamic>? ?? const {};
    final participation = rewards['participation'] as Map<String, dynamic>?;
    final rules = json['rules'] as Map<String, dynamic>? ?? const {};
    final judgingEndsAt = json['judging_ends_at'] as String?;
    final placements = [
      for (final item in rewards['placements'] as List? ?? const [])
        ChallengePlacementReward.fromJson(item as Map<String, dynamic>),
    ]..sort((a, b) => a.place.compareTo(b.place));
    // Servers (and caches) from before competitions: placements meant winners.
    final isCompetition = json['is_competition'] as bool? ?? placements.isNotEmpty;

    return Challenge(
      id: json['id'] as int,
      cadence: cadence,
      tag: json['tag'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coverImageUrl: json['cover_image_url'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      participationGems: participation?['gems'] as int? ?? 0,
      isCompetition: isCompetition,
      placements: isCompetition ? placements : const [],
      entryCount: json['entry_count'] as int? ?? 0,
      myEntries: [
        for (final item in json['my_entries'] as List? ?? const [])
          ChallengeEntrySummary.fromJson(item as Map<String, dynamic>),
      ],
      status: json['status'] as String? ?? 'active',
      judgingEndsAt: judgingEndsAt == null ? null : DateTime.parse(judgingEndsAt),
      maxEntriesPerUser: rules['max_entries_per_user'] as int? ?? 3,
      requiredPack: rules['required_pack'] as String?,
      winners: [
        for (final item in json['winners'] as List? ?? const [])
          if (ChallengeWinner.tryParse(item as Map<String, dynamic>) case final winner?) winner,
      ]..sort((a, b) => (a.place ?? 99).compareTo(b.place ?? 99)),
      myRewards: [
        for (final item in json['my_rewards'] as List? ?? const [])
          if (RewardGrant.tryParse(item) case final grant?) grant,
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cadence': cadence.name,
        'tag': tag,
        'title': title,
        'description': description,
        if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
        'is_competition': isCompetition,
        'rewards': {
          'participation': {'gems': participationGems},
          'placements': [for (final reward in placements) reward.toJson()],
        },
        'entry_count': entryCount,
        'my_entries': [for (final entry in myEntries) entry.toJson()],
        'my_rewards': [for (final grant in myRewards) grant.toJson()],
        'status': status,
        if (judgingEndsAt != null) 'judging_ends_at': judgingEndsAt!.toUtc().toIso8601String(),
        'rules': {
          'max_entries_per_user': maxEntriesPerUser,
          if (requiredPack != null) 'required_pack': requiredPack,
        },
      };

  @override
  List<Object?> get props => [
        id,
        cadence,
        status,
        tag,
        title,
        description,
        coverImageUrl,
        startsAt,
        endsAt,
        judgingEndsAt,
        isCompetition,
        participationGems,
        placements,
        entryCount,
        myEntries,
        winners,
        myRewards,
      ];
}

/// The response of `GET /challenges/{id}`: `{challenge, server_time}`.
class ChallengeDetails extends Equatable {
  const ChallengeDetails({required this.challenge, required this.serverTime, required this.receivedAt});

  final Challenge challenge;
  final DateTime serverTime;
  final DateTime receivedAt;

  /// The current time on the server's clock.
  DateTime serverNow() => DateTime.now().add(serverTime.difference(receivedAt));

  /// Null when the challenge is of a kind this app version does not know.
  static ChallengeDetails? tryParse(Map<String, dynamic> json, {DateTime? receivedAt}) {
    final received = receivedAt ?? DateTime.now();
    final challenge = Challenge.tryParse(json['challenge'] as Map<String, dynamic>? ?? json);
    if (challenge == null) return null;
    return ChallengeDetails(
      challenge: challenge,
      serverTime: DateTime.tryParse(json['server_time'] as String? ?? '') ?? received,
      receivedAt: received,
    );
  }

  @override
  List<Object?> get props => [challenge, serverTime, receivedAt];
}

/// The response of `GET /challenges/current`, with the server clock so
/// countdowns do not trust the device clock.
class CurrentChallenges extends Equatable {
  const CurrentChallenges({required this.challenges, required this.serverTime, required this.receivedAt});

  final List<Challenge> challenges;
  final DateTime serverTime;

  /// Device time when [serverTime] was received.
  final DateTime receivedAt;

  /// Difference between the server clock and this device's clock.
  Duration get clockOffset => serverTime.difference(receivedAt);

  /// The current time on the server's clock.
  DateTime serverNow() => DateTime.now().add(clockOffset);

  /// Challenges that are still running, as the banner shows them.
  List<Challenge> running() {
    final now = serverNow();
    return challenges.where((challenge) => challenge.endsAt.isAfter(now) && !challenge.startsAt.isAfter(now)).toList();
  }

  factory CurrentChallenges.fromJson(Map<String, dynamic> json, {DateTime? receivedAt}) {
    final received = receivedAt ?? DateTime.now();
    return CurrentChallenges(
      challenges: [
        for (final item in json['challenges'] as List? ?? const [])
          if (Challenge.tryParse(item as Map<String, dynamic>) case final challenge?) challenge,
      ],
      serverTime: DateTime.tryParse(json['server_time'] as String? ?? '') ?? received,
      receivedAt: received,
    );
  }

  Map<String, dynamic> toJson() => {
        'challenges': [for (final challenge in challenges) challenge.toJson()],
        'server_time': serverTime.toUtc().toIso8601String(),
        'received_at': receivedAt.toUtc().toIso8601String(),
      };

  /// Restores a cached response with the clock offset it was received with.
  factory CurrentChallenges.fromCache(Map<String, dynamic> json) => CurrentChallenges.fromJson(
        json,
        receivedAt: DateTime.tryParse(json['received_at'] as String? ?? ''),
      );

  @override
  List<Object?> get props => [challenges, serverTime, receivedAt];
}

/// Why a tagged project did not enter a challenge, from the publish response.
enum ChallengeWarningCode {
  challengeNotActive('challenge_not_active'),
  projectNotPublic('project_not_public'),
  publishedBeforeStart('project_published_before_start'),
  entryLimitReached('entry_limit_reached'),
  accountNotEligible('account_not_eligible'),
  unknown('');

  const ChallengeWarningCode(this.wireName);

  final String wireName;

  static ChallengeWarningCode parse(String? value) =>
      values.firstWhere((code) => code.wireName == value, orElse: () => unknown);
}

class ChallengeSubmissionWarning extends Equatable {
  const ChallengeSubmissionWarning({required this.challengeId, required this.tag, required this.code});

  final int challengeId;
  final String tag;
  final ChallengeWarningCode code;

  @override
  List<Object?> get props => [challengeId, tag, code];
}

/// What publishing or editing a project did to its challenge entries: the
/// challenges it is now entered in and the tags that could not enter.
class ChallengeSubmission extends Equatable {
  const ChallengeSubmission({this.enteredTags = const [], this.warnings = const []});

  /// Tags of challenges the project is entered in (pending or accepted).
  final List<String> enteredTags;
  final List<ChallengeSubmissionWarning> warnings;

  bool get isEmpty => enteredTags.isEmpty && warnings.isEmpty;

  /// Reads `challenge_entries` and `challenge_warnings` from a project
  /// create/update response; null when the server sent neither.
  static ChallengeSubmission? tryParse(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    final entries = data['challenge_entries'];
    final warnings = data['challenge_warnings'];
    if (entries is! List && warnings is! List) return null;
    try {
      return ChallengeSubmission(
        enteredTags: [
          for (final entry in entries as List? ?? const [])
            if (entry is Map<String, dynamic> && entry['status'] != 'rejected') entry['tag'] as String,
        ],
        warnings: [
          for (final warning in warnings as List? ?? const [])
            if (warning is Map<String, dynamic>)
              ChallengeSubmissionWarning(
                challengeId: warning['challenge_id'] as int,
                tag: warning['tag'] as String,
                code: ChallengeWarningCode.parse(warning['code'] as String?),
              ),
        ],
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [enteredTags, warnings];
}

/// Why the server paid a reward.
enum RewardGrantReason { challengeParticipation, challengePlacement, challengeMention, manual, unknown }

/// A reward the server paid out (challenge participation, a win, support).
/// The app claims it once and adds it to the local wallet.
class RewardGrant extends Equatable {
  const RewardGrant({
    required this.id,
    required this.gems,
    required this.reason,
    required this.status,
    this.effectPack,
    this.badge,
    this.challengeTag,
    this.challengeTitle,
    this.claimedAt,
  });

  final String id;
  final int gems;

  /// An `EffectPackId` name, such as `vfxMagic`.
  final String? effectPack;
  final String? badge;
  final RewardGrantReason reason;

  /// `unclaimed`, `claimed` or `revoked`.
  final String status;
  final String? challengeTag;
  final String? challengeTitle;
  final DateTime? claimedAt;

  bool get isUnclaimed => status == 'unclaimed';

  Map<String, dynamic> toJson() => {
        'id': id,
        'gems': gems,
        'effect_pack': effectPack,
        'badge': badge,
        'reason': switch (reason) {
          RewardGrantReason.challengeParticipation => 'challenge_participation',
          RewardGrantReason.challengePlacement => 'challenge_placement',
          RewardGrantReason.challengeMention => 'challenge_mention',
          RewardGrantReason.manual => 'manual',
          RewardGrantReason.unknown => 'unknown',
        },
        'status': status,
        'challenge_tag': challengeTag,
        'challenge_title': challengeTitle,
        'claimed_at': claimedAt?.toUtc().toIso8601String(),
      };

  RewardGrant copyWith({String? status}) => RewardGrant(
        id: id,
        gems: gems,
        effectPack: effectPack,
        badge: badge,
        reason: reason,
        status: status ?? this.status,
        challengeTag: challengeTag,
        challengeTitle: challengeTitle,
        claimedAt: claimedAt,
      );
  bool get isClaimed => status == 'claimed';

  static RewardGrant? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    try {
      final reason = switch (json['reason']) {
        'challenge_participation' => RewardGrantReason.challengeParticipation,
        'challenge_placement' => RewardGrantReason.challengePlacement,
        'challenge_mention' => RewardGrantReason.challengeMention,
        'manual' => RewardGrantReason.manual,
        _ => RewardGrantReason.unknown,
      };
      return RewardGrant(
        id: json['id'] as String,
        gems: json['gems'] as int? ?? 0,
        effectPack: json['effect_pack'] as String?,
        badge: json['badge'] as String?,
        reason: reason,
        status: json['status'] as String,
        challengeTag: json['challenge_tag'] as String?,
        challengeTitle: json['challenge_title'] as String?,
        claimedAt: DateTime.tryParse(json['claimed_at'] as String? ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [id, gems, effectPack, badge, reason, status, challengeTag, challengeTitle, claimedAt];
}

/// One of the signed-in user's entries, across all challenges.
class MyChallengeEntry extends Equatable {
  const MyChallengeEntry({
    required this.id,
    required this.challengeId,
    required this.tag,
    required this.cadence,
    required this.challengeStatus,
    required this.challengeTitle,
    required this.projectId,
    required this.projectTitle,
    required this.status,
    this.endsAt,
    this.place,
    this.isMention = false,
    this.rejectionReason,
    this.createdAt,
  });

  final int id;
  final int challengeId;
  final String tag;
  final ChallengeCadence cadence;

  /// `scheduled`, `active`, `judging` or `completed`.
  final String challengeStatus;
  final String challengeTitle;
  final DateTime? endsAt;
  final int projectId;
  final String projectTitle;

  /// `pending`, `accepted`, `rejected`, `withdrawn` or `winner`.
  final String status;
  final int? place;
  final bool isMention;
  final String? rejectionReason;
  final DateTime? createdAt;

  /// Same URL as [ApiProject.thumbnailUrl].
  String get thumbnailUrl => '${Constants.apiUrl}/projects/$projectId/thumbnail';

  static MyChallengeEntry? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    try {
      return MyChallengeEntry(
        id: json['id'] as int,
        challengeId: json['challenge_id'] as int,
        tag: json['tag'] as String,
        cadence: ChallengeCadence.values.asNameMap()[json['cadence']] ?? ChallengeCadence.daily,
        challengeStatus: json['challenge_status'] as String? ?? 'active',
        challengeTitle: json['challenge_title'] as String? ?? '',
        endsAt: DateTime.tryParse(json['ends_at'] as String? ?? ''),
        projectId: json['project_id'] as int,
        projectTitle: json['project_title'] as String? ?? '',
        status: json['status'] as String,
        place: json['place'] as int?,
        isMention: json['mention'] == true,
        rejectionReason: json['rejection_reason'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        id,
        challengeId,
        tag,
        cadence,
        challengeStatus,
        challengeTitle,
        endsAt,
        projectId,
        projectTitle,
        status,
        place,
        isMention,
        rejectionReason,
        createdAt,
      ];
}
