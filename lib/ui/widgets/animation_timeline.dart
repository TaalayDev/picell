import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../pixel/animation_frame_controller.dart';
import '../../pixel/image_painter.dart';
import '../../data.dart';
import '../../l10n/strings.dart';
import '../utils/multi_selection.dart';
import '../widgets.dart';
import 'app_expandable.dart';

class AnimationTimeline extends HookWidget {
  const AnimationTimeline({
    super.key,
    required this.width,
    required this.height,
    required this.onSelectFrame,
    required this.onAddFrame,
    required this.onDeleteFrame,
    required this.onDurationChanged,
    required this.onFrameReordered,
    required this.onPlayPause,
    required this.onStop,
    required this.onNextFrame,
    required this.onPreviousFrame,
    required this.states,
    required this.frames,
    required this.selectedStateId,
    required this.selectedFrameId,
    required this.isPlaying,
    required this.settings,
    required this.onSettingsChanged,
    this.isExpanded = false,
    required this.onExpandChanged,
    required this.copyFrame,
    required this.onAddState,
    required this.onRenameState,
    required this.onDeleteState,
    required this.onDuplicateState,
    required this.onCopyState,
    required this.onSelectedStateChanged,
  });

  final int width;
  final int height;
  final Function(int) onSelectFrame;
  final VoidCallback onAddFrame;
  final Function(Set<int>) onDeleteFrame;
  final Function(Set<int>, int) onDurationChanged;
  final Function(Set<int>, int) onFrameReordered;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback onNextFrame;
  final VoidCallback onPreviousFrame;
  final List<AnimationStateModel> states;
  final List<AnimationFrame> frames;
  final int selectedStateId;
  final int selectedFrameId;
  final bool isPlaying;
  final AnimationSettings settings;
  final Function(AnimationSettings) onSettingsChanged;
  final bool isExpanded;
  final VoidCallback onExpandChanged;
  final Function(Set<int>) copyFrame;
  final Function(String) onAddState;
  final Function(int, String) onRenameState;
  final Function(int) onDeleteState;
  final Function(int) onDuplicateState;
  final Function(int) onCopyState;
  final Function(int) onSelectedStateChanged;

  @override
  Widget build(BuildContext context) {
    final activeFrame = frames.firstWhere((f) => f.id == selectedFrameId);
    final selectedIds = useState<Set<int>>({selectedFrameId});
    final anchor = useRef<int?>(selectedFrameId);
    final stateFrameIds = frames
        .where((frame) => frame.stateId == activeFrame.stateId)
        .map((frame) => frame.id)
        .toSet();
    var effectiveSelection = selectedIds.value.intersection(stateFrameIds);
    if (!effectiveSelection.contains(selectedFrameId)) {
      effectiveSelection = {selectedFrameId};
    }

    void selectFrame(int frameId, List<AnimationFrame> orderedFrames) {
      final clickedFrame = frames.firstWhere((frame) => frame.id == frameId);
      final sameState = clickedFrame.stateId == activeFrame.stateId;
      final result = updateMultiSelection(
        orderedItems: orderedFrames.map((frame) => frame.id).toList(),
        selected: sameState ? effectiveSelection : {frameId},
        active: sameState ? selectedFrameId : frameId,
        clicked: frameId,
        anchor: sameState ? anchor.value : frameId,
        toggle: sameState && isMultiSelectTogglePressed,
        extendRange: sameState && isRangeSelectPressed,
      );
      selectedIds.value = result.selected;
      anchor.value = result.anchor;
      onSelectFrame(result.active);
    }

    final textController = useTextEditingController(
      text: activeFrame.duration.toString(),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMainControlBar(context, textController, effectiveSelection),
        AppExpandable(
          expand: isExpanded,
          child: _buildExpandedTimeline(
            context,
            textController,
            effectiveSelection,
            selectFrame,
          ),
        ),
      ],
    );
  }

  Widget _buildMainControlBar(
    BuildContext context,
    TextEditingController textController,
    Set<int> selectedFrameIds,
  ) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            // Playback controls
            _PlaybackControls(
              isPlaying: isPlaying,
              onPlayPause: onPlayPause,
              onStop: onStop,
              onNextFrame: onNextFrame,
              onPreviousFrame: onPreviousFrame,
            ),
            VerticalDivider(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              width: 1,
              thickness: 1,
            ),
            const SizedBox(width: 16),

            const Spacer(),

            if (selectedFrameIds.length > 1) ...[
              Tooltip(
                message: '${selectedFrameIds.length} frames selected',
                child: Container(
                  key: const ValueKey('selected-frame-count'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.checklist,
                        size: 13,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${selectedFrameIds.length}',
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Frame duration
            SizedBox(
              width: 64,
              child: TextFormField(
                controller: textController,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  isDense: true,
                  suffix: Text(
                    'ms',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
                style: const TextStyle(fontSize: 12),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final duration = int.tryParse(value);
                  if (duration != null) {
                    onDurationChanged(selectedFrameIds, duration);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),

            // Frame actions
            Row(
              children: [
                IconButton(
                  icon: const Icon(Feather.copy, size: 16),
                  onPressed:
                      isExpanded ? () => copyFrame(selectedFrameIds) : null,
                  tooltip: Strings.of(context).copyFrame,
                ),
                IconButton(
                  icon: const Icon(Feather.plus, size: 16),
                  onPressed: isExpanded ? onAddFrame : null,
                  tooltip: Strings.of(context).addFrame,
                ),
                IconButton(
                  icon: const Icon(
                    Feather.trash,
                    size: 16,
                    color: Colors.red,
                  ),
                  onPressed: isExpanded
                      ? () {
                          onDeleteFrame(selectedFrameIds);
                        }
                      : null,
                  tooltip: Strings.of(context).deleteFrame,
                ),
              ],
            ),

            // Expand/collapse button
            IconButton(
              icon: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_up,
                size: 16,
              ),
              onPressed: onExpandChanged,
              tooltip: isExpanded
                  ? Strings.of(context).collapse
                  : Strings.of(context).expand,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedTimeline(
    BuildContext context,
    TextEditingController controller,
    Set<int> selectedFrameIds,
    void Function(int, List<AnimationFrame>) selectFrame,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: _StatesPanel(
        states: states,
        selectedStateId: selectedStateId,
        onAddState: onAddState,
        onCopyState: onCopyState,
        onDeleteState: onDeleteState,
        onRenameState: onRenameState,
        onSelectedStateChanged: onSelectedStateChanged,
        frames: frames,
        selectedFrameId: selectedFrameId,
        selectedFrameIds: selectedFrameIds,
        width: width,
        height: height,
        onSelectFrame: (frameId, orderedFrames) {
          selectFrame(frameId, orderedFrames);

          final index = frames.indexWhere((e) => e.id == frameId);
          controller.text = frames[index].duration.toString();
        },
        copyFrame: copyFrame,
        onReorderFrame: onFrameReordered,
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    required this.isPlaying,
    required this.onPlayPause,
    required this.onStop,
    required this.onNextFrame,
    required this.onPreviousFrame,
  });

  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback onNextFrame;
  final VoidCallback onPreviousFrame;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (MediaQuery.sizeOf(context).width > 600)
          IconButton(
            icon: const Icon(Feather.skip_back, size: 16),
            onPressed: onPreviousFrame,
            tooltip: Strings.of(context).previousFrame,
          ),
        IconButton(
          icon: Icon(
            isPlaying ? Feather.pause : Feather.play,
            size: 16,
          ),
          onPressed: onPlayPause,
          tooltip:
              isPlaying ? Strings.of(context).pause : Strings.of(context).play,
        ),
        if (MediaQuery.sizeOf(context).width > 600)
          IconButton(
            icon: const Icon(Feather.skip_forward, size: 16),
            onPressed: onNextFrame,
            tooltip: Strings.of(context).nextFrame,
          ),
      ],
    );
  }
}

class _StatesPanel extends StatelessWidget {
  const _StatesPanel({
    required this.states,
    required this.selectedStateId,
    required this.onAddState,
    required this.onCopyState,
    required this.onDeleteState,
    required this.onRenameState,
    required this.onSelectedStateChanged,
    required this.frames,
    required this.selectedFrameId,
    required this.selectedFrameIds,
    required this.width,
    required this.height,
    required this.onSelectFrame,
    required this.copyFrame,
    required this.onReorderFrame,
  });

  final List<AnimationStateModel> states;
  final int selectedStateId;
  final List<AnimationFrame> frames;
  final int selectedFrameId;
  final Set<int> selectedFrameIds;
  final int width;
  final int height;
  final Function(String) onAddState;
  final Function(int) onCopyState;
  final Function(int) onDeleteState;
  final Function(int, String) onRenameState;
  final Function(int) onSelectedStateChanged;
  final void Function(int, List<AnimationFrame>) onSelectFrame;
  final Function(Set<int>) copyFrame;
  final void Function(Set<int> draggedIds, int targetId) onReorderFrame;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: states.length,
            itemBuilder: (context, index) {
              final state = states[index];

              return Container(
                key: ValueKey(state.id),
                height: 30,
                color: state.id == selectedStateId
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : null,
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 30,
                      child: ListTile(
                        dense: true,
                        selected: state.id == selectedStateId,
                        title: Text(
                          state.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        minTileHeight: 30,
                        trailing: PopupMenuButton(
                          child: const Icon(Feather.more_vertical, size: 16),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(Strings.of(context).delete),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'delete') {
                              onDeleteState(state.id);
                            }
                          },
                        ),
                        onTap: () => onSelectedStateChanged(state.id),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 5),
                      ),
                    ),
                    VerticalDivider(
                      color:
                          Theme.of(context).dividerColor.withValues(alpha: 0.5),
                      width: 1,
                      thickness: 1,
                    ),
                    Expanded(
                      child: _FramesGrid(
                        frames: frames
                            .where(
                              (f) => f.stateId == state.id,
                            )
                            .toList(),
                        selectedFrameId: selectedFrameId,
                        selectedFrameIds: selectedFrameIds,
                        onSelectFrame: (frameId) {
                          if (state.id != selectedStateId) {
                            onSelectedStateChanged(state.id);
                          }
                          onSelectFrame(
                              frameId,
                              frames
                                  .where((f) => f.stateId == state.id)
                                  .toList());
                        },
                        onReorderFrame: onReorderFrame,
                        width: width,
                        height: height,
                      ),
                    )
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) {
              return const Divider(height: 1);
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: Text(Strings.of(context).addState,
                    style: const TextStyle(fontSize: 12)),
                onPressed: () => _showAddStateDialog(context),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Feather.copy, size: 16),
                label: Text(Strings.of(context).copyState,
                    style: const TextStyle(fontSize: 12)),
                onPressed: () => onCopyState(selectedStateId),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAddStateDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Strings.of(context).addAnimationState),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: Strings.of(context).stateName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(Strings.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onAddState(controller.text);
                Navigator.of(context).pop();
              }
            },
            child: Text(Strings.of(context).add),
          ),
        ],
      ),
    );
  }
}

class _FramesGrid extends StatelessWidget {
  const _FramesGrid({
    required this.frames,
    required this.selectedFrameId,
    required this.selectedFrameIds,
    required this.onSelectFrame,
    required this.onReorderFrame,
    required this.width,
    required this.height,
  });

  final List<AnimationFrame> frames;
  final int selectedFrameId;
  final Set<int> selectedFrameIds;
  final Function(int) onSelectFrame;
  final void Function(Set<int> draggedIds, int targetId) onReorderFrame;
  final int width;
  final int height;

  @override
  Widget build(BuildContext context) {
    if (frames.isEmpty) {
      return const SizedBox.shrink();
    }

    final aspectRatio =
        (width > 0 && height > 0) ? (width / height).clamp(0.5, 2.0) : 1.0;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      itemCount: frames.length,
      separatorBuilder: (context, index) => const SizedBox(width: 6),
      itemBuilder: (context, index) {
        final frame = frames[index];
        final isSelected = selectedFrameIds.contains(frame.id);
        final isActive = frame.id == selectedFrameId;

        final thumbnail = _FrameThumbnail(
          frame: frame,
          isSelected: isSelected,
          isActive: isActive,
          width: width,
          height: height,
          index: index,
        );

        return AspectRatio(
          aspectRatio: aspectRatio,
          child: DragTarget<Set<int>>(
            key: ValueKey(frame.id),
            onWillAcceptWithDetails: (details) =>
                !details.data.contains(frame.id),
            onAcceptWithDetails: (details) =>
                onReorderFrame(details.data, frame.id),
            builder: (context, candidates, _) {
              final draggedIds = isSelected ? selectedFrameIds : {frame.id};
              return Draggable<Set<int>>(
                data: draggedIds,
                onDragStarted:
                    isSelected ? null : () => onSelectFrame(frame.id),
                feedback: SizedBox(
                  width: (36 * aspectRatio).clamp(24.0, 72.0),
                  height: 36,
                  child: Material(
                    color: Colors.transparent,
                    child: _FrameThumbnail(
                      frame: frame,
                      isSelected: true,
                      isActive: true,
                      width: width,
                      height: height,
                      index: index,
                    ),
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.3, child: thumbnail),
                child: Tooltip(
                  message:
                      '${frame.name.isNotEmpty ? frame.name : 'Frame ${index + 1}'} (${frame.duration}ms)',
                  waitDuration: const Duration(milliseconds: 600),
                  child: InkWell(
                    onTap: () => onSelectFrame(frame.id),
                    borderRadius: BorderRadius.circular(4),
                    child: candidates.isNotEmpty
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: thumbnail,
                          )
                        : thumbnail,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _FrameThumbnail extends StatelessWidget {
  const _FrameThumbnail({
    required this.frame,
    required this.isSelected,
    required this.isActive,
    required this.width,
    required this.height,
    this.index,
  });

  final AnimationFrame frame;
  final bool isSelected;
  final bool isActive;
  final int width;
  final int height;
  final int? index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Semantics(
      selected: isSelected,
      focused: isActive,
      label: frame.name,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(4),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        primaryColor.withValues(alpha: isActive ? 0.38 : 0.2),
                    blurRadius: isActive ? 5 : 3,
                    spreadRadius: isActive ? 1 : 0,
                  ),
                ]
              : null,
        ),
        // Draw the selection ring above the preview. A background decoration's
        // border is hidden by the edge-to-edge thumbnail image.
        foregroundDecoration: BoxDecoration(
          border: Border.all(
            color: isActive
                ? primaryColor
                : isSelected
                    ? primaryColor.withValues(alpha: 0.9)
                    : theme.dividerColor.withValues(alpha: 0.25),
            width: isActive
                ? 3
                : isSelected
                    ? 2
                    : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LayersPreview(
                width: width,
                height: height,
                layers: frame.layers,
                builder: (context, image) {
                  return image != null
                      ? CustomPaint(painter: ImagePainter(image))
                      : const ColoredBox(color: Colors.white);
                },
              ),
            ),
            if (isSelected)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  key: ValueKey('frame-${frame.id}-selected'),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isActive
                        ? primaryColor
                        : primaryColor.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Icon(
                    isActive ? Icons.circle : Icons.check,
                    size: isActive ? 5 : 8,
                    color: Colors.white,
                  ),
                ),
              ),
            if (index != null)
              Positioned(
                left: 2,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 2.5, vertical: 0.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '${index! + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Future<void> showAnimationPreviewDialog(
//   BuildContext context, {
//   required List<AnimationFrame> frames,
//   required int width,
//   required int height,
// }) {
//   return showDialog(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         content: Stack(
//           children: [
//             AnimationPreview(
//               frames: frames,
//               width: width,
//               height: height,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text(Strings.of(context).close),
//           ),
//         ],
//       );
//     },
//   );
// }

class AnimationPreview extends StatefulWidget {
  const AnimationPreview({
    super.key,
    required this.width,
    required this.height,
    required this.frames,
  });

  final List<AnimationFrame> frames;
  final int width;
  final int height;

  @override
  State<AnimationPreview> createState() => _AnimationPreviewState();
}

class _AnimationPreviewState extends State<AnimationPreview> {
  int _currentFrameIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    final frame = widget.frames[_currentFrameIndex];
    _timer?.cancel();
    _timer = Timer(
      Duration(milliseconds: frame.duration),
      () {
        setState(() {
          _currentFrameIndex = (_currentFrameIndex + 1) % widget.frames.length;
          _next();
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentFrameIndex,
      children: [
        for (var frame in widget.frames)
          Container(
            width: (widget.width * 10).clamp(0, 400).toDouble(),
            height: (widget.height * 10).clamp(0, 400).toDouble(),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              color: Colors.white.withValues(alpha: 0.8),
            ),
            child: LayersPreview(
              width: widget.width,
              height: widget.height,
              layers: frame.layers,
              builder: (context, image) {
                return image != null
                    ? CustomPaint(painter: ImagePainter(image))
                    : const ColoredBox(color: Colors.white);
              },
            ),
          ),
      ],
    );
  }
}
