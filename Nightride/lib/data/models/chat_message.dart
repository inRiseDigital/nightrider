import 'package:uuid/uuid.dart';

class ChatMessage {
  final String id;
  final String content;
  final String role; // 'user' or 'assistant'
  final DateTime timestamp;
  bool isLiked;
  bool isFavorited;

  ChatMessage({
    String? id,
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.isLiked = false,
    this.isFavorited = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  // Minimal — used when sending history to the backend
  Map<String, dynamic> toJson() => {'content': content, 'role': role};

  // Full — used for local persistence
  Map<String, dynamic> toJsonFull() => {
        'id': id,
        'content': content,
        'role': role,
        'timestamp': timestamp.toIso8601String(),
        'isLiked': isLiked,
        'isFavorited': isFavorited,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      ChatMessage(content: json['content'], role: json['role']);

  factory ChatMessage.fromJsonFull(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        content: json['content'],
        role: json['role'],
        timestamp: DateTime.parse(json['timestamp']),
        isLiked: json['isLiked'] ?? false,
        isFavorited: json['isFavorited'] ?? false,
      );
}
