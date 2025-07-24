// models/message.dart
import 'package:uuid/uuid.dart';

enum MessageType { text, image, audio, file }
enum MessageSender { user, bot }

class Message {
  final String id;
  final String content;
  final MessageType type;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isRead;
  final bool isTyping;
  final String? imageUrl;
  final String? audioUrl;
  final String? fileName;

  Message({
    String? id,
    required this.content,
    this.type = MessageType.text,
    required this.sender,
    DateTime? timestamp,
    this.isRead = false,
    this.isTyping = false,
    this.imageUrl,
    this.audioUrl,
    this.fileName,
  }) : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Message copyWith({
    String? content,
    MessageType? type,
    MessageSender? sender,
    DateTime? timestamp,
    bool? isRead,
    bool? isTyping,
    String? imageUrl,
    String? audioUrl,
    String? fileName,
  }) {
    return Message(
      id: id,
      content: content ?? this.content,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isTyping: isTyping ?? this.isTyping,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      fileName: fileName ?? this.fileName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.toString(),
      'sender': sender.toString(),
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isTyping': isTyping,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'fileName': fileName,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      type: MessageType.values.firstWhere(
            (e) => e.toString() == json['type'],
      ),
      sender: MessageSender.values.firstWhere(
            (e) => e.toString() == json['sender'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      isTyping: json['isTyping'] ?? false,
      imageUrl: json['imageUrl'],
      audioUrl: json['audioUrl'],
      fileName: json['fileName'],
    );
  }
}


