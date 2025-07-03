import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_chat_history.dart';

class AiLocalStorage {
  static const String _storageKey = 'ai_chat_history';

  Future<List<AiChatHistory>> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_storageKey) ?? [];
    return historyJson
        .map((json) => AiChatHistory.fromMap(jsonDecode(json)))
        .toList();
  }

  Future<void> saveChatHistory(List<AiChatHistory> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = history.map((chat) => jsonEncode(chat.toMap())).toList();
    await prefs.setStringList(_storageKey, historyJson);
  }

  Future<void> addChatToHistory(AiChatHistory chat) async {
    final history = await loadChatHistory();
    history.insert(0, chat);
    await saveChatHistory(history);
  }

  Future<void> clearChatHistory(dynamic SharedPreferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}