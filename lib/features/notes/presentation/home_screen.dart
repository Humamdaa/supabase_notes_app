import 'package:flutter/material.dart';
import 'package:myapp/features/auth/presentation/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/note/note_service.dart';
import '../../../widgets/note_helper.dart';

import 'note_detail_screen.dart';
import 'note_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _data = DataNotes();

  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // READ
  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final result = await _data.read();

    debugPrint('READ SUCCESS: ${result.isSuccess}');
    debugPrint('READ DATA: ${result.data}');
    debugPrint('READ ERROR: ${result.error}');
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _notes = result.data ?? [];
        _error = null;
      } else {
        _error = result.error;
      }
    });
  }

  // CREATE
  Future<void> _createNote() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
    );
    if (changed == true) _load(showSpinner: false);
  }

  // READ one / UPDATE / DELETE happen from the detail page
  Future<void> _openNote(Map<String, dynamic> note) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
    );
    if (changed == true) _load(showSpinner: false);
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Notes',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNote,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New note'),
      ),
      body: _buildBody(scheme),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _MessageView(
        icon: Icons.cloud_off_rounded,
        title: 'Something went wrong',
        message: _error!,
        actionLabel: 'Try again',
        onAction: _load,
      );
    }

    if (_notes.isEmpty) {
      return _MessageView(
        icon: Icons.edit_note_rounded,
        title: 'No notes yet',
        message: 'Tap "New note" to write your first one.',
        actionLabel: 'New note',
        onAction: _createNote,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(showSpinner: false),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: _notes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final note = _notes[index];

          // DELETE (swipe)
          return Dismissible(
            key: ValueKey(note['id']),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => confirmAndDeleteNote(context, _data, note),
            onDismissed: (_) => setState(() => _notes.removeAt(index)),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: scheme.error,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.delete_rounded, color: scheme.onError),
            ),
            child: _NoteCard(
              note: note,
              data: _data,
              onTap: () => _openNote(note),
            ),
          );
        },
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.data,
    required this.onTap,
  });

  final Map<String, dynamic> note;
  final DataNotes data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final title = (note['title'] ?? '') as String;
    final content = (note['content'] ?? '') as String;
    final imagePath = note['image_path'] as String?;
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    final date = formatNoteDate(note['created_at']);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              NoteImage(url: data.getImageUrl(imagePath), height: 150),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'Untitled' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (content.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      date,
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: scheme.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
