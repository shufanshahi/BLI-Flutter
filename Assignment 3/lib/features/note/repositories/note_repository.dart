import '../../../core/database/database_helper.dart';
import '../models/note.dart';

class NoteRepository {
  final DatabaseHelper _databaseHelper;

  NoteRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  // Create a new note
  Future<Note> createNote({
    required String title,
    required String content,
  }) async {
    final now = DateTime.now();
    final note = Note(
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );

    final id = await _databaseHelper.insertNote(note);
    return note.copyWith(id: id);
  }

  // Get all notes
  Future<List<Note>> getAllNotes() async {
    return await _databaseHelper.getAllNotes();
  }

  // Get a note by id
  Future<Note?> getNoteById(int id) async {
    return await _databaseHelper.getNoteById(id);
  }

  // Update an existing note
  Future<Note> updateNote(Note note) async {
    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    await _databaseHelper.updateNote(updatedNote);
    return updatedNote;
  }

  // Delete a note
  Future<bool> deleteNote(int id) async {
    final result = await _databaseHelper.deleteNote(id);
    return result > 0;
  }

  // Search notes
  Future<List<Note>> searchNotes(String query) async {
    if (query.trim().isEmpty) {
      return await getAllNotes();
    }
    return await _databaseHelper.searchNotes(query);
  }

  // Delete all notes (for testing)
  Future<bool> deleteAllNotes() async {
    final result = await _databaseHelper.deleteAllNotes();
    return result >= 0;
  }
}