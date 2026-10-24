import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/app_message.dart';
import '../../../core/widgets/bottom_action_button.dart';
import '../data/note_repository.dart';
import '../domain/note_draft.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 18, 14),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.6,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Keep reminders and ideas close at hand',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: notes.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const Center(child: Text('Notes could not be loaded.')),
            data: (items) => items.isEmpty
                ? const _NotesEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) => _NoteCard(
                      note: items[index],
                      onTap: () => _editNote(context, ref, items[index]),
                      onDelete: () => _deleteNote(context, ref, items[index]),
                    ),
                  ),
          ),
        ),
        BottomActionButton(
          label: 'New note',
          icon: Icons.add_rounded,
          onPressed: () => _editNote(context, ref),
        ),
      ],
    );
  }

  Future<void> _editNote(
    BuildContext context,
    WidgetRef ref, [
    Note? note,
  ]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => NoteFormSheet(note: note),
    );
    if (saved == true && context.mounted) {
      showAppMessage(
        context,
        note == null ? 'Note saved.' : 'Note updated.',
        type: AppMessageType.success,
      );
    }
  }

  Future<void> _deleteNote(
    BuildContext context,
    WidgetRef ref,
    Note note,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this note?'),
        content: const Text('This note will be removed from your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(noteRepositoryProvider).deleteNote(note.id);
      if (context.mounted) {
        showAppMessage(context, 'Note deleted.', type: AppMessageType.success);
      }
    } catch (_) {
      if (context.mounted) {
        showAppMessage(
          context,
          'Could not delete this note.',
          type: AppMessageType.error,
        );
      }
    }
  }
}

class NoteFormSheet extends ConsumerStatefulWidget {
  const NoteFormSheet({this.note, super.key});

  final Note? note;

  @override
  ConsumerState<NoteFormSheet> createState() => _NoteFormSheetState();
}

class _NoteFormSheetState extends ConsumerState<NoteFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note?.title ?? '');
    _content = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.note == null ? 'Write a note' : 'Edit note',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                counterText: '',
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _content,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              minLines: 5,
              maxLines: 12,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Your note',
                alignLabelWithHint: true,
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.note == null ? 'Save note' : 'Save changes',
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _save() async {
    if (_content.text.trim().isEmpty) {
      showAppMessage(
        context,
        'Write something for your note.',
        type: AppMessageType.error,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repository = ref.read(noteRepositoryProvider);
      final draft = NoteDraft(title: _title.text, content: _content.text);
      if (widget.note == null) {
        await repository.createNote(draft);
      } else {
        await repository.updateNote(widget.note!.id, draft);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      final message = error is NoteValidationException
          ? error.message
          : 'Could not save this note.';
      if (mounted) {
        showAppMessage(context, message, type: AppMessageType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 13, 8, 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title?.isNotEmpty == true ? note.title! : 'Quick note',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Edited ${_noteDate(note.updatedAt)}',
                    style: const TextStyle(
                      color: AppColors.rose,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Note actions',
              onSelected: (_) => onDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: AppColors.muted,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NotesEmptyState extends StatelessWidget {
  const _NotesEmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sticky_note_2_outlined, size: 44, color: AppColors.rose),
          SizedBox(height: 13),
          Text(
            'A little space for your thoughts',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Save a reminder, an idea, or something to follow up on.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    ),
  );
}

String _noteDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')} ${_noteMonths[value.month - 1]} ${value.year}';

const _noteMonths = [
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
