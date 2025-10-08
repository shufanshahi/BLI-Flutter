import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sembast/sembast_io.dart';
import 'model/story.dart';
import 'model/story_type.dart';

class DatabaseService {
  static const String _dbName = 'hackernews.db';
  static const String _storiesStoreName = 'stories';
  static const String _storyIdsStoreName = 'story_ids';

  Database? _database;
  final _storiesStore = intMapStoreFactory.store(_storiesStoreName);
  final _storyIdsStore = stringMapStoreFactory.store(_storyIdsStoreName);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDocumentDir.path, _dbName);
    final database = await databaseFactoryIo.openDatabase(dbPath);
    return database;
  }

  // Store story IDs for a specific story type
  Future<void> saveStoryIds(StoryType storyType, List<int> storyIds) async {
    final db = await database;
    final key = _getStoryIdsKey(storyType);
    await _storyIdsStore.record(key).put(db, {'ids': storyIds, 'timestamp': DateTime.now().millisecondsSinceEpoch});
  }

  // Get cached story IDs for a specific story type
  Future<List<int>?> getCachedStoryIds(StoryType storyType) async {
    final db = await database;
    final key = _getStoryIdsKey(storyType);
    final record = await _storyIdsStore.record(key).get(db);

    if (record != null) {
      final timestamp = record['timestamp'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;

      // Cache for 30 minutes
      if (age < 30 * 60 * 1000) {
        final ids = record['ids'];
        if (ids is List) {
          return List<int>.from(ids);
        }
      }
    }
    return null;
  }

  // Store a story
  Future<void> saveStory(Story story) async {
    final db = await database;
    await _storiesStore.record(story.id).put(db, story.toJson());
  }

  // Get a cached story
  Future<Story?> getCachedStory(int id) async {
    final db = await database;
    final record = await _storiesStore.record(id).get(db);

    if (record != null) {
      return Story.fromJson(Map<String, dynamic>.from(record));
    }
    return null;
  }

  // Get multiple cached stories
  Future<List<Story>> getCachedStories(List<int> ids) async {
    final stories = <Story>[];

    for (final id in ids) {
      final story = await getCachedStory(id);
      if (story != null) {
        stories.add(story);
      }
    }

    return stories;
  }

  // Save multiple stories
  Future<void> saveStories(List<Story> stories) async {
    final db = await database;

    await db.transaction((txn) async {
      for (final story in stories) {
        await _storiesStore.record(story.id).put(txn, story.toJson());
      }
    });
  }

  // Get stories for a specific story type and range
  Future<List<Story>> getStoriesForType(StoryType storyType, int startIndex, int count) async {
    final cachedIds = await getCachedStoryIds(storyType);

    if (cachedIds == null || cachedIds.length <= startIndex) {
      return [];
    }

    final endIndex = (startIndex + count).clamp(0, cachedIds.length);
    final idsToFetch = cachedIds.sublist(startIndex, endIndex);

    return await getCachedStories(idsToFetch);
  }

  // Check if we have enough cached stories for the requested range
  Future<bool> hasEnoughCachedStories(StoryType storyType, int startIndex, int count) async {
    final cachedIds = await getCachedStoryIds(storyType);

    if (cachedIds == null) return false;

    final endIndex = startIndex + count;
    return cachedIds.length >= endIndex;
  }

  // Clear old cache (older than specified hours)
  Future<void> clearOldCache(int hours) async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(Duration(hours: hours)).millisecondsSinceEpoch;

    // Clear old story IDs
    final storyIdsRecords = await _storyIdsStore.find(db);
    for (final record in storyIdsRecords) {
      final timestamp = record.value['timestamp'] as int;
      if (timestamp < cutoffTime) {
        await _storyIdsStore.record(record.key).delete(db);
      }
    }
  }

  String _getStoryIdsKey(StoryType storyType) {
    switch (storyType) {
      case StoryType.top:
        return 'top_stories';
      case StoryType.best:
        return 'best_stories';
      case StoryType.newStories:
        return 'new_stories';
    }
  }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}