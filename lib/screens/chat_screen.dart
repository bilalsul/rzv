import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:rzv/providers/shared_preferences_provider.dart';
import 'package:rzv/services/ai_chat_service.dart';
import 'package:rzv/widgets/chat/chat_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late AiChatService _service;
  List<Map<String, dynamic>> _messages = [];
  bool _isSending = false;
  StreamSubscription<String>? _streamSub;
  // attached context files: {path, content}
  final List<Map<String, String>> _attachments = [];

  @override
  void initState() {
    super.initState();
    final prefs = Prefs();
    _service = AiChatService(prefs);
    _loadConversation();
  }

  Widget _buildFloatingInput() {
    final width = MediaQuery.of(context).size.width;
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(24),
      color: Theme.of(context).cardColor.withOpacity(0.98),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: width > 800 ? 700 : width - 24),
        child: Row(children: [
          // attach / paste / quick actions
          IconButton(
            icon: const Icon(Icons.attach_file),
            tooltip: 'Attach file (enter path)',
            onPressed: _insertFile,
          ),
          IconButton(
            icon: const Icon(Icons.paste),
            tooltip: 'Paste from clipboard',
            onPressed: _pasteFromClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb),
            tooltip: 'Quick questions',
            onPressed: _showQuickQuestions,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Type a message (or "gen" for generated stream)',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          _isSending
              ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(icon: const Icon(Icons.send), onPressed: _send),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    final prefs = Prefs();
    final raw = prefs.prefs.getString('ai_conversation') ?? '[]';
    try {
      final decoded = jsonDecode(raw) as List;
      _messages = decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      setState(() {});
    } catch (_) {}
  }

  Future<void> _insertFile() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File insertion is not supported on web')));
      return;
    }
    final tc = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Insert file by path'),
      content: TextField(controller: tc, decoration: const InputDecoration(hintText: '/absolute/path/to/file')),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Load'))],
    ));
    if (confirmed != true) return;
    final path = tc.text.trim();
    if (path.isEmpty) return;
    try {
      final f = File(path);
      if (!await f.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File not found')));
        return;
      }
      var content = await f.readAsString();
      // truncate large files to keep payload reasonable
      const maxLen = 2000;
      if (content.length > maxLen) content = content.substring(0, maxLen) + '\n... (truncated)';
      setState(() {
        _attachments.add({'path': path, 'content': content});
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File attached')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reading file: $e')));
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null || data!.text!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
      return;
    }
    final txt = data.text!;
    setState(() {
      // append with a space if needed
      if (_controller.text.isNotEmpty) _controller.text = _controller.text + '\n' + txt;
      else _controller.text = txt;
    });
  }

  Future<void> _showQuickQuestions() async {
    // derive suggestions from attachments or last message
    final List<String> suggestions = [];
    if (_attachments.isNotEmpty) {
      for (final a in _attachments) {
        final name = a['path']?.split(Platform.pathSeparator).last ?? a['path'] ?? 'file';
        suggestions.add('Summarize $name');
        suggestions.add('List TODOs in $name');
        suggestions.add('Explain the responsibilities of $name');
      }
    } else if (_messages.isNotEmpty) {
      suggestions.add('Summarize the last assistant reply');
      suggestions.add('What are the next steps?');
      suggestions.add('Find TODOs in the conversation');
    } else {
      suggestions.addAll(['Give me a summary of my project', 'Suggest next steps to improve code quality', 'What should I ask about this repository?']);
    }

    final choice = await showModalBottomSheet<String>(context: context, builder: (ctx) {
      return SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final s in suggestions) ListTile(title: Text(s), onTap: () => Navigator.of(ctx).pop(s)),
          ListTile(title: const Text('Cancel'), onTap: () => Navigator.of(ctx).pop(null)),
        ]),
      );
    });
    if (choice != null && choice.isNotEmpty) {
      setState(() {
        _controller.text = choice;
      });
    }
  }

  Future<void> _saveConversation() async {
    final prefs = Prefs();
    await prefs.prefs.setString('ai_conversation', jsonEncode(_messages));
  }
  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    // Create user message
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    // include attachment file names in the message metadata
    final attachedNames = _attachments.map((a) => a['path']?.split(Platform.pathSeparator).last ?? a['path']).toList();
    final userMsg = {'id': userId, 'role': 'user', 'text': text, 'time': DateTime.now().toIso8601String(), 'attachments': attachedNames};
    setState(() {
      _isSending = true;
      _messages.add(userMsg);
      // placeholder assistant message
      _messages.add({'id': '${userId}-assistant', 'role': 'assistant', 'text': '', 'time': DateTime.now().toIso8601String(), 'streaming': true});
      _controller.clear();
    });
    await _saveConversation();

    // Stream or fake-stream
    try {
      // if attachments exist, prepend their content as context (truncated)
      var finalMessage = text;
      if (_attachments.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln('CONTEXT FILES:');
        for (final a in _attachments) {
          final name = a['path']?.split(Platform.pathSeparator).last ?? a['path'];
          buffer.writeln('\n--- $name ---\n');
          buffer.writeln(a['content'] ?? '');
        }
        buffer.writeln('\n--- END CONTEXT ---\n');
        buffer.writeln('\nUSER MESSAGE:\n');
        buffer.writeln(text);
        finalMessage = buffer.toString();
      }

      final stream = _service.streamMessage(finalMessage);
      String buffer = '';
      // cancel previous stream if any
      await _streamSub?.cancel();
      _streamSub = stream.listen((chunk) async {
        buffer += chunk;
        // update assistant message
        final idx = _messages.indexWhere((m) => m['id'] == '${userId}-assistant');
        if (idx != -1) {
          setState(() {
            _messages[idx]['text'] = buffer;
          });
          // persist intermittently
          await _saveConversation();
        }
      }, onError: (e) async {
        final idx = _messages.indexWhere((m) => m['id'] == '${userId}-assistant');
        if (idx != -1) {
          setState(() {
            _messages[idx]['text'] = 'Error: ${e.toString()}';
            _messages[idx]['streaming'] = false;
          });
          await _saveConversation();
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Error: ${e.toString()}')));
      }, onDone: () async {
        final idx = _messages.indexWhere((m) => m['id'] == '${userId}-assistant');
        if (idx != -1) {
          setState(() {
            _messages[idx]['streaming'] = false;
          });
          await _saveConversation();
          await Future.delayed(const Duration(milliseconds: 80));
          if (_scroll.hasClients) {
            _scroll.animateTo(_scroll.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
          }
        }
        setState(() {
          _isSending = false;
          // clear attachments after successful send
          _attachments.clear();
        });
      });
    } catch (e) {
      // show error on assistant message
      final idx = _messages.indexWhere((m) => m['id'] == '${userId}-assistant');
      if (idx != -1) {
        setState(() {
          _messages[idx]['text'] = 'Error: ${e.toString()}';
          _messages[idx]['streaming'] = false;
        });
        await _saveConversation();
      }
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _regenerateAtIndex(int assistantIndex) async {
    // find nearest user message before this assistant
    for (int i = assistantIndex - 1; i >= 0; i--) {
      if (_messages[i]['role'] == 'user') {
        final userText = _messages[i]['text'] as String? ?? '';
        // remove assistant at assistantIndex
        setState(() {
          _messages.removeAt(assistantIndex);
        });
        // send again
        _controller.text = userText;
        await _send();
        return;
      }
    }
  }

  Future<void> _editAtIndex(int index) async {
    final current = _messages[index]['text'] as String? ?? '';
    final tc = TextEditingController(text: current);
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Edit message'),
      content: TextField(controller: tc, maxLines: 6),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save'))],
    ));
    if (confirmed == true) {
      setState(() {
        _messages[index]['text'] = tc.text;
      });
      await _saveConversation();
    }
  }

  Future<void> _copyAtIndex(int index) async {
    final txt = _messages[index]['text'] as String? ?? '';
    await Clipboard.setData(ClipboardData(text: txt));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
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
      body: Stack(children: [
        // message list
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final role = m['role'] == 'user' ? ChatRole.user : ChatRole.assistant;
                final timeStr = m['time'] as String?;
                final time = timeStr != null ? DateTime.tryParse(timeStr)?.toLocal().toString().split('.').first : null;
                return ChatBubble(
                  text: m['text'] ?? '',
                  role: role,
                  time: time,
                  onCopy: () => _copyAtIndex(i),
                  onEdit: () => _editAtIndex(i),
                  onRegenerate: () async {
                    // regenerate nearest user message
                    if (m['role'] == 'assistant') {
                      await _regenerateAtIndex(i);
                    } else {
                      // regenerate the user's own message by sending it again
                      _controller.text = m['text'] ?? '';
                      await _send();
                    }
                  },
                );
              },
            ),
          ),
        ),

        // Floating input: centered when conversation is empty, bottom when there are messages
        Positioned.fill(
          child: IgnorePointer(
            ignoring: false,
            child: Align(
              alignment: _messages.isEmpty ? Alignment.center : Alignment.bottomCenter,
              child: FractionallySizedBox(
                widthFactor: 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_attachments.isNotEmpty) ...[
                      // show attached files as removable chips
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _attachments.map((a) {
                            final name = a['path']?.split(Platform.pathSeparator).last ?? a['path'];
                            return Chip(
                              label: Text(name ?? 'file'),
                              onDeleted: () {
                                setState(() {
                                  _attachments.remove(a);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    _buildFloatingInput(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
