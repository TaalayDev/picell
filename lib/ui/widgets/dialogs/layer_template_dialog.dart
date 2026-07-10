import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../data/models/layer.dart';
import '../../../data/models/template.dart';
import '../../../l10n/strings.dart';
import '../../../core/utils/image_helper.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/template_provider.dart';
import '../animated_background.dart';
import '../app_icon.dart';
import 'auth_dialog.dart';

class LayerToTemplateDialog extends HookConsumerWidget {
  final Layer layer;
  final int width;
  final int height;
  final Function(Template template)? onTemplateCreated;

  const LayerToTemplateDialog({
    super.key,
    required this.layer,
    required this.width,
    required this.height,
    this.onTemplateCreated,
  });

  static Future<Template?> show(
    BuildContext context, {
    required Layer layer,
    required int width,
    required int height,
    Function(Template template)? onTemplateCreated,
  }) {
    return showDialog<Template>(
      context: context,
      builder: (context) => LayerToTemplateDialog(
        layer: layer,
        width: width,
        height: height,
        onTemplateCreated: onTemplateCreated,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templateNotifier = ref.read(templateProvider.notifier);
    final authState = ref.watch(authProvider);

    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final selectedCategory = useState<String?>('characters');
    final selectedTags = useState<List<String>>([]);
    final isPublic = useState(true);
    final saveOption = useState<SaveOption>(SaveOption.both);

    final isProcessing = useState(false);
    final errorMessage = useState<String?>(null);
    final previewImage = useState<ui.Image?>(null);

    // Available categories
    final categories = [
      'characters',
      'objects',
      'backgrounds',
      'ui-elements',
      'tiles',
      'effects',
      'decorations',
    ];

    // Available tags
    final availableTags = [
      '8bit',
      '16bit',
      'retro',
      'modern',
      'cute',
      'dark',
      'bright',
      'small',
      'medium',
      'large',
      'animated',
      'static',
      'colorful',
      'monochrome',
      'simple',
      'detailed',
      'fantasy',
      'sci-fi',
    ];

    // Generate preview image
    useEffect(() {
      _generatePreview(layer, previewImage);
      return null;
    }, []);

    // Auto-generate unique name
    useEffect(() {
      _generateUniqueName(context, templateNotifier, nameController);
      return null;
    }, []);

    final size = MediaQuery.sizeOf(context);
    final isSmallScreen = size.width < 500;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: size.width * 0.9,
        height: size.height * 0.8,
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 700,
        ),
        child: AnimatedBackground(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Row(
                  children: [
                    AppIcon(
                      AppIcons.gallery_wide,
                      size: isSmallScreen ? 21 : 28,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      Strings.of(context).createTemplate,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 18 : 24,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: isProcessing.value ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Layer Preview
                      Center(
                        child: Container(
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: _buildLayerPreview(layer, previewImage.value),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Layer Info
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(Strings.of(context).layerNameLabel(layer.name)),
                                Text(Strings.of(context).layerSizeLabel(width, height)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(Strings.of(context).nonTransparentPixels(layer.pixels.where((p) => p != 0).length)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Template Name
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: Strings.of(context).templateName,
                          border: OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.edit),
                        ),
                        enabled: !isProcessing.value,
                      ),

                      const SizedBox(height: 16),

                      // Description
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: Strings.of(context).descriptionOptional,
                          border: OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        maxLines: 3,
                        enabled: !isProcessing.value,
                      ),

                      const SizedBox(height: 16),

                      // Category Selection
                      DropdownButtonFormField<String>(
                        value: selectedCategory.value,
                        decoration: InputDecoration(
                          labelText: Strings.of(context).category,
                          border: OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.category),
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(_formatCategoryName(category)),
                          );
                        }).toList(),
                        onChanged: isProcessing.value ? null : (value) => selectedCategory.value = value,
                      ),

                      const SizedBox(height: 16),

                      // Tags Selection
                      Text(
                        Strings.of(context).tags,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        children: availableTags.map((tag) {
                          final isSelected = selectedTags.value.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: isSelected,
                            onSelected: isProcessing.value
                                ? null
                                : (selected) {
                                    if (selected) {
                                      if (selectedTags.value.length < 5) {
                                        selectedTags.value = [...selectedTags.value, tag];
                                      }
                                    } else {
                                      selectedTags.value = selectedTags.value.where((t) => t != tag).toList();
                                    }
                                  },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Save Options
                      Text(
                        Strings.of(context).saveOptions,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),

                      // Local Save Option
                      RadioListTile<SaveOption>(
                        title: Text(Strings.of(context).saveLocally),
                        subtitle: Text(Strings.of(context).storeOnDeviceOnly),
                        value: SaveOption.local,
                        groupValue: saveOption.value,
                        onChanged: isProcessing.value ? null : (value) => saveOption.value = value!,
                      ),

                      // Upload Option (if signed in)
                      if (authState.isSignedIn) ...[
                        RadioListTile<SaveOption>(
                          title: Text(Strings.of(context).uploadToCloud),
                          subtitle: Text(isPublic.value
                              ? Strings.of(context).shareWithCommunity
                              : Strings.of(context).privateCloudStorage),
                          value: SaveOption.upload,
                          groupValue: saveOption.value,
                          onChanged: isProcessing.value ? null : (value) => saveOption.value = value!,
                        ),

                        // Public/Private toggle for upload
                        if (saveOption.value == SaveOption.upload) ...[
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: Text(Strings.of(context).makePublic),
                            subtitle: Text(isPublic.value
                                ? Strings.of(context).otherUsersCanDiscoverTemplate
                                : Strings.of(context).onlyYouCanAccessTemplate),
                            value: isPublic.value,
                            onChanged: isProcessing.value ? null : (value) => isPublic.value = value,
                          ),
                        ],

                        // Both Option
                        RadioListTile<SaveOption>(
                          title: Text(Strings.of(context).saveLocallyAndUpload),
                          subtitle: Text(Strings.of(context).bestOfBothWorlds),
                          value: SaveOption.both,
                          groupValue: saveOption.value,
                          onChanged: isProcessing.value ? null : (value) => saveOption.value = value!,
                        ),
                      ],

                      // Sign in prompt with button
                      if (!authState.isSignedIn) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.cloud_upload, color: Colors.blue),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          Strings.of(context).signInToUploadTemplates,
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          Strings.of(context).shareTemplatesWithCommunity,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showAuthDialog(context),
                                  icon: const Icon(Feather.user),
                                  label: Text(Strings.of(context).signInWithGoogle),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Error Message
                      if (errorMessage.value != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage.value!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isProcessing.value ? null : () => Navigator.of(context).pop(),
                        child: Text(Strings.of(context).cancel),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isProcessing.value
                            ? null
                            : () => _handleSave(
                                  context,
                                  ref,
                                  layer,
                                  nameController.text.trim(),
                                  descriptionController.text.trim(),
                                  selectedCategory.value,
                                  selectedTags.value,
                                  isPublic.value,
                                  saveOption.value,
                                  isProcessing,
                                  errorMessage,
                                  width,
                                  height,
                                ),
                        icon: isProcessing.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                            isProcessing.value ? Strings.of(context).feedback_sending : Strings.of(context).create),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayerPreview(Layer layer, ui.Image? previewImage) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        // Checkerboard background
        CustomPaint(
          painter: _CheckerboardPainter(),
        ),
        // Layer preview
        if (previewImage != null)
          CustomPaint(
            painter: _LayerPreviewPainter(previewImage),
          )
        else
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  String _formatCategoryName(String category) {
    return category.split('-').map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  Future<void> _generatePreview(Layer layer, ValueNotifier<ui.Image?> previewImage) async {
    try {
      final image = await ImageHelper.createImageFromPixels(
        layer.pixels,
        width,
        height,
      );
      previewImage.value = image;
    } catch (e) {
      debugPrint('Error generating preview: $e');
    }
  }

  Future<void> _generateUniqueName(
    BuildContext context,
    TemplateNotifier templateNotifier,
    TextEditingController nameController,
  ) async {
    try {
      final uniqueName = await templateNotifier.generateUniqueTemplateName(
        Strings.of(context).layerTemplateDefaultName,
      );
      nameController.text = uniqueName;
    } catch (e) {
      debugPrint('Error generating unique name: $e');
    }
  }

  Future<void> _showAuthDialog(BuildContext context) async {
    await AuthDialog.show(
      context,
      title: Strings.of(context).signInToUploadTemplatesTitle,
      subtitle: Strings.of(context).signInToUploadTemplatesSubtitle,
      showSkipOption: true,
    );
  }

  Future<void> _handleSave(
    BuildContext context,
    WidgetRef ref,
    Layer layer,
    String name,
    String description,
    String? category,
    List<String> tags,
    bool isPublic,
    SaveOption saveOption,
    ValueNotifier<bool> isProcessing,
    ValueNotifier<String?> errorMessage,
    int width,
    int height,
  ) async {
    if (name.isEmpty) {
      errorMessage.value = Strings.of(context).pleaseEnterTemplateName;
      return;
    }

    isProcessing.value = true;
    errorMessage.value = null;

    try {
      final templateNotifier = ref.read(templateProvider.notifier);

      // Convert layer to template
      final template = await templateNotifier.convertLayerToTemplate(layer, width, height, name: name);
      if (template == null) {
        errorMessage.value = Strings.of(context).failedToConvertLayerToTemplate;
        isProcessing.value = false;
        return;
      }

      final enhancedTemplate = template.copyWith(
        description: description.isNotEmpty ? description : null,
        category: category,
        tags: tags,
        isPublic: isPublic,
      );

      bool localSaveSuccess = false;
      bool uploadSuccess = false;

      // Save locally
      if (saveOption == SaveOption.local || saveOption == SaveOption.both) {
        localSaveSuccess = await templateNotifier.saveTemplateLocally(enhancedTemplate);
        if (!localSaveSuccess) {
          errorMessage.value = Strings.of(context).failedToSaveTemplateLocally;
          isProcessing.value = false;
          return;
        }
      }

      // Upload to server
      if (saveOption == SaveOption.upload || saveOption == SaveOption.both) {
        final uploadedTemplate = await templateNotifier.uploadTemplate(
          enhancedTemplate,
          description: description.isNotEmpty ? description : null,
          category: category,
          tags: tags,
          isPublic: isPublic,
        );
        uploadSuccess = uploadedTemplate != null;

        if (!uploadSuccess) {
          errorMessage.value = Strings.of(context).failedToUploadTemplateToServer;
          isProcessing.value = false;
          return;
        }
      }

      // Success!
      if (context.mounted) {
        onTemplateCreated?.call(enhancedTemplate);
        Navigator.of(context).pop(enhancedTemplate);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getSuccessMessage(context, saveOption, localSaveSuccess, uploadSuccess)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      errorMessage.value = Strings.of(context).errorCreatingTemplate(e.toString());
    } finally {
      isProcessing.value = false;
    }
  }

  String _getSuccessMessage(BuildContext context, SaveOption saveOption, bool localSaved, bool uploaded) {
    final s = Strings.of(context);
    switch (saveOption) {
      case SaveOption.local:
        return s.templateSavedLocally;
      case SaveOption.upload:
        return s.templateUploadedSuccessfully;
      case SaveOption.both:
        if (localSaved && uploaded) {
          return s.templateSavedAndUploaded;
        } else if (localSaved) {
          return s.templateSavedUploadFailed;
        } else if (uploaded) {
          return s.templateUploadedLocalSaveFailed;
        } else {
          return s.templateCreationFailed;
        }
    }
  }
}

enum SaveOption { local, upload, both }

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 16.0;
    final paint = Paint();
    final rows = (size.height / cellSize).ceil();
    final cols = (size.width / cellSize).ceil();

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final color = (row + col) % 2 == 0 ? const Color(0xFFE0E0E0) : const Color(0xFFF5F5F5);
        paint.color = color;

        canvas.drawRect(
          Rect.fromLTWH(
            col * cellSize,
            row * cellSize,
            cellSize,
            cellSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LayerPreviewPainter extends CustomPainter {
  final ui.Image image;

  _LayerPreviewPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.none;

    // Calculate scale to fit image in available space while maintaining aspect ratio
    final imageAspectRatio = image.width / image.height;
    final containerAspectRatio = size.width / size.height;

    double scale;
    if (imageAspectRatio > containerAspectRatio) {
      scale = size.width / image.width;
    } else {
      scale = size.height / image.height;
    }

    final scaledWidth = image.width * scale;
    final scaledHeight = image.height * scale;

    // Center the image
    final offsetX = (size.width - scaledWidth) / 2;
    final offsetY = (size.height - scaledHeight) / 2;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LayerPreviewPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
