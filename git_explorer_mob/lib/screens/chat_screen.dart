import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
import 'package:git_explorer_mob/services/ai_chat_service.dart';
import 'package:git_explorer_mob/widgets/chat/chat_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late AiChatService _service;
  List<Map<String, String>> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final prefs = Prefs();
    _service = AiChatService(prefs);
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    final prefs = Prefs();
    final raw = prefs.prefs.getString('ai_conversation') ?? '[]';
    try {
      final decoded = jsonDecode(raw) as List;
      _messages = decoded.map<Map<String, String>>((e) => Map<String, String>.from(e)).toList();
      setState(() {});
    } catch (_) {}
  }

  Future<void> _saveConversation() async {
    final prefs = Prefs();
    await prefs.prefs.setString('ai_conversation', jsonEncode(_messages));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() {
      _isSending = true;
      _messages.add({'role': 'user', 'text': text});
      _controller.clear();
    });
    await _saveConversation();

    try {
      final reply = await _service.sendMessage(text);
      setState(() {
        _messages.add({'role': 'assistant', 'text': reply});
      });
      await _saveConversation();
      // scroll to bottom
      await Future.delayed(const Duration(milliseconds: 80));
      _scroll.animateTo(_scroll.position.maxScrollExtent + 120, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': 'Error: ${e.toString()}'});
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _showApiKeyDialog() async {
    final prefs = Prefs();
    final existing = await prefs.getPluginApiKey('openai') ?? '';
    final tc = TextEditingController(text: existing);
    await showDialog<void>(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('OpenAI API Key'),
        content: TextField(
          controller: tc,
          decoration: const InputDecoration(hintText: 'sk-...'),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            final val = tc.text.trim();
            if (val.isEmpty) {
              await prefs.removePluginApiKey('openai');
            } else {
              await prefs.setPluginApiKey('openai', val);
            }
            Navigator.of(ctx).pop();
            setState(() {});
          }, child: const Text('Save')),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
  ref.watch(prefsProvider); // ensure rebuild when prefs change (API key, settings)

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        actions: [
          IconButton(icon: const Icon(Icons.vpn_key), onPressed: _showApiKeyDialog),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async {
            final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
              title: const Text('Clear conversation'),
              content: const Text('Are you sure you want to clear the conversation history?'),
              actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes'))],
            ));
            if (confirmed == true) {
              _messages.clear();
              await _saveConversation();
              setState(() {});
            }
          })
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            itemCount: _messages.length,
            itemBuilder: (ctx, i) {
              final m = _messages[i];
              final role = m['role'] == 'user' ? ChatRole.user : ChatRole.assistant;
              return ChatBubble(text: m['text'] ?? '', role: role);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 6,
                decoration: const InputDecoration(hintText: 'Send a message', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide.none), filled: true, fillColor: Colors.white24),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            _isSending ? const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : IconButton(icon: const Icon(Icons.send), onPressed: _send),
          ]),
        )
      ]),
    );
  }
}
