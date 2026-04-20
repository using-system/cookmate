import 'package:flutter/widgets.dart';
import 'package:flutter_gemma/core/model_response.dart';
import 'package:flutter_gemma/core/tool.dart';

import 'tool_handler.dart';

/// Central registry for all function calling tool handlers.
///
/// Register a new tool by adding a [ToolHandler] to the constructor list.
/// The registry provides [tools] for flutter_gemma's `createChat()` and
/// [handle] to dispatch [FunctionCallResponse] events from the stream.
class ToolRegistry {
  ToolRegistry(List<ToolHandler> handlers)
      : _handlers = _buildHandlers(handlers);

  static Map<String, ToolHandler> _buildHandlers(List<ToolHandler> handlers) {
    final map = <String, ToolHandler>{};
    for (final h in handlers) {
      final name = h.definition.name;
      if (map.containsKey(name)) {
        throw ArgumentError(
          'Duplicate tool handler registration for "$name". '
          'Tool names must be unique.',
        );
      }
      map[name] = h;
    }
    return map;
  }

  final Map<String, ToolHandler> _handlers;

  /// All tool definitions, ready to pass to `createChat(tools: ...)`.
  List<Tool> get tools => _handlers.values.map((h) => h.definition).toList();

  /// Whether any tools are registered.
  bool get hasTools => _handlers.isNotEmpty;

  /// Dispatch a single [FunctionCallResponse] to the matching handler.
  Future<void> handle(
      FunctionCallResponse response, BuildContext context) async {
    debugPrint('>>> ToolRegistry.handle: "${response.name}" args=${response.args}');
    final handler = _handlers[response.name];
    if (handler != null) {
      await handler.execute(response.args, context);
    } else {
      debugPrint('>>> ToolRegistry: no handler for "${response.name}"');
    }
  }
}
