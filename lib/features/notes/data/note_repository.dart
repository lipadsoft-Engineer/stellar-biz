import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../domain/note_draft.dart';

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(ref.watch(appDatabaseProvider)),
);

final notesProvider = StreamProvider<List<Note>>(
  (ref) => ref.watch(noteRepositoryProvider).watchNotes(),
);

class NoteRepository {
  const NoteRepository(this._database);

  final AppDatabase _database;

  Stream<List<Note>> watchNotes() =>
      (_database.select(_database.notes)..orderBy([
            (note) => OrderingTerm.desc(note.updatedAt),
            (note) => OrderingTerm.desc(note.id),
          ]))
          .watch();

  Future<int> createNote(NoteDraft draft) {
    final content = draft.content.trim();
    if (content.isEmpty) {
      throw const NoteValidationException('Write something for your note.');
    }
    final title = draft.title?.trim();
    final now = DateTime.now();
    return _database
        .into(_database.notes)
        .insert(
          NotesCompanion.insert(
            title: Value(title == null || title.isEmpty ? null : title),
            content: content,
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> updateNote(int id, NoteDraft draft) async {
    final content = draft.content.trim();
    if (content.isEmpty) {
      throw const NoteValidationException('Write something for your note.');
    }
    final title = draft.title?.trim();
    final updated =
        await (_database.update(
          _database.notes,
        )..where((note) => note.id.equals(id))).write(
          NotesCompanion(
            title: Value(title == null || title.isEmpty ? null : title),
            content: Value(content),
            updatedAt: Value(DateTime.now()),
          ),
        );
    if (updated == 0) {
      throw const NoteValidationException('This note no longer exists.');
    }
  }

  Future<void> deleteNote(int id) async {
    final deleted = await (_database.delete(
      _database.notes,
    )..where((note) => note.id.equals(id))).go();
    if (deleted == 0) {
      throw const NoteValidationException('This note no longer exists.');
    }
  }
}
