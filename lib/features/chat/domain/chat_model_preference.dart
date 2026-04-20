import 'package:flutter_gemma/flutter_gemma.dart';

enum ChatModelPreference {
  gemma4E2B(
    label: 'gemma-4-E2B-it',
    fileName: 'gemma-4-E2B-it.litertlm',
    url:
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
    modelType: ModelType.gemmaIt,
    fileType: ModelFileType.task,
  ),
  gemma4E4B(
    label: 'gemma-4-E4B-it',
    fileName: 'gemma-4-E4B-it.litertlm',
    url:
        'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm',
    modelType: ModelType.gemmaIt,
    fileType: ModelFileType.task,
  ),
  ;

  const ChatModelPreference({
    required this.label,
    required this.fileName,
    required this.url,
    required this.modelType,
    required this.fileType,
  });

  final String label;
  final String fileName;
  final String url;
  final ModelType modelType;
  final ModelFileType fileType;

  static const ChatModelPreference defaultModel = ChatModelPreference.gemma4E4B;

  String toStorageValue() => name;

  static ChatModelPreference fromStorageValue(String? raw) {
    if (raw == null || raw.isEmpty) {
      return defaultModel;
    }
    for (final model in ChatModelPreference.values) {
      if (model.name == raw) {
        return model;
      }
    }
    return defaultModel;
  }
}
