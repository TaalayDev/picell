import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../l10n/strings.dart';
import '../../../core/utils/file_utils.dart';

/// Shows a rendered GIF of the rig's animation, looping, with the option to
/// keep it. Its pixels are shown without smoothing.
class RigGifPreviewDialog extends StatelessWidget {
  const RigGifPreviewDialog({super.key, required this.bytes, required this.fileName, this.onBeforeSave});

  final Uint8List bytes;
  final String fileName;

  /// Asked before the GIF is saved; false keeps it unsaved. Null allows it.
  final Future<bool> Function()? onBeforeSave;

  static Future<void> show(
    BuildContext context, {
    required Uint8List bytes,
    required String fileName,
    Future<bool> Function()? onBeforeSave,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => RigGifPreviewDialog(bytes: bytes, fileName: fileName, onBeforeSave: onBeforeSave),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(Strings.of(context).rigPreviewTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 360),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.memory(
              bytes,
              key: const ValueKey('rig-gif-preview'),
              filterQuality: FilterQuality.none,
              gaplessPlayback: true,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(Strings.of(context).close)),
        FilledButton.icon(
          key: const ValueKey('save-rig-gif'),
          icon: const Icon(Icons.download, size: 16),
          label: Text(Strings.of(context).rigSaveGif),
          onPressed: () async {
            final gate = onBeforeSave;
            if (gate != null && !await gate()) return;
            if (context.mounted) FileUtils(context).saveImage(bytes, fileName);
          },
        ),
      ],
    );
  }
}
