import 'package:cookmate/features/tools/gemma4_tool_call_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Gemma4ToolCallParser', () {
    const sampleToolCall =
        '<|tool_call>call:share_recipe:share_recipe{title: "Poulet Épicé", '
        'content: "Ingrédients:\\n* 4 blancs de poulet"}<tool_call|>';

    test('containsToolCall detects marker', () {
      expect(Gemma4ToolCallParser.containsToolCall(sampleToolCall), isTrue);
      expect(Gemma4ToolCallParser.containsToolCall('Hello world'), isFalse);
    });

    test('parseAll extracts name and args with end marker', () {
      final results = Gemma4ToolCallParser.parseAll(sampleToolCall);
      expect(results, hasLength(1));
      expect(results[0].name, 'share_recipe');
      expect(results[0].args['title'], 'Poulet Épicé');
      expect(results[0].args['content'], contains('blancs de poulet'));
    });

    test('parseAll works without end marker', () {
      const raw =
          '<|tool_call>call:share_recipe:share_recipe{title: "Test", '
          'content: "Body"}';
      final results = Gemma4ToolCallParser.parseAll(raw);
      expect(results, hasLength(1));
      expect(results[0].args['title'], 'Test');
    });

    test('parseAll handles escaped quotes in values', () {
      const raw =
          '<|tool_call>call:test:test{msg: "He said \\"hello\\""}<tool_call|>';
      final results = Gemma4ToolCallParser.parseAll(raw);
      expect(results, hasLength(1));
      expect(results[0].args['msg'], 'He said "hello"');
    });

    test('parseAll converts escaped newlines', () {
      const raw =
          '<|tool_call>call:share_recipe:share_recipe{title: "Gâteau", '
          'content: "Ligne 1\\nLigne 2\\nLigne 3"}<tool_call|>';
      final results = Gemma4ToolCallParser.parseAll(raw);
      expect(results, hasLength(1));
      expect(results[0].args['content'], 'Ligne 1\nLigne 2\nLigne 3');
    });

    test('parseAll returns empty for no match', () {
      expect(Gemma4ToolCallParser.parseAll('Just text'), isEmpty);
    });

    test('stripToolCalls removes call markers with end tag', () {
      const text =
          'Here is your recipe <|tool_call>call:share_recipe:'
          'share_recipe{title: "X", content: "Y"}<tool_call|> done';
      final stripped = Gemma4ToolCallParser.stripToolCalls(text);
      expect(stripped, isNot(contains('<|tool_call>')));
      expect(stripped, isNot(contains('<tool_call|>')));
      expect(stripped, contains('Here is your recipe'));
    });

    test('parseAll handles real Gemma 4 output', () {
      const raw = '<|tool_call>call:share_recipe:share_recipe'
          '{title: "Gâteau au Chocolat Moelleux (4 portions)", '
          'content: "## Gâteau au Chocolat\\n\\n**Ingrédients**\\n'
          '* 250 g de farine"}<tool_call|>';
      final results = Gemma4ToolCallParser.parseAll(raw);
      expect(results, hasLength(1));
      expect(results[0].name, 'share_recipe');
      expect(results[0].args['title'],
          'Gâteau au Chocolat Moelleux (4 portions)');
      expect(results[0].args['content'], contains('Ingrédients'));
    });
  });
}
