import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../pixel/animation_frame_controller.dart';
import '../../pixel/image_painter.dart';
import '../../pixel/rig/rig_bake.dart';
import '../../data.dart';
import '../../l10n/strings.dart';
import '../utils/multi_selection.dart';
import '../widgets.dart';
import 'app_expandable.dart';
import 'panel_select_all_region.dart';

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
    this.onOpenRig,
    this.rigLocked = false,
    this.selectedFrameIds,
    this.onSelectFrames,
    this.onSelectAllFrames,
    this.onInteract,
    this.onRenameFrame,
    this.onReverseFrames,
    this.onMoveFramesToState,
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

  /// Opens the bone rig editor for the selected animation; the button is
  /// hidden when null.
  final VoidCallback? onOpenRig;

  /// Marks the rig button as a Pro feature.
  final bool rigLocked;

  /// Frames selected for bulk actions. Defaults to only [selectedFrameId].
  final Set<int>? selectedFrameIds;

  /// Handles a frame click with its modifiers (Ctrl/Cmd-click or long-press
  /// toggles, Shift-click extends a range). Without it the timeline only
  /// single-selects through [onSelectFrame].
  final void Function(int frameId, {required bool toggle, required bool extendRange})? onSelectFrames;

  /// Ctrl/Cmd+A inside the timeline.
  final VoidCallback? onSelectAllFrames;

  /// Any pointer down inside the timeline.
  final VoidCallback? onInteract;

  // Frame context menu actions; each item is hidden when its callback is null.
  final void Function(int frameId, String name)? onRenameFrame;
  final void Function(Set<int> frameIds)? onReverseFrames;

  /// Moves the frames to the animation, or copies them there when `copy`.
  final void Function(Set<int> frameIds, int stateId, bool copy)? onMoveFramesToState;

  @override
  Widget build(BuildContext context) {
    final activeFrame = frames.firstWhere((f) => f.id == selectedFrameId);
    final stateFrameIds =
        frames.where((frame) => frame.stateId == activeFrame.stateId).map((frame) => frame.id).toSet();
    var effectiveSelection = (selectedFrameIds ?? const {}).intersection(stateFrameIds);
    if (!effectiveSelection.contains(selectedFrameId)) {
      effectiveSelection = {selectedFrameId};
    }

    // [forceToggle] is the touch equivalent of Ctrl/Cmd-click (long-press).
    // Modifiers only apply within the active animation; a frame of another
    // animation is always selected alone.
    void selectFrame(int frameId, {bool forceToggle = false}) {
      final onSelectFrames = this.onSelectFrames;
      if (onSelectFrames == null) {
        onSelectFrame(frameId);
        return;
      }
      final clickedFrame = frames.firstWhere((frame) => frame.id == frameId);
      final sameState = clickedFrame.stateId == activeFrame.stateId;
      onSelectFrames(
        frameId,
        toggle: sameState && (forceToggle || isMultiSelectTogglePressed),
        extendRange: sameState && isRangeSelectPressed,
      );
    }

    final textController = useTextEditingController(
      text: activeFrame.duration.toString(),
    );
    final durationFocus = useFocusNode();
    // Show the active frame's duration unless the user is typing one.
    useEffect(() {
      if (!durationFocus.hasFocus) textController.text = '${activeFrame.duration}';
      return null;
    }, [activeFrame.id, activeFrame.duration]);

    // The duration applies to every selected frame on Enter or when the field
    // loses focus, as one undo step; invalid input reverts.
    void commitDuration() {
      final duration = int.tryParse(textController.text);
      if (duration == null || duration <= 0) {
        textController.text = '${activeFrame.duration}';
        return;
      }
      onDurationChanged(effectiveSelection, duration);
    }

    final commitRef = useRef(commitDuration)..value = commitDuration;
    useEffect(() {
      void onFocusChange() {
        if (!durationFocus.hasFocus) commitRef.value();
      }

      durationFocus.addListener(onFocusChange);
      return () => durationFocus.removeListener(onFocusChange);
    }, [durationFocus]);

    return PanelSelectAllRegion(
      onSelectAll: () => onSelectAllFrames?.call(),
      onPointerDown: onInteract,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMainControlBar(context, textController, durationFocus, commitDuration, effectiveSelection),
          AppExpandable(
            expand: isExpanded,
            child: _buildExpandedTimeline(
              context,
              effectiveSelection,
              selectFrame,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainControlBar(
    BuildContext context,
    TextEditingController textController,
    FocusNode durationFocus,
    VoidCallback commitDuration,
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
            const SizedBox(width: 8),
            if (onOpenRig != null)
              Tooltip(
                message: 'Bone rig',
                child: IconButton(
                  key: const ValueKey('open-rig-editor'),
                  icon: Badge(
                    isLabelVisible: rigLocked,
                    smallSize: 6,
                    child: const Icon(Icons.accessibility_new, size: 18),
                  ),
                  onPressed: onOpenRig,
                ),
              ),
            const SizedBox(width: 8),

            const Spacer(),

            if (selectedFrameIds.length > 1) ...[
              Tooltip(
                message: '${selectedFrameIds.length} frames selected',
                child: Container(
                  key: const ValueKey('selected-frame-count'),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                key: const ValueKey('frame-duration-field'),
                controller: textController,
                focusNode: durationFocus,
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onFieldSubmitted: (_) => commitDuration(),
              ),
            ),
            const SizedBox(width: 8),

            // Frame actions
            Row(
              children: [
                IconButton(
                  icon: const Icon(Feather.copy, size: 16),
                  onPressed: isExpanded ? () => copyFrame(selectedFrameIds) : null,
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
                isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                size: 16,
              ),
              onPressed: onExpandChanged,
              tooltip: isExpanded ? Strings.of(context).collapse : Strings.of(context).expand,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedTimeline(
    BuildContext context,
    Set<int> selectedFrameIds,
    void Function(int, {bool forceToggle}) selectFrame,
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
        onSelectFrame: (frameId, {bool forceToggle = false}) => selectFrame(frameId, forceToggle: forceToggle),
        copyFrame: copyFrame,
        onReorderFrame: onFrameReordered,
        menu: _FrameMenuActions(
          states: states,
          onDuplicate: copyFrame,
          onDelete: onDeleteFrame,
          onDurationChanged: onDurationChanged,
          onToggle: onSelectFrames == null ? null : (frameId) => selectFrame(frameId, forceToggle: true),
          onRename: onRenameFrame,
          onReverse: onReverseFrames,
          onMoveToState: onMoveFramesToState,
        ),
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
          tooltip: isPlaying ? Strings.of(context).pause : Strings.of(context).play,
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
    required this.menu,
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
  final void Function(int, {bool forceToggle}) onSelectFrame;
  final Function(Set<int>) copyFrame;
  final void Function(Set<int> draggedIds, int targetId) onReorderFrame;
  final _FrameMenuActions menu;

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
                color: state.id == selectedStateId ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                      ),
                    ),
                    VerticalDivider(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
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
                        onSelectFrame: (frameId, {bool forceToggle = false}) {
                          if (state.id != selectedStateId) {
                            onSelectedStateChanged(state.id);
                          }
                          onSelectFrame(frameId, forceToggle: forceToggle);
                        },
                        onReorderFrame: onReorderFrame,
                        menu: menu,
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
                label: Text(Strings.of(context).addState, style: const TextStyle(fontSize: 12)),
                onPressed: () => _showAddStateDialog(context),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Feather.copy, size: 16),
                label: Text(Strings.of(context).copyState, style: const TextStyle(fontSize: 12)),
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

/// What the frame context menu can do. A null callback hides its item.
class _FrameMenuActions {
  const _FrameMenuActions({
    required this.states,
    required this.onDuplicate,
    required this.onDelete,
    required this.onDurationChanged,
    this.onToggle,
    this.onRename,
    this.onReverse,
    this.onMoveToState,
  });

  final List<AnimationStateModel> states;
  final void Function(Set<int> frameIds) onDuplicate;
  final void Function(Set<int> frameIds) onDelete;
  final void Function(Set<int> frameIds, int duration) onDurationChanged;
  final void Function(int frameId)? onToggle;
  final void Function(int frameId, String name)? onRename;
  final void Function(Set<int> frameIds)? onReverse;
  final void Function(Set<int> frameIds, int stateId, bool copy)? onMoveToState;
}

class _FramesGrid extends StatefulWidget {
  const _FramesGrid({
    required this.frames,
    required this.selectedFrameId,
    required this.selectedFrameIds,
    required this.onSelectFrame,
    required this.onReorderFrame,
    required this.menu,
    required this.width,
    required this.height,
  });

  final List<AnimationFrame> frames;
  final int selectedFrameId;
  final Set<int> selectedFrameIds;
  final void Function(int frameId, {bool forceToggle}) onSelectFrame;
  final void Function(Set<int> draggedIds, int targetId) onReorderFrame;
  final _FrameMenuActions menu;
  final int width;
  final int height;

  @override
  State<_FramesGrid> createState() => _FramesGridState();
}

class _FramesGridState extends State<_FramesGrid> {
  // Frames being dragged; all of them fade, not only the one under the
  // pointer.
  Set<int> _dragging = const {};

  void _setDragging(Set<int> ids) {
    if (mounted) setState(() => _dragging = ids);
  }

  @override
  Widget build(BuildContext context) {
    final frames = widget.frames;
    if (frames.isEmpty) {
      return const SizedBox.shrink();
    }

    final aspectRatio = (widget.width > 0 && widget.height > 0) ? (widget.width / widget.height).clamp(0.5, 2.0) : 1.0;
    final frameIds = {for (final frame in frames) frame.id};
    final primary = Theme.of(context).colorScheme.primary;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      itemCount: frames.length,
      separatorBuilder: (context, index) => const SizedBox(width: 6),
      itemBuilder: (context, index) {
        final frame = frames[index];
        final isSelected = widget.selectedFrameIds.contains(frame.id);
        final isActive = frame.id == widget.selectedFrameId;

        final thumbnail = Opacity(
          opacity: _dragging.contains(frame.id) ? 0.3 : 1,
          child: _FrameThumbnail(
            frame: frame,
            isSelected: isSelected,
            isActive: isActive,
            width: widget.width,
            height: widget.height,
          ),
        );

        return AspectRatio(
          aspectRatio: aspectRatio,
          child: DragTarget<Set<int>>(
            key: ValueKey(frame.id),
            // Only frames of this animation can be dropped here.
            onWillAcceptWithDetails: (details) =>
                !details.data.contains(frame.id) && details.data.every(frameIds.contains),
            onAcceptWithDetails: (details) => widget.onReorderFrame(details.data, frame.id),
            builder: (context, candidates, _) {
              final draggedIds = isSelected ? widget.selectedFrameIds : {frame.id};
              // The block lands after this frame when it comes from before it,
              // otherwise before it (see reorderFramesByIds).
              final hovering = candidates.whereType<Set<int>>().firstOrNull;
              bool? insertAfter;
              if (hovering != null) {
                final first = frames.indexWhere((f) => hovering.contains(f.id));
                insertAfter = first >= 0 && first < index;
              }
              return Draggable<Set<int>>(
                data: draggedIds,
                onDragStarted: () {
                  if (!isSelected) widget.onSelectFrame(frame.id);
                  _setDragging(draggedIds);
                },
                onDragEnd: (_) => _setDragging(const {}),
                feedback: SizedBox(
                  width: (36 * aspectRatio).clamp(24.0, 72.0),
                  height: 36,
                  child: Material(
                    color: Colors.transparent,
                    child: Badge(
                      key: const ValueKey('dragged-frame-count'),
                      isLabelVisible: draggedIds.length > 1,
                      label: Text('${draggedIds.length}'),
                      child: _FrameThumbnail(
                        frame: frame,
                        isSelected: true,
                        isActive: true,
                        width: widget.width,
                        height: widget.height,
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _FrameThumbnail(
                    frame: frame,
                    isSelected: isSelected,
                    isActive: isActive,
                    width: widget.width,
                    height: widget.height,
                  ),
                ),
                child: Tooltip(
                  message: '${frame.name.isNotEmpty ? frame.name : 'Frame ${index + 1}'} (${frame.duration}ms)',
                  waitDuration: const Duration(milliseconds: 600),
                  child: Builder(
                    builder: (itemContext) => GestureDetector(
                      onSecondaryTapUp: (details) => _openMenu(itemContext, frame, details.globalPosition),
                      child: InkWell(
                        onTap: () => widget.onSelectFrame(frame.id),
                        // Touch has no right-click: long-press opens the menu,
                        // which also offers adding the frame to the selection.
                        onLongPress: () {
                          final box = itemContext.findRenderObject() as RenderBox;
                          _openMenu(itemContext, frame, box.localToGlobal(box.size.center(Offset.zero)));
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          clipBehavior: Clip.none,
                          fit: StackFit.expand,
                          children: [
                            thumbnail,
                            if (insertAfter != null)
                              Positioned(
                                key: const ValueKey('frame-insert-marker'),
                                top: 0,
                                bottom: 0,
                                left: insertAfter ? null : -4.5,
                                right: insertAfter ? -4.5 : null,
                                width: 3,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Shows the frame menu at [position]. Actions apply to the selection when
  /// [frame] is part of it, otherwise to [frame] alone.
  Future<void> _openMenu(BuildContext context, AnimationFrame frame, Offset position) async {
    final menu = widget.menu;
    final isSelected = widget.selectedFrameIds.contains(frame.id);
    final ids = isSelected ? widget.selectedFrameIds : {frame.id};
    final count = ids.length;
    final s = Strings.of(context);
    // Frames of another animation can't join this selection.
    final inActiveAnimation = widget.frames.any((f) => f.id == widget.selectedFrameId);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    PopupMenuItem<VoidCallback> item(String key, IconData icon, String label, VoidCallback action) {
      return PopupMenuItem<VoidCallback>(
        key: ValueKey('frame-menu-$key'),
        value: action,
        height: 36,
        child: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 10),
            // Animation names can be long; the menu is at most 280px wide.
            Flexible(
              child: Text(label, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
    }

    final otherStates = menu.states.where((state) => state.id != frame.stateId).toList();
    final action = await showMenu<VoidCallback>(
      context: context,
      position: RelativeRect.fromRect(position & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        if (menu.onToggle != null && inActiveAnimation && !isSelected)
          item('select', Icons.add_box_outlined, 'Add to selection', () => menu.onToggle!(frame.id)),
        if (menu.onToggle != null && isSelected && count > 1)
          item('deselect', Icons.indeterminate_check_box_outlined, 'Remove from selection',
              () => menu.onToggle!(frame.id)),
        item('duplicate', Feather.copy, count > 1 ? 'Duplicate $count frames' : s.copyFrame,
            () => menu.onDuplicate(ids)),
        item('duration', Icons.timer_outlined, 'Set duration…', () async {
          final value = await _promptText(
            context,
            title: count > 1 ? 'Duration of $count frames (ms)' : 'Duration (ms)',
            initial: '${frame.duration}',
            numeric: true,
          );
          final duration = int.tryParse(value ?? '');
          if (duration != null && duration > 0) menu.onDurationChanged(ids, duration);
        }),
        if (menu.onRename != null && count == 1)
          item('rename', Icons.edit_outlined, 'Rename…', () async {
            final name = await _promptText(context, title: 'Rename frame', initial: frame.name);
            if (name != null && name.trim().isNotEmpty) menu.onRename!(frame.id, name.trim());
          }),
        if (menu.onReverse != null && count > 1)
          item('reverse', Icons.swap_horiz, 'Reverse order', () => menu.onReverse!(ids)),
        if (menu.onMoveToState != null)
          for (final state in otherStates) ...[
            item('move-${state.id}', Icons.drive_file_move_outline, 'Move to ${state.name}',
                () => menu.onMoveToState!(ids, state.id, false)),
            item('copy-${state.id}', Icons.copy_all_outlined, 'Copy to ${state.name}',
                () => menu.onMoveToState!(ids, state.id, true)),
          ],
        const PopupMenuDivider(),
        item('delete', Feather.trash, count > 1 ? 'Delete $count frames' : s.deleteFrame, () => menu.onDelete(ids)),
      ],
    );
    action?.call();
  }

  Future<String?> _promptText(
    BuildContext context, {
    required String title,
    required String initial,
    bool numeric = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => _TextPromptDialog(title: title, initial: initial, numeric: numeric),
    );
  }
}

/// A one-field dialog for the frame menu. It owns its controller so the
/// controller outlives the dialog's closing animation.
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({required this.title, required this.initial, required this.numeric});

  final String title;
  final String initial;
  final bool numeric;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: const TextStyle(fontSize: 16)),
      content: TextField(
        key: const ValueKey('frame-menu-input'),
        controller: _controller,
        autofocus: true,
        keyboardType: widget.numeric ? TextInputType.number : TextInputType.text,
        inputFormatters: widget.numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(Strings.of(context).cancel),
        ),
        TextButton(
          key: const ValueKey('frame-menu-confirm'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('OK'),
        ),
      ],
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
  });

  final AnimationFrame frame;
  final bool isSelected;
  final bool isActive;
  final int width;
  final int height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Semantics(
      key: ValueKey(
        'frame-${frame.id}-${isSelected ? 'selected' : 'unselected'}',
      ),
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
                    color: primaryColor.withValues(alpha: isActive ? 0.38 : 0.2),
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
            if (RigBakePlanner.isRigFrame(frame))
              Positioned(
                top: 2,
                left: 2,
                child: Container(
                  key: ValueKey('rig-badge-${frame.id}'),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.accessibility_new, size: 10, color: Colors.white),
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
