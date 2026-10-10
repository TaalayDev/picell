import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:collection/collection.dart';

import '../../data/models/template.dart';
import '../../pixel/services/template_service.dart';
import '../data.dart';
import 'providers.dart';

/// State class for template management
@immutable
class TemplateState {
  final List<Template> assetTemplates;
  final List<Template> localTemplates;
  final List<Template> apiTemplates;
  final List<Template> allTemplates;
  final List<TemplateCategory> categories;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isLoadingTemplate;
  final String? error;
  final int currentPage;
  final bool hasMorePages;
  final int totalCount;
  final bool apiTemplatesLoaded;

  const TemplateState({
    this.assetTemplates = const [],
    this.localTemplates = const [],
    this.apiTemplates = const [],
    this.allTemplates = const [],
    this.categories = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isLoadingTemplate = false,
    this.error,
    this.currentPage = 1,
    this.hasMorePages = true,
    this.totalCount = 0,
    this.apiTemplatesLoaded = false,
  });

  TemplateState copyWith({
    List<Template>? localTemplates,
    List<Template>? apiTemplates,
    List<Template>? allTemplates,
    List<Template>? assetTemplates,
    List<TemplateCategory>? categories,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isLoadingTemplate,
    String? error,
    int? currentPage,
    bool? hasMorePages,
    int? totalCount,
    bool? apiTemplatesLoaded,
    bool clearError = false,
  }) {
    return TemplateState(
      localTemplates: localTemplates ?? this.localTemplates,
      apiTemplates: apiTemplates ?? this.apiTemplates,
      allTemplates: allTemplates ?? this.allTemplates,
      assetTemplates: assetTemplates ?? this.assetTemplates,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isLoadingTemplate: isLoadingTemplate ?? this.isLoadingTemplate,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      totalCount: totalCount ?? this.totalCount,
      apiTemplatesLoaded: apiTemplatesLoaded ?? this.apiTemplatesLoaded,
    );
  }

  /// Get templates filtered by tab
  List<Template> getTemplatesByTab(TemplateTab tab, {String? currentUserId}) {
    switch (tab) {
      case TemplateTab.local:
        return localTemplates;
      case TemplateTab.community:
        return apiTemplates;
      case TemplateTab.mine:
        // Filter by current user
        return apiTemplates.where((t) => t.createdBy == currentUserId).toList();
      default:
        return allTemplates;
    }
  }

  /// Categories represented by templates in the selected tab.
  List<TemplateCategory> categoriesForTab(TemplateTab tab,
      {String? currentUserId}) {
    final counts = <String, int>{};
    for (final template
        in getTemplatesByTab(tab, currentUserId: currentUserId)) {
      final key = normalizeTemplateCategory(template.category ?? '');
      if (key.isNotEmpty) counts[key] = (counts[key] ?? 0) + 1;
    }
    final available = counts.entries.map((entry) {
      final known = categories
          .where((c) => normalizeTemplateCategory(c.slug) == entry.key);
      final label = known.isNotEmpty
          ? known.first.name
          : entry.key
              .split('-')
              .map((word) =>
                  word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
              .join(' ');
      return TemplateCategory(
          id: known.isNotEmpty ? known.first.id : -1,
          name: label,
          slug: entry.key,
          templateCount: entry.value);
    }).toList();
    available.sort((a, b) => a.name.compareTo(b.name));
    return available;
  }

  /// Filter templates by category and search
  List<Template> filterTemplates(
    List<Template> templates, {
    String? category,
    String? searchQuery,
  }) {
    List<Template> filtered = templates;

    // Apply category filter
    if (category != null && category != 'All') {
      filtered = filtered
          .where((template) =>
              template.category != null &&
              normalizeTemplateCategory(template.category!) ==
                  normalizeTemplateCategory(category))
          .toList();
    }

    // Apply search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((template) {
        return template.name.toLowerCase().contains(query) ||
            (template.description?.toLowerCase().contains(query) ?? false) ||
            (template.tags?.any((tag) => tag.toLowerCase().contains(query)) ??
                false);
      }).toList();
    }

    return filtered;
  }
}

/// Template provider for managing template state and operations
class TemplateNotifier extends StateNotifier<TemplateState> {
  final TemplateService _templateService;
  final Logger _logger = Logger('TemplateNotifier');

  TemplateNotifier(this._templateService) : super(const TemplateState());

  /// Initialize template data
  Future<void> initialize({bool forceRefresh = false}) async {
    if (state.isLoading) return;

    // Don't reload if already loaded unless forced
    if (!forceRefresh && state.allTemplates.isNotEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Load local templates (which includes asset templates as samples) and categories
      final futures = await Future.wait([
        _templateService.loadAssetTemplates(),
        _templateService.getLocalTemplates(),
        _templateService.getTemplateCategories(),
      ]);

      final assetTemplates = futures[0] as List<Template>;
      final localTemplates = futures[1] as List<Template>;
      final categories = futures[2] as List<TemplateCategory>;

      // Start with empty API templates - these will be loaded separately when needed
      final List<Template> apiTemplates = [];
      final allTemplates = [
        ...assetTemplates,
        ...localTemplates,
        ...apiTemplates
      ];

      state = state.copyWith(
        assetTemplates: assetTemplates,
        localTemplates: localTemplates,
        apiTemplates: apiTemplates,
        allTemplates: allTemplates,
        categories: categories,
        isLoading: false,
      );

      await loadInitialApiTemplates();

      _logger.info(
          'Initialized templates: ${localTemplates.length} local, ${apiTemplates.length} API');
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load templates: $error',
      );
      _logger.severe('Error initializing templates: $error');
    }
  }

  /// Load API templates for the first time
  Future<void> loadInitialApiTemplates({
    String? category,
    String? search,
    String sort = 'popular',
    List<String>? tags,
  }) async {
    if (state.apiTemplatesLoaded || state.isLoading) return;

    await loadApiTemplates(
      page: 1,
      limit: 20,
      category: category,
      search: search,
      sort: sort,
      tags: tags,
      append: false,
    );

    state = state.copyWith(apiTemplatesLoaded: true);
  }

  /// Load API templates
  Future<void> loadApiTemplates({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String sort = 'popular',
    List<String>? tags,
    bool append = false,
  }) async {
    if (!append) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final response = await _templateService.getTemplatesFromAPI(
        page: page,
        limit: limit,
        category: category,
        search: search,
        sort: sort,
        tags: tags,
      );

      List<Template> newApiTemplates;
      if (append) {
        newApiTemplates = [...state.apiTemplates, ...response.templates];
      } else {
        newApiTemplates = response.templates;
      }

      final allTemplates = [
        ...state.assetTemplates,
        ...state.localTemplates,
        ...newApiTemplates
      ];

      state = state.copyWith(
        apiTemplates: newApiTemplates,
        allTemplates: allTemplates,
        isLoading: false,
        isLoadingMore: false,
        currentPage: response.page,
        hasMorePages: response.hasMore,
        totalCount: response.total,
      );

      _logger.info(
          'Loaded API templates: ${response.templates.length} new, ${newApiTemplates.length} total');
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Failed to load API templates: $error',
      );
      _logger.severe('Error loading API templates: $error');
    }
  }

  /// Get individual template by ID (new method)
  Future<Template?> getTemplate(int templateId) async {
    if (state.isLoadingTemplate) return null;

    state = state.copyWith(isLoadingTemplate: true, clearError: true);

    try {
      // If not in cache, fetch from API
      final response = await _templateService.getTemplateFromAPI(templateId);

      if (response != null) {
        // Update our API templates cache with the fetched template
        final updatedApiTemplates = [...state.apiTemplates];
        final existingIndex =
            updatedApiTemplates.indexWhere((t) => t.id == templateId);

        if (existingIndex >= 0) {
          updatedApiTemplates[existingIndex] = response;
        } else {
          updatedApiTemplates.add(response);
        }

        // Update allTemplates as well
        final allTemplates = [
          ...state.assetTemplates,
          ...state.localTemplates,
          ...updatedApiTemplates
        ];

        state = state.copyWith(
          apiTemplates: updatedApiTemplates,
          allTemplates: allTemplates,
          isLoadingTemplate: false,
        );

        _logger.info('Fetched and cached template $templateId from API');
        return response;
      }

      state = state.copyWith(isLoadingTemplate: false);
      return null;
    } catch (error) {
      state = state.copyWith(
        isLoadingTemplate: false,
        error: 'Failed to fetch template: $error',
      );
      _logger.severe('Error fetching template $templateId: $error');
      return null;
    }
  }

  /// Save template locally
  Future<bool> saveTemplateLocally(Template template) async {
    try {
      final success = await _templateService.saveTemplateLocally(template);
      if (success) {
        // Update local state
        final updatedLocal = [...state.localTemplates];
        final existingIndex =
            updatedLocal.indexWhere((t) => t.name == template.name);

        if (existingIndex >= 0) {
          updatedLocal[existingIndex] = template;
        } else {
          updatedLocal.add(template);
        }

        final allTemplates = [
          ...state.assetTemplates,
          ...updatedLocal,
          ...state.apiTemplates
        ];

        state = state.copyWith(
          localTemplates: updatedLocal,
          allTemplates: allTemplates,
        );

        _logger.info('Template "${template.name}" saved locally');
      }
      return success;
    } catch (error) {
      state = state.copyWith(error: 'Failed to save template: $error');
      _logger.severe('Error saving template: $error');
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
      final uploadedTemplate = await _templateService.uploadTemplate(
        template,
        description: description,
        category: category,
        tags: tags,
        isPublic: isPublic,
      );

      if (uploadedTemplate != null) {
        // Update API templates
        final updatedApi = [...state.apiTemplates, uploadedTemplate];
        final allTemplates = [
          ...state.assetTemplates,
          ...state.localTemplates,
          ...updatedApi
        ];

        state = state.copyWith(
          apiTemplates: updatedApi,
          allTemplates: allTemplates,
        );

        _logger.info('Template "${template.name}" uploaded successfully');
      }

      return uploadedTemplate;
    } catch (error) {
      state = state.copyWith(error: 'Failed to upload template: $error');
      _logger.severe('Error uploading template: $error');
      return null;
    }
  }

  /// Delete local template
  Future<bool> deleteLocalTemplate(String templateName) async {
    try {
      final success = await _templateService.deleteLocalTemplate(templateName);
      if (success) {
        // Update local state
        final updatedLocal = state.localTemplates
            .where((template) => template.name != templateName)
            .toList();
        final allTemplates = [
          ...state.assetTemplates,
          ...updatedLocal,
          ...state.apiTemplates
        ];

        state = state.copyWith(
          localTemplates: updatedLocal,
          allTemplates: allTemplates,
        );

        _logger.info('Template "$templateName" deleted locally');
      }
      return success;
    } catch (error) {
      state = state.copyWith(error: 'Failed to delete template: $error');
      _logger.severe('Error deleting template: $error');
      return false;
    }
  }

  /// Delete API template (if user owns it)
  Future<bool> deleteApiTemplate(int templateId) async {
    try {
      final template =
          state.apiTemplates.firstWhereOrNull((t) => t.id == templateId);
      if (template?.id != null) {
        final success = await _templateService.deleteApiTemplate(template!.id!);
      }

      // For now, just remove from local state
      final updatedApi = state.apiTemplates
          .where((template) => template.id != templateId)
          .toList();
      final allTemplates = [
        ...state.assetTemplates,
        ...state.localTemplates,
        ...updatedApi
      ];

      state = state.copyWith(
        apiTemplates: updatedApi,
        allTemplates: allTemplates,
      );

      _logger.info('Template "$templateId" removed from API templates');
      return true;
    } catch (error) {
      state = state.copyWith(error: 'Failed to delete API template: $error');
      _logger.severe('Error deleting API template: $error');
      return false;
    }
  }

  /// Convert layer to template
  Future<Template?> convertLayerToTemplate(
    Layer layer,
    int width,
    int height, {
    String? name,
  }) async {
    try {
      final template = await _templateService.convertLayerToTemplate(
        layer,
        width,
        height,
        name: name,
      );
      return template;
    } catch (error) {
      state =
          state.copyWith(error: 'Failed to convert layer to template: $error');
      _logger.severe('Error converting layer to template: $error');
      return null;
    }
  }

  /// Generate unique template name
  Future<String> generateUniqueTemplateName(String baseName) async {
    try {
      return await _templateService.generateUniqueTemplateName(baseName);
    } catch (error) {
      _logger.warning('Failed to generate unique name, using fallback: $error');
      return '$baseName ${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh templates
  Future<void> refresh() async {
    await initialize(forceRefresh: true);
  }

  /// Search templates
  List<Template> searchTemplates(String query,
      {TemplateTab? tab, String? currentUserId}) {
    List<Template> baseTemplates;

    if (tab != null) {
      baseTemplates =
          state.getTemplatesByTab(tab, currentUserId: currentUserId);
    } else {
      baseTemplates = state.allTemplates;
    }

    if (query.isEmpty) return baseTemplates;

    final searchQuery = query.toLowerCase();
    return baseTemplates.where((template) {
      return template.name.toLowerCase().contains(searchQuery) ||
          (template.description?.toLowerCase().contains(searchQuery) ??
              false) ||
          (template.tags
                  ?.any((tag) => tag.toLowerCase().contains(searchQuery)) ??
              false);
    }).toList();
  }
}

/// Provider for template management
final templateProvider =
    StateNotifierProvider<TemplateNotifier, TemplateState>((ref) {
  final templateService = ref.watch(templateServiceProvider);
  return TemplateNotifier(templateService);
});

/// Provider for template categories
final templateCategoriesProvider = Provider<List<TemplateCategory>>((ref) {
  return ref.watch(templateProvider).categories;
});

/// Provider for local templates only
final localTemplatesProvider = Provider<List<Template>>((ref) {
  return ref.watch(templateProvider).localTemplates;
});

/// Provider for API templates only
final apiTemplatesProvider = Provider<List<Template>>((ref) {
  return ref.watch(templateProvider).apiTemplates;
});

/// Provider for all templates
final allTemplatesProvider = Provider<List<Template>>((ref) {
  return ref.watch(templateProvider).allTemplates;
});

/// Provider for template loading state
final templateLoadingProvider = Provider<bool>((ref) {
  return ref.watch(templateProvider).isLoadingTemplate;
});

/// Enum for template tabs
enum TemplateTab { all, local, community, mine }
