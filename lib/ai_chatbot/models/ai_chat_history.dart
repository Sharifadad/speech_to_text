import 'ai_message.dart';

class AiChatHistory {
  final String id;
  final String title;
  final List<AiMessage> messages;
  final DateTime date;

  AiChatHistory({
    required this.id,
    required this.title,
    required this.messages,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((msg) => msg.toMap()).toList(),
      'date': date.toIso8601String(),
    };
  }

  factory AiChatHistory.fromMap(Map<String, dynamic> map) {
    return AiChatHistory(
      id: map['id'],
      title: map['title'],
      messages: (map['messages'] as List)
          .map((msg) => AiMessage.fromMap(msg))
          .toList(),
      date: DateTime.parse(map['date']),
    );
  }
}