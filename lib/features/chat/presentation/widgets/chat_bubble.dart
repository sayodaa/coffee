import 'package:coffee_app/core/theme/app_colors.dart';
import 'package:coffee_app/features/chat/domain/entities/message.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isError = message.isError;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          // Advanced Gradient or Solid Colors
          gradient: isUser && !isError
              ? (isDark
                  ? AppColors.primaryGradientDark
                  : AppColors.primaryGradientLight)
              : null,
          color: isUser
              ? null // Handled by gradient
              : isError
                  ? (isDark
                      ? AppColors.error.withOpacity(0.2)
                      : AppColors.error.withOpacity(0.1))
                  : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: isError
                  ? AppColors.error.withOpacity(0.1)
                  : (isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.15)),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
          border: isError
              ? Border.all(color: AppColors.error.withOpacity(0.5))
              : (isUser
                  ? null
                  : Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    )),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser
                      ? Colors.white
                      : isError
                          ? AppColors.error
                          : theme.textTheme.bodyMedium?.color,
                  height: 1.4,
                  fontWeight: isError ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('hh:mm a').format(message.timestamp),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isUser
                          ? Colors.white.withOpacity(0.7)
                          : theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                  if (isError) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.error_outline,
                        size: 12, color: AppColors.error),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
