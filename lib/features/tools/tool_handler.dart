import 'package:flutter/widgets.dart';
import 'package:flutter_gemma/core/tool.dart';

/// A tool handler pairs a flutter_gemma [Tool] definition with the callback
/// that executes when the LLM invokes it via function calling.
///
/// Each handler lives in its own file under `handlers/`.
abstract class ToolHandler {
  /// The flutter_gemma tool definition (name, description, JSON schema).
  Tool get definition;

  /// Execute this tool with the args provided by the LLM.
  ///
  /// Return a result map to send back to the LLM via [Message.toolResponse],
  /// or `null` for fire-and-forget tools (e.g. share).
  Future<Map<String, dynamic>?> execute(
      Map<String, dynamic> args, BuildContext context);
}
