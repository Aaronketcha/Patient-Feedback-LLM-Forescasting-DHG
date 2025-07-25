// models/chat.dart
import 'package:uuid/uuid.dart';
import 'message.dart'; // Make sure the path is correct based on your structure

class Chat {
  final String id;
  final String title;
  final List<Message> messages;
  final DateTime lastUpdated;
  final bool isPinned;
  final String? description;

  Chat({
    String? id,
    required this.title,
    List<Message>? messages,
    DateTime? lastUpdated,
    this.isPinned = false,
    this.description,
  })  : id = id ?? const Uuid().v4(),
        messages = messages ?? [],
        lastUpdated = lastUpdated ?? DateTime.now();

  /// Create a copy of this chat with some modified fields
  Chat copyWith({
    String? title,
    List<Message>? messages,
    DateTime? lastUpdated,
    bool? isPinned,
    String? description,
  }) {
    return Chat(
      id: id, // Keep the original ID
      title: title ?? this.title,
      messages: messages ?? this.messages,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isPinned: isPinned ?? this.isPinned,
      description: description ?? this.description,
    );
  }

  /// Returns the latest message as preview (max 50 characters)
  String get lastMessagePreview {
    if (messages.isEmpty) return 'Nouvelle conversation';
    final lastMessage = messages.last;
    return lastMessage.content.length > 50
        ? '${lastMessage.content.substring(0, 50)}...'
        : lastMessage.content;
  }

  /// Convert Chat to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => m.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'isPinned': isPinned,
      'description': description,
    };
  }

  /// Create Chat from JSON
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      title: json['title'],
      messages: (json['messages'] as List<dynamic>?)
          ?.map((m) => Message.fromJson(m))
          .toList() ??
          [],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      isPinned: json['isPinned'] ?? false,
      description: json['description'],
    );
  }
}
