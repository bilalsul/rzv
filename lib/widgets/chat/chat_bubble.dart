import 'package:flutter/material.dart';

enum ChatRole { user, assistant, system }

class ChatBubble extends StatelessWidget {
  final String text;
  final ChatRole role;
  final String? time;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onRegenerate;

  const ChatBubble({
    super.key,
    required this.text,
    required this.role,
    this.time,
    this.onCopy,
    this.onEdit,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = role == ChatRole.user;
    final bg = isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor;
    final color = isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: GestureDetector(
          onLongPress: () async {
            // show actions
            final choice = await showModalBottomSheet<String>(context: context, builder: (ctx) {
              return SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ListTile(leading: const Icon(Icons.copy), title: const Text('Copy'), onTap: () => Navigator.of(ctx).pop('copy')),
                  ListTile(leading: const Icon(Icons.edit), title: const Text('Edit'), onTap: () => Navigator.of(ctx).pop('edit')),
                  ListTile(leading: const Icon(Icons.refresh), title: const Text('Regenerate'), onTap: () => Navigator.of(ctx).pop('regenerate')),
                  ListTile(leading: const Icon(Icons.close), title: const Text('Cancel'), onTap: () => Navigator.of(ctx).pop(null)),
                ]),
              );
            });
            if (choice == 'copy') {
              onCopy?.call();
            } else if (choice == 'edit') {
              onEdit?.call();
            } else if (choice == 'regenerate') {
              onRegenerate?.call();
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!isUser) ...[
                CircleAvatar(child: Icon(Icons.smart_toy, size: 18), radius: 16),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SelectableText(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 8),
                    Text(time!, style: Theme.of(context).textTheme.bodySmall),
                  ]
                ]),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(child: Icon(Icons.person, size: 18), radius: 16),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
