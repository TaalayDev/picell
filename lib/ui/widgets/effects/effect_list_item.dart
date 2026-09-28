import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../pixel/effects/effect_pack_catalog.dart';
import '../../../pixel/effects/effects.dart';
import '../../../l10n/strings.dart';
import '../../../providers/progression_provider.dart';
import '../../screens/effect_store_screen.dart';
import '../app_icon.dart';
import '../fields/ui_field.dart';
import '../fields/ui_field_builder.dart';
import 'effect_pack_l10n.dart';

/// A layer effect row. Effects from packs the user does not own still render,
/// but their parameters and animation generation stay locked.
class EffectListItem extends ConsumerStatefulWidget {
  final Effect effect;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback? onApply;
  final VoidCallback? onAnimate;
  final bool showDragHandle;
  final bool showRemoveButton;
  final bool showApplyButton;
  final Function(Effect)? onParametersChanged;

  const EffectListItem({
    super.key,
    required this.effect,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onRemove,
    this.onApply,
    this.onAnimate,
    this.showDragHandle = false,
    this.showRemoveButton = true,
    this.showApplyButton = false,
    this.onParametersChanged,
  });

  @override
  ConsumerState<EffectListItem> createState() => _EffectListItemState();
}

class _EffectListItemState extends ConsumerState<EffectListItem> {
  bool _isExpanded = false;
  late Map<String, dynamic> _parameters;

  @override
  void initState() {
    super.initState();
    _parameters = Map<String, dynamic>.from(widget.effect.parameters);
  }

  @override
  void didUpdateWidget(EffectListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.effect != widget.effect) {
      _parameters = Map<String, dynamic>.from(widget.effect.parameters);
    }
  }

  void _updateParameter(String key, dynamic value) {
    setState(() {
      _parameters[key] = value;
    });

    // Create updated effect and notify parent
    if (widget.onParametersChanged != null) {
      final updatedEffect = EffectsManager.createEffect(
        widget.effect.type,
        _parameters,
      );
      widget.onParametersChanged!(updatedEffect);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectColor = widget.effect.getColor(context);
    final effectIcon = widget.effect.getIcon(color: effectColor, size: 18);
    final theme = Theme.of(context);
    final isLocked = !ref.watch(effectAccessProvider(widget.effect.type));
    final fields = isLocked ? const <UIField>[] : widget.effect.getFields();
    final pack = EffectPackCatalog.packIdOf(widget.effect.type);
    void openPack() => EffectStoreScreen.show(context, pack: pack);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: widget.isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: widget.isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: widget.isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          InkWell(
            onTap: widget.onSelect,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: effectColor.withValues(alpha: 0.2),
                    radius: 10,
                    child: effectIcon,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.effect.getName(context),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isLocked)
                    Tooltip(
                      message: Strings.of(context).effectLockedTooltip(pack.localizedName(context)),
                      child: InkWell(
                        key: const ValueKey('locked-effect-badge'),
                        onTap: openPack,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(Icons.lock_outline, size: 16, color: theme.colorScheme.primary),
                        ),
                      ),
                    ),
                  if (fields.isNotEmpty)
                    InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                        ),
                      ),
                    ),

                  InkWell(
                    onTap: isLocked ? openPack : widget.onEdit,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: AppIcon(AppIcons.settings_2, size: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.effect.isAnimation && widget.onAnimate != null)
                    IconButton(
                      onPressed: isLocked ? openPack : widget.onAnimate,
                      tooltip: Strings.of(context).generateAnimation,
                      icon: const Icon(Icons.movie_creation_outlined, size: 18),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (widget.showApplyButton && widget.onApply != null)
                    InkWell(
                      onTap: widget.onApply,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Feather.check_circle,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ),
                  // Remove button
                  if (widget.showRemoveButton)
                    InkWell(
                      onTap: widget.onRemove,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                          size: 16,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
          if (_isExpanded && fields.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: UIFieldBuilder.buildAll(
                  context: context,
                  fields: fields,
                  values: _parameters,
                  onChanged: _updateParameter,
                ),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}
