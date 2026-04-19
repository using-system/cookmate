import 'package:cookmate/features/chat/domain/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 4, 18, 12, 0, 0);

  group('ChatMessage', () {
    test('stores all fields', () {
      final msg = ChatMessage(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: 'user',
        content: 'Hello',
        createdAt: now,
      );

      expect(msg.id, 'msg-1');
      expect(msg.conversationId, 'conv-1');
      expect(msg.role, 'user');
      expect(msg.content, 'Hello');
      expect(msg.createdAt, now);
    });

    test('toMap serializes to SQLite-compatible map', () {
      final msg = ChatMessage(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: 'assistant',
        content: 'Hi there',
        createdAt: now,
      );

      final map = msg.toMap();
      expect(map['id'], 'msg-1');
      expect(map['conversation_id'], 'conv-1');
      expect(map['role'], 'assistant');
      expect(map['content'], 'Hi there');
      expect(map['created_at'], now.millisecondsSinceEpoch);
    });

    test('fromMap deserializes from SQLite row', () {
      final map = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'role': 'user',
        'content': 'Hello',
        'created_at': now.millisecondsSinceEpoch,
      };

      final msg = ChatMessage.fromMap(map);
      expect(msg.id, 'msg-1');
      expect(msg.conversationId, 'conv-1');
      expect(msg.role, 'user');
      expect(msg.content, 'Hello');
      expect(msg.createdAt, now);
    });

    test('type defaults to text', () {
      final msg = ChatMessage(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: 'user',
        content: 'Hello',
        createdAt: now,
      );
      expect(msg.type, 'text');
      expect(msg.mediaPath, isNull);
    });

    test('toMap includes type and media_path', () {
      final msg = ChatMessage(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: 'user',
        content: 'Photo',
        createdAt: now,
        type: 'image',
        mediaPath: '/path/img.jpg',
      );

      final map = msg.toMap();
      expect(map['type'], 'image');
      expect(map['media_path'], '/path/img.jpg');
    });

    test('fromMap defaults type to text when absent', () {
      final map = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'role': 'user',
        'content': 'Hello',
        'created_at': now.millisecondsSinceEpoch,
      };

      final msg = ChatMessage.fromMap(map);
      expect(msg.type, 'text');
      expect(msg.mediaPath, isNull);
    });

    test('fromMap deserializes type and mediaPath', () {
      final map = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'role': 'user',
        'content': '',
        'created_at': now.millisecondsSinceEpoch,
        'type': 'audio',
        'media_path': '/path/audio.m4a',
      };

      final msg = ChatMessage.fromMap(map);
      expect(msg.type, 'audio');
      expect(msg.mediaPath, '/path/audio.m4a');
    });
  });
}
