import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:coffee_app/features/ai_assistant/cubit/ai_history_cubit.dart';
import 'package:coffee_app/features/ai_assistant/cubit/ai_history_state.dart';
import 'package:coffee_app/features/ai_assistant/view/ai_assistant_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AiHistoryPage extends StatelessWidget {
  const AiHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Reload history when the page is built/returned to
    context.read<AiHistoryCubit>().loadConversations();

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(LangKeys.ai_assistant_history_title)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AiAssistantPage(conversationId: null),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(context.tr(LangKeys.new_chat)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: BlocBuilder<AiHistoryCubit, AiHistoryState>(
        builder: (context, state) {
          if (state is AiHistoryInitial || state is AiHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AiHistoryLoaded) {
            if (state.conversations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr(LangKeys.no_conversations_yet),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(LangKeys.tap_new_chat_to_begin),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: state.conversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = state.conversations[index];

                String previewText = context.tr(LangKeys.empty_conversation);
                if (conversation.messages.isNotEmpty) {
                  previewText = conversation.messages.last.text;
                  if (previewText.length > 50) {
                    previewText = '${previewText.substring(0, 50)}...';
                  }
                }

                // Format date cleanly
                final now = DateTime.now();
                final msgDate = conversation.lastMessageAt;
                final isToday = now.year == msgDate.year &&
                    now.month == msgDate.month &&
                    now.day == msgDate.day;
                final dateStr = isToday
                    ? DateFormat.Hm().format(msgDate)
                    : DateFormat.yMMMd().format(msgDate);

                return Dismissible(
                  key: Key(conversation.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: const EdgeInsets.only(right: 24.0),
                    alignment: Alignment.centerRight,
                    color: theme.colorScheme.error,
                    child: Icon(Icons.delete, color: theme.colorScheme.onError),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(context.tr(LangKeys.confirm_delete_title)),
                          content: Text(
                            context.tr(LangKeys.confirm_delete_conversation_message),
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(context.tr(LangKeys.cancel)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(context.tr(LangKeys.delete),
                                  style: TextStyle(
                                      color: theme.colorScheme.error)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    context
                        .read<AiHistoryCubit>()
                        .deleteConversation(conversation.id);
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AiAssistantPage(
                            conversationId: conversation.id,
                          ),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.smart_toy,
                          color: theme.colorScheme.onPrimaryContainer),
                    ),
                    title: Text(
                      conversation.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      previewText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    trailing: Text(
                      dateStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
