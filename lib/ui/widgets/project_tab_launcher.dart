import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/constants.dart';
import '../../data/models/project_model.dart';
import '../../data/models/subscription_model.dart';
import '../../l10n/strings.dart';
import '../../providers/projects_provider.dart';
import '../../providers/subscription_provider.dart';

class ProjectTabLauncher extends ConsumerStatefulWidget {
  const ProjectTabLauncher({super.key, required this.showDragHandle});

  final bool showDragHandle;

  static Future<Project?> show(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    if (isMobile) {
      return showModalBottomSheet<Project>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: const ProjectTabLauncher(showDragHandle: true),
            ),
          ),
        ),
      );
    }

    return showDialog<Project>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 560,
            maxWidth: 720,
            maxHeight: 640,
          ),
          child: SizedBox(
            width: 720,
            height: MediaQuery.sizeOf(context).height * 0.8,
            child: const ProjectTabLauncher(showDragHandle: false),
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<ProjectTabLauncher> createState() => _ProjectTabLauncherState();
}

class _ProjectTabLauncherState extends ConsumerState<ProjectTabLauncher>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _widthController = TextEditingController(text: '16');
  final _heightController = TextEditingController(text: '16');
  late final TabController _tabController;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    if (_isCreating || !_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);
    try {
      final now = DateTime.now();
      final project = await ref.read(projectsProvider.notifier).addProject(
            Project(
              id: 0,
              name: _nameController.text.trim(),
              width: int.parse(_widthController.text),
              height: int.parse(_heightController.text),
              createdAt: now,
              editedAt: now,
            ),
          );
      if (mounted) Navigator.of(context).pop(project);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.of(context).anErrorOccurred)),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _applySize(int size) {
    _widthController.text = size.toString();
    _heightController.text = size.toString();
  }

  @override
  Widget build(BuildContext context) {
    final strings = Strings.of(context);
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        if (widget.showDragHandle)
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
          child: Row(
            children: [
              Icon(Icons.add_to_photos_outlined, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.openProject,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: strings.close,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.add), text: strings.newProject),
            Tab(icon: const Icon(Icons.folder_open), text: strings.projects),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCreateProject(context),
              _buildProjectList(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateProject(BuildContext context) {
    final strings = Strings.of(context);
    final subscription = ref.watch(subscriptionStateProvider);
    final maxCanvasSize =
        subscription.getFeatureLimit<int>(SubscriptionFeature.maxCanvasSize);

    String? validateDimension(String? value, bool width) {
      if (value == null || value.isEmpty) {
        return width ? strings.widthRequired : strings.heightRequired;
      }
      final dimension = int.tryParse(value);
      const absoluteLimit = 5024;
      if (dimension == null || dimension < 1 || dimension > absoluteLimit) {
        return width
            ? strings.widthRangeError(absoluteLimit)
            : strings.heightRangeError(absoluteLimit);
      }
      if (!kIsDemo && dimension > maxCanvasSize) {
        return strings.planLimitError(maxCanvasSize);
      }
      return null;
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            key: const ValueKey('project-tab-new-name'),
            controller: _nameController,
            autofocus: !widget.showDragHandle,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: strings.projectName,
              prefixIcon: const Icon(Icons.edit_outlined),
              border: const OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? strings.projectNameRequired
                : null,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final size in const [16, 32, 64, 128])
                ActionChip(
                  label: Text('$size × $size'),
                  onPressed: () => _applySize(size),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  key: const ValueKey('project-tab-new-width'),
                  controller: _widthController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: strings.width,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => validateDimension(value, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: const ValueKey('project-tab-new-height'),
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: strings.height,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => validateDimension(value, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: const ValueKey('project-tab-create'),
              onPressed: _isCreating ? null : _createProject,
              icon: _isCreating
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(strings.create),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList(BuildContext context) {
    final strings = Strings.of(context);
    final projects = ref.watch(projectsProvider);

    return projects.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(strings.errorLoadingProjects),
      ),
      data: (items) => items.isEmpty
          ? Center(child: Text(strings.noProjectsYet))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final project = items[index];
                return ListTile(
                  key: ValueKey('project-tab-picker-${project.id}'),
                  leading: const Icon(Icons.image_outlined),
                  title: Text(project.name),
                  subtitle: Text('${project.width} × ${project.height}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pop(project),
                );
              },
            ),
    );
  }
}
