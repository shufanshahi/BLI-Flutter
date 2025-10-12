import 'message.dart';

class Chat {
  final String id;
  final String name;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Chat({
    required this.id,
    required this.name,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'messages': messages.map((message) => message.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      name: json['name'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((messageJson) => Message.fromJson(messageJson as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Chat copyWith({
    String? id,
    String? name,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to add a message to the chat
  Chat addMessage(Message message) {
    return copyWith(
      messages: [...messages, message],
      updatedAt: DateTime.now(),
    );
  }

  // Helper method to get the last message for preview
  String get lastMessagePreview {
    if (messages.isEmpty) return 'No messages';
    final lastMessage = messages.last;
    return lastMessage.content.length > 50 
        ? '${lastMessage.content.substring(0, 50)}...'
        : lastMessage.content;
  }
}