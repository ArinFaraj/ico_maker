// ignore_for_file: deprecated_member_use

import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ico_dart/ico_dart.dart';
import 'package:image/image.dart' as img;

import '../utils/image_utils.dart';

enum EditorTool {
  pen,
  eraser,
  line,
  rectangle,
  filledRectangle,
  eyeDropper,
  fill,
}

class IconEditor extends StatefulWidget {
  final IconDirectoryEntry entry;
  final Function(Uint8List) onImageUpdated;
  final double zoom;

  const IconEditor({
    super.key,
    required this.entry,
    required this.onImageUpdated,
    this.zoom = 1.0,
  });

  @override
  State<IconEditor> createState() => _IconEditorState();
}

class _IconEditorState extends State<IconEditor> {
  img.Image? _image;
  EditorTool _currentTool = EditorTool.pen;
  Color _currentColor = Colors.black;
  int _penSize = 1;
  bool _isDrawing = false;
  Offset? _lastPosition;
  Offset? _startPosition;

  // Double buffer for drawing operations
  img.Image? _drawBuffer;

  // Color history
  final List<Color> _recentColors = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
  ];

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(IconEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry) {
      _loadImage();
    }
  }

  void _loadImage() {
    _image = ImageUtils.bytesToImage(widget.entry.imageData);
    _drawBuffer = _image != null ? img.Image.from(_image!) : null;
    setState(() {});
  }

  void _updateImage(img.Image newImage) {
    setState(() {
      _image = newImage;
      _drawBuffer = img.Image.from(newImage);
    });

    final pngBytes = ImageUtils.imageToPngBytes(newImage);
    if (pngBytes != null) {
      widget.onImageUpdated(pngBytes);
    }
  }

  void _addToRecentColors(Color color) {
    // Don't add if it's already the most recent
    if (_recentColors.isNotEmpty && _recentColors.first == color) {
      return;
    }

    setState(() {
      // Remove if it exists elsewhere in the list
      _recentColors.remove(color);
      // Add at the beginning
      _recentColors.insert(0, color);
      // Keep only 10 recent colors
      if (_recentColors.length > 10) {
        _recentColors.removeLast();
      }
    });
  }

  // Drawing methods
  void _startDrawing(Offset position) {
    if (_image == null) return;

    final int x = (position.dx / widget.zoom).floor();
    final int y = (position.dy / widget.zoom).floor();

    if (x < 0 || x >= _image!.width || y < 0 || y >= _image!.height) return;

    setState(() {
      _isDrawing = true;
      _lastPosition = position;
      _startPosition = position;

      _drawBuffer ??= img.Image.from(_image!);

      // Apply initial action based on the tool
      switch (_currentTool) {
        case EditorTool.pen:
          _drawPixel(x, y, _currentColor);
          break;
        case EditorTool.eraser:
          _drawPixel(x, y, Colors.transparent);
          break;
        case EditorTool.eyeDropper:
          final color = ImageUtils.getPixelColor(_image!, x, y);
          if (color != null) {
            setState(() {
              _currentColor = color;
              _addToRecentColors(color);
            });
          }
          break;
        case EditorTool.fill:
          _fill(x, y, _currentColor);
          break;
        // For other tools, we'll preview them but apply on end
        case EditorTool.line:
        case EditorTool.rectangle:
        case EditorTool.filledRectangle:
          // Preview will be handled in the draw method
          break;
      }
    });
  }

  void _continueDrawing(Offset position) {
    if (!_isDrawing || _image == null || _lastPosition == null) return;

    final int x = (position.dx / widget.zoom).floor();
    final int y = (position.dy / widget.zoom).floor();

    _drawBuffer ??= img.Image.from(_image!);

    switch (_currentTool) {
      case EditorTool.pen:
        _drawLine(
          (_lastPosition!.dx / widget.zoom).floor(),
          (_lastPosition!.dy / widget.zoom).floor(),
          x,
          y,
          _currentColor,
        );
        break;
      case EditorTool.eraser:
        _drawLine(
          (_lastPosition!.dx / widget.zoom).floor(),
          (_lastPosition!.dy / widget.zoom).floor(),
          x,
          y,
          Colors.transparent,
        );
        break;
      case EditorTool.line:
        // Preview the line
        _previewLine(
          (_startPosition!.dx / widget.zoom).floor(),
          (_startPosition!.dy / widget.zoom).floor(),
          x,
          y,
        );
        break;
      case EditorTool.rectangle:
      case EditorTool.filledRectangle:
        // Preview the rectangle
        _previewRectangle(
          (_startPosition!.dx / widget.zoom).floor(),
          (_startPosition!.dy / widget.zoom).floor(),
          x,
          y,
        );
        break;
      case EditorTool.eyeDropper:
        if (x >= 0 && x < _image!.width && y >= 0 && y < _image!.height) {
          final color = ImageUtils.getPixelColor(_image!, x, y);
          if (color != null) {
            setState(() {
              _currentColor = color;
              _addToRecentColors(color);
            });
          }
        }
        break;
      case EditorTool.fill:
        // Fill is only applied on start/click
        break;
    }

    setState(() {
      _lastPosition = position;
    });
  }

  void _endDrawing() {
    if (!_isDrawing || _image == null) return;

    // For tools that only apply on completion
    if (_startPosition != null && _lastPosition != null) {
      final startX = (_startPosition!.dx / widget.zoom).floor();
      final startY = (_startPosition!.dy / widget.zoom).floor();
      final endX = (_lastPosition!.dx / widget.zoom).floor();
      final endY = (_lastPosition!.dy / widget.zoom).floor();

      switch (_currentTool) {
        case EditorTool.line:
          final newImage = ImageUtils.drawLine(
            _image!,
            startX,
            startY,
            endX,
            endY,
            _currentColor,
            thickness: _penSize,
          );
          _updateImage(newImage);
          break;
        case EditorTool.rectangle:
          final x = startX < endX ? startX : endX;
          final y = startY < endY ? startY : endY;
          final width = (startX - endX).abs() + 1;
          final height = (startY - endY).abs() + 1;

          final newImage = ImageUtils.drawRectangle(
            _image!,
            x,
            y,
            width,
            height,
            _currentColor,
            filled: false,
          );
          _updateImage(newImage);
          break;
        case EditorTool.filledRectangle:
          final x = startX < endX ? startX : endX;
          final y = startY < endY ? startY : endY;
          final width = (startX - endX).abs() + 1;
          final height = (startY - endY).abs() + 1;

          final newImage = ImageUtils.drawRectangle(
            _image!,
            x,
            y,
            width,
            height,
            _currentColor,
            filled: true,
          );
          _updateImage(newImage);
          break;
        default:
          // For tools that apply continuously (pen, eraser)
          // or immediately (eyedropper, fill)
          if (_drawBuffer != null) {
            _updateImage(_drawBuffer!);
          }
          break;
      }
    }

    setState(() {
      _isDrawing = false;
      _lastPosition = null;
      _startPosition = null;
      _drawBuffer = null;
    });
  }

  void _drawPixel(int x, int y, Color color) {
    if (_drawBuffer == null) return;

    // Apply the pen size
    for (int px = x - _penSize ~/ 2; px <= x + _penSize ~/ 2; px++) {
      for (int py = y - _penSize ~/ 2; py <= y + _penSize ~/ 2; py++) {
        if (px >= 0 &&
            px < _drawBuffer!.width &&
            py >= 0 &&
            py < _drawBuffer!.height) {
          _drawBuffer!.setPixel(
            px,
            py,
            img.ColorRgba8(color.red, color.green, color.blue, color.alpha),
          );
        }
      }
    }
  }

  void _drawLine(int x1, int y1, int x2, int y2, Color color) {
    if (_drawBuffer == null) return;

    final updatedBuffer = ImageUtils.drawLine(
      _drawBuffer!,
      x1,
      y1,
      x2,
      y2,
      color,
      thickness: _penSize,
    );

    setState(() {
      _drawBuffer = updatedBuffer;
    });
  }

  void _previewLine(int x1, int y1, int x2, int y2) {
    if (_image == null) return;

    // Create a fresh buffer from the original image
    final previewBuffer = img.Image.from(_image!);

    // Draw the line preview
    final updatedBuffer = ImageUtils.drawLine(
      previewBuffer,
      x1,
      y1,
      x2,
      y2,
      _currentColor,
      thickness: _penSize,
    );

    setState(() {
      _drawBuffer = updatedBuffer;
    });
  }

  void _previewRectangle(int x1, int y1, int x2, int y2) {
    if (_image == null) return;

    // Create a fresh buffer from the original image
    final previewBuffer = img.Image.from(_image!);

    // Normalize rectangle coordinates
    final x = x1 < x2 ? x1 : x2;
    final y = y1 < y2 ? y1 : y2;
    final width = (x1 - x2).abs() + 1;
    final height = (y1 - y2).abs() + 1;

    // Draw the rectangle preview
    final updatedBuffer = ImageUtils.drawRectangle(
      previewBuffer,
      x,
      y,
      width,
      height,
      _currentColor,
      filled: _currentTool == EditorTool.filledRectangle,
    );

    setState(() {
      _drawBuffer = updatedBuffer;
    });
  }

  void _fill(int x, int y, Color targetColor) {
    if (_image == null) return;

    // Get the color at the target position
    final sourceColor = ImageUtils.getPixelColor(_image!, x, y);
    if (sourceColor == null) return;

    // Don't fill if the colors are identical
    if (sourceColor.value == targetColor.value) return;

    // Create working copies
    final newImage = img.Image.from(_image!);
    final width = newImage.width;
    final height = newImage.height;

    // Set for tracking visited pixels
    final visited = <String>{};

    // Queue for flood fill
    final queue = Queue<MapEntry<int, int>>();
    queue.add(MapEntry(x, y));

    // Flood fill algorithm
    while (queue.isNotEmpty) {
      final point = queue.removeFirst();
      final px = point.key;
      final py = point.value;

      // Skip if out of bounds or already visited
      final key = '$px,$py';
      if (px < 0 ||
          px >= width ||
          py < 0 ||
          py >= height ||
          visited.contains(key)) {
        continue;
      }

      // Check if the pixel is the same color as the source
      final pixelColor = ImageUtils.getPixelColor(newImage, px, py);
      if (pixelColor == null || pixelColor.value != sourceColor.value) {
        continue;
      }

      // Set new color and mark as visited
      newImage.setPixel(
        px,
        py,
        img.ColorRgba8(
          targetColor.red,
          targetColor.green,
          targetColor.blue,
          targetColor.alpha,
        ),
      );
      visited.add(key);

      // Add adjacent pixels to queue
      queue.add(MapEntry(px + 1, py));
      queue.add(MapEntry(px - 1, py));
      queue.add(MapEntry(px, py + 1));
      queue.add(MapEntry(px, py - 1));
    }

    _updateImage(newImage);
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withAlpha(isDarkMode ? 120 : 60),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tools
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildToolButton(
                    tool: EditorTool.pen,
                    icon: Icons.edit,
                    tooltip: 'Pen Tool (Draw)',
                  ),
                  _buildToolButton(
                    tool: EditorTool.eraser,
                    icon: Icons.auto_fix_normal,
                    tooltip: 'Eraser Tool',
                  ),
                  _buildToolButton(
                    tool: EditorTool.line,
                    icon: Icons.show_chart,
                    tooltip: 'Line Tool',
                  ),
                  _buildToolButton(
                    tool: EditorTool.rectangle,
                    icon: Icons.crop_square,
                    tooltip: 'Rectangle Tool',
                  ),
                  _buildToolButton(
                    tool: EditorTool.filledRectangle,
                    icon: Icons.crop_din,
                    tooltip: 'Filled Rectangle Tool',
                  ),
                  _buildToolButton(
                    tool: EditorTool.eyeDropper,
                    icon: Icons.colorize,
                    tooltip: 'Color Picker Tool',
                  ),
                  _buildToolButton(
                    tool: EditorTool.fill,
                    icon: Icons.format_color_fill,
                    tooltip: 'Fill Tool',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Color and size controls
              Row(
                children: [
                  // Current color
                  _buildColorIndicator(
                    _currentColor,
                    size: 36,
                    onTap: _showColorPicker,
                    isSelected: true,
                  ),
                  const SizedBox(width: 12),

                  // Recent colors
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children:
                            _recentColors
                                .map(
                                  (color) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: _buildColorIndicator(
                                      color,
                                      size: 30,
                                      onTap:
                                          () => setState(
                                            () => _currentColor = color,
                                          ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Pen size selector
                  Row(
                    children: [
                      const Text('Size: '),
                      DropdownButton<int>(
                        value: _penSize,
                        items:
                            [1, 2, 3, 5, 8]
                                .map(
                                  (size) => DropdownMenuItem<int>(
                                    value: size,
                                    child: Text('$size px'),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _penSize = value);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Image editor area
        Expanded(
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              margin: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // Transparent checkerboard background
                    Container(
                      width: _image!.width * widget.zoom,
                      height: _image!.height * widget.zoom,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomPaint(
                        painter: CheckerboardPainter(
                          squareSize: 10,
                          color1: Colors.grey[300]!,
                          color2: Colors.white,
                        ),
                      ),
                    ),

                    // The image
                    GestureDetector(
                      onPanStart:
                          (details) => _startDrawing(details.localPosition),
                      onPanUpdate:
                          (details) => _continueDrawing(details.localPosition),
                      onPanEnd: (_) => _endDrawing(),
                      child: CustomPaint(
                        painter: ImagePainter(
                          image: _drawBuffer ?? _image!,
                          zoom: widget.zoom,
                        ),
                        size: Size(
                          _image!.width * widget.zoom,
                          _image!.height * widget.zoom,
                        ),
                      ),
                    ),

                    // Grid overlay (optional)
                    if (widget.zoom >= 8)
                      CustomPaint(
                        painter: GridPainter(
                          width: _image!.width,
                          height: _image!.height,
                          zoom: widget.zoom,
                          color: Colors.grey.withAlpha(100),
                        ),
                        size: Size(
                          _image!.width * widget.zoom,
                          _image!.height * widget.zoom,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Status bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: colorScheme.surface,
          child: Row(
            children: [
              Text(
                'Size: ${_image!.width}×${_image!.height} | Zoom: ${widget.zoom.round()}× | Tool: ${_currentTool.name}',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('Help'),
                onPressed: _showHelp,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolButton({
    required EditorTool tool,
    required IconData icon,
    required String tooltip,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _currentTool == tool;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _currentTool = tool),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorIndicator(
    Color color, {
    required double size,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(100),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                  : null,
        ),
        // Show checkerboard for transparent/semi-transparent colors
        child:
            color.alpha < 255
                ? CustomPaint(
                  painter: CheckerboardPainter(
                    squareSize: 4,
                    color1: Colors.grey[300]!,
                    color2: Colors.white,
                  ),
                )
                : null,
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Color'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Basic colors
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Common colors
                      _buildColorPickerItem(Colors.black),
                      _buildColorPickerItem(Colors.white),
                      _buildColorPickerItem(Colors.red),
                      _buildColorPickerItem(Colors.green),
                      _buildColorPickerItem(Colors.blue),
                      _buildColorPickerItem(Colors.yellow),
                      _buildColorPickerItem(Colors.purple),
                      _buildColorPickerItem(Colors.orange),
                      _buildColorPickerItem(Colors.teal),
                      _buildColorPickerItem(Colors.pink),
                      _buildColorPickerItem(Colors.brown),
                      _buildColorPickerItem(Colors.grey),

                      // Transparent
                      _buildColorPickerItem(Colors.transparent),

                      // Semi-transparent black and white
                      _buildColorPickerItem(Colors.black.withAlpha(127)),
                      _buildColorPickerItem(Colors.white.withAlpha(127)),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Text('Recent Colors'),
                  const SizedBox(height: 8),

                  // Recent colors
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _recentColors
                            .map((color) => _buildColorPickerItem(color))
                            .toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildColorPickerItem(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() => _currentColor = color);
        _addToRecentColors(color);
        Navigator.of(context).pop();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey),
        ),
        // Show checkerboard for transparent/semi-transparent colors
        child:
            color.alpha < 255
                ? CustomPaint(
                  painter: CheckerboardPainter(
                    squareSize: 4,
                    color1: Colors.grey[300]!,
                    color2: Colors.white,
                  ),
                )
                : null,
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editor Help'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHelpItem(Icons.edit, 'Pen Tool', 'Draw pixels'),
                  _buildHelpItem(
                    Icons.auto_fix_normal,
                    'Eraser',
                    'Erase pixels (make transparent)',
                  ),
                  _buildHelpItem(
                    Icons.show_chart,
                    'Line Tool',
                    'Draw straight lines',
                  ),
                  _buildHelpItem(
                    Icons.crop_square,
                    'Rectangle',
                    'Draw rectangle outlines',
                  ),
                  _buildHelpItem(
                    Icons.crop_din,
                    'Filled Rectangle',
                    'Draw filled rectangles',
                  ),
                  _buildHelpItem(
                    Icons.colorize,
                    'Color Picker',
                    'Select color from image',
                  ),
                  _buildHelpItem(
                    Icons.format_color_fill,
                    'Fill Tool',
                    'Fill connected area with color',
                  ),
                  const Divider(),
                  _buildHelpItem(
                    Icons.zoom_in,
                    'Zoom',
                    'Use the slider to adjust zoom level',
                  ),
                  _buildHelpItem(
                    Icons.color_lens,
                    'Color',
                    'Click the color box to change color',
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(description, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Painters

class CheckerboardPainter extends CustomPainter {
  final double squareSize;
  final Color color1;
  final Color color2;

  CheckerboardPainter({
    this.squareSize = 10,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    final numSquaresX = (size.width / squareSize).ceil();
    final numSquaresY = (size.height / squareSize).ceil();

    for (int y = 0; y < numSquaresY; y++) {
      for (int x = 0; x < numSquaresX; x++) {
        paint.color = (x + y) % 2 == 0 ? color1 : color2;
        canvas.drawRect(
          Rect.fromLTWH(x * squareSize, y * squareSize, squareSize, squareSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CheckerboardPainter oldDelegate) =>
      oldDelegate.squareSize != squareSize ||
      oldDelegate.color1 != color1 ||
      oldDelegate.color2 != color2;
}

class GridPainter extends CustomPainter {
  final int width;
  final int height;
  final double zoom;
  final Color color;

  GridPainter({
    required this.width,
    required this.height,
    required this.zoom,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..strokeWidth = 1;

    // Draw vertical lines
    for (int x = 0; x <= width; x++) {
      final dx = x * zoom;
      canvas.drawLine(Offset(dx, 0), Offset(dx, height * zoom), paint);
    }

    // Draw horizontal lines
    for (int y = 0; y <= height; y++) {
      final dy = y * zoom;
      canvas.drawLine(Offset(0, dy), Offset(width * zoom, dy), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) =>
      oldDelegate.width != width ||
      oldDelegate.height != height ||
      oldDelegate.zoom != zoom ||
      oldDelegate.color != color;
}

class ImagePainter extends CustomPainter {
  final img.Image image;
  final double zoom;

  ImagePainter({required this.image, required this.zoom});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        if (pixel.a > 0) {
          paint.color = Color.fromARGB(
            pixel.a.toInt(),
            pixel.r.toInt(),
            pixel.g.toInt(),
            pixel.b.toInt(),
          );
          canvas.drawRect(Rect.fromLTWH(x * zoom, y * zoom, zoom, zoom), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(ImagePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.zoom != zoom;
}
