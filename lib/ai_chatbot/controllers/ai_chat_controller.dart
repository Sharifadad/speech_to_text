import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/ai_message.dart';
import '../models/ai_chat_history.dart';
import '../services/ai_local_storage.dart';
import '../services/voice_service.dart';

class AiChatController with ChangeNotifier {
  final AiLocalStorage _storage = AiLocalStorage();
  final VoiceService _voiceService = VoiceService();

  List<AiMessage> _messages = [];
  List<AiChatHistory> _chatHistory = [];
  bool _isTyping = false;
  bool _isListening = false;

  List<AiMessage> get messages => _messages;
  List<AiChatHistory> get chatHistory => _chatHistory;
  bool get isTyping => _isTyping;
  bool get isListening => _isListening;

  void setTyping(bool typing) {
    _isTyping = typing;
    notifyListeners();
  }

  AiChatController() {
    _loadChatHistory();
    initializeVoice();
  }

  Future<void> _loadChatHistory() async {
    _chatHistory = await _storage.loadChatHistory();
    notifyListeners();
  }

  Future<void> initializeVoice() async {
    await _voiceService.initialize();
  }

  Future<void> startListening() async {
    _isListening = true;
    notifyListeners();

    final result = await _voiceService.listen();
    _isListening = false;
    notifyListeners();

    if (result != null && result.isNotEmpty) {
      await sendMessage(result, isUser: true);
    }
  }

  void stopListening() {
    _voiceService.stop();
    _isListening = false;
    notifyListeners();
  }

  Future<void> sendMessage(String message, {required bool isUser}) async {
    _addMessage(message, isUser ? MessageSender.user : MessageSender.bot);

    if (isUser) {
      _isTyping = true;
      notifyListeners();

      try {
        final response = await _getLocalResponse(message);
        _addMessage(response, MessageSender.bot);
        await _voiceService.speak(response);

        if (_messages.length == 2) {
          final chat = AiChatHistory(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: message.length > 20
                ? '${message.substring(0, 20)}...'
                : message,
            messages: List.from(_messages),
          );
          await _storage.addChatToHistory(chat);
          _chatHistory.insert(0, chat);
        }
      } catch (e) {
        final errorMsg = 'Sorry, I encountered an error: $e';
        _addMessage(errorMsg, MessageSender.bot);
        await _voiceService.speak(errorMsg);
      } finally {
        _isTyping = false;
        notifyListeners();
      }
    }
  }

  Future<String> _getLocalResponse(String query) async {
    try {
      final predefined = _getPredefinedResponse(query);
      if (predefined != null) return predefined;

      return await _scrapeWebAnswer(query);
    } catch (e) {
      return "I couldn't find an answer to that question. Please try asking something else.";
    }
  }

  String? _getPredefinedResponse(String query) {
    final responses = {
      'hello': 'Hello there! How can I help you today?',
      'hi': 'Hi! What can I do for you?',
      'what is your name': 'I am your local AI assistant',
      'who created you': 'I was created by a developer to help you',
      'how are you': 'I\'m functioning well, thank you for asking!',
      'what can you do': 'I can answer questions and have conversations with you',
      'thank you': 'You\'re welcome! Is there anything else you need?',
      'goodbye': 'Goodbye! Feel free to come back if you have more questions.',
    };

    final lowerQuery = query.toLowerCase();

    if (responses.containsKey(lowerQuery)) {
      return responses[lowerQuery]!;
    }

    for (final key in responses.keys) {
      if (lowerQuery.contains(key)) {
        return responses[key]!;
      }
    }

    return null;
  }

  Future<String> _scrapeWebAnswer(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&exintro&explaintext&titles=$encodedQuery';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pages = data['query']['pages'];
        final page = pages.values.first;

        if (page['extract'] != null) {
          final extract = page['extract'] as String;
          return _summarizeExtract(extract);
        }
      }
      return 'I found no information about "$query" on Wikipedia.';
    } catch (e) {
      return 'Sorry, I couldn\'t fetch information online. Please try asking something else.';
    }
  }

  String _summarizeExtract(String extract) {
    final firstParagraph = extract.split('\n')[0];
    if (firstParagraph.length > 200) {
      return '${firstParagraph.substring(0, 200)}...';
    }
    return firstParagraph;
  }

  void _addMessage(String content, MessageSender sender) {
    _messages.add(AiMessage(
      content: content,
      sender: sender,
      timeSent: DateTime.now(),
    ));
    notifyListeners();
  }

  Future<void> loadChatFromHistory(AiChatHistory chat) async {
    _messages = List.from(chat.messages);
    notifyListeners();
  }

  void clearCurrentChat() {
    _messages.clear();
    notifyListeners();
  }

  Future<void> deleteChatHistory(String id) async {
    _chatHistory.removeWhere((chat) => chat.id == id);
    await _storage.saveChatHistory(_chatHistory);
    notifyListeners();
  }

  void speak(String content) {}
}