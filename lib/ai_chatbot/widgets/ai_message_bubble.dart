import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_message.dart';
import '../controllers/ai_chat_controller.dart';

class AiMessageBubble extends StatelessWidget {
  final AiMessage message;
  final bool isUser;

  const AiMessageBubble({
    super.key,
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Provider.of<AiChatController>(context, listen: false);

    return GestureDetector(
      onTap: () {
        if (!isUser) {
          controller.speak(message.content);  // Changed from _voiceService to controller
        }
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isUser
                ? theme.primaryColor
                : theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12.0),
              topRight: const Radius.circular(12.0),
              bottomLeft: isUser
                  ? const Radius.circular(12.0)
                  : const Radius.circular(0.0),
              bottomRight: isUser
                  ? const Radius.circular(0.0)
                  : const Radius.circular(12.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 2.0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : theme.colorScheme.onSurface,
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(height: 4.0),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUser)
                    Icon(
                      Icons.volume_up,
                      size: 12.0,
                      color: isUser ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  const SizedBox(width: 4.0),
                  Text(
                    _formatTime(message.timeSent),
                    style: TextStyle(
                      color: isUser
                          ? Colors.white70
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 10.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}