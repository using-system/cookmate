import 'package:flutter_gemma/core/model_response.dart';

/// Parses Gemma 4 tool call format from raw text.
///
/// Gemma 4 emits:
/// `<|tool_call>call:name:name{arg1: "val1", arg2: "val2"}<tool_call|>`
///
/// flutter_gemma 0.13.5 does not parse this format natively — it arrives
/// as plain text. This parser detects, extracts, and strips these calls.
class Gemma4ToolCallParser {
  static const _startMarker = '<|tool_call>';
  static const _endMarker = '<tool_call|>';

  /// Whether [text] contains a Gemma 4 tool call.
  static bool containsToolCall(String text) => text.contains(_startMarker);

  /// Parse all tool calls from accumulated [text].
  static List<FunctionCallResponse> parseAll(String text) {
    final results = <FunctionCallResponse>[];
    // Pattern: <|tool_call>call:name:name{args}<tool_call|>
    // Also match without end marker (may be cut off).
    final regex = RegExp(
      r'<\|tool_call>call:\w+:(\w+)\{(.*?)\}(?:<tool_call\|>)?',
      dotAll: true,
    );

    for (final match in regex.allMatches(text)) {
      final name = match.group(1)!;
      final argsStr = match.group(2)!;
      final args = _parseArgs(argsStr);
      results.add(FunctionCallResponse(name: name, args: args));
    }
    return results;
  }

  /// Strip the tool call markers from [text], returning only the
  /// human-readable portion (if any).
  static String stripToolCalls(String text) {
    return text
        .replaceAll(
          RegExp(
            r'<\|tool_call>call:\w+:\w+\{.*?\}(?:<tool_call\|>)?',
            dotAll: true,
          ),
          '',
        )
        .trim();
  }

  /// Parse `key: "value", key2: "value2"` into a map.
  static Map<String, dynamic> _parseArgs(String argsStr) {
    final args = <String, dynamic>{};
    // Match key: "value" pairs — value can contain escaped quotes and
    // any character including newlines.
    final regex = RegExp(r'(\w+):\s*"((?:[^"\\]|\\.)*)"');
    for (final match in regex.allMatches(argsStr)) {
      final key = match.group(1)!;
      final value = match.group(2)!
          .replaceAll(r'\"', '"')
          .replaceAll(r'\n', '\n');
      args[key] = value;
    }
    return args;
  }
}
