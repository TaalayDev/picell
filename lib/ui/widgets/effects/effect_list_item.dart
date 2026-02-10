import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../pixel/effects/effects.dart';
import '../app_icon.dart';
import '../fields/ui_field_builder.dart';

class EffectListItem extends StatefulWidget {
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
  State<EffectListItem> createState() => _EffectListItemState();
}

class _EffectListItemState extends State<EffectListItem> {
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
    final fields = widget.effect.getFields();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: widget.isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: widget.isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2),
          width: widget.isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: widget.onSelect,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // Icon
                  CircleAvatar(
                    backgroundColor: effectColor.withOpacity(0.2),
                    radius: 10,
                    child: effectIcon,
                  ),
                  const SizedBox(width: 12),
                  // Title
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
                  // Expand button
                  if (fields.isNotEmpty)
                    InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                        ),
                      ),
                    ),

                  // Edit button
                  InkWell(
                    onTap: widget.onEdit,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: AppIcon(AppIcons.settings_2, size: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Apply button
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
          // Expanded parameters section
          if (_isExpanded && fields.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
            ),
        ],
      ),
    );
  }
}
