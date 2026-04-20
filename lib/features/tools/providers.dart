import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'handlers/share_handler.dart';
import 'tool_registry.dart';

/// All tool handlers are registered here. Add new handlers to the list.
final toolRegistryProvider = Provider<ToolRegistry>(
  (ref) => ToolRegistry([
    ShareHandler(),
  ]),
);
