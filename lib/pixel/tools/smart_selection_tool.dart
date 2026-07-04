import '../../data/models/selection_region.dart';
import '../services/selection_service.dart';
import '../tools.dart';

class SmartSelectionTool extends Tool {
  SmartSelectionTool({
    required this.selectionService,
    this.onSelectionEnd,
    this.tolerance = 0,
    this.contiguous = true,
  }) : super(PixelTool.smartSelect);

  final SelectionService selectionService;
  final void Function(SelectionRegion?)? onSelectionEnd;

  /// Color-distance threshold (Euclidean in ARGB, 0-441 range; UI maps
  /// 0-100% onto 0-255). Updated live from editor settings.
  int tolerance;

  /// Flood-fill from the tapped pixel when true; select-by-color across the
  /// whole layer when false.
  bool contiguous;

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
      contiguous: contiguous,
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
