import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_model_preference.dart';
import '../providers.dart';

const _modelUrls = {
  ChatModelPreference.gemma4E2B:
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.task',
  ChatModelPreference.gemma4E4B:
      'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.task',
};

class ModelDownloadPage extends ConsumerStatefulWidget {
  const ModelDownloadPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<ModelDownloadPage> createState() => _ModelDownloadPageState();
}

class _ModelDownloadPageState extends ConsumerState<ModelDownloadPage> {
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    setState(() {
      _error = null;
      _progress = 0;
    });

    try {
      final model = ref.read(chatModelPreferenceProvider).valueOrNull ??
          ChatModelPreference.defaultModel;
      final url = _modelUrls[model]!;

      await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
          .fromNetwork(url)
          .withProgress((progress) {
        if (mounted) {
          setState(() => _progress = progress);
        }
      }).install();

      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.smart_toy_outlined, size: 64),
              const SizedBox(height: 24),
              Text(
                l10n.chatModelDownloadTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(
                  l10n.chatModelDownloadError,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _startDownload,
                  child: Text(l10n.chatModelDownloadRetry),
                ),
              ] else ...[
                LinearProgressIndicator(value: _progress / 100),
                const SizedBox(height: 8),
                Text(l10n.chatModelDownloadProgress(_progress)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
