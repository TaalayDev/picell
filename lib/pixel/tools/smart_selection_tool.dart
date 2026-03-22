import '../../data/models/selection_region.dart';
import '../services/selection_service.dart';
import '../tools.dart';

class SmartSelectionTool extends Tool {
  SmartSelectionTool({
    required this.selectionService,
    this.onSelectionEnd,
    this.tolerance = 0,
  }) : super(PixelTool.smartSelect);

  final SelectionService selectionService;
  final void Function(SelectionRegion?)? onSelectionEnd;
  final int tolerance;

  @override
  void onStart(PixelDrawDetails details) {
    final pixels = details.currentLayer.processedPixels;
    final pixelPosition = details.pixelPosition;

    if (pixelPosition.x < 0 || pixelPosition.x >= details.width ||
        pixelPosition.y < 0 || pixelPosition.y >= details.height) {
      return;
    }

    final region = selectionService.createWandSelection(
      pixels: pixels,
      x: pixelPosition.x,
      y: pixelPosition.y,
      w: details.width,
      h: details.height,
      tolerance: tolerance,
    );

    onSelectionEnd?.call(region);
  }

  @override
  void onMove(PixelDrawDetails details) {
    // Not needed for a tap-based tool
  }

  @override
  void onEnd(PixelDrawDetails details) {
    // Not needed for a tap-based tool
  }
}
