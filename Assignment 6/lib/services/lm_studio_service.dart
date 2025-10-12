import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';

class LMStudioService {
  static const String baseUrl = 'http://localhost:1234/v1';
  static const Duration timeoutDuration = Duration(seconds: 30);

  // Get available models
  Future<List<ModelInfo>> getModels() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/models'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final modelsResponse = ModelsResponse.fromJson(data);
        return modelsResponse.data;
      } else {
        throw Exception('Failed to load models: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching models: $e');
    }
  }

  // Send chat completion request (non-streaming)
  Future<String> sendChatCompletion({
    required String model,
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    try {
      final request = ChatCompletionRequest(
        model: model,
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
      );

      final response = await http
          .post(
            Uri.parse('$baseUrl/chat/completions'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(request.toJson()),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final completionResponse = ChatCompletionResponse.fromJson(data);
        
        if (completionResponse.choices.isNotEmpty) {
          return completionResponse.choices.first.message.content;
        } else {
          throw Exception('No response generated');
        }
      } else {
        throw Exception('Failed to get completion: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending chat completion: $e');
    }
  }

  // Send streaming chat completion request
  Stream<String> sendStreamingChatCompletion({
    required String model,
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    try {
      final request = ChatCompletionRequest(
        model: model,
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
        stream: true,
      );

      final httpRequest = http.Request(
        'POST',
        Uri.parse('$baseUrl/chat/completions'),
      );
      
      httpRequest.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      });
      
      httpRequest.body = json.encode(request.toJson());

      final streamedResponse = await http.Client().send(httpRequest);

      if (streamedResponse.statusCode == 200) {
        await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          
          for (final line in lines) {
            if (line.trim().isEmpty) continue;
            if (line.startsWith('data: ')) {
              final data = line.substring(6).trim();
              
              if (data == '[DONE]') {
                return;
              }
              
              try {
                final jsonData = json.decode(data);
                if (jsonData['choices'] != null && 
                    jsonData['choices'].isNotEmpty &&
                    jsonData['choices'][0]['delta'] != null &&
                    jsonData['choices'][0]['delta']['content'] != null) {
                  final content = jsonData['choices'][0]['delta']['content'] as String;
                  if (content.isNotEmpty) {
                    yield content;
                  }
                }
              } catch (e) {
                // Skip malformed JSON chunks
                continue;
              }
            }
          }
        }
      } else {
        throw Exception('Failed to get streaming completion: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending streaming chat completion: $e');
    }
  }

  // Generate chat name using LLM
  Future<String> generateChatName(List<ChatMessage> messages) async {
    try {
      // Get the first few messages for context
      final contextMessages = messages.take(4).toList();
      
      final namePrompt = ChatMessage(
        role: 'system',
        content: 'Based on the following conversation, generate a short, descriptive title (3-5 words maximum) that captures the main topic. Respond only with the title, no quotes or extra text.',
      );

      final nameMessages = [namePrompt, ...contextMessages];

      // Get available models first
      final models = await getModels();
      if (models.isEmpty) {
        throw Exception('No models available');
      }

      final response = await sendChatCompletion(
        model: models.first.id,
        messages: nameMessages,
        temperature: 0.3, // Lower temperature for more consistent naming
        maxTokens: 20, // Short response for title
      );

      // Clean up the response by removing quotes and backticks
      String cleanResponse = response.trim();
      if (cleanResponse.startsWith('"') && cleanResponse.endsWith('"')) {
        cleanResponse = cleanResponse.substring(1, cleanResponse.length - 1);
      }
      if (cleanResponse.startsWith("'") && cleanResponse.endsWith("'")) {
        cleanResponse = cleanResponse.substring(1, cleanResponse.length - 1);
      }
      if (cleanResponse.startsWith('`') && cleanResponse.endsWith('`')) {
        cleanResponse = cleanResponse.substring(1, cleanResponse.length - 1);
      }
      return cleanResponse;
    } catch (e) {
      // Fallback to timestamp-based name if naming fails
      return 'Chat ${DateTime.now().toString().substring(5, 16)}';
    }
  }

  // Check if LM Studio server is running
  Future<bool> isServerAvailable() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/models'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get the best available model (first one in the list)
  Future<String?> getBestModel() async {
    try {
      final models = await getModels();
      return models.isNotEmpty ? models.first.id : null;
    } catch (e) {
      return null;
    }
  }
}