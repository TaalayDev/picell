import '../../../data/models/rig/rig.dart';

/// Reads bone and layer names the way a person would: "Arm L", "left_arm",
/// "upperArm" and "arm_l" all mean the same thing. Used to find the bones an
/// animation preset is written for, and to bind layers to bones by name.
abstract final class NameTokens {
  /// Words that mean the same thing, folded to one spelling.
  static const _synonyms = <String, String>{
    'left': 'l',
    'right': 'r',
    'upperarm': 'arm',
    'uparm': 'arm',
    'shoulder': 'arm',
    'lowerarm': 'forearm',
    'elbow': 'forearm',
    'wrist': 'hand',
    'upperleg': 'thigh',
    'upleg': 'thigh',
    'lowerleg': 'shin',
    'calf': 'shin',
    'knee': 'shin',
    'ankle': 'foot',
    'pelvis': 'hips',
    'hip': 'hips',
    'torso': 'spine',
    'chest': 'spine',
    'back': 'spine',
  };

  /// The canonical words of [name], with side words folded to `l` / `r`
  /// ("Left Arm" -> {arm, l}). Numbers are kept: "tail_1" and "tail_2" are
  /// different bones, and a copy such as "arm_l_2" still has the words of
  /// "arm_l", so it matches that role, just less closely.
  static Set<String> of(String name) {
    // Split camelCase, then on anything that is not a letter or digit.
    final spaced = name.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    final words = [
      for (final w in spaced.toLowerCase().split(RegExp(r'[^a-z0-9]+')))
        if (w.isNotEmpty) w,
    ];
    final out = <String>{};
    for (var i = 0; i < words.length; i++) {
      // "upper arm" and "upperArm" are one word to the synonym table.
      if (i + 1 < words.length) {
        final pair = _synonyms[words[i] + words[i + 1]];
        if (pair != null) {
          out.add(pair);
          i++;
          continue;
        }
      }
      out.add(_synonyms[words[i]] ?? words[i]);
    }
    return out;
  }

  /// Whether two names read the same: the same words, neither more nor fewer.
  static bool sameThing(String a, String b) {
    final ta = of(a), tb = of(b);
    return ta.isNotEmpty && ta.length == tb.length && ta.containsAll(tb);
  }

  /// With the left and right sides swapped: "arm_l" -> {arm, r}.
  static Set<String> mirrored(Set<String> tokens) => {
        for (final t in tokens)
          if (t == 'l') 'r' else if (t == 'r') 'l' else t,
      };
}

/// Finds the bones of a rig that play the standard parts a preset animates
/// ("head", "arm_l", "thigh_r", "tail_1"...), by name.
abstract final class RoleMatcher {
  /// For each wanted role, the bone that best fits its name; roles nothing
  /// fits are absent. A bone fits a role when its name has all the role's
  /// words; the bone with the fewest extra words wins, and one bone is never
  /// given to two roles.
  static Map<String, Bone> match(Iterable<String> roles, Iterable<Bone> bones) {
    final tokens = {for (final b in bones) b.id: NameTokens.of(b.name)};
    final byId = {for (final b in bones) b.id: b};
    final taken = <String>{};
    final out = <String, Bone>{};

    // More specific roles (more words) choose first so "arm_l" is not lost to
    // a bare "arm" role that fits several bones.
    final ordered = roles.toList()..sort((a, b) => NameTokens.of(b).length.compareTo(NameTokens.of(a).length));
    for (final role in ordered) {
      final wanted = NameTokens.of(role);
      if (wanted.isEmpty) continue;
      String? best;
      var bestExtra = 1 << 20;
      for (final entry in tokens.entries) {
        if (taken.contains(entry.key) || !entry.value.containsAll(wanted)) continue;
        final extra = entry.value.length - wanted.length;
        if (extra < bestExtra) {
          best = entry.key;
          bestExtra = extra;
        }
      }
      if (best != null) {
        taken.add(best);
        out[role] = byId[best]!;
      }
    }
    return out;
  }
}
