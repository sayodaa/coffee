import 'package:coffee_app/features/ai_assistant/cubit/ai_assistant_cubit.dart';
import 'package:coffee_app/features/ai_assistant/cubit/ai_assistant_state.dart';
import 'package:coffee_app/features/ai_assistant/cubit/ai_history_cubit.dart';
import 'package:coffee_app/features/ai_assistant/data/ai_assistant_repository.dart';
import 'package:coffee_app/features/ai_assistant/widgets/chat_bubble.dart';
import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiAssistantPage extends StatefulWidget {
  final String? conversationId;
  final String? initialPrompt;

  const AiAssistantPage({
    super.key,
    required this.conversationId,
    this.initialPrompt,
  });

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AiAssistantCubit _chatCubit;

  @override
  void initState() {
    super.initState();
    // Initialize a fresh cubit for this specific chat page instance
    // Since each chat page is independent and might be pushed on the stack
    _chatCubit = AiAssistantCubit(
      repository: context.read<AiAssistantRepository>(),
      historyCubit: context.read<AiHistoryCubit>(),
    )..loadOrCreateConversation(widget.conversationId).then((_) {
        if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
          _chatCubit.sendMessage(widget.initialPrompt!);
        }
      });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _chatCubit.close(); // Clean up this localized cubit
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatCubit,
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<AiAssistantCubit, AiAssistantState>(
            builder: (context, state) {
              if (state is AiAssistant) {
                return Text(state.conversation.title);
              }
              return Text(context.tr(LangKeys.ai_assistant_title));
            },
          ),
          centerTitle: true,
        ),
        body: BlocConsumer<AiAssistantCubit, AiAssistantState>(
          listener: (context, state) {
            if (state is AiAssistant) {
              Future.delayed(
                  const Duration(milliseconds: 100), _scrollToBottom);
            }
          },
          builder: (context, state) {
            if (state is AiAssistantInitial || state is AiAssistantLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AiAssistant) {
              return Column(
                children: [
                  Expanded(
                    child: state.conversation.messages.isEmpty
                        ? Center(
                            child: Text(context.tr(LangKeys.no_messages_yet)),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            itemCount: state.conversation.messages.length,
                            itemBuilder: (context, index) {
                              return ChatBubble(
                                message: state.conversation.messages[index],
                              );
                            },
                          ),
                  ),
                  if (state.isTyping)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(context.tr(LangKeys.assistant_is_typing),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  )),
                        ],
                      ),
                    ),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        state.error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  _buildMessageInput(context),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0).copyWith(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: context.tr(LangKeys.type_a_message),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            onPressed: () => _sendMessage(),
            elevation: 0,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isNotEmpty) {
      _chatCubit.sendMessage(text);
      _textController.clear();
    }
  }
}
