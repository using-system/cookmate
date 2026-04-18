import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatConversationsTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final conv = await ref
              .read(conversationsProvider.notifier)
              .create(l10n.chatNewConversation);
          if (context.mounted) {
            context.go('/home/chat/${conv.id}');
          }
        },
        child: const Icon(Icons.add),
      ),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(child: Text(l10n.chatEmptyState));
          }
          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return Dismissible(
                key: ValueKey(conv.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Theme.of(context).colorScheme.error,
                  child: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.chatDeleteConversation),
                      content: Text(l10n.chatDeleteConfirmation),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) {
                  ref.read(conversationsProvider.notifier).delete(conv.id);
                },
                child: ListTile(
                  title: Text(
                    conv.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _formatDate(conv.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () => context.go('/home/chat/${conv.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
