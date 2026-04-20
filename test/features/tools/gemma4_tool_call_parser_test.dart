import 'package:cookmate/features/tools/gemma4_tool_call_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Gemma4ToolCallParser', () {
    const sampleToolCall =
        '<|tool_call>call:share_recipe:share_recipe(title: "Poulet Épicé", '
        'content: "Ingrédients:\\n* 4 blancs de poulet")';

    test('containsToolCall detects marker', () {
      expect(Gemma4ToolCallParser.containsToolCall(sampleToolCall), isTrue);
      expect(Gemma4ToolCallParser.containsToolCall('Hello world'), isFalse);
    });

    test('parseAll extracts name and args', () {
      final results = Gemma4ToolCallParser.parseAll(sampleToolCall);
      expect(results, hasLength(1));
      expect(results[0].name, 'share_recipe');
      expect(results[0].args['title'], 'Poulet Épicé');
      expect(results[0].args['content'], contains('blancs de poulet'));
    });

    test('parseAll handles escaped quotes in values', () {
      const raw = '<|tool_call>call:test:test(msg: "He said \\"hello\\"")';
      final results = Gemma4ToolCallParser.parseAll(raw);
      expect(results, hasLength(1));
      expect(results[0].args['msg'], 'He said "hello"');
    });

    test('parseAll returns empty for no match', () {
      expect(Gemma4ToolCallParser.parseAll('Just text'), isEmpty);
    });

    test('stripToolCalls removes call markers', () {
      const text = 'Here is your recipe <|tool_call>call:share_recipe:'
          'share_recipe(title: "X", content: "Y") done';
      final stripped = Gemma4ToolCallParser.stripToolCalls(text);
      expect(stripped, isNot(contains('<|tool_call>')));
      expect(stripped, contains('Here is your recipe'));
    });

    test('parseAll handles multiline content', () {
      const raw = '<|tool_call>call:share_recipe:share_recipe('
          'title: "Gâteau", content: "Ligne 1\\nLigne 2\\nLigne 3")';
      final results = Gemma4ToolCallParser.parseAll(raw);
      expect(results, hasLength(1));
      expect(results[0].args['content'], contains('Ligne 1'));
    });
  });
}
