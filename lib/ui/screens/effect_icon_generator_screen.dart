import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/utils/file_utils.dart';
import '../../l10n/strings.dart';
import '../../pixel/effects/effects.dart';
import '../../pixel/services/effect_icon_export_service.dart';
import '../widgets/effects/effects_editor_dialog.dart';
import '../widgets/effects/pixlel_preview_painter.dart';
import '../widgets/notifications/app_notification.dart';

class EffectIconGeneratorScreen extends StatefulWidget {
  const EffectIconGeneratorScreen({super.key});

  @override
  State<EffectIconGeneratorScreen> createState() =>
      _EffectIconGeneratorScreenState();
}

class _EffectIconGeneratorScreenState extends State<EffectIconGeneratorScreen> {
  static const _service = EffectIconExportService();

  late final Map<EffectType, Effect> _effects;
  final _searchController = TextEditingController();
  EffectWorkspace? _workspace;
  int _outputSize = EffectIconExportService.defaultOutputSize;
  bool _exporting = false;
  int _completedExports = 0;
  int _totalExports = 0;

  @override
  void initState() {
    super.initState();
    _effects = {
      for (final type in EffectType.values)
        type: EffectsManager.createEffect(type),
    };
    _searchController.addListener(_refreshSearch);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshSearch)
      ..dispose();
    super.dispose();
  }

  void _refreshSearch() => setState(() {});

  List<Effect> _visibleEffects(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    return [
      for (final effect in _effects.values)
        if ((_workspace == null ||
                EffectCatalog.forType(effect.type).workspace == _workspace) &&
            (query.isEmpty ||
                effect.type.name.toLowerCase().contains(query) ||
                effect.getName(context).toLowerCase().contains(query)))
          effect,
    ];
  }

  String _workspaceLabel(
    BuildContext context,
    EffectWorkspace? workspace,
  ) {
    final strings = Strings.of(context);
    return switch (workspace) {
      null => strings.all,
      EffectWorkspace.filters => strings.effectWorkspaceFilters,
      EffectWorkspace.materials => strings.effectWorkspaceMaterials,
      EffectWorkspace.generators => strings.effectWorkspaceGenerators,
      EffectWorkspace.animation => strings.effectWorkspaceAnimation,
      EffectWorkspace.lighting => strings.effectWorkspaceLighting,
    };
  }

  Future<void> _editEffect(Effect effect) async {
    await showDialog<void>(
      context: context,
      builder: (context) => EffectEditorDialog(
        effect: effect,
        layerWidth: EffectIconExportService.canvasSize,
        layerHeight: EffectIconExportService.canvasSize,
        layerPixels: _service.sourcePixelsFor(effect),
        onEffectUpdated: (updated) {
          setState(() {
            _effects[updated.type] = updated;
          });
        },
      ),
    );
  }

  void _resetEffect(Effect effect) {
    setState(() {
      _effects[effect.type] = EffectsManager.createEffect(effect.type);
    });
  }

  Future<void> _exportEffect(Effect effect) async {
    final strings = Strings.of(context);
    try {
      final asset = await _service.buildAsset(
        effect,
        outputSize: _outputSize,
      );
      if (!mounted) return;
      await FileUtils(context).saveImage(asset.bytes, asset.fileName);
      if (!mounted) return;
      AppNotification.success(
        context,
        '${strings.effectIconExportComplete}: ${asset.fileName}',
      );
    } catch (error) {
      if (!mounted) return;
      AppNotification.error(
        context,
        '${strings.effectIconExportFailed}: $error',
      );
    }
  }

  Future<void> _exportVisible(List<Effect> visibleEffects) async {
    if (_exporting || visibleEffects.isEmpty) return;
    final strings = Strings.of(context);
    setState(() {
      _exporting = true;
      _completedExports = 0;
      _totalExports = visibleEffects.length;
    });

    try {
      final result = await _service.buildArchive(
        visibleEffects,
        outputSize: _outputSize,
        onProgress: (completed, total) {
          if (!mounted) return;
          setState(() {
            _completedExports = completed;
            _totalExports = total;
          });
        },
      );
      if (!mounted) return;
      await FileUtils(context).saveBinaryFile(
        result.bytes,
        'effect-icons-${_outputSize}px.zip',
      );
      if (!mounted) return;
      final failed = result.failures.length;
      final message = '${strings.effectIconExportComplete}: '
          '${result.exportedCount}/${visibleEffects.length}'
          '${failed == 0 ? '' : ' · ${strings.effectIconExportFailed}: $failed'}';
      if (failed == 0) {
        AppNotification.success(context, message);
      } else {
        AppNotification.warning(context, message);
      }
    } catch (error) {
      if (!mounted) return;
      AppNotification.error(
        context,
        '${strings.effectIconExportFailed}: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = Strings.of(context);
    final effects = _visibleEffects(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.effectIconGeneratorTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              key: const ValueKey('export-visible-effect-icons'),
              onPressed: _exporting ? null : () => _exportVisible(effects),
              icon: _exporting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.archive_outlined),
              label: Text(
                _exporting
                    ? '$_completedExports/$_totalExports'
                    : '${strings.effectIconExportVisible} (${effects.length})',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: colors.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.effectIconGeneratorSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 280,
                          child: TextField(
                            key: const ValueKey('effect-icon-search'),
                            controller: _searchController,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: strings.searchEffects,
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: _searchController.clear,
                                    ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        DropdownButton<int>(
                          key: const ValueKey('effect-icon-output-size'),
                          value: _outputSize,
                          items: [
                            for (final size in const [64, 128, 256, 512])
                              DropdownMenuItem(
                                value: size,
                                child: Text(
                                  '${strings.effectIconOutputSize}: '
                                  '$size×$size',
                                ),
                              ),
                          ],
                          onChanged: _exporting
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _outputSize = value);
                                  }
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final workspace in <EffectWorkspace?>[
                            null,
                            ...EffectWorkspace.values,
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label:
                                    Text(_workspaceLabel(context, workspace)),
                                selected: _workspace == workspace,
                                onSelected: (_) {
                                  setState(() => _workspace = workspace);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_exporting)
              LinearProgressIndicator(
                value: _totalExports == 0
                    ? null
                    : _completedExports / _totalExports,
                semanticsLabel: strings.effectIconExporting,
              ),
            Expanded(
              child: effects.isEmpty
                  ? Center(child: Text(strings.noEffectsMatch))
                  : GridView.builder(
                      key: const ValueKey('effect-icon-grid'),
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 270,
                        mainAxisExtent: 330,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: effects.length,
                      itemBuilder: (context, index) {
                        final effect = effects[index];
                        return _EffectIconCard(
                          effect: effect,
                          service: _service,
                          exporting: _exporting,
                          onEdit: () => _editEffect(effect),
                          onReset: () => _resetEffect(effect),
                          onExport: () => _exportEffect(effect),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EffectIconCard extends StatefulWidget {
  const _EffectIconCard({
    required this.effect,
    required this.service,
    required this.exporting,
    required this.onEdit,
    required this.onReset,
    required this.onExport,
  });

  final Effect effect;
  final EffectIconExportService service;
  final bool exporting;
  final VoidCallback onEdit;
  final VoidCallback onReset;
  final VoidCallback onExport;

  @override
  State<_EffectIconCard> createState() => _EffectIconCardState();
}

class _EffectIconCardState extends State<_EffectIconCard> {
  late Future<Uint32List> _preview;

  @override
  void initState() {
    super.initState();
    _preview = widget.service.renderPreview(widget.effect);
  }

  @override
  void didUpdateWidget(covariant _EffectIconCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.effect != widget.effect) {
      _preview = widget.service.renderPreview(widget.effect);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = Strings.of(context);
    final descriptor = EffectCatalog.forType(widget.effect.type);
    final isGenerator = descriptor.role == EffectRole.generator;
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ColoredBox(
              color: colors.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: FutureBuilder<Uint32List>(
                  future: _preview,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Tooltip(
                        message: snapshot.error.toString(),
                        child: Icon(Icons.broken_image_outlined,
                            color: colors.error),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return CustomPaint(
                      painter: PixelPreviewPainter(
                        pixels: snapshot.data!,
                        width: EffectIconExportService.canvasSize,
                        height: EffectIconExportService.canvasSize,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text(
              widget.effect.getName(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _FormatBadge(
                  label: descriptor.isAnimated ? 'GIF' : 'JPG',
                  color: descriptor.isAnimated ? Colors.purple : Colors.blue,
                ),
                _FormatBadge(
                  label: isGenerator
                      ? strings.effectIconEmptySource
                      : strings.effectIconSmileySource,
                  color: isGenerator ? Colors.orange : Colors.green,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: strings.editParameters,
                  onPressed: widget.exporting ? null : widget.onEdit,
                  icon: const Icon(Icons.tune),
                ),
                IconButton(
                  tooltip: strings.reset,
                  onPressed: widget.exporting ? null : widget.onReset,
                  icon: const Icon(Icons.restart_alt),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: widget.exporting ? null : widget.onExport,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: Text(strings.export),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatBadge extends StatelessWidget {
  const _FormatBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
