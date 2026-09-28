import 'package:flutter/material.dart';

import '../../../l10n/strings.dart';
import '../../../pixel/effects/effect_pack_catalog.dart';

extension EffectPackPresentation on EffectPackId {
  String localizedName(BuildContext context) {
    final s = Strings.of(context);
    return switch (this) {
      EffectPackId.free => s.packNameFree,
      EffectPackId.basicFilters => s.packNameBasicFilters,
      EffectPackId.artistic => s.packNameArtistic,
      EffectPackId.materials => s.packNameMaterials,
      EffectPackId.worldGenerators => s.packNameWorldGenerators,
      EffectPackId.lightingDistortion => s.packNameLightingDistortion,
      EffectPackId.motion => s.packNameMotion,
      EffectPackId.vfxNature => s.packNameVfxNature,
      EffectPackId.vfxMagic => s.packNameVfxMagic,
      EffectPackId.vfxAction => s.packNameVfxAction,
    };
  }

  String localizedDescription(BuildContext context) {
    final s = Strings.of(context);
    return switch (this) {
      EffectPackId.free => s.packDescFree,
      EffectPackId.basicFilters => s.packDescBasicFilters,
      EffectPackId.artistic => s.packDescArtistic,
      EffectPackId.materials => s.packDescMaterials,
      EffectPackId.worldGenerators => s.packDescWorldGenerators,
      EffectPackId.lightingDistortion => s.packDescLightingDistortion,
      EffectPackId.motion => s.packDescMotion,
      EffectPackId.vfxNature => s.packDescVfxNature,
      EffectPackId.vfxMagic => s.packDescVfxMagic,
      EffectPackId.vfxAction => s.packDescVfxAction,
    };
  }
}
