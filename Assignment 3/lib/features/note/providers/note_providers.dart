import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import '../repositories/note_repository.dart';

// Provider for the note repository
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

// Provider for all notes
final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(() {
  return NotesNotifier();
});

// Provider for a single note by ID
final noteByIdProvider = FutureProvider.family<Note?, int>((ref, id) async {
  final repository = ref.read(noteRepositoryProvider);
  return await repository.getNoteById(id);
});

// Search provider
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Note>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final repository = ref.read(noteRepositoryProvider);
  return await repository.searchNotes(query);
});

// Notes Notifier for managing the list of notes
class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    final repository = ref.read(noteRepositoryProvider);
    return await repository.getAllNotes();
  }

  // Refresh the notes list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(noteRepositoryProvider);
      final notes = await repository.getAllNotes();
      state = AsyncValue.data(notes);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Add a new note
  Future<Note?> addNote({
    required String title,
    required String content,
  }) async {
    try {
      final repository = ref.read(noteRepositoryProvider);
      final newNote = await repository.createNote(
        title: title,
        content: content,
      );
      
      // Refresh the notes list
      await refresh();
      return newNote;
    } catch (error) {
      // Handle error appropriately
      print('Error adding note: $error');
      return null;
    }
  }

  // Update an existing note
  Future<Note?> updateNote(Note note) async {
    try {
      final repository = ref.read(noteRepositoryProvider);
      final updatedNote = await repository.updateNote(note);
      
      // Refresh the notes list
      await refresh();
      return updatedNote;
    } catch (error) {
      // Handle error appropriately
      print('Error updating note: $error');
      return null;
    }
  }

  // Delete a note
  Future<bool> deleteNote(int id) async {
    try {
      final repository = ref.read(noteRepositoryProvider);
      final success = await repository.deleteNote(id);
      
      if (success) {
        // Refresh the notes list
        await refresh();
      }
      return success;
    } catch (error) {
      // Handle error appropriately
      print('Error deleting note: $error');
      return false;
    }
  }

  // Delete all notes (for testing)
  Future<bool> deleteAllNotes() async {
    try {
      final repository = ref.read(noteRepositoryProvider);
      final success = await repository.deleteAllNotes();
      
      if (success) {
        // Refresh the notes list
        await refresh();
      }
      return success;
    } catch (error) {
      // Handle error appropriately
      print('Error deleting all notes: $error');
      return false;
    }
  }
}