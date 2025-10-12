import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat.dart';

class ChatStorageService {
  static const String _chatsKey = 'stored_chats';
  static const String _currentChatIdKey = 'current_chat_id';

  // Save a chat to storage
  Future<void> saveChat(Chat chat) async {
    final prefs = await SharedPreferences.getInstance();
    final chats = await getAllChats();
    
    // Update existing chat or add new one
    final existingIndex = chats.indexWhere((c) => c.id == chat.id);
    if (existingIndex != -1) {
      chats[existingIndex] = chat;
    } else {
      chats.add(chat);
    }

    // Sort chats by updated date (most recent first)
    chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Convert to JSON and save
    final chatsJson = chats.map((chat) => chat.toJson()).toList();
    await prefs.setString(_chatsKey, json.encode(chatsJson));
  }

  // Get all chats from storage
  Future<List<Chat>> getAllChats() async {
    final prefs = await SharedPreferences.getInstance();
    final chatsString = prefs.getString(_chatsKey);
    
    if (chatsString == null) {
      return [];
    }

    try {
      final chatsList = json.decode(chatsString) as List<dynamic>;
      return chatsList
          .map((chatJson) => Chat.fromJson(chatJson as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return empty list if parsing fails
      return [];
    }
  }

  // Get a specific chat by ID
  Future<Chat?> getChatById(String chatId) async {
    final chats = await getAllChats();
    try {
      return chats.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      return null;
    }
  }

  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    final chats = await getAllChats();
    chats.removeWhere((chat) => chat.id == chatId);
    
    final prefs = await SharedPreferences.getInstance();
    final chatsJson = chats.map((chat) => chat.toJson()).toList();
    await prefs.setString(_chatsKey, json.encode(chatsJson));

    // Clear current chat ID if it's the deleted chat
    final currentChatId = await getCurrentChatId();
    if (currentChatId == chatId) {
      await clearCurrentChatId();
    }
  }

  // Save current chat ID
  Future<void> setCurrentChatId(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentChatIdKey, chatId);
  }

  // Get current chat ID
  Future<String?> getCurrentChatId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentChatIdKey);
  }

  // Clear current chat ID
  Future<void> clearCurrentChatId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentChatIdKey);
  }

  // Get current chat
  Future<Chat?> getCurrentChat() async {
    final currentChatId = await getCurrentChatId();
    if (currentChatId != null) {
      return await getChatById(currentChatId);
    }
    return null;
  }

  // Clear all chats (for testing or reset)
  Future<void> clearAllChats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatsKey);
    await prefs.remove(_currentChatIdKey);
  }

  // Get recent chats (limited number)
  Future<List<Chat>> getRecentChats({int limit = 20}) async {
    final chats = await getAllChats();
    return chats.take(limit).toList();
  }

  // Search chats by name or content
  Future<List<Chat>> searchChats(String query) async {
    if (query.trim().isEmpty) {
      return await getAllChats();
    }

    final chats = await getAllChats();
    final lowercaseQuery = query.toLowerCase();

    return chats.where((chat) {
      // Search in chat name
      if (chat.name.toLowerCase().contains(lowercaseQuery)) {
        return true;
      }

      // Search in message content
      return chat.messages.any((message) =>
          message.content.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Export chats as JSON string (for backup)
  Future<String> exportChats() async {
    final chats = await getAllChats();
    final chatsJson = chats.map((chat) => chat.toJson()).toList();
    return json.encode(chatsJson);
  }

  // Import chats from JSON string (for restore)
  Future<void> importChats(String jsonString) async {
    try {
      final chatsList = json.decode(jsonString) as List<dynamic>;
      final chats = chatsList
          .map((chatJson) => Chat.fromJson(chatJson as Map<String, dynamic>))
          .toList();

      final prefs = await SharedPreferences.getInstance();
      final chatsJson = chats.map((chat) => chat.toJson()).toList();
      await prefs.setString(_chatsKey, json.encode(chatsJson));
    } catch (e) {
      throw Exception('Failed to import chats: $e');
    }
  }
}