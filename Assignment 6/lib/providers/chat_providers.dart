import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/api_models.dart';
import '../services/lm_studio_service.dart';
import '../services/chat_storage_service.dart';

// Services
final lmStudioServiceProvider = Provider<LMStudioService>((ref) => LMStudioService());
final chatStorageServiceProvider = Provider<ChatStorageService>((ref) => ChatStorageService());

// Current chat state
final currentChatProvider = StateNotifierProvider<CurrentChatNotifier, Chat?>((ref) {
  return CurrentChatNotifier(
    ref.read(lmStudioServiceProvider),
    ref.read(chatStorageServiceProvider),
  );
});

// All chats list
final allChatsProvider = StateNotifierProvider<AllChatsNotifier, List<Chat>>((ref) {
  return AllChatsNotifier(ref.read(chatStorageServiceProvider));
});

// Loading states
final isLoadingProvider = StateProvider<bool>((ref) => false);
final isServerAvailableProvider = FutureProvider<bool>((ref) {
  return ref.read(lmStudioServiceProvider).isServerAvailable();
});

// Available models
final availableModelsProvider = FutureProvider<List<ModelInfo>>((ref) {
  return ref.read(lmStudioServiceProvider).getModels();
});

// Current Chat Notifier
class CurrentChatNotifier extends StateNotifier<Chat?> {
  final LMStudioService _lmStudioService;
  final ChatStorageService _storageService;
  final Uuid _uuid = const Uuid();

  CurrentChatNotifier(this._lmStudioService, this._storageService) : super(null) {
    _loadCurrentChat();
  }

  Future<void> _loadCurrentChat() async {
    final currentChat = await _storageService.getCurrentChat();
    state = currentChat;
  }

  // Create a new chat
  Future<void> createNewChat() async {
    final newChat = Chat(
      id: _uuid.v4(),
      name: 'New Chat',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = newChat;
    await _storageService.saveChat(newChat);
    await _storageService.setCurrentChatId(newChat.id);
  }

  // Load an existing chat
  Future<void> loadChat(String chatId) async {
    final chat = await _storageService.getChatById(chatId);
    if (chat != null) {
      state = chat;
      await _storageService.setCurrentChatId(chatId);
    }
  }

  // Send a message and get streaming response
  Future<void> sendMessage(String content) async {
    if (state == null) {
      await createNewChat();
    }

    final userMessage = Message(
      id: _uuid.v4(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Add user message
    state = state!.addMessage(userMessage);
    await _storageService.saveChat(state!);

    // Create placeholder AI message for streaming
    final aiMessageId = _uuid.v4();
    final aiMessage = Message(
      id: aiMessageId,
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    state = state!.addMessage(aiMessage);
    await _storageService.saveChat(state!);

    try {
      // Convert chat messages to API format for context (excluding the empty streaming message)
      final apiMessages = state!.messages
          .where((msg) => msg.id != aiMessageId) // Exclude the streaming placeholder
          .map((msg) => ChatMessage(
        role: msg.isUser ? 'user' : 'assistant',
        content: msg.content,
      )).toList();

      // Get the best available model
      final model = await _lmStudioService.getBestModel();
      if (model == null) {
        // Try to get more info about why no models are available
        final isAvailable = await _lmStudioService.isServerAvailable();
        if (!isAvailable) {
          throw Exception('LM Studio server is not running at localhost:1234');
        } else {
          throw Exception('No models available. Please load a model in LM Studio.');
        }
      }

      // Get streaming AI response
      String fullResponse = '';
      await for (final chunk in _lmStudioService.sendStreamingChatCompletion(
        model: model,
        messages: apiMessages,
      )) {
        fullResponse += chunk;
        
        // Update the streaming message with current content
        final updatedMessages = state!.messages.map((msg) {
          if (msg.id == aiMessageId) {
            return msg.copyWith(content: fullResponse);
          }
          return msg;
        }).toList();
        
        state = state!.copyWith(messages: updatedMessages);
        // Don't save to storage on every chunk to avoid performance issues
      }

      // Finalize the message (mark as not streaming and save)
      final finalMessages = state!.messages.map((msg) {
        if (msg.id == aiMessageId) {
          return msg.copyWith(content: fullResponse, isStreaming: false);
        }
        return msg;
      }).toList();
      
      state = state!.copyWith(messages: finalMessages);

      // Generate chat name if this is the first exchange
      if (state!.messages.length == 2 && state!.name == 'New Chat') {
        try {
          final generatedName = await _lmStudioService.generateChatName(apiMessages);
          state = state!.copyWith(name: generatedName);
        } catch (e) {
          // Keep default name if generation fails
        }
      }

      await _storageService.saveChat(state!);
    } catch (e) {
      // Replace the streaming message with error message
      final errorMessage = Message(
        id: aiMessageId,
        content: 'Error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: false,
      );

      final updatedMessages = state!.messages.map((msg) {
        if (msg.id == aiMessageId) {
          return errorMessage;
        }
        return msg;
      }).toList();

      state = state!.copyWith(messages: updatedMessages);
      await _storageService.saveChat(state!);
    }
  }

  // Clear current chat
  void clearCurrentChat() {
    state = null;
    _storageService.clearCurrentChatId();
  }
}

// All Chats Notifier
class AllChatsNotifier extends StateNotifier<List<Chat>> {
  final ChatStorageService _storageService;

  AllChatsNotifier(this._storageService) : super([]) {
    loadAllChats();
  }

  Future<void> loadAllChats() async {
    final chats = await _storageService.getAllChats();
    state = chats;
  }

  Future<void> deleteChat(String chatId) async {
    await _storageService.deleteChat(chatId);
    state = state.where((chat) => chat.id != chatId).toList();
  }

  Future<void> searchChats(String query) async {
    final chats = await _storageService.searchChats(query);
    state = chats;
  }

  Future<void> refreshChats() async {
    await loadAllChats();
  }
}