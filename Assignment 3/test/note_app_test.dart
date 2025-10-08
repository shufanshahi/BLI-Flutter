import 'package:flutter_test/flutter_test.dart';
import 'package:day_3/features/note/models/note.dart';
import 'package:day_3/features/note/repositories/note_repository.dart';
import 'package:day_3/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('Note Taking App Tests', () {
    late NoteRepository noteRepository;

    setUpAll(() {
      // Initialize sqflite for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      noteRepository = NoteRepository();
    });

    test('should create a new note', () async {
      final note = await noteRepository.createNote(
        title: 'Test Note',
        content: 'This is a test note content.',
      );

      expect(note.title, equals('Test Note'));
      expect(note.content, equals('This is a test note content.'));
      expect(note.id, isNotNull);
    });

    test('should retrieve all notes', () async {
      // Create some test notes
      await noteRepository.createNote(
        title: 'Note 1',
        content: 'Content 1',
      );
      await noteRepository.createNote(
        title: 'Note 2',
        content: 'Content 2',
      );

      final notes = await noteRepository.getAllNotes();
      expect(notes.length, greaterThanOrEqualTo(2));
    });

    test('should update an existing note', () async {
      final originalNote = await noteRepository.createNote(
        title: 'Original Title',
        content: 'Original Content',
      );

      final updatedNote = originalNote.copyWith(
        title: 'Updated Title',
        content: 'Updated Content',
      );

      final result = await noteRepository.updateNote(updatedNote);
      expect(result.title, equals('Updated Title'));
      expect(result.content, equals('Updated Content'));
    });

    test('should delete a note', () async {
      final note = await noteRepository.createNote(
        title: 'To Delete',
        content: 'This will be deleted',
      );

      final success = await noteRepository.deleteNote(note.id!);
      expect(success, isTrue);

      final retrievedNote = await noteRepository.getNoteById(note.id!);
      expect(retrievedNote, isNull);
    });

    test('should search notes by title and content', () async {
      await noteRepository.createNote(
        title: 'Flutter Development',
        content: 'Learning Flutter and Dart programming',
      );
      await noteRepository.createNote(
        title: 'Grocery List',
        content: 'Milk, Bread, Flutter magazine',
      );

      final searchResults = await noteRepository.searchNotes('Flutter');
      expect(searchResults.length, equals(2));
    });

    test('Note model should have correct content preview', () {
      final note = Note(
        title: 'Test Note',
        content: 'Line 1\nLine 2\nLine 3\nLine 4',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(note.contentPreview, equals('Line 1\nLine 2...'));
    });
  });
}