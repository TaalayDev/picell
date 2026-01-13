import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../data/models/project_model.dart';
import '../../../data/models/subscription_model.dart';
import '../../../l10n/strings.dart';

const kMaxPixelWidth = 5024;
const kMaxPixelHeight = 5024;

class ProjectTemplate {
  final String name;
  final int width;
  final int height;

  ProjectTemplate({
    required this.name,
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
  final _formKey = GlobalKey<FormState>();
  String _projectName = '';
  int _width = 16;
  int _height = 16;
  ProjectType _projectType = ProjectType.pixelArt;

  // Tile size for tile generator
  int _tileWidth = 16;
  int _tileHeight = 16;

  final List<ProjectTemplate> _templates = [
    ProjectTemplate(name: 'Tiny Icon', width: 16, height: 16),
    ProjectTemplate(name: 'Small Sprite', width: 32, height: 32),
    ProjectTemplate(name: 'Medium Character', width: 64, height: 64),
    ProjectTemplate(name: 'Large Scene', width: 128, height: 128),
    ProjectTemplate(name: 'Custom', width: 32, height: 32),
  ];

  int _selectedTemplateIndex = 0;

  String _getTemplateName(ProjectTemplate template) {
    if (template.name == 'Custom') {
      return template.name;
    }
    return '${template.name} (${template.width}x${template.height})';
  }

  @override
  Widget build(BuildContext context) {
    final maxCanvasSize = SubscriptionFeatureConfig.maxCanvasSize[widget.subscription.plan] ?? 64;

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
              // Project Type Selector
              _buildProjectTypeSelector(context),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: Strings.of(context).projectName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.create),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project name';
                  }
                  return null;
                },
                onSaved: (value) => _projectName = value!,
              ),
              const SizedBox(height: 16),
              // Show different options based on project type
              if (_projectType == ProjectType.pixelArt) ...[
                _buildPixelArtOptions(context, maxCanvasSize),
              ] else ...[
                _buildTileGeneratorOptions(context),
              ],
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
              if (_projectType == ProjectType.tileGenerator) {
                // For tile generator, tile size is the project size
                Navigator.of(context).pop((
                  name: _projectName,
                  width: _tileWidth,
                  height: _tileHeight,
                  type: _projectType,
                  tileWidth: _tileWidth,
                  tileHeight: _tileHeight,
                ));
              } else {
                Navigator.of(context).pop((
                  name: _projectName,
                  width: _width,
                  height: _height,
                  type: _projectType,
                  tileWidth: null as int?,
                  tileHeight: null as int?,
                ));
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildProjectTypeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Project Type',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<ProjectType>(
          segments: const [
            ButtonSegment<ProjectType>(
              value: ProjectType.pixelArt,
              label: Text('Pixel Art'),
              icon: Icon(Icons.brush),
            ),
            ButtonSegment<ProjectType>(
              value: ProjectType.tileGenerator,
              label: Text('Tile Generator'),
              icon: Icon(Icons.auto_awesome),
            ),
          ],
          selected: {_projectType},
          onSelectionChanged: (Set<ProjectType> newSelection) {
            setState(() {
              _projectType = newSelection.first;
            });
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
              child: Text(_getTemplateName(template)),
            );
          }),
          validator: (value) {
            if (value == null) {
              return 'Please select a template';
            }
            if (value != _templates.length - 1 && (_width > maxCanvasSize || _height > maxCanvasSize)) {
              return 'Your plan is limited to $maxCanvasSize pixels';
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
                      return 'Enter width';
                    }
                    int? width = int.tryParse(value);
                    if (width == null || width < 1 || width > kMaxPixelWidth) {
                      return 'Width: 1-$kMaxPixelWidth';
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
                      return 'Enter height';
                    }
                    int? height = int.tryParse(value);
                    if (height == null || height < 1 || height > kMaxPixelHeight) {
                      return 'Height: 1-$kMaxPixelHeight';
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

  Widget _buildTileGeneratorOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tile Size',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Width',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.width_normal),
                  suffixText: 'px',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                initialValue: _tileWidth.toString(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  int? width = int.tryParse(value);
                  if (width == null || width < 8 || width > 128) {
                    return '8-128';
                  }
                  return null;
                },
                onSaved: (value) => _tileWidth = int.parse(value!),
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) {
                    setState(() => _tileWidth = parsed);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Height',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.height),
                  suffixText: 'px',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                initialValue: _tileHeight.toString(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  int? height = int.tryParse(value);
                  if (height == null || height < 8 || height > 128) {
                    return '8-128';
                  }
                  return null;
                },
                onSaved: (value) => _tileHeight = int.parse(value!),
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) {
                    setState(() => _tileHeight = parsed);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Generate a ${_tileWidth}×${_tileHeight} tile using procedural generation, then edit it in the pixel editor.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
