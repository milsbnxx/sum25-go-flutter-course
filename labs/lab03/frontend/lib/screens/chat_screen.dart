// lib/screens/chat_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lab03_frontend/main.dart';             // для ChatProvider
import 'package:lab03_frontend/services/api_service.dart';
import 'package:lab03_frontend/models/message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _usernameController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Загружаем сообщения сразу после первого рендера
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadMessages();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final user = _usernameController.text.trim();
    final content = _messageController.text.trim();
    if (user.isEmpty || content.isEmpty) {
      // Тесты ожидают SnackBar при пустых полях
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username and content are required')),
      );
      return;
    }
    try {
      await context.read<ChatProvider>().createMessage(
            CreateMessageRequest(username: user, content: content),
          );
      // Показать SnackBar об успехе
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent')),
      );
      _messageController.clear();
    } catch (_) {
      // Ошибку создаёт провайдер и отображает виджет ошибки
    }
  }

  Future<void> _showHTTPStatus(int code) async {
  try {
    final st = await context.read<ApiService>().getHTTPStatus(code);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('HTTP Status: $code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(st.description),
            const SizedBox(height: 8),
            Image.network(
              st.imageUrl,
              // Если картинка не загрузится (в тестах Flutter возвращает 400),
              // вместо ошибки покажем пустой SizedBox.
              errorBuilder: (ctx, error, stack) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}

  Widget _buildBody(ChatProvider prov) {
    if (prov.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text(prov.error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: prov.loadMessages, child: const Text('Retry')),
        ]),
      );
    }
    if (prov.messages.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          Text('No messages yet'),
          SizedBox(height: 4),
          Text('Send your first message to get started!'),
        ]),
      );
    }
    return ListView.builder(
      itemCount: prov.messages.length,
      itemBuilder: (_, i) {
        final msg = prov.messages[i];
        return ListTile(
          leading: CircleAvatar(
            child: Text(msg.username.isNotEmpty
                ? msg.username[0].toUpperCase()
                : '?'),
          ),
          title: Text(msg.username),
          subtitle: Text(msg.content),
          trailing: PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') {
                // Редактировать сообщение
                _editMessage(msg);
              }
              if (v == 'delete') {
                _deleteMessage(msg);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
          onTap: () {
            // Показываем случайный HTTP-cat
            final codes = [200, 404, 500];
            _showHTTPStatus(codes[Random().nextInt(codes.length)]);
          },
        );
      },
    );
  }

  Future<void> _editMessage(Message msg) async {
    final ctl = TextEditingController(text: msg.content);
    final res = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(controller: ctl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (res != null && res.isNotEmpty) {
      await context.read<ChatProvider>().updateMessage(
            msg.id,
            UpdateMessageRequest(content: res),
          );
    }
  }

  Future<void> _deleteMessage(Message msg) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Message?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
            ],
          ),
        ) ??
        false;
    if (ok) {
      await context.read<ChatProvider>().deleteMessage(msg.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ChatProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('REST API Chat'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: prov.loadMessages)],
      ),
      body: _buildBody(prov),
      bottomSheet: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Enter your username'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(labelText: 'Enter your message'),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: _sendMessage, child: const Text('Send'))),
            const SizedBox(width: 8),
            TextButton(onPressed: () => _showHTTPStatus(200), child: const Text('200 OK')),
            TextButton(onPressed: () => _showHTTPStatus(404), child: const Text('404 Not Found')),
            TextButton(onPressed: () => _showHTTPStatus(500), child: const Text('500 Error')),
          ]),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: prov.loadMessages,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
