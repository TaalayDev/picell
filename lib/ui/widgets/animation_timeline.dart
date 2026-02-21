import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../pixel/animation_frame_controller.dart';
import '../../pixel/image_painter.dart';
import '../../data.dart';
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
  final Function(int) onDeleteFrame;
  final Function(int, int) onDurationChanged;
  final Function(int, int) onFrameReordered;
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
  final Function(int) copyFrame;
  final Function(String) onAddState;
  final Function(int, String) onRenameState;
  final Function(int) onDeleteState;
  final Function(int) onDuplicateState;
  final Function(int) onCopyState;
  final Function(int) onSelectedStateChanged;

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController(
      text: frames
          .firstWhere(
            (f) => f.id == selectedFrameId,
          )
          .duration
          .toString(),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMainControlBar(context, textController),
        AppExpandable(
          expand: isExpanded,
          child: _buildExpandedTimeline(context, textController),
        ),
      ],
    );
  }

  Widget _buildMainControlBar(
    BuildContext context,
    TextEditingController textController,
  ) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
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
              color: Theme.of(context).dividerColor.withOpacity(0.5),
              width: 1,
              thickness: 1,
            ),
            const SizedBox(width: 16),

            const Spacer(),

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
                    final index = frames.indexWhere((e) => e.id == selectedFrameId);
                    onDurationChanged(index, duration);
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
                  onPressed: isExpanded ? () => copyFrame(selectedFrameId) : null,
                  tooltip: 'Copy Frame',
                ),
                IconButton(
                  icon: const Icon(Feather.plus, size: 16),
                  onPressed: isExpanded ? onAddFrame : null,
                  tooltip: 'Add Frame',
                ),
                IconButton(
                  icon: const Icon(
                    Feather.trash,
                    size: 16,
                    color: Colors.red,
                  ),
                  onPressed: isExpanded
                      ? () {
                          final index = frames.indexWhere((e) => e.id == selectedFrameId);
                          onDeleteFrame(index);
                        }
                      : null,
                  tooltip: 'Delete Frame',
                ),
              ],
            ),

            // Expand/collapse button
            IconButton(
              icon: Icon(
                isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                size: 16,
              ),
              onPressed: onExpandChanged,
              tooltip: isExpanded ? 'Collapse' : 'Expand',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedTimeline(
    BuildContext context,
    TextEditingController controller,
  ) {
    return Container(
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
        width: width,
        height: height,
        onSelectFrame: (frameId) {
          onSelectFrame(frameId);

          final index = frames.indexWhere((e) => e.id == frameId);
          controller.text = frames[index].duration.toString();
        },
        copyFrame: copyFrame,
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
            tooltip: 'Previous Frame',
          ),
        IconButton(
          icon: Icon(
            isPlaying ? Feather.pause : Feather.play,
            size: 16,
          ),
          onPressed: onPlayPause,
          tooltip: isPlaying ? 'Pause' : 'Play',
        ),
        IconButton(
          icon: const Icon(Feather.square, size: 16),
          onPressed: onStop,
          tooltip: 'Stop',
        ),
        if (MediaQuery.sizeOf(context).width > 600)
          IconButton(
            icon: const Icon(Feather.skip_forward, size: 16),
            onPressed: onNextFrame,
            tooltip: 'Next Frame',
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
    required this.width,
    required this.height,
    required this.onSelectFrame,
    required this.copyFrame,
  });

  final List<AnimationStateModel> states;
  final int selectedStateId;
  final List<AnimationFrame> frames;
  final int selectedFrameId;
  final int width;
  final int height;
  final Function(String) onAddState;
  final Function(int) onCopyState;
  final Function(int) onDeleteState;
  final Function(int, String) onRenameState;
  final Function(int) onSelectedStateChanged;
  final Function(int) onSelectFrame;
  final Function(int) copyFrame;

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
                height: 40,
                color: state.id == selectedStateId ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                child: Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: ListTile(
                        dense: true,
                        selected: state.id == selectedStateId,
                        title: Text(
                          state.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: PopupMenuButton(
                          child: const Icon(Feather.more_vertical, size: 16),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('delete'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'delete') {
                              onDeleteState(state.id);
                            }
                          },
                        ),
                        onTap: () => onSelectedStateChanged(state.id),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                      ),
                    ),
                    VerticalDivider(
                      color: Theme.of(context).dividerColor.withOpacity(0.5),
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
                        onSelectFrame: (index) {
                          if (state.id != selectedStateId) {
                            onSelectedStateChanged(state.id);
                          }

                          onSelectFrame(index);
                        },
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
                label: const Text('Add State', style: TextStyle(fontSize: 12)),
                onPressed: () => _showAddStateDialog(context),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Feather.copy, size: 16),
                label: const Text('Copy State', style: TextStyle(fontSize: 12)),
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
        title: const Text('Add Animation State'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'State Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onAddState(controller.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
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
    required this.onSelectFrame,
    required this.width,
    required this.height,
  });

  final List<AnimationFrame> frames;
  final int selectedFrameId;
  final Function(int) onSelectFrame;
  final int width;
  final int height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 18,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          mainAxisExtent: 18,
        ),
        itemCount: frames.length,
        itemBuilder: (context, index) {
          final frame = frames[index];
          final isSelected = frame.id == selectedFrameId;

          return InkWell(
            key: ValueKey(frame.id),
            onTap: () => onSelectFrame(frame.id),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor.withOpacity(0.2),
                  width: isSelected ? 1.5 : 1,
                ),
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
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
            ),
          );
        },
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
              color: Colors.white.withOpacity(0.8),
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
