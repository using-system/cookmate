import 'package:cookmate/features/tools/tool_handler.dart';
import 'package:cookmate/features/tools/tool_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gemma/core/model_response.dart';
import 'package:flutter_gemma/core/tool.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHandler extends ToolHandler {
  String? lastCalledWith;

  @override
  Tool get definition => const Tool(
        name: 'test_tool',
        description: 'A test tool.',
        parameters: {
          'type': 'object',
          'properties': {
            'value': {'type': 'string', 'description': 'A value.'},
          },
          'required': ['value'],
        },
      );

  @override
  Future<Map<String, dynamic>?> execute(
      Map<String, dynamic> args, BuildContext context) async {
    lastCalledWith = args['value'] as String?;
    return {'status': 'ok'};
  }
}

void main() {
  group('ToolRegistry', () {
    test('tools returns definitions from all handlers', () {
      final registry = ToolRegistry([_FakeHandler()]);
      expect(registry.tools, hasLength(1));
      expect(registry.tools[0].name, 'test_tool');
    });

    test('hasTools is true when handlers registered', () {
      expect(ToolRegistry([_FakeHandler()]).hasTools, isTrue);
      expect(ToolRegistry([]).hasTools, isFalse);
    });

    test('handle dispatches to correct handler', () async {
      final handler = _FakeHandler();
      final registry = ToolRegistry([handler]);
      const response = FunctionCallResponse(
        name: 'test_tool',
        args: {'value': 'hello'},
      );

      // Use a minimal BuildContext stub — handler doesn't use it in test.
      await registry.handle(response, _FakeBuildContext());
      expect(handler.lastCalledWith, 'hello');
    });

    test('handle ignores unknown tool names', () async {
      final registry = ToolRegistry([_FakeHandler()]);
      const response = FunctionCallResponse(
        name: 'unknown_tool',
        args: {},
      );
      // Should not throw.
      await registry.handle(response, _FakeBuildContext());
    });
  });
}

class _FakeBuildContext extends Fake implements BuildContext {}
