class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.type = 'text',
    this.mediaPath,
  });

  final String id;
  final String conversationId;
  final String role;
  final String content;
  final DateTime createdAt;

  /// Message type: 'text', 'image', or 'audio'.
  final String type;

  /// Local file path for image or audio messages.
  final String? mediaPath;

  Map<String, Object?> toMap() => {
        'id': id,
        'conversation_id': conversationId,
        'role': role,
        'content': content,
        'created_at': createdAt.millisecondsSinceEpoch,
        'type': type,
        'media_path': mediaPath,
      };

  factory ChatMessage.fromMap(Map<String, Object?> map) => ChatMessage(
        id: map['id'] as String,
        conversationId: map['conversation_id'] as String,
        role: map['role'] as String,
        content: map['content'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        type: (map['type'] as String?) ?? 'text',
        mediaPath: map['media_path'] as String?,
      );
}
