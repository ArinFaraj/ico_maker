import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

import '../models/ico_editor_model.dart';
import '../utils/file_utils.dart';
import '../utils/image_utils.dart';
import '../widgets/icon_editor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _zoom = 8.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 2,
        title: Row(
          children: [
            Icon(Icons.photo_filter, color: colorScheme.primary),
            const SizedBox(width: 12),
            const Text('ICO Maker'),
          ],
        ),
        actions: [
          _buildActionButton(
            icon: Icons.add,
            label: 'New',
            onPressed: _createNew,
          ),
          _buildActionButton(
            icon: Icons.folder_open,
            label: 'Open',
            onPressed: _openFile,
          ),
          _buildActionButton(
            icon: Icons.save,
            label: 'Save',
            onPressed: _saveFile,
          ),
          _buildActionButton(
            icon: Icons.image,
            label: 'Import',
            onPressed: _importImage,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<IcoEditorModel>(
        builder: (context, model, child) {
          if (!model.hasIcoFile) {
            return _buildEmptyState();
          }

          return Row(
            children: [
              // Left panel - Icon entries list
              Card(
                margin: const EdgeInsets.all(8),
                child: SizedBox(
                  width: 220,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Icon Entries',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${model.entries.length}',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child:
                            model.entries.isEmpty
                                ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'No icon entries yet.\nAdd a new size to get started.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: model.entries.length,
                                  itemBuilder: (context, index) {
                                    final entry = model.entries[index];
                                    final isSelected =
                                        model.selectedEntryIndex == index;

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      color:
                                          isSelected
                                              ? colorScheme.primaryContainer
                                                  .withAlpha(100)
                                              : null,
                                      elevation: isSelected ? 2 : 0,
                                      child: ListTile(
                                        selected: isSelected,
                                        dense: true,
                                        title: Text(
                                          '${entry.width}×${entry.height}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${entry.bitsPerPixel} bits',
                                        ),
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(
                                                  40,
                                                ),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child:
                                              entry.imageData.isNotEmpty
                                                  ? Image.memory(
                                                    entry.imageData,
                                                  )
                                                  : const Icon(
                                                    Icons.broken_image,
                                                    size: 24,
                                                  ),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 20,
                                          ),
                                          tooltip: 'Delete entry',
                                          onPressed: () => _deleteEntry(index),
                                        ),
                                        onTap: () => model.selectEntry(index),
                                      ),
                                    );
                                  },
                                ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            minimumSize: const Size.fromHeight(44),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Size'),
                          onPressed: _addNewEntry,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right panel - Icon editor
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Editor',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            const Text('Zoom:'),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 200,
                              child: Slider(
                                value: _zoom,
                                min: 1.0,
                                max: 32.0,
                                divisions: 31,
                                label: _zoom.round().toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _zoom = value;
                                  });
                                },
                              ),
                            ),
                            Text('${_zoom.round()}×'),
                          ],
                        ),
                      ),

                      // Editor
                      Expanded(
                        child:
                            model.selectedEntry != null
                                ? IconEditor(
                                  entry: model.selectedEntry!,
                                  onImageUpdated:
                                      (imageData) => _updateEntryImage(
                                        model.selectedEntryIndex,
                                        imageData,
                                      ),
                                  zoom: _zoom,
                                )
                                : const Center(
                                  child: Text(
                                    'Select an icon entry to edit or create a new one.',
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Tooltip(
        message: label,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_filter, size: 64, color: colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Welcome to ICO Maker Pro',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Create and edit Windows icon files with multiple sizes and bit depths.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Create New ICO File'),
                    onPressed: _createNew,
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Open Existing File'),
                    onPressed: _openFile,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createNew() async {
    final model = Provider.of<IcoEditorModel>(context, listen: false);
    model.createNew();
  }

  Future<void> _openFile() async {
    final bytes = await FileUtils.openFile(
      allowedExtensions: ['ico'],
      dialogTitle: 'Open ICO File',
    );
    if (!mounted) return;

    if (bytes != null) {
      final model = Provider.of<IcoEditorModel>(context, listen: false);
      try {
        model.loadFromBytes(bytes);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error loading ICO file: $e')));
        }
      }
    }
  }

  Future<void> _saveFile() async {
    final model = Provider.of<IcoEditorModel>(context, listen: false);
    final bytes = model.saveToBytes();

    if (bytes != null) {
      final success = await FileUtils.saveFile(
        bytes,
        fileName: 'icon.ico',
        dialogTitle: 'Save ICO File',
        allowedExtensions: ['ico'],
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ICO file saved successfully')),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save ICO file')),
        );
      }
    }
  }

  Future<void> _importImage() async {
    final bytes = await FileUtils.openFile(
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      dialogTitle: 'Import Image',
    );

    if (bytes != null) {
      try {
        final image = img.decodeImage(bytes);
        if (image != null) {
          _showSizeSelectionDialog(image);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error importing image: $e')));
        }
      }
    }
  }

  void _showSizeSelectionDialog(img.Image image) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        const standardSizes = [16, 24, 32, 48, 64, 128, 256];
        return AlertDialog(
          title: const Text('Select Icon Size'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: ListView(
              children: [
                Text(
                  'Original size: ${image.width}×${image.height}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select standard size:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      standardSizes
                          .map(
                            (size) => ActionChip(
                              avatar: const Icon(
                                Icons.photo_size_select_actual,
                                size: 16,
                              ),
                              label: Text('$size×$size'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _addResizedImage(image, size, size);
                              },
                            ),
                          )
                          .toList(),
                ),
                const Divider(height: 32),
                Text(
                  'Or keep original size:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.photo_size_select_actual),
                  title: Text('${image.width}×${image.height} (original)'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _addResizedImage(image, image.width, image.height);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _addResizedImage(img.Image originalImage, int width, int height) {
    final model = Provider.of<IcoEditorModel>(context, listen: false);

    // Resize image if needed
    final resizedImage =
        (originalImage.width != width || originalImage.height != height)
            ? ImageUtils.resizeImage(originalImage, width, height)
            : originalImage;

    // Create new entry from image
    final entry = model.createEntryFromImage(resizedImage);

    // Add entry to model
    model.addEntry(entry);
  }

  void _addNewEntry() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        const standardSizes = [16, 24, 32, 48, 64, 128, 256];
        return AlertDialog(
          title: const Text('Select Icon Size'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select standard size:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children:
                        standardSizes
                            .map(
                              (size) => InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _createEmptyEntry(size, size);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: colorScheme.outline,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.grid_on),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$size×$size',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _createEmptyEntry(int width, int height) {
    final model = Provider.of<IcoEditorModel>(context, listen: false);

    // Create empty transparent image
    final emptyImage = ImageUtils.createEmptyImage(width, height);

    // Create new entry from image
    final entry = model.createEntryFromImage(emptyImage);

    // Add entry to model
    model.addEntry(entry);
  }

  void _deleteEntry(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Delete Entry'),
              ],
            ),
            content: const Text(
              'Are you sure you want to delete this icon entry?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  final model = Provider.of<IcoEditorModel>(
                    context,
                    listen: false,
                  );
                  model.removeEntry(index);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _updateEntryImage(int index, Uint8List imageData) {
    final model = Provider.of<IcoEditorModel>(context, listen: false);
    model.updateEntryImage(index, imageData);
  }
}
