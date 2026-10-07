import 'package:flutter/material.dart';
import 'package:myapp/features/notes/models/note.dart';

import '../data/note/note_service.dart';
import '../../../widgets/note_helper.dart';
import 'note_editor_screen.dart';

/// Read the full note. Edit and delete are actions in the app bar.
/// Pops with `true` when something changed so Home can refresh.
class NoteDetailScreen extends StatelessWidget {
  NoteDetailScreen({super.key, required this.note});

  final Note note;
  final _data = NoteService();

  // UPDATE
  Future<void> _edit(BuildContext context) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    );
    if (changed == true && context.mounted) Navigator.pop(context, true);
  }

  // DELETE
  Future<void> _delete(BuildContext context) async {
    final deleted = await confirmAndDeleteNote(context, _data, note);
    if (deleted && context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final title = note.title;
    final content = note.content;
    final imagePath = note.imagePath;
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    final date = formatNoteDate(note.createdAt);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _edit(context),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
            onPressed: () => _delete(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: NoteImage(
                      url: _data.getImageUrl(imagePath),
                      height: 240,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                SelectableText(
                  title.isEmpty ? 'Untitled' : title,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    date,
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SelectableText(
                  content.isEmpty ? 'No content.' : content,
                  style: textTheme.bodyLarge?.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
