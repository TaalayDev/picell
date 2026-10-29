import 'dart:ui';

/// A bone's animated offset from its rest pose.
class BonePose {
  /// Degrees added to the bone's rest orientation. Not wrapped: keyed values
  /// are offsets, so 0 -> 350 turns the long way, as the artist asked.
  final double rotation;
  final Offset translation;
  final bool flipX;

  /// Mirrors the bone upside down about its head.
  final bool flipY;

  /// Stretch along the bone (x) and across it (y), about its head, in the
  /// bone's rest direction. 1 is the drawn size; children scale with it.
  final double scaleX;
  final double scaleY;

  const BonePose({
    this.rotation = 0,
    this.translation = Offset.zero,
    this.flipX = false,
    this.flipY = false,
    this.scaleX = 1,
    this.scaleY = 1,
  });

  static const rest = BonePose();

  /// Smallest scale a pose can hold; zero would collapse the art.
  static const minScale = 0.01;

  bool get isScaled => scaleX != 1 || scaleY != 1;

  BonePose copyWith({
    double? rotation,
    Offset? translation,
    bool? flipX,
    bool? flipY,
    double? scaleX,
    double? scaleY,
  }) =>
      BonePose(
        rotation: rotation ?? this.rotation,
        translation: translation ?? this.translation,
        flipX: flipX ?? this.flipX,
        flipY: flipY ?? this.flipY,
        scaleX: scaleX ?? this.scaleX,
        scaleY: scaleY ?? this.scaleY,
      );

  Map<String, dynamic> toJson() => {
        'rotation': rotation,
        'translation': {'dx': translation.dx, 'dy': translation.dy},
        'flipX': flipX,
        // Absent in rigs saved before these existed; only written when used.
        if (flipY) 'flipY': true,
        if (scaleX != 1) 'scaleX': scaleX,
        if (scaleY != 1) 'scaleY': scaleY,
      };

  factory BonePose.fromJson(Map<String, dynamic> json) {
    final t = json['translation'] as Map<String, dynamic>?;
    return BonePose(
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      translation: t == null ? Offset.zero : Offset((t['dx'] as num).toDouble(), (t['dy'] as num).toDouble()),
      flipX: json['flipX'] as bool? ?? false,
      flipY: json['flipY'] as bool? ?? false,
      scaleX: (json['scaleX'] as num?)?.toDouble() ?? 1,
      scaleY: (json['scaleY'] as num?)?.toDouble() ?? 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BonePose &&
      other.rotation == rotation &&
      other.translation == translation &&
      other.flipX == flipX &&
      other.flipY == flipY &&
      other.scaleX == scaleX &&
      other.scaleY == scaleY;

  @override
  int get hashCode => Object.hash(rotation, translation, flipX, flipY, scaleX, scaleY);

  @override
  String toString() => 'BonePose($rotation, $translation, flip: $flipX/$flipY, scale: $scaleX x $scaleY)';
}
