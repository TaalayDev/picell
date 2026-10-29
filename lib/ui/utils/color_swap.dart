import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../pixel/providers/pixel_canvas_provider.dart';
import '../../providers/editor_settings_provider.dart';

/// Swaps the primary (canvas) colour with the secondary colour (X).
void swapPrimarySecondaryColors(WidgetRef ref, PixelCanvasNotifier notifier) {
  final settings = ref.read(editorSettingsNotifierProvider.notifier);
  final secondary = ref.read(editorSettingsNotifierProvider).secondaryColor;
  settings.setSecondaryColor(notifier.currentColor);
  notifier.currentColor = secondary;
}

/// Resets to black primary / white secondary (D).
void resetDefaultColors(WidgetRef ref, PixelCanvasNotifier notifier) {
  ref.read(editorSettingsNotifierProvider.notifier).setSecondaryColor(Colors.white);
  notifier.currentColor = Colors.black;
}
