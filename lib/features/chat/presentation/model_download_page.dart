import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class ModelDownloadPage extends ConsumerStatefulWidget {
  const ModelDownloadPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<ModelDownloadPage> createState() => _ModelDownloadPageState();
}

class _ModelDownloadPageState extends ConsumerState<ModelDownloadPage> {
  int _progress = 0;
  String? _error;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  /// Returns true if the download should proceed, false otherwise.
  Future<bool> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();

    if (results.contains(ConnectivityResult.none)) {
      if (!mounted) return false;
      final l10n = AppLocalizations.of(context);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.chatModelDownloadNoConnectionTitle),
          content: Text(l10n.chatModelDownloadNoConnectionBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return false;
    }

    if (!results.contains(ConnectivityResult.wifi)) {
      if (!mounted) return false;
      final l10n = AppLocalizations.of(context);
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.chatModelDownloadMobileDataTitle),
          content: Text(l10n.chatModelDownloadMobileDataBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.chatModelDownloadContinue),
            ),
          ],
        ),
      );
      return proceed ?? false;
    }

    return true;
  }

  Future<void> _startDownload() async {
    if (_downloading) return;
    _downloading = true;
    setState(() {
      _error = null;
      _progress = 0;
    });

    final shouldProceed = await _checkConnectivity();
    if (!shouldProceed) {
      _downloading = false;
      if (mounted) {
        setState(() {
          _error = 'connectivity';
        });
      }
      return;
    }

    try {
      final model = await ref.read(chatModelPreferenceProvider.future);

      await FlutterGemma.installModel(
        modelType: model.modelType,
        fileType: model.fileType,
      ).fromNetwork(model.url).withProgress((progress) {
        if (mounted) {
          setState(() => _progress = progress);
        }
      }).install();

      final storage =
          await ref.read(chatModelPreferenceStorageProvider.future);
      await storage.writeInstalled(model);

      if (mounted) {
        widget.onComplete();
      }
    } catch (e, stack) {
      debugPrint('Model download failed: $e\n$stack');
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      _downloading = false;
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
