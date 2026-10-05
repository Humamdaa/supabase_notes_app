import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../features/data/note/note_service.dart';
import '../../../widgets/auth_widgets.dart';
import '../../../widgets/note_helper.dart';

/// Create a note (note == null) or edit an existing one.
/// Also handles picking / replacing / removing the note's image.
/// Pops with `true` when the note was saved.
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.note});

  final Map<String, dynamic>? note;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _data = DataNotes();
  final _picker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  late final String? _originalImagePath;
  String? _imagePath; // image already stored in Supabase
  File? _newImage; // image picked but not uploaded yet

  bool _isSaving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: (widget.note?['title'] ?? '') as String,
    );
    _contentController = TextEditingController(
      text: (widget.note?['content'] ?? '') as String,
    );
    _originalImagePath = widget.note?['image_path'] as String?;
    _imagePath = _originalImagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _newImage = File(picked.path));
  }

  void _removeImage() {
    setState(() {
      _newImage = null;
      _imagePath = null;
    });
  }

  void _showImageSheet() {
    final hasImage = _newImage != null || (_imagePath?.isNotEmpty ?? false);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            if (hasImage)
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: const Text('Remove image'),
                onTap: () {
                  Navigator.pop(ctx);
                  _removeImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  // CREATE / UPDATE (+ UPLOAD IMAGE)
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    String? imagePath = _imagePath;
    String? uploadedPath;

    // 1) Upload the new image first (if any)
    if (_newImage != null) {
      final upload = await _data.uploadImage(_newImage!);
      final path = upload.data;

      if (!upload.success || path == null) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        showAuthSnackBar(context, upload.message, isError: true);
        return;
      }

      uploadedPath = path;
      imagePath = path;
    }

    // 2) Save the note
    final result = _isEditing
        ? await _data.update(
            widget.note!['id'].toString(),
            title,
            content,
            imagePath: imagePath,
          )
        : await _data.create(title, content, imagePath: imagePath);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (result.success) {
      // Clean up the old image if it was replaced or removed
      if (_originalImagePath != null &&
          _originalImagePath!.isNotEmpty &&
          _originalImagePath != imagePath) {
        _data.deleteImage(_originalImagePath!); // best effort
      }

      showAuthSnackBar(context, _isEditing ? 'Note updated' : 'Note created');
      Navigator.pop(context, true);
    } else {
      // Saving failed: don't leave an orphan upload in storage
      if (uploadedPath != null) _data.deleteImage(uploadedPath);
      showAuthSnackBar(context, result.message, isError: true);
    }
  }

  InputDecoration _decoration(
    String label,
    IconData? icon,
    ColorScheme scheme,
  ) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      contentPadding: const EdgeInsets.all(16),
      border: border(Colors.transparent),
      enabledBorder: border(scheme.outlineVariant),
      focusedBorder: border(scheme.primary, 2),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 2),
    );
  }

  Widget _imageSection(ColorScheme scheme) {
    final hasStored = _imagePath != null && _imagePath!.isNotEmpty;

    // No image yet -> "Add image" tile
    if (_newImage == null && !hasStored) {
      return InkWell(
        onTap: _showImageSheet,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant, width: 1.5),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 32,
                color: scheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Add image',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Image preview with change / remove buttons
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          _newImage != null
              ? Image.file(
                  _newImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : NoteImage(url: _data.getImageUrl(_imagePath!), height: 200),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _OverlayButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Change image',
                  onPressed: _showImageSheet,
                ),
                const SizedBox(width: 8),
                _OverlayButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Remove image',
                  onPressed: _removeImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit note' : 'New note',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _imageSection(scheme),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _decoration(
                        'Title',
                        Icons.title_rounded,
                        scheme,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      minLines: 8,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _decoration('Content', null, scheme),
                    ),
                    const SizedBox(height: 28),
                    AuthButton(
                      label: _isEditing ? 'Save changes' : 'Create note',
                      isLoading: _isSaving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}
