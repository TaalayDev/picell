import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/utils/file_utils.dart';

/// Shows a rendered GIF of the rig's animation, looping, with the option to
/// keep it. Its pixels are shown without smoothing.
class RigGifPreviewDialog extends StatelessWidget {
  const RigGifPreviewDialog({super.key, required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;

  static Future<void> show(BuildContext context, {required Uint8List bytes, required String fileName}) {
    return showDialog<void>(
      context: context,
      builder: (_) => RigGifPreviewDialog(bytes: bytes, fileName: fileName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Animation preview'),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        FilledButton.icon(
          key: const ValueKey('save-rig-gif'),
          icon: const Icon(Icons.download, size: 16),
          label: const Text('Save GIF'),
          onPressed: () => FileUtils(context).saveImage(bytes, fileName),
        ),
      ],
    );
  }
}
