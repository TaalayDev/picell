import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/challenge_models.dart';

Map<String, dynamic> _challenge({String cadence = 'weekly', String endsAt = '2026-10-05T00:00:00Z'}) => {
      'id': 412,
      'cadence': cadence,
      'status': 'active',
      'tag': 'dragons-2026w40',
      'title': 'Dragon Week',
      'description': 'Draw a dragon.',
      'starts_at': '2026-09-28T00:00:00Z',
      'ends_at': endsAt,
      'rewards': {
        'participation': {'gems': 50},
        'placements': [
          {'place': 2, 'gems': 300},
          {'place': 1, 'gems': 500, 'effect_pack': 'vfxMagic'},
        ],
      },
      'entry_count': 37,
      'my_entries': [
        {'project_id': 9012, 'status': 'accepted'},
      ],
    };

void main() {
  test('parses the current challenges response', () {
    final current = CurrentChallenges.fromJson({
      'challenges': [_challenge()],
      'server_time': '2026-09-30T14:02:11Z',
    });

    final challenge = current.challenges.single;
    expect(challenge.cadence, ChallengeCadence.weekly);
    expect(challenge.placements.map((reward) => reward.place), [1, 2]);
    expect(challenge.placements.first.effectPack, 'vfxMagic');
    expect(challenge.topGems, 500);
    expect(challenge.joined, isTrue);
  });

  test('skips challenge kinds this app version does not know', () {
    final current = CurrentChallenges.fromJson({
      'challenges': [_challenge(), _challenge(cadence: 'hourly')],
      'server_time': '2026-09-30T14:02:11Z',
    });
    expect(current.challenges, hasLength(1));
  });

  test('rejected or withdrawn entries do not count as joined', () {
    final json = _challenge()..['my_entries'] = [
        {'project_id': 1, 'status': 'rejected'},
        {'project_id': 2, 'status': 'withdrawn'},
      ];
    expect(Challenge.tryParse(json)!.joined, isFalse);
  });

  test('uses the server clock to decide what is still running', () {
    final received = DateTime.now();
    final current = CurrentChallenges.fromJson(
      {
        // The server is 3 days ahead of this device, past the challenge end.
        'challenges': [_challenge(endsAt: received.add(const Duration(days: 2)).toUtc().toIso8601String())],
        'server_time': received.add(const Duration(days: 3)).toUtc().toIso8601String(),
      },
      receivedAt: received,
    );
    expect(current.running(), isEmpty);
  });

  test('round-trips through the cache with its clock offset', () {
    final received = DateTime.utc(2026, 9, 30, 14);
    final current = CurrentChallenges.fromJson(
      {'challenges': [_challenge()], 'server_time': '2026-09-30T14:05:00Z'},
      receivedAt: received,
    );
    final restored = CurrentChallenges.fromCache(current.toJson());
    expect(restored.challenges.single, current.challenges.single);
    expect(restored.clockOffset, const Duration(minutes: 5));
  });

  test('parses challenge details with rules, winners and review results', () {
    Map<String, dynamic> project(int id) => {
          'id': id,
          'title': 'Entry $id',
          'width': 32,
          'height': 32,
          'user_id': 1,
        };
    final json = _challenge()
      ..['status'] = 'completed'
      ..['judging_ends_at'] = '2026-10-07T00:00:00Z'
      ..['rules'] = {'max_entries_per_user': 2, 'required_pack': 'vfxMagic'}
      ..['my_entries'] = [
        {'project_id': 9012, 'status': 'rejected', 'rejection_reason': 'Off-topic'},
      ]
      ..['winners'] = [
        {'mention': true, 'project': project(3)},
        {'place': 2, 'project': project(2)},
        {'place': 1, 'project': project(1)},
      ];

    final details = ChallengeDetails.tryParse({'challenge': json, 'server_time': '2026-10-08T00:00:00Z'})!;
    final challenge = details.challenge;
    expect(challenge.isCompleted, isTrue);
    expect(challenge.maxEntriesPerUser, 2);
    expect(challenge.requiredPack, 'vfxMagic');
    expect(challenge.myEntries.single.rejectionReason, 'Off-topic');
    expect(challenge.joined, isFalse);
    // Placements first in order, mentions last.
    expect(challenge.winners.map((winner) => winner.place), [1, 2, null]);
    expect(challenge.winners.last.isMention, isTrue);
  });

  test('reads challenge results from a publish response', () {
    final submission = ChallengeSubmission.tryParse({
      'project': {'id': 1},
      'challenge_entries': [
        {'id': 9, 'challenge_id': 412, 'tag': 'dragons-2026w40', 'status': 'pending'},
      ],
      'challenge_warnings': [
        {'challenge_id': 400, 'tag': 'robots-20260927', 'code': 'challenge_not_active'},
        {'challenge_id': 401, 'tag': 'cats-202609', 'code': 'something_new'},
      ],
    })!;

    expect(submission.enteredTags, ['dragons-2026w40']);
    expect(submission.warnings.map((warning) => warning.code),
        [ChallengeWarningCode.challengeNotActive, ChallengeWarningCode.unknown]);
    expect(ChallengeSubmission.tryParse({'project': {'id': 1}}), isNull);
  });

  test('parses reward grants', () {
    final grant = RewardGrant.tryParse({
      'id': '5f0c',
      'gems': 300,
      'effect_pack': null,
      'badge': null,
      'reason': 'challenge_placement',
      'challenge_tag': 'dragons-2026w40',
      'challenge_title': 'Dragon Week',
      'status': 'unclaimed',
      'claimed_at': null,
    })!;

    expect(grant.isUnclaimed, isTrue);
    expect(grant.reason, RewardGrantReason.challengePlacement);
    expect(grant.challengeTitle, 'Dragon Week');
    expect(RewardGrant.tryParse({'gems': 1}), isNull);
  });

  test('parses my entries across challenges', () {
    final entry = MyChallengeEntry.tryParse({
      'id': 9,
      'challenge_id': 412,
      'tag': 'dragons-2026w40',
      'cadence': 'weekly',
      'challenge_status': 'completed',
      'challenge_title': 'Dragon Week',
      'ends_at': '2026-10-05T00:00:00Z',
      'project_id': 77,
      'project_title': 'Red dragon',
      'status': 'winner',
      'place': 1,
      'mention': false,
      'created_at': '2026-09-29T10:00:00Z',
    })!;

    expect(entry.cadence, ChallengeCadence.weekly);
    expect(entry.place, 1);
    expect(entry.isMention, isFalse);
    expect(entry.thumbnailUrl, endsWith('/projects/77/thumbnail'));
    expect(MyChallengeEntry.tryParse({'id': 'x'}), isNull);
  });

  test('regular challenges have no winners, whatever the placements say', () {
    final challenge = Challenge.tryParse({..._challenge(), 'is_competition': false})!;

    expect(challenge.isCompetition, isFalse);
    expect(challenge.placements, isEmpty);
    expect(challenge.topGems, 50);
  });

  test('reads competitions, and infers them from placements on older data', () {
    expect(Challenge.tryParse({..._challenge(), 'is_competition': true})!.isCompetition, isTrue);
    // Cached before the flag existed: placements meant a competition.
    final cached = Challenge.tryParse(_challenge())!;
    expect(cached.isCompetition, isTrue);
    expect(Challenge.tryParse(cached.toJson())!.isCompetition, isTrue);
  });

  test('reads the user\'s rewards so the screen can offer a claim button', () {
    final challenge = Challenge.tryParse({
      ..._challenge(),
      'is_competition': false,
      'my_rewards': [
        {'id': 'g-1', 'gems': 50, 'reason': 'challenge_participation', 'status': 'unclaimed'},
      ],
    })!;

    final reward = challenge.myRewards.single;
    expect(reward.isUnclaimed, isTrue);
    expect(reward.gems, 50);
    expect(challenge.hasAcceptedEntry, isTrue);
    // Survives the banner cache.
    expect(Challenge.tryParse(challenge.toJson())!.myRewards.single.id, 'g-1');
  });
}
