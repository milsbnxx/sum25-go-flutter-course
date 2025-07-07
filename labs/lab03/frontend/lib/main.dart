// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'services/api_service.dart';
import 'models/message.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
          dispose: (_, svc) => svc.dispose(),
        ),
        ChangeNotifierProxyProvider<ApiService, ChatProvider>(
          create: (ctx) => ChatProvider(ctx.read<ApiService>()),
          update: (ctx, api, prev) => prev!..apiService = api,
        ),
      ],
      child: MaterialApp(
        title: 'Lab 03 REST API Chat',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const ChatScreen(),
      ),
    );
  }
}

class ChatProvider extends ChangeNotifier {
  late ApiService apiService;
  ChatProvider(this.apiService);

  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Загрузить сообщения с бэкенда
  Future<void> loadMessages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _messages = await apiService.getMessages();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Создать новое сообщение
  Future<void> createMessage(CreateMessageRequest req) async {
    try {
      final msg = await apiService.createMessage(req);
      _messages.add(msg);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Обновить существующее сообщение
  Future<void> updateMessage(int id, UpdateMessageRequest req) async {
    try {
      final updated = await apiService.updateMessage(id, req);
      final idx = _messages.indexWhere((m) => m.id == id);
      if (idx != -1) {
        _messages[idx] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Удалить сообщение
  Future<void> deleteMessage(int id) async {
    try {
      await apiService.deleteMessage(id);
      _messages.removeWhere((m) => m.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Очистить список и перезагрузить
  Future<void> refreshMessages() async {
    _messages.clear();
    notifyListeners();
    await loadMessages();
  }

  /// Сбросить текст ошибки
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
