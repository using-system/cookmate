import 'package:cookmate/features/tools/handlers/share_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBuildContext extends Fake implements BuildContext {}

void main() {
  group('ShareHandler definition', () {
    test('has name "share_recipe"', () {
      final handler = ShareHandler();
      expect(handler.definition.name, 'share_recipe');
    });

    test('has required parameters "title" and "content"', () {
      final handler = ShareHandler();
      final required = handler.definition.parameters['required'] as List;
      expect(required, containsAll(['title', 'content']));
    });

    test('parameters include title and content properties', () {
      final handler = ShareHandler();
      final properties =
          handler.definition.parameters['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('title'), isTrue);
      expect(properties.containsKey('content'), isTrue);
    });
  });

  // Note: ShareHandler.execute calls SharePlus.instance.share which requires
  // a platform channel unavailable in unit tests.  We only test the definition
  // here; integration tests cover the share sheet behaviour.
}
