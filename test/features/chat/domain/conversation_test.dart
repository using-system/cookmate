import 'package:cookmate/features/chat/domain/conversation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 4, 18, 12, 0, 0);

  group('Conversation', () {
    test('stores all fields', () {
      final conv = Conversation(
        id: 'abc-123',
        title: 'My recipe',
        createdAt: now,
        updatedAt: now,
      );

      expect(conv.id, 'abc-123');
      expect(conv.title, 'My recipe');
      expect(conv.createdAt, now);
      expect(conv.updatedAt, now);
    });

    test('toMap serializes to SQLite-compatible map', () {
      final conv = Conversation(
        id: 'abc-123',
        title: 'My recipe',
        createdAt: now,
        updatedAt: now,
      );

      final map = conv.toMap();
      expect(map['id'], 'abc-123');
      expect(map['title'], 'My recipe');
      expect(map['created_at'], now.millisecondsSinceEpoch);
      expect(map['updated_at'], now.millisecondsSinceEpoch);
    });

    test('fromMap deserializes from SQLite row', () {
      final map = {
        'id': 'abc-123',
        'title': 'My recipe',
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      };

      final conv = Conversation.fromMap(map);
      expect(conv.id, 'abc-123');
      expect(conv.title, 'My recipe');
      expect(conv.createdAt, now);
      expect(conv.updatedAt, now);
    });

    test('copyWith creates a modified copy', () {
      final conv = Conversation(
        id: 'abc-123',
        title: 'Old title',
        createdAt: now,
        updatedAt: now,
      );

      final updated = conv.copyWith(title: 'New title');
      expect(updated.title, 'New title');
      expect(updated.id, conv.id);
    });
  });
}
