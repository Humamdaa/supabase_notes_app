import 'package:flutter/material.dart';
import 'package:myapp/features/notes/models/note.dart';

import '../features/notes/data/note/note_service.dart';
import 'auth_widgets.dart';

/// Asks for confirmation, then deletes the note (and its image).
/// Returns true if the note was deleted.
Future<bool> confirmAndDeleteNote(
  BuildContext context,
  NoteService data,
  Note note,
) async {
  final scheme = Theme.of(context).colorScheme;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Icon(Icons.delete_outline_rounded, color: scheme.error, size: 32),
      title: const Text('Delete note?'),
      content: Text(
        '"${note.title}" will be permanently deleted.',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;

  final result = await data.delete(note.id);

  if (result.isSuccess) {
    final imagePath = note.imagePath;
    if (imagePath != null && imagePath.isNotEmpty) {
      await data.deleteImage(imagePath); // best effort
    }
  }

  if (context.mounted) {
    showAuthSnackBar(
      context,
      result.isSuccess
          ? 'Note deleted'
          : result.error ?? 'Failed to delete note',
      isError: !result.isSuccess,
    );
  }

  return result.isSuccess;
}

String formatNoteDate(DateTime value) {
  final date = value.toLocal();

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Network image with loading + error states.
class NoteImage extends StatelessWidget {
  const NoteImage({super.key, required this.url, this.height = 180});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: height,
          color: scheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      },
      errorBuilder: (context, error, stack) => Container(
        height: height,
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined, color: scheme.outline),
      ),
    );
  }
}
