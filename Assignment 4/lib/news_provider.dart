import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'model/story.dart';
import 'model/comment.dart';
import 'model/story_type.dart';
import 'database_service.dart';

class NewsProvider {
  static const String baseUrl = 'https://hacker-news.firebaseio.com/v0';
  final DatabaseService _databaseService = DatabaseService();
  
  // Fetch story IDs by type with caching
  Future<List<int>> fetchStoryIds(StoryType storyType) async {
    // First check cache
    final cachedIds = await _databaseService.getCachedStoryIds(storyType);
    if (cachedIds != null) {
      return cachedIds;
    }

    // If not in cache, fetch from API
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/${storyType.apiEndpoint}.json'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final storyIds = data.cast<int>();

        // Cache the story IDs
        await _databaseService.saveStoryIds(storyType, storyIds);

        return storyIds;
      } else {
        throw Exception('Failed to load ${storyType.displayName.toLowerCase()}');
      }
    } catch (e) {
      throw Exception('Error fetching ${storyType.displayName.toLowerCase()}: $e');
    }
  }

  // Fetch multiple stories with caching
  Future<List<Story>> fetchStories(List<int> storyIds) async {
    final stories = <Story>[];

    for (final id in storyIds) {
      try {
        final story = await fetchStory(id);
        stories.add(story);
      } catch (e) {
        // Skip failed stories and continue
        debugPrint('Failed to fetch story $id: $e');
      }
    }

    return stories;
  }

  // Legacy method for backward compatibility
  Future<List<int>> fetchTopStoryIds() async {
    return fetchStoryIds(StoryType.top);
  }
  
  // Fetch story details by ID with caching
  Future<Story> fetchStory(int id) async {
    // First check cache
    final cachedStory = await _databaseService.getCachedStory(id);
    if (cachedStory != null) {
      return cachedStory;
    }

    // If not in cache, fetch from API
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/item/$id.json'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final story = Story.fromJson(data);

        // Cache the story
        await _databaseService.saveStory(story);

        return story;
      } else {
        throw Exception('Failed to load story');
      }
    } catch (e) {
      throw Exception('Error fetching story: $e');
    }
  }
  
  // Fetch comment by ID
  Future<Comment> fetchComment(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/item/$id.json'),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Comment.fromJson(data);
      } else {
        throw Exception('Failed to load comment');
      }
    } catch (e) {
      throw Exception('Error fetching comment: $e');
    }
  }
  
  // Fetch multiple comments for a story
  Future<List<Comment>> fetchComments(List<int> commentIds) async {
    List<Comment> comments = [];
    
    for (int id in commentIds) {
      try {
        final comment = await fetchComment(id);
        comments.add(comment);
      } catch (e) {
        // Skip failed comments and continue
        // In production, use a proper logging framework
        debugPrint('Failed to fetch comment $id: $e');
      }
    }
    
    return comments;
  }
}
