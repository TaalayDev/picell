import 'package:flutter/material.dart';

import '../../../../app/theme/pv_tokens.dart';
import '../../../../l10n/strings.dart';
import '../../pv/pv.dart';
import 'pv_my_projects.dart';

/// The home action card follows the user's current Pro access.
class PvHomeActionPanel extends StatelessWidget {
  const PvHomeActionPanel({
    super.key,
    required this.isPro,
    required this.onPreviewPro,
    required this.onPickSize,
    required this.onImport,
  });

  final bool isPro;
  final VoidCallback onPreviewPro;
  final ValueChanged<int> onPickSize;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    if (isPro) return PvQuickCreatePanel(onPickSize: onPickSize, onImport: onImport);

    final pv = context.pv;
    final strings = Strings.of(context);
    Widget feature(IconData icon, String label) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(icon, color: pv.accent, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: pv.body(size: 12))),
            ],
          ),
        );

    return Container(
      key: const ValueKey('home-pro-preview'),
      padding: const EdgeInsets.all(16),
      decoration: pv.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_outlined, size: 28, color: pv.accent),
              const SizedBox(width: 10),
              Expanded(child: Text('PICELL PRO', style: pv.pixelLabel(size: 15, color: pv.accent))),
            ],
          ),
          const SizedBox(height: 12),
          feature(Icons.account_tree_outlined, strings.whatsNewBoneRigTitle),
          feature(Icons.aspect_ratio, strings.unlockLargerCanvasSizes),
          feature(Icons.movie_outlined, strings.unlockAllExportFormats),
          feature(Icons.palette_outlined, strings.featureAdvancedEffects),
          const SizedBox(height: 4),
          PvPixelButton(
            label: strings.upgradeToPro,
            icon: Icons.auto_awesome,
            expand: true,
            onPressed: onPreviewPro,
          ),
        ],
      ),
    );
  }
}
