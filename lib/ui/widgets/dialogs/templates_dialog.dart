import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../core.dart';
import '../../../data/models/subscription_model.dart';
import '../../../data/models/template.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../providers/template_provider.dart';
import '../../screens/subscription_screen.dart';
import '../animated_background.dart';
import '../app_icon.dart';

/// Dialog for selecting and applying templates to the canvas
class TemplatesDialog extends ConsumerStatefulWidget {
  final Function(Template template) onTemplateSelected;

  const TemplatesDialog({
    super.key,
    required this.onTemplateSelected,
  });

  static Future<void> show(BuildContext context, Function(Template template) onTemplateSelected) async {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.9,
            child: TemplatesDialog(onTemplateSelected: onTemplateSelected),
          );
        },
      );
      return;
    }

    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.85,
            constraints: const BoxConstraints(
              maxWidth: 900,
              maxHeight: 700,
              minWidth: 700,
              minHeight: 500,
            ),
            child: TemplatesDialog(onTemplateSelected: onTemplateSelected),
          ),
        );
      },
    );
  }

  @override
  ConsumerState createState() => _TemplatesDialogState();
}

class _TemplatesDialogState extends ConsumerState<TemplatesDialog> {
  late TextEditingController searchController;
  TemplateTab currentTab = TemplateTab.all;
  String? selectedCategory = 'All';
  List<Template> filteredTemplates = [];
  late ScrollController scrollController;
  bool _isLoadingTemplate = false;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    scrollController = ScrollController();

    // Initialize templates on dialog open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(templateProvider.notifier).initialize();
    });

    // Setup scroll listener for pagination
    scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final templateState = ref.read(templateProvider);
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      if (!templateState.isLoadingMore && templateState.hasMorePages && currentTab == TemplateTab.community) {
        ref.read(templateProvider.notifier).loadApiTemplates(
              page: templateState.currentPage + 1,
              append: true,
              category: selectedCategory != 'All' ? selectedCategory : null,
              search: searchController.text.trim().isNotEmpty ? searchController.text.trim() : null,
            );
      }
    }
  }

  void _updateFilteredTemplates() {
    final templateState = ref.read(templateProvider);
    final authState = ref.read(authProvider);

    final baseTemplates = templateState.getTemplatesByTab(
      currentTab,
      currentUserId: authState.apiUser?.id.toString(),
    );

    final filtered = templateState.filterTemplates(
      baseTemplates,
      category: selectedCategory != 'All' ? selectedCategory : null,
      searchQuery: searchController.text.trim().isNotEmpty ? searchController.text.trim() : null,
    );

    setState(() {
      filteredTemplates = filtered;
    });
  }

  /// Handle template selection with cloud template fetching
  Future<void> _handleTemplateSelection(Template template) async {
    // If it's a local template or asset template, select it immediately
    if (template.isLocal || template.isAsset) {
      widget.onTemplateSelected(template);
      Navigator.of(context).pop();
      return;
    }

    // For cloud templates, fetch full data first
    setState(() {
      _isLoadingTemplate = true;
    });

    try {
      // Use template provider to fetch full template data
      final fullTemplate = await ref.read(templateProvider.notifier).getTemplate(template.id!);

      if (fullTemplate != null) {
        widget.onTemplateSelected(fullTemplate);
        Navigator.of(context).pop();
      } else {
        // If fetch failed, show error and use existing template data as fallback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load template details. Using cached data.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        widget.onTemplateSelected(template);
        Navigator.of(context).pop();
      }
    } catch (e) {
      // On error, show message and use existing template data as fallback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading template: $e'),
            backgroundColor: Colors.red,
          ),
        );
        widget.onTemplateSelected(template);
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTemplate = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templateState = ref.watch(templateProvider);
    final authState = ref.watch(authProvider);

    // Update filtered templates when dependencies change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFilteredTemplates();
    });

    return Stack(
      children: [
        AnimatedBackground(
          child: Column(
            children: [
              // Header
              _HeaderWidget(
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 8),

              // Tab Bar
              _TabBarWidget(
                currentTab: currentTab,
                isSignedIn: authState.isSignedIn,
                onTabChanged: (tab) {
                  setState(() {
                    currentTab = tab;
                  });
                },
              ),

              // Search and Filters
              _SearchAndFiltersWidget(
                searchController: searchController,
                categories: templateState.categories,
                selectedCategory: selectedCategory,
                onChanged: () {
                  _updateFilteredTemplates();
                },
                onCategoryChanged: (category) {
                  setState(() {
                    selectedCategory = category;
                  });
                },
              ),

              // Content
              Expanded(
                child: _ContentWidget(
                  currentTab: currentTab,
                  templates: filteredTemplates,
                  isLoading: templateState.isLoading,
                  isLoadingMore: templateState.isLoadingMore,
                  error: templateState.error,
                  scrollController: scrollController,
                  totalCount: templateState.totalCount,
                  onRetry: () => ref.read(templateProvider.notifier).refresh(),
                  currentUserId: authState.apiUser?.id.toString(),
                  onTemplateSelected: _handleTemplateSelection,
                  onDeleteTemplate: (template) => _showDeleteConfirmation(context, template),
                ),
              ),

              // Footer with stats
              _FooterWidget(
                displayedCount: filteredTemplates.length,
                totalCount: templateState.totalCount,
              ),
            ],
          ),
        ),

        // Loading overlay for template fetching
        if (_isLoadingTemplate)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading template...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, Template template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${template.name}"?'),
            const SizedBox(height: 8),
            if (template.isLocal)
              const Text(
                'This template will be permanently removed from your local storage.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              )
            else
              const Text(
                'This template will be removed from the cloud and can\'t be recovered.',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteTemplate(context, template);
    }
  }

  Future<void> _deleteTemplate(BuildContext context, Template template) async {
    final templateNotifier = ref.read(templateProvider.notifier);

    bool success = false;
    if (template.isLocal) {
      success = await templateNotifier.deleteLocalTemplate(template.name);
    } else if (template.id != null) {
      success = await templateNotifier.deleteApiTemplate(template.id!);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Template "${template.name}" deleted successfully'
              : 'Failed to delete template "${template.name}"'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

/// Header widget for the templates dialog
class _HeaderWidget extends StatelessWidget {
  final VoidCallback onClose;

  const _HeaderWidget({
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Row(
        children: [
          AppIcon(
            AppIcons.gallery_wide,
            size: isSmallScreen ? 20 : 28,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Text(
            'Template Gallery',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 16 : 20,
                ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }
}

/// Tab bar widget for switching between template categories
class _TabBarWidget extends StatelessWidget {
  final TemplateTab currentTab;
  final bool isSignedIn;
  final Function(TemplateTab) onTabChanged;

  const _TabBarWidget({
    required this.currentTab,
    required this.isSignedIn,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _TabButton(
            title: 'All Templates',
            tab: TemplateTab.all,
            currentTab: currentTab,
            icon: Feather.grid,
            onTap: onTabChanged,
          ),
          const SizedBox(width: 12),
          _TabButton(
            title: 'Local',
            tab: TemplateTab.local,
            currentTab: currentTab,
            icon: Feather.hard_drive,
            onTap: onTabChanged,
          ),
          const SizedBox(width: 12),
          _TabButton(
            title: 'Community',
            tab: TemplateTab.community,
            currentTab: currentTab,
            icon: Feather.cloud,
            onTap: onTabChanged,
          ),
          if (isSignedIn) ...[
            const SizedBox(width: 12),
            _TabButton(
              title: 'My Templates',
              tab: TemplateTab.mine,
              currentTab: currentTab,
              icon: Feather.user,
              onTap: onTabChanged,
            ),
          ],
        ],
      ),
    );
  }
}

/// Individual tab button widget
class _TabButton extends StatelessWidget {
  final String title;
  final TemplateTab tab;
  final TemplateTab currentTab;
  final IconData icon;
  final Function(TemplateTab) onTap;

  const _TabButton({
    required this.title,
    required this.tab,
    required this.currentTab,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;
    final isSelected = currentTab == tab;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(tab),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color:
                        isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Search and filters widget
class _SearchAndFiltersWidget extends StatelessWidget {
  final TextEditingController searchController;
  final List<TemplateCategory> categories;
  final String? selectedCategory;
  final VoidCallback onChanged;
  final Function(String?) onCategoryChanged;

  const _SearchAndFiltersWidget({
    required this.searchController,
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: searchController,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              hintText: 'Search templates...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        onChanged();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),

          const SizedBox(height: 12),

          // Category filter
          if (categories.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'All',
                    isSelected: selectedCategory == 'All',
                    onTap: () {
                      onCategoryChanged('All');
                      onChanged();
                    },
                  ),
                  const SizedBox(width: 8),
                  ...categories
                      .map((category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _CategoryChip(
                              label: category.name,
                              isSelected: selectedCategory == category.slug,
                              onTap: () {
                                onCategoryChanged(category.slug);
                                onChanged();
                              },
                            ),
                          ))
                      .toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Category filter chip widget
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: isSmallScreen ? 12 : 14,
      ),
    );
  }
}

/// Content widget displaying templates grid or loading/error states
class _ContentWidget extends StatelessWidget {
  final TemplateTab currentTab;
  final List<Template> templates;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final ScrollController scrollController;
  final int totalCount;
  final VoidCallback onRetry;
  final String? currentUserId;
  final Function(Template) onTemplateSelected;
  final Function(Template) onDeleteTemplate;

  const _ContentWidget({
    required this.currentTab,
    required this.templates,
    required this.isLoading,
    required this.isLoadingMore,
    required this.error,
    required this.scrollController,
    required this.totalCount,
    required this.onRetry,
    required this.currentUserId,
    required this.onTemplateSelected,
    required this.onDeleteTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;

    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading templates...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              error!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyStateIcon(currentTab),
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateMessage(currentTab),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Consumer(builder: (context, ref, child) {
              final subscriptionState = ref.watch(subscriptionStateProvider);
              final hasTemplateAccess = subscriptionState.hasFeatureAccess(SubscriptionFeature.templates);

              return GridView.builder(
                controller: scrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isSmallScreen ? 2 : 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                itemCount: templates.length + (isLoadingMore ? 4 : 0),
                itemBuilder: (context, index) {
                  if (index >= templates.length) {
                    return _LoadingPlaceholder();
                  }

                  final template = templates[index];
                  final isLocked = template.isPro && !hasTemplateAccess;

                  return _TemplateCard(
                    template: template,
                    onTap: () => isLocked ? _showUpgradePrompt(context, ref) : onTemplateSelected(template),
                    onDelete: _canDeleteTemplate(template, currentUserId) ? () => onDeleteTemplate(template) : null,
                    isLocked: isLocked,
                  );
                },
              );
            }),
          ),
        ),
        if (isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  void _showUpgradePrompt(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Premium Template', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This template is available in the Pro version.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Pro features include:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Premium templates'),
            Text('• Advanced effects and tools'),
            Text('• Unlimited projects'),
            Text('• Cloud backup'),
            Text('• Priority support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close the templates dialog too
              SubscriptionOfferScreen.show(
                context,
                featurePrompt: SubscriptionFeature.templates,
              );
            },
            icon: const Icon(Icons.upgrade),
            label: const Text('Upgrade to Pro'),
          ),
        ],
      ),
    );
  }

  IconData _getEmptyStateIcon(TemplateTab tab) {
    switch (tab) {
      case TemplateTab.local:
        return Feather.hard_drive;
      case TemplateTab.community:
        return Feather.cloud;
      case TemplateTab.mine:
        return Feather.user;
      case TemplateTab.all:
        return Feather.grid;
    }
  }

  String _getEmptyStateMessage(TemplateTab tab) {
    switch (tab) {
      case TemplateTab.local:
        return 'No local templates found.\nCreate your first template from a layer!';
      case TemplateTab.community:
        return 'No community templates found.\nTry adjusting your search or filters.';
      case TemplateTab.mine:
        return 'You haven\'t uploaded any templates yet.\nShare your creations with the community!';
      case TemplateTab.all:
        return 'No templates found.\nTry adjusting your search or filters.';
    }
  }

  bool _canDeleteTemplate(Template template, String? currentUserId) {
    if (template.isLocal && !template.isAsset) {
      return true;
    }

    // User can delete their own uploaded templates
    if (!template.isLocal && currentUserId != null && template.createdBy == currentUserId) {
      return true;
    }

    return false;
  }
}

/// Loading placeholder widget for grid items
class _LoadingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

/// Footer widget showing template count and info
class _FooterWidget extends StatelessWidget {
  final int displayedCount;
  final int totalCount;

  const _FooterWidget({
    required this.displayedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isSmallScreen)
            Text(
              'Showing $displayedCount${totalCount > 0 ? ' of $totalCount' : ''} templates',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                'Click a template to apply it',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatefulWidget {
  final Template template;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isLocked;

  const _TemplateCard({
    required this.template,
    required this.onTap,
    this.onDelete,
    this.isLocked = false,
  });

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard> {
  ui.Image? _previewImage;
  bool _isLoadingPreview = true;

  @override
  void initState() {
    super.initState();
    _generatePreview();
  }

  Future<void> _generatePreview() async {
    try {
      final image = await ImageHelper.createImageFromPixels(
        widget.template.pixelsAsUint32List,
        widget.template.width,
        widget.template.height,
      );

      if (mounted) {
        setState(() {
          _previewImage = image;
          _isLoadingPreview = false;
        });
      }
    } catch (e) {
      debugPrint('Error generating template preview: $e');
      if (mounted) {
        setState(() {
          _isLoadingPreview = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _previewImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _PreviewWidget(
                          template: widget.template,
                          previewImage: _previewImage,
                          isLoadingPreview: _isLoadingPreview,
                        ),
                      ),

                      // Lock overlay for premium templates
                      if (widget.isLocked) ...[
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Local/Cloud indicators
                      if (!widget.isLocked) ...[
                        if (widget.template.isLocal && !widget.template.isAsset)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Feather.hard_drive, size: 10, color: Colors.white),
                                  SizedBox(width: 2),
                                  Text(
                                    'Local',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (!widget.template.isLocal && !widget.template.isAsset)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Feather.cloud, size: 10, color: Colors.white),
                                  SizedBox(width: 2),
                                  Text(
                                    'Cloud',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],

                      // Pro badge for premium templates
                      if (widget.template.isPro && !widget.isLocked)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.purple, Colors.orange],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 10, color: Colors.white),
                                SizedBox(width: 2),
                                Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Delete button for deletable templates (not shown when locked)
                      if (widget.onDelete != null && !widget.isLocked)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete, size: 16, color: Colors.white),
                              onPressed: widget.onDelete,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Template info
              Text(
                widget.template.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: widget.isLocked ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6) : null,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.template.sizeString,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.isLocked
                              ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)
                              : Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  if (widget.template.category != null)
                    Text(
                      widget.template.categoryDisplayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: widget.isLocked
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                                : Theme.of(context).colorScheme.primary,
                            fontSize: 10,
                          ),
                    ),
                ],
              ),

              // Stats for remote templates
              if (!widget.template.isLocal && widget.template.likeCount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 12,
                      color: widget.isLocked ? Colors.red.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.template.likeCount}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: widget.isLocked
                                ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)
                                : Theme.of(context).colorScheme.outline,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              ],

              // Locked indicator text
              if (widget.isLocked) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to Unlock',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return cardContent;
  }
}

/// Preview widget for template card
class _PreviewWidget extends StatelessWidget {
  final Template template;
  final ui.Image? previewImage;
  final bool isLoadingPreview;

  const _PreviewWidget({
    required this.template,
    required this.previewImage,
    required this.isLoadingPreview,
  });

  @override
  Widget build(BuildContext context) {
    if (template.thumbnailImageUrl != null) {
      return CustomPaint(
        painter: _CheckerboardPainter(),
        child: Image.network(
          template.thumbnailImageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    if (isLoadingPreview) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (previewImage == null) {
      return Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 32,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }

    return CustomPaint(
      painter: _TemplatePreviewPainter(previewImage!),
      child: const SizedBox.expand(),
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const checkerSize = 8.0;
    final paint = Paint();

    for (double y = 0; y < size.height; y += checkerSize) {
      for (double x = 0; x < size.width; x += checkerSize) {
        final isEven = ((x / checkerSize).floor() + (y / checkerSize).floor()) % 2 == 0;
        paint.color = isEven ? const Color(0xFFE0E0E0) : const Color(0xFFF5F5F5);

        canvas.drawRect(
          Rect.fromLTWH(
            x,
            y,
            (x + checkerSize > size.width) ? size.width - x : checkerSize,
            (y + checkerSize > size.height) ? size.height - y : checkerSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for rendering template preview
class _TemplatePreviewPainter extends CustomPainter {
  final ui.Image image;

  _TemplatePreviewPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.none;

    _drawCheckerboard(canvas, size);

    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = _calculateDestRect(size);

    canvas.drawImageRect(image, src, dst, paint);
  }

  void _drawCheckerboard(Canvas canvas, Size size) {
    const checkerSize = 8.0;
    final paint = Paint();

    for (double y = 0; y < size.height; y += checkerSize) {
      for (double x = 0; x < size.width; x += checkerSize) {
        final isEven = ((x / checkerSize).floor() + (y / checkerSize).floor()) % 2 == 0;
        paint.color = isEven ? const Color(0xFFE0E0E0) : const Color(0xFFF5F5F5);

        canvas.drawRect(
          Rect.fromLTWH(
            x,
            y,
            (x + checkerSize > size.width) ? size.width - x : checkerSize,
            (y + checkerSize > size.height) ? size.height - y : checkerSize,
          ),
          paint,
        );
      }
    }
  }

  Rect _calculateDestRect(Size size) {
    final imageAspectRatio = image.width / image.height;
    final containerAspectRatio = size.width / size.height;

    late double width, height, left, top;

    if (imageAspectRatio > containerAspectRatio) {
      width = size.width;
      height = size.width / imageAspectRatio;
      left = 0;
      top = (size.height - height) / 2;
    } else {
      width = size.height * imageAspectRatio;
      height = size.height;
      left = (size.width - width) / 2;
      top = 0;
    }

    return Rect.fromLTWH(left, top, width, height);
  }

  @override
  bool shouldRepaint(covariant _TemplatePreviewPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
