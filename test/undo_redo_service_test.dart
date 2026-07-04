import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/animation_frame_model.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/pixel/pixel_canvas_state.dart';
import 'package:picell/pixel/services/undo_redo_service.dart';
import 'package:picell/pixel/tools.dart';

PixelCanvasState _buildState({int width = 8, int height = 8, Uint32List? pixels}) {
  return PixelCanvasState(
    width: width,
    height: height,
    animationStates: const [AnimationStateModel(id: 1, name: 'Default', frameRate: 12)],
    frames: [
      AnimationFrame(
        id: 1,
        stateId: 1,
        name: 'Frame 1',
        duration: 100,
        layers: [
          Layer(
            layerId: 1,
            id: 'layer-1',
            name: 'Layer 1',
            pixels: pixels ?? Uint32List(width * height),
            order: 0,
          ),
        ],
      ),
    ],
    currentColor: Colors.black,
    currentTool: PixelTool.pencil,
    mirrorAxis: MirrorAxis.vertical,
  );
}

/// Simulates a copy-on-write drawing commit: returns a new state whose
/// current layer holds [newPixels].
PixelCanvasState _commitPixels(PixelCanvasState state, Uint32List newPixels) {
  final frame = state.frames[0];
  final layer = frame.layers[0].copyWith(pixels: newPixels);
  return state.copyWith(
    frames: [frame.copyWith(layers: [layer])],
  );
}

void main() {
  group('UndoRedoService pixel diffs', () {
    test('draw -> undo -> redo restores identical buffers', () {
      final service = UndoRedoService();
      final before = Uint32List(64);
      var state = _buildState(pixels: before);

      final after = Uint32List.fromList(before);
      after[10] = 0xFF112233;
      after[11] = 0xFF445566;

      service.savePixelDiff(preState: state, prePixels: before, postPixels: after);
      state = _commitPixels(state, after);

      final undone = service.undo(state)!;
      expect(undone.frames[0].layers[0].pixels, equals(before));
      expect(service.canRedo, isTrue);

      final redone = service.redo(undone)!;
      expect(redone.frames[0].layers[0].pixels, equals(after));
    });

    test('no-op stroke records nothing', () {
      final service = UndoRedoService();
      final pixels = Uint32List(64);
      final state = _buildState(pixels: pixels);

      service.savePixelDiff(preState: state, prePixels: pixels, postPixels: Uint32List.fromList(pixels));
      expect(service.canUndo, isFalse);
    });

    test('large change uses full-buffer entry and round-trips', () {
      final service = UndoRedoService();
      final before = Uint32List(64);
      var state = _buildState(pixels: before);

      // Change every pixel (flood fill).
      final after = Uint32List(64);
      for (var i = 0; i < after.length; i++) {
        after[i] = 0xFFABCDEF;
      }

      service.savePixelDiff(preState: state, prePixels: before, postPixels: after);
      state = _commitPixels(state, after);

      final undone = service.undo(state)!;
      expect(undone.frames[0].layers[0].pixels, equals(before));
      final redone = service.redo(undone)!;
      expect(redone.frames[0].layers[0].pixels, equals(after));
    });

    test('multiple strokes unwind in order', () {
      final service = UndoRedoService();
      final buf0 = Uint32List(64);
      var state = _buildState(pixels: buf0);

      final buf1 = Uint32List.fromList(buf0)..[0] = 0xFF000001;
      service.savePixelDiff(preState: state, prePixels: buf0, postPixels: buf1);
      state = _commitPixels(state, buf1);

      final buf2 = Uint32List.fromList(buf1)..[1] = 0xFF000002;
      service.savePixelDiff(preState: state, prePixels: buf1, postPixels: buf2);
      state = _commitPixels(state, buf2);

      state = service.undo(state)!;
      expect(state.frames[0].layers[0].pixels, equals(buf1));
      state = service.undo(state)!;
      expect(state.frames[0].layers[0].pixels, equals(buf0));
      expect(service.canUndo, isFalse);

      state = service.redo(state)!;
      expect(state.frames[0].layers[0].pixels, equals(buf1));
      state = service.redo(state)!;
      expect(state.frames[0].layers[0].pixels, equals(buf2));
      expect(service.canRedo, isFalse);
    });

    test('new stroke clears redo stack', () {
      final service = UndoRedoService();
      final buf0 = Uint32List(64);
      var state = _buildState(pixels: buf0);

      final buf1 = Uint32List.fromList(buf0)..[0] = 0xFF000001;
      service.savePixelDiff(preState: state, prePixels: buf0, postPixels: buf1);
      state = _commitPixels(state, buf1);

      state = service.undo(state)!;
      expect(service.canRedo, isTrue);

      final buf2 = Uint32List.fromList(buf0)..[2] = 0xFF000003;
      service.savePixelDiff(preState: state, prePixels: buf0, postPixels: buf2);
      expect(service.canRedo, isFalse);
    });

    test('mixed full snapshots and diffs round-trip', () {
      final service = UndoRedoService();
      final buf0 = Uint32List(64);
      var state = _buildState(pixels: buf0);

      // Structural op: full snapshot.
      service.saveState(state);
      final buf1 = Uint32List.fromList(buf0)..[5] = 0xFF00AA00;
      state = _commitPixels(state, buf1);

      // Drawing op: diff.
      final buf2 = Uint32List.fromList(buf1)..[6] = 0xFF00BB00;
      service.savePixelDiff(preState: state, prePixels: buf1, postPixels: buf2);
      state = _commitPixels(state, buf2);

      state = service.undo(state)!; // reverts diff
      expect(state.frames[0].layers[0].pixels, equals(buf1));
      state = service.undo(state)!; // reverts to full snapshot
      expect(state.frames[0].layers[0].pixels, equals(buf0));

      state = service.redo(state)!;
      expect(state.frames[0].layers[0].pixels, equals(buf1));
      state = service.redo(state)!;
      expect(state.frames[0].layers[0].pixels, equals(buf2));
    });

    test('diff entry survives when frame id still matches after reorder', () {
      final service = UndoRedoService();
      final before = Uint32List(64);
      var state = _buildState(pixels: before);

      final after = Uint32List.fromList(before)..[3] = 0xFF010203;
      service.savePixelDiff(preState: state, prePixels: before, postPixels: after);
      state = _commitPixels(state, after);

      // Prepend an unrelated frame — the entry should still find frame id 1.
      final extraFrame = AnimationFrame(
        id: 2,
        stateId: 1,
        name: 'Frame 0',
        duration: 100,
        layers: [
          Layer(layerId: 2, id: 'layer-2', name: 'L', pixels: Uint32List(64), order: 0),
        ],
      );
      state = state.copyWith(frames: [extraFrame, ...state.frames]);

      final undone = service.undo(state)!;
      final targetFrame = undone.frames.firstWhere((f) => f.id == 1);
      expect(targetFrame.layers[0].pixels, equals(before));
    });
  });
}
