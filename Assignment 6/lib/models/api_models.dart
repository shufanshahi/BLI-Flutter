// API Request models for LM Studio
class ChatCompletionRequest {
  final String model;
  final List<ChatMessage> messages;
  final double temperature;
  final int maxTokens;
  final bool stream;

  const ChatCompletionRequest({
    required this.model,
    required this.messages,
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.stream = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': stream,
    };
  }
}

class ChatMessage {
  final String role; // "user", "assistant", "system"
  final String content;

  const ChatMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
    );
  }
}

// API Response models
class ChatCompletionResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final List<Choice> choices;
  final Usage usage;

  const ChatCompletionResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    required this.usage,
  });

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> json) {
    return ChatCompletionResponse(
      id: json['id'] as String,
      object: json['object'] as String,
      created: json['created'] as int,
      model: json['model'] as String,
      choices: (json['choices'] as List<dynamic>)
          .map((choice) => Choice.fromJson(choice as Map<String, dynamic>))
          .toList(),
      usage: Usage.fromJson(json['usage'] as Map<String, dynamic>),
    );
  }
}

class Choice {
  final int index;
  final ChatMessage message;
  final String finishReason;

  const Choice({
    required this.index,
    required this.message,
    required this.finishReason,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      index: json['index'] as int,
      message: ChatMessage.fromJson(json['message'] as Map<String, dynamic>),
      finishReason: json['finish_reason'] as String,
    );
  }
}

class Usage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  const Usage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory Usage.fromJson(Map<String, dynamic> json) {
    return Usage(
      promptTokens: json['prompt_tokens'] as int,
      completionTokens: json['completion_tokens'] as int,
      totalTokens: json['total_tokens'] as int,
    );
  }
}

// Model information
class ModelInfo {
  final String id;
  final String object;
  final int? created;
  final String ownedBy;

  const ModelInfo({
    required this.id,
    required this.object,
    this.created,
    required this.ownedBy,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'] as String,
      object: json['object'] as String,
      created: json['created'] as int?,
      ownedBy: json['owned_by'] as String? ?? 'organization_owner',
    );
  }
}

class ModelsResponse {
  final String object;
  final List<ModelInfo> data;

  const ModelsResponse({
    required this.object,
    required this.data,
  });

  factory ModelsResponse.fromJson(Map<String, dynamic> json) {
    return ModelsResponse(
      object: json['object'] as String,
      data: (json['data'] as List<dynamic>)
          .map((model) => ModelInfo.fromJson(model as Map<String, dynamic>))
          .toList(),
    );
  }
}