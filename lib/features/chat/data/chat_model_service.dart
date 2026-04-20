import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../domain/chat_backend_preference.dart';
import '../domain/chat_model_preference.dart';
import 'chat_backend_preference_storage.dart';
import 'chat_model_preference_storage.dart';

class ChatModelService {
  ChatModelService({
    required this.modelStorage,
    required this.backendStorage,
  });

  final ChatModelPreferenceStorage modelStorage;
  final ChatBackendPreferenceStorage backendStorage;

  Future<void> switchModel(ChatModelPreference newModel) async {
    await modelStorage.write(newModel);
    try {
      final installed = modelStorage.readInstalled();
      if (installed != null) {
        await FlutterGemma.uninstallModel(installed.fileName);
      }
    } catch (e, stack) {
      debugPrint('Failed to delete old model: $e\n$stack');
    }
    await modelStorage.clearInstalled();
  }

  Future<void> switchBackend(ChatBackendPreference newBackend) async {
    await backendStorage.write(newBackend);
  }
}
