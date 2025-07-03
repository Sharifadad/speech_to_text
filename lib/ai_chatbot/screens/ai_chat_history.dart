import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/ai_chat_controller.dart';
import '../models/ai_chat_history.dart';

class AiChatHistoryScreen extends StatelessWidget {
  const AiChatHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatController = Provider.of<AiChatController>(context);
    final history = chatController.chatHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
      ),
      body: ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final chat = history[index];
          return ListTile(
            title: Text(chat.title),
            subtitle: Text('${chat.messages.length} messages'),
            trailing: Text(chat.date.toString().substring(0, 10)),
            onTap: () {
              chatController.loadChatFromHistory(chat);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}