import 'package:flutter/material.dart';

enum ChatRole { user, assistant, system }

class ChatBubble extends StatelessWidget {
  final String text;
  final ChatRole role;

  const ChatBubble({super.key, required this.text, required this.role});

  @override
  Widget build(BuildContext context) {
    final isUser = role == ChatRole.user;
    final bg = isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor;
    final color = isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: SelectableText(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
