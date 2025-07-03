import 'package:flutter/foundation.dart';

enum MessageSender { user, bot }

class AiMessage {
  final String content;
  final DateTime timeSent;
  final MessageSender sender;

  AiMessage({
    required this.content,
    required this.sender,
    DateTime? timeSent,
  }) : timeSent = timeSent ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'timeSent': timeSent.toIso8601String(),
      'sender': sender == MessageSender.user ? 'user' : 'bot',
    };
  }

  factory AiMessage.fromMap(Map<String, dynamic> map) {
    return AiMessage(
      content: map['content'],
      timeSent: DateTime.parse(map['timeSent']),
      sender: map['sender'] == 'user' ? MessageSender.user : MessageSender.bot,
    );
  }
}