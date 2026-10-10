import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../config/constants.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/subscription_model.dart';
import '../../../data/models/template.dart';
import '../../../l10n/strings.dart';
import 'templates_dialog.dart';

const kMaxPixelWidth = 5024;
const kMaxPixelHeight = 5024;

enum ProjectTemplatePreset {
  tinyIcon,
  smallSprite,
  mediumCharacter,
  largeScene,
  custom,
}

class ProjectTemplate {
  final ProjectTemplatePreset preset;
  final int width;
  final int height;

  ProjectTemplate({
    required this.preset,
    required this.width,
    required this.height,
  });
}

class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key, required this.subscription});

  final UserSubscription subscription;

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final _formKey = GlobalKey<FormState>(debugLabel: 'new-project-form');
  String _projectName = '';
  int _width = 16;
  int _height = 16;
  final _nameController = TextEditingController();

  /// Template the new project is seeded from, if one was picked.
  Template? _template;
  String? _templateError;

  final List<ProjectTemplate> _templates = [
    ProjectTemplate(
      preset: ProjectTemplatePreset.tinyIcon,
      width: 16,
      height: 16,
    ),
    ProjectTemplate(
      preset: ProjectTemplatePreset.smallSprite,
      width: 32,
      height: 32,
    ),
    ProjectTemplate(
      preset: ProjectTemplatePreset.mediumCharacter,
      width: 64,
      height: 64,
    ),
    ProjectTemplate(
      preset: ProjectTemplatePreset.largeScene,
      width: 128,
      height: 128,
    ),
    ProjectTemplate(
      preset: ProjectTemplatePreset.custom,
      width: 32,
      height: 32,
    ),
  ];

  int _selectedTemplateIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTemplate() async {
    await TemplatesDialog.show(context, (template) {
      if (!mounted) return;
      setState(() {
        _template = template;
        _templateError = null;
        _width = template.width;
        _height = template.height;
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = template.name;
        }
      });
    });
  }

  void _clearTemplate() {
    setState(() {
      _template = null;
      _templateError = null;
      if (_selectedTemplateIndex != _templates.length - 1) {
        _width = _templates[_selectedTemplateIndex].width;
        _height = _templates[_selectedTemplateIndex].height;
      }
    });
  }

  Widget _buildTemplatePicker(BuildContext context, int maxCanvasSize) {
    final scheme = Theme.of(context).colorScheme;
    final template = _template;

    if (template == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _pickTemplate,
          icon: const Icon(Octicons.repo_template, size: 18),
          label: Text(Strings.of(context).template),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _templateError != null ? scheme.error : scheme.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(Octicons.repo_template, size: 18, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${template.width}x${template.height}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz, size: 18),
                tooltip: Strings.of(context).template,
                onPressed: _pickTemplate,
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                onPressed: _clearTemplate,
              ),
            ],
          ),
        ),
        if (_templateError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              _templateError!,
              style: TextStyle(color: scheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  String _getTemplateName(BuildContext context, ProjectTemplate template) {
    final s = Strings.of(context);
    final String localizedName;
    switch (template.preset) {
      case ProjectTemplatePreset.tinyIcon:
        localizedName = s.tinyIcon;
        break;
      case ProjectTemplatePreset.smallSprite:
        localizedName = s.smallSprite;
        break;
      case ProjectTemplatePreset.mediumCharacter:
        localizedName = s.mediumCharacter;
        break;
      case ProjectTemplatePreset.largeScene:
        localizedName = s.largeScene;
        break;
      case ProjectTemplatePreset.custom:
        localizedName = s.paletteCustom;
        break;
    }

    if (template.preset == ProjectTemplatePreset.custom) {
      return localizedName;
    }
    return '$localizedName (${template.width}x${template.height})';
  }

  @override
  Widget build(BuildContext context) {
    final maxCanvasSize = widget.subscription.getFeatureLimit<int>(SubscriptionFeature.maxCanvasSize);

    return AlertDialog(
      title: Text(
        Strings.of(context).newProject,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: Strings.of(context).projectName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.create),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return Strings.of(context).projectNameRequired;
                  }
                  return null;
                },
                onSaved: (value) => _projectName = value!,
              ),
              const SizedBox(height: 16),
              // Canvas size comes from the template once one is chosen.
              if (_template == null) _buildPixelArtOptions(context, maxCanvasSize),
              _buildTemplatePicker(context, maxCanvasSize),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text(Strings.of(context).cancel),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text(Strings.of(context).create),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final template = _template;
              if (template != null && !kIsDemo && (template.width > maxCanvasSize || template.height > maxCanvasSize)) {
                setState(() => _templateError = Strings.of(context).planLimitError(maxCanvasSize));
                return;
              }
              Navigator.of(context).pop((
                name: _projectName,
                width: _width,
                height: _height,
                type: ProjectType.pixelArt,
                // Tile-generator fields are not creatable from this dialog.
                tileWidth: null as int?,
                tileHeight: null as int?,
                gridColumns: null as int?,
                gridRows: null as int?,
                template: template,
              ));
            }
          },
        ),
      ],
    );
  }

  Widget _buildPixelArtOptions(BuildContext context, int maxCanvasSize) {
    return Column(
      children: [
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: Strings.of(context).template,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Octicons.repo_template),
          ),
          style: Theme.of(context).textTheme.bodyMedium,
          value: _selectedTemplateIndex,
          items: List.generate(_templates.length, (index) {
            final template = _templates[index];
            return DropdownMenuItem(
              value: index,
              child: Text(_getTemplateName(context, template)),
            );
          }),
          validator: (value) {
            if (value == null) {
              return Strings.of(context).templateRequired;
            }
            // Use the preset's own size: `_width`/`_height` are only written
            // on save, so they can be stale while validating.
            final preset = _templates[value];
            if (!kIsDemo &&
                preset.preset != ProjectTemplatePreset.custom &&
                (preset.width > maxCanvasSize || preset.height > maxCanvasSize)) {
              return Strings.of(context).planLimitError(maxCanvasSize);
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _selectedTemplateIndex = value!;
              if (_selectedTemplateIndex != _templates.length - 1) {
                _width = _templates[_selectedTemplateIndex].width;
                _height = _templates[_selectedTemplateIndex].height;
              }
            });
          },
        ),
        const SizedBox(height: 16),
        if (_selectedTemplateIndex == _templates.length - 1)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: Strings.of(context).width,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.width_normal),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  initialValue: _width.toString(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return Strings.of(context).widthRequired;
                    }
                    int? width = int.tryParse(value);
                    if (width == null || width < 1 || width > kMaxPixelWidth) {
                      return Strings.of(context).widthRangeError(kMaxPixelWidth);
                    }
                    if (!kIsDemo && width > maxCanvasSize) {
                      return Strings.of(context).planLimitError(maxCanvasSize);
                    }
                    return null;
                  },
                  onSaved: (value) => _width = int.parse(value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: Strings.of(context).height,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.height),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  initialValue: _height.toString(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return Strings.of(context).heightRequired;
                    }
                    int? height = int.tryParse(value);
                    if (height == null || height < 1 || height > kMaxPixelHeight) {
                      return Strings.of(context).heightRangeError(kMaxPixelHeight);
                    }
                    if (!kIsDemo && height > maxCanvasSize) {
                      return Strings.of(context).planLimitError(maxCanvasSize);
                    }
                    return null;
                  },
                  onSaved: (value) => _height = int.parse(value!),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
