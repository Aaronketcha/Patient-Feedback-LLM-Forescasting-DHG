import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../models/chat.dart';
import '../models/message.dart';

class ChatService extends ChangeNotifier {
  List<Chat> _chats = [];
  Chat? _currentChat;
  bool _isLoading = false;
  bool _isTyping = false;

  List<Chat> get chats => List.unmodifiable(_chats);
  Chat? get currentChat => _currentChat;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;

  // Initialize service
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadChatsFromStorage();

      // Create a default chat if none exist
      if (_chats.isEmpty) {
        await createNewChat('Nouvelle conversation');
      }
    } catch (e) {
      debugPrint('Error initializing chat service: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load chats from local storage
  Future<void> _loadChatsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatIds = prefs.getStringList('chat_ids') ?? [];

      _chats.clear();
      for (String chatId in chatIds) {
        final chatJson = prefs.getString('chat_$chatId');
        if (chatJson != null) {
          // In a real app, you would properly deserialize JSON
          // For now, we'll create sample data
        }
      }

      // Add sample chats for demo
      if (_chats.isEmpty) {
        _createSampleChats();
      }
    } catch (e) {
      debugPrint('Error loading chats: $e');
    }
  }

  // Save chats to local storage
  Future<void> _saveChatsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatIds = _chats.map((chat) => chat.id).toList();

      await prefs.setStringList('chat_ids', chatIds);

      for (Chat chat in _chats) {
        await prefs.setString('chat_${chat.id}', chat.toJson().toString());
      }
    } catch (e) {
      debugPrint('Error saving chats: $e');
    }
  }

  // Create sample chats for demo
  void _createSampleChats() {
    final sampleChat = Chat(
      title: 'Assistant IA',
      messages: [
        Message(
          content: 'Bonjour ! Je suis votre assistant IA. Comment puis-je vous aider aujourd\'hui ?',
          sender: MessageSender.bot,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ],
    );

    _chats.add(sampleChat);
    _currentChat = sampleChat;
  }

  // Create new chat
  Future<Chat> createNewChat(String title) async {
    final newChat = Chat(
      title: title,
      messages: [
        Message(
          content: 'Bonjour ! Comment puis-je vous aider ?',
          sender: MessageSender.bot,
        ),
      ],
    );

    _chats.insert(0, newChat);
    _currentChat = newChat;

    await _saveChatsToStorage();
    notifyListeners();

    return newChat;
  }

  // Set current chat
  void setCurrentChat(Chat chat) {
    _currentChat = chat;
    notifyListeners();
  }

  // Send message
  Future<void> sendMessage(String content, {MessageType type = MessageType.text}) async {
    if (_currentChat == null || content.trim().isEmpty) return;

    // Add user message
    final userMessage = Message(
      content: content.trim(),
      sender: MessageSender.user,
      type: type,
    );

    _currentChat!.messages.add(userMessage);

    // Update chat title if it's the first user message
    if (_currentChat!.messages.where((m) => m.sender == MessageSender.user).length == 1) {
      _currentChat = _currentChat!.copyWith(
        title: content.length > 30 ? '${content.substring(0, 30)}...' : content,
      );

      // Update in the list as well
      final index = _chats.indexWhere((chat) => chat.id == _currentChat!.id);
      if (index != -1) {
        _chats[index] = _currentChat!;
      }
    }

    notifyListeners();

    // Simulate bot typing
    _isTyping = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 1000 + Random().nextInt(2000)));

      // Generate bot response
      final botResponse = await _generateBotResponse(content);

      _currentChat!.messages.add(botResponse);

      await _saveChatsToStorage();

    } catch (e) {
      debugPrint('Error sending message: $e');

      // Add error message
      _currentChat!.messages.add(
        Message(
          content: 'Désolé, une erreur s\'est produite. Veuillez réessayer.',
          sender: MessageSender.bot,
        ),
      );
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  // Generate bot response (mock AI response)
  Future<Message> _generateBotResponse(String userMessage) async {
    final responses = [
      'C\'est une excellente question ! Laissez-moi y réfléchir...',
      'Je comprends votre point de vue. Voici ce que je pense...',
      'Intéressant ! Permettez-moi de vous donner quelques informations à ce sujet.',
      'D\'après mon analyse, voici ma réponse...',
      'C\'est un sujet fascinant. Voici mon point de vue...',
      'Je vais faire de mon mieux pour vous aider avec cela.',
      'Excellente question ! Voici ce que je sais à ce sujet...',
      'Permettez-moi de vous expliquer cela en détail.',
    ];

    final randomResponse = responses[Random().nextInt(responses.length)];

    return Message(
      content: '$randomResponse\n\nVous avez mentionné: "$userMessage"\n\nComme assistant IA, je suis là pour vous aider avec toutes vos questions. N\'hésitez pas à me demander des clarifications ou des informations supplémentaires !',
      sender: MessageSender.bot,
    );
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    _chats.removeWhere((chat) => chat.id == chatId);

    if (_currentChat?.id == chatId) {
      _currentChat = _chats.isNotEmpty ? _chats.first : null;
    }

    await _saveChatsToStorage();
    notifyListeners();
  }

  // Clear all chats
  Future<void> clearAllChats() async {
    _chats.clear();
    _currentChat = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_ids');

    notifyListeners();
  }

  // Pin/unpin chat
  Future<void> toggleChatPin(String chatId) async {
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final chat = _chats[chatIndex];
      _chats[chatIndex] = chat.copyWith(isPinned: !chat.isPinned);

      // Sort chats (pinned first)
      _chats.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.lastUpdated.compareTo(a.lastUpdated);
      });

      await _saveChatsToStorage();
      notifyListeners();
    }
  }

  // Search messages
  List<Message> searchMessages(String query) {
    if (query.trim().isEmpty) return [];

    final results = <Message>[];
    final lowerQuery = query.toLowerCase();

    for (Chat chat in _chats) {
      for (Message message in chat.messages) {
        if (message.content.toLowerCase().contains(lowerQuery)) {
          results.add(message);
        }
      }
    }

    return results;
  }

  // Get chat statistics
  Map<String, dynamic> getChatStatistics() {
    int totalMessages = 0;
    int userMessages = 0;
    int botMessages = 0;

    for (Chat chat in _chats) {
      totalMessages += chat.messages.length;
      userMessages += chat.messages.where((m) => m.sender == MessageSender.user).length;
      botMessages += chat.messages.where((m) => m.sender == MessageSender.bot).length;
    }

    return {
      'totalChats': _chats.length,
      'totalMessages': totalMessages,
      'userMessages': userMessages,
      'botMessages': botMessages,
      'pinnedChats': _chats.where((c) => c.isPinned).length,
    };
  }
}