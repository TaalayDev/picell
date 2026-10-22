import 'dart:ui';

/// A bone's animated offset from its rest pose.
class BonePose {
  /// Degrees added to the bone's rest orientation. Not wrapped: keyed values
  /// are offsets, so 0 -> 350 turns the long way, as the artist asked.
  final double rotation;
  final Offset translation;
  final bool flipX;

  const BonePose({this.rotation = 0, this.translation = Offset.zero, this.flipX = false});

  static const rest = BonePose();

  Map<String, dynamic> toJson() => {
        'rotation': rotation,
        'translation': {'dx': translation.dx, 'dy': translation.dy},
        'flipX': flipX,
      };

  factory BonePose.fromJson(Map<String, dynamic> json) {
    final t = json['translation'] as Map<String, dynamic>?;
    return BonePose(
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      translation: t == null ? Offset.zero : Offset((t['dx'] as num).toDouble(), (t['dy'] as num).toDouble()),
      flipX: json['flipX'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BonePose && other.rotation == rotation && other.translation == translation && other.flipX == flipX;

  @override
  int get hashCode => Object.hash(rotation, translation, flipX);

  @override
  String toString() => 'BonePose($rotation, $translation, flipX: $flipX)';
}
