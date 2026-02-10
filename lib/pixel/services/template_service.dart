import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picell/core/utils.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../../data.dart';
import '../../data/models/template.dart';
import '../../data/repo/template_api_repo.dart';
import '../../core/utils/image_helper.dart';

/// Enhanced service for managing pixel art templates with local storage and API support
class TemplateService {
  TemplateService(this._apiRepo);

  final TemplateAPIRepo _apiRepo;
  final Logger _logger = Logger('TemplateService');

  // Cache for loaded templates
  TemplateCollection? _assetTemplates;
  List<Template> _localTemplates = [];
  List<Template> _apiTemplates = [];
  List<TemplateCategory> _categories = [];
  bool _isAssetLoading = false;
  bool _isLocalLoaded = false;

  /// Get templates, loading them if necessary (backward compatible method)
  Future<TemplateCollection> getTemplates() async {
    await _loadAssetTemplates();
    await _loadLocalTemplates();

    // Combine asset and local templates
    final allTemplates = List<Template>.from([
      ..._assetTemplates?.templates ?? [],
      ..._localTemplates,
    ]);

    return TemplateCollection(templates: allTemplates);
  }

  /// Load templates from assets (enhanced version of original method)
  Future<TemplateCollection> loadTemplates() async {
    return await getTemplates();
  }

  /// Convert a layer to a template
  Future<Template> convertLayerToTemplate(Layer layer, int width, int height, {String? name}) async {
    final templateName = name ?? 'Template ${DateTime.now().millisecondsSinceEpoch}';

    return Template(
      name: templateName,
      width: width,
      height: height,
      pixels: Uint32List.fromList(layer.processedPixels),
      isLocal: true,
    );
  }

  /// Save template locally
  Future<bool> saveTemplateLocally(Template template) async {
    try {
      await _loadLocalTemplates();

      // Check if template with same name already exists
      final existingIndex = _localTemplates.indexWhere((t) => t.name == template.name);

      if (existingIndex >= 0) {
        // Update existing template
        _localTemplates[existingIndex] = template.copyWith(isLocal: true);
      } else {
        // Add new template
        _localTemplates.add(template.copyWith(isLocal: true));
      }

      await _saveLocalTemplates();
      _logger.info('Template "${template.name}" saved locally');
      return true;
    } catch (e) {
      _logger.severe('Error saving template locally: $e');
      return false;
    }
  }

  /// Upload template to server
  Future<Template?> uploadTemplate(
    Template template, {
    String? description,
    String? category,
    List<String> tags = const [],
    bool isPublic = true,
  }) async {
    try {
      // Generate thumbnail for the template
      final thumbnail = await _generateTemplateThumbnail(template);

      final response = await _apiRepo.uploadTemplate(
        name: template.name,
        width: template.width,
        height: template.height,
        pixels: template.pixels,
        description: description,
        category: category,
        tags: tags,
        isPublic: isPublic,
        thumbnailBytes: thumbnail,
      );

      _logger.info('Template "${template.name}" uploaded successfully');
      return response.data ?? template;
    } catch (e) {
      _logger.severe('Error uploading template: $e');
      return template;
    }
  }

  /// Get templates from API with pagination
  Future<TemplatesResponse> getTemplatesFromAPI({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String sort = 'popular',
    List<String>? tags,
  }) async {
    try {
      final response = await _apiRepo.fetchTemplates(
        page: page,
        limit: limit,
        category: category,
        search: search,
        sort: sort,
        tags: tags,
      );

      return response.data!;
    } catch (e) {
      _logger.severe('Error fetching templates from API: $e');
      rethrow;
    }
  }

  Future<Template?> getTemplateFromAPI(int templateId) async {
    try {
      final response = await _apiRepo.fetchTemplate(templateId);
      return response.data?.copyWith(pixels: ImageHelper.fixColorChannels(Uint32List.fromList(response.data!.pixels)));
    } catch (e) {
      _logger.severe('Error fetching template $templateId from API: $e');
      return null;
    }
  }

  /// Get local templates only
  Future<List<Template>> getLocalTemplates() async {
    await _loadLocalTemplates();
    return List.from(_localTemplates);
  }

  /// Delete local template
  Future<bool> deleteLocalTemplate(String templateName) async {
    try {
      await _loadLocalTemplates();

      final initialLength = _localTemplates.length;
      _localTemplates.removeWhere((template) => template.name == templateName);

      if (_localTemplates.length < initialLength) {
        await _saveLocalTemplates();
        _logger.info('Template "$templateName" deleted locally');
        return true;
      }

      return false;
    } catch (e) {
      _logger.severe('Error deleting local template: $e');
      return false;
    }
  }

  /// Create a layer from a template (enhanced version of original method)
  Future<Layer> createLayerFromTemplate({
    required Template template,
    required int projectId,
    required int frameId,
    required int canvasWidth,
    required int canvasHeight,
    String? layerName,
  }) async {
    // Calculate position to center the template on the canvas
    final offsetX = (canvasWidth - template.width) ~/ 2;
    final offsetY = (canvasHeight - template.height) ~/ 2;

    // Create canvas-sized pixel array
    final canvasPixels = Uint32List(canvasWidth * canvasHeight);

    // Place template pixels at calculated offset
    for (int ty = 0; ty < template.height; ty++) {
      for (int tx = 0; tx < template.width; tx++) {
        final templateIndex = ty * template.width + tx;
        if (templateIndex >= template.pixels.length) continue;

        final pixel = template.pixels[templateIndex];
        if (pixel == 0) continue; // Skip transparent pixels

        final canvasX = offsetX + tx;
        final canvasY = offsetY + ty;

        if (canvasX >= 0 && canvasX < canvasWidth && canvasY >= 0 && canvasY < canvasHeight) {
          final canvasIndex = canvasY * canvasWidth + canvasX;
          canvasPixels[canvasIndex] = pixel;
        }
      }
    }

    // Create layer with template data
    final layer = Layer(
      layerId: 0, // Will be assigned by the database
      id: const Uuid().v4(),
      name: layerName ?? template.name,
      pixels: canvasPixels,
      isVisible: true,
      order: 0, // Will be set appropriately when added to frame
    );

    return layer;
  }

  /// Apply template directly to existing layer at specified position (original method preserved)
  Uint32List applyTemplateToLayer({
    required Template template,
    required Uint32List layerPixels,
    required int layerWidth,
    required int layerHeight,
    int? positionX,
    int? positionY,
    bool replacePixels = false,
  }) {
    final newPixels = Uint32List.fromList(layerPixels);

    // Default to center position if not specified
    final offsetX = positionX ?? (layerWidth - template.width) ~/ 2;
    final offsetY = positionY ?? (layerHeight - template.height) ~/ 2;

    for (int ty = 0; ty < template.height; ty++) {
      for (int tx = 0; tx < template.width; tx++) {
        final templateIndex = ty * template.width + tx;
        if (templateIndex >= template.pixels.length) continue;

        final templatePixel = template.pixels[templateIndex];
        if (templatePixel == 0 && !replacePixels) continue; // Skip transparent pixels

        final layerX = offsetX + tx;
        final layerY = offsetY + ty;

        if (layerX >= 0 && layerX < layerWidth && layerY >= 0 && layerY < layerHeight) {
          final layerIndex = layerY * layerWidth + layerX;
          newPixels[layerIndex] = templatePixel;
        }
      }
    }

    return newPixels;
  }

  /// Get template categories
  Future<List<TemplateCategory>> getTemplateCategories() async {
    try {
      final response = await _apiRepo.fetchCategories();
      _categories = response.data!;
      return _categories;
    } catch (e) {
      _logger.warning('Error fetching categories from API: $e');
    }
    // Return default categories if API is not available
    return [
      const TemplateCategory(id: 1, name: 'Characters', slug: 'characters', templateCount: 0),
      const TemplateCategory(id: 2, name: 'Objects', slug: 'objects', templateCount: 0),
      const TemplateCategory(id: 3, name: 'Backgrounds', slug: 'backgrounds', templateCount: 0),
      const TemplateCategory(id: 4, name: 'UI Elements', slug: 'ui-elements', templateCount: 0),
      const TemplateCategory(id: 5, name: 'Tiles', slug: 'tiles', templateCount: 0),
    ];
  }

  /// Get templates by category
  List<Template> getTemplatesByCategory(String category) {
    // For local templates, we might need to implement a simple categorization
    // For now, return all templates
    return _localTemplates;
  }

  /// Search templates
  Future<List<Template>> searchTemplates(String query) async {
    await _loadLocalTemplates();

    final searchQuery = query.toLowerCase();
    return _localTemplates.where((template) {
      return template.name.toLowerCase().contains(searchQuery);
    }).toList();
  }

  /// Load built-in/asset templates
  Future<List<Template>> loadAssetTemplates() async {
    try {
      // Try to load from assets
      final String jsonString = await rootBundle.loadString('assets/data/templates.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      return jsonList.map((json) => Template.fromJson(json).copyWith(isAsset: true)).toList();
    } catch (e) {
      _logger.info('No asset templates found, returning empty list');
      return [];
    }
  }

  /// Check if template name is available locally
  Future<bool> isTemplateNameAvailable(String name) async {
    await _loadLocalTemplates();
    return !_localTemplates.any((template) => template.name == name);
  }

  /// Generate a unique template name
  Future<String> generateUniqueTemplateName(String baseName) async {
    await _loadLocalTemplates();

    String name = baseName;
    int counter = 1;

    while (_localTemplates.any((template) => template.name == name)) {
      name = '$baseName ($counter)';
      counter++;
    }

    return name;
  }

  /// Load asset templates from bundle (enhanced version of original loadTemplates)
  Future<void> _loadAssetTemplates() async {
    if (_assetTemplates != null || _isAssetLoading) {
      // Wait for current loading to complete
      while (_isAssetLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isAssetLoading = true;
    try {
      final String jsonString = await rootBundle.loadString('assets/data/templates.json');
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

      _assetTemplates = TemplateCollection.fromJson(jsonList);
      _logger.info('Loaded ${_assetTemplates!.templates.length} asset templates');

      // Mark asset templates as not local
      final updatedTemplates = _assetTemplates!.templates.map((template) {
        return template.copyWith(isLocal: false);
      }).toList();

      _assetTemplates = TemplateCollection(templates: updatedTemplates);
    } catch (e) {
      _logger.warning('Error loading asset templates: $e');
      // Return empty collection if loading fails
      _assetTemplates = const TemplateCollection(templates: []);
    } finally {
      _isAssetLoading = false;
    }
  }

  /// Load local templates from SharedPreferences
  Future<void> _loadLocalTemplates() async {
    if (_isLocalLoaded) return;

    try {
      final file = File('${(await getApplicationDocumentsDirectory()).path}/local_templates.json');

      if (file.existsSync()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        _localTemplates = jsonList.map((json) => Template.fromJson(json)).toList();

        // Ensure all local templates are marked as local
        _localTemplates = _localTemplates.map((template) {
          return template.copyWith(isLocal: true);
        }).toList();
      } else {
        _localTemplates = [];
      }

      _isLocalLoaded = true;
      _logger.info('Loaded ${_localTemplates.length} local templates');
    } catch (e) {
      _logger.severe('Error loading local templates: $e');
      _localTemplates = [];
      _isLocalLoaded = true;
    }
  }

  /// Save local templates to SharedPreferences
  Future<void> _saveLocalTemplates() async {
    try {
      final jsonString = json.encode(_localTemplates.map((t) => t.toJson()).toList());

      final file = File('${(await getApplicationDocumentsDirectory()).path}/local_templates.json');
      await file.writeAsString(jsonString);

      _logger.info('Saved ${_localTemplates.length} local templates');
    } catch (e) {
      _logger.severe('Error saving local templates: $e');
    }
  }

  /// Generate thumbnail for template
  Future<Uint8List?> _generateTemplateThumbnail(Template template) async {
    try {
      // Create image from template pixels
      final image = await ImageHelper.createImageFromPixels(
        ImageHelper.fixColorChannels(Uint32List.fromList(template.pixels)),
        template.width,
        template.height,
      );

      // Convert to thumbnail size (e.g., 64x64)
      const thumbnailSize = 64;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Calculate scale to fit within thumbnail size
      final scale = thumbnailSize / (template.width > template.height ? template.width : template.height);
      final scaledWidth = (template.width * scale).round();
      final scaledHeight = (template.height * scale).round();

      // Center the image
      final offsetX = (thumbnailSize - scaledWidth) / 2;
      final offsetY = (thumbnailSize - scaledHeight) / 2;

      // Draw scaled image
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, template.width.toDouble(), template.height.toDouble()),
        Rect.fromLTWH(offsetX, offsetY, scaledWidth.toDouble(), scaledHeight.toDouble()),
        Paint()..filterQuality = FilterQuality.none,
      );

      final picture = recorder.endRecording();
      final thumbnailImage = await picture.toImage(thumbnailSize, thumbnailSize);
      final byteData = await thumbnailImage.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      _logger.warning('Error generating template thumbnail: $e');
      return null;
    }
  }

  Future<bool> deleteApiTemplate(int templateId) async {
    try {
      final response = await _apiRepo.deleteTemplate(templateId);
      if (response.success) {
        // Remove from local API templates cache
        _apiTemplates.removeWhere((template) => template.id == templateId);
        _logger.info('Template "$templateId" deleted from API and local cache');
      }
      return response.success;
    } catch (e) {
      _logger.severe('Error deleting API template: $e');
      return false;
    }
  }

  /// Clear all cached data
  void clearCache() {
    _assetTemplates = null;
    _localTemplates.clear();
    _categories.clear();
    _isLocalLoaded = false;
    _isAssetLoading = false;
  }
}
