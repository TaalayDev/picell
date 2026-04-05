import 'package:flutter/material.dart';

import '../../../pixel/tools/texture_brush_tool.dart';

class TextureBrushPanel extends StatefulWidget {
  final Function(TexturePattern?, BlendMode, bool isFill) onTextureSelected;
  final int? selectedTextureId;
  final BlendMode blendMode;
  final bool isFill;
  final Function(BlendMode)? onBlendModeChanged;
  final Function(bool)? onFillModeChanged;

  const TextureBrushPanel({
    super.key,
    required this.onTextureSelected,
    this.selectedTextureId,
    this.blendMode = BlendMode.srcOver,
    this.isFill = false,
    this.onBlendModeChanged,
    this.onFillModeChanged,
  });

  @override
  State<TextureBrushPanel> createState() => _TextureBrushPanelState();
}

class _TextureBrushPanelState extends State<TextureBrushPanel> {
  List<TexturePattern> _textures = [];
  bool _isLoading = true;

  TexturePattern? _selectedTexture;
  BlendMode _blendMode = BlendMode.srcOver;
  bool _isFill = false;

  @override
  void initState() {
    super.initState();
    _loadTextures();
    _blendMode = widget.blendMode;
    _isFill = widget.isFill;
  }

  @override
  void didUpdateWidget(TextureBrushPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFill != widget.isFill) {
      _isFill = widget.isFill;
    }
    if (oldWidget.blendMode != widget.blendMode) {
      _blendMode = widget.blendMode;
    }
  }

  Future<void> _loadTextures() async {
    try {
      final textures = await TextureManager().getTextures();
      if (mounted) {
        setState(() {
          _textures = textures.isNotEmpty ? textures : TextureManager().getDefaultTextures();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _textures = TextureManager().getDefaultTextures();
          _isLoading = false;
        });
      }
    }
  }

  void _onFillModeToggled(bool value) {
    setState(() {
      _isFill = value;
    });

    // Notify parent of the change
    if (widget.onFillModeChanged != null) {
      widget.onFillModeChanged!(value);
    }

    // If a texture is already selected, update it with the new fill mode
    if (_selectedTexture != null) {
      widget.onTextureSelected(_selectedTexture, widget.blendMode, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.texture,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Texture Brush',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Settings Panel
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Fill Mode Switch
              Row(
                children: [
                  Icon(
                    _isFill ? Icons.format_color_fill : Icons.brush,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fill Mode',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  Switch.adaptive(
                    value: _isFill,
                    onChanged: _onFillModeToggled,
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),

              // Divider between settings
              if (widget.onBlendModeChanged != null) ...[
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 12),
              ],

              // Blend Mode Selector
              if (widget.onBlendModeChanged != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.layers,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Blend Mode',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<BlendMode>(
                          value: _blendMode,
                          onChanged: (BlendMode? newMode) {
                            if (newMode != null) {
                              setState(() {
                                _blendMode = newMode;
                              });
                              widget.onBlendModeChanged!(newMode);
                            }
                          },
                          isDense: true,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                          items: const [
                            DropdownMenuItem(
                              value: BlendMode.srcOver,
                              child: Text('Normal'),
                            ),
                            DropdownMenuItem(
                              value: BlendMode.multiply,
                              child: Text('Multiply'),
                            ),
                            DropdownMenuItem(
                              value: BlendMode.overlay,
                              child: Text('Overlay'),
                            ),
                            DropdownMenuItem(
                              value: BlendMode.screen,
                              child: Text('Screen'),
                            ),
                            DropdownMenuItem(
                              value: BlendMode.softLight,
                              child: Text('Soft Light'),
                            ),
                            DropdownMenuItem(
                              value: BlendMode.hardLight,
                              child: Text('Hard Light'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Texture Grid Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                'Select Texture',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
              ),
              const Spacer(),
              if (_selectedTexture != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedTexture!.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Texture Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: _textures.length,
            itemBuilder: (context, index) {
              final texture = _textures[index];
              final isSelected = texture.id == _selectedTexture?.id;

              return GestureDetector(
                onTap: () => _selectTexture(texture),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                      width: isSelected ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.surface,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Texture preview
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: CustomPaint(
                              painter: TexturePreviewPainter(texture),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),

                      // Texture name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                        child: Text(
                          texture.name,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _selectTexture(TexturePattern texture) async {
    try {
      final textureBrush = await TextureManager().createTextureBrush(
        textureId: texture.id,
        blendMode: _blendMode,
      );

      setState(() {
        _selectedTexture = texture;
      });

      widget.onTextureSelected(texture, _blendMode, _isFill);
    } catch (e) {
      print('Error creating texture brush: $e');
      widget.onTextureSelected(null, _blendMode, _isFill);
    }
  }
}

/// Custom painter for texture preview
class TexturePreviewPainter extends CustomPainter {
  final TexturePattern texture;

  TexturePreviewPainter(this.texture);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Calculate how many times we need to repeat the pattern
    final repeatX = (size.width / texture.width).ceil();
    final repeatY = (size.height / texture.height).ceil();

    final pixelWidth = size.width / (texture.width * repeatX);
    final pixelHeight = size.height / (texture.height * repeatY);

    for (int ry = 0; ry < repeatY; ry++) {
      for (int rx = 0; rx < repeatX; rx++) {
        for (int py = 0; py < texture.height; py++) {
          for (int px = 0; px < texture.width; px++) {
            final pixelValue = texture.getPixel(px, py);

            if (pixelValue != 0) {
              final color = Color(pixelValue);
              if (color.alpha > 0) {
                paint.color = color;

                final rect = Rect.fromLTWH(
                  (rx * texture.width + px) * pixelWidth,
                  (ry * texture.height + py) * pixelHeight,
                  pixelWidth,
                  pixelHeight,
                );

                canvas.drawRect(rect, paint);
              }
            }
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant TexturePreviewPainter oldDelegate) {
    return oldDelegate.texture != texture;
  }
}
