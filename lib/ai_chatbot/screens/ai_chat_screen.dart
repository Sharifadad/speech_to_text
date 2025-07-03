import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:worldchat/ai_chatbot/models/ai_message.dart';
import '../controllers/ai_chat_controller.dart';
import '../services/ai_service.dart';
import '../widgets/ai_message_bubble.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<AiChatController>(context, listen: false);
      controller.initializeVoice();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSearchRequest(String query) async {
    final controller = Provider.of<AiChatController>(context, listen: false);
    final aiService = AiService();

    // Show typing indicator through controller
    controller.setTyping(true);

    try {
      // First get the AI response
      final response = await aiService.getAiResponse(controller.messages);

      // Check if the response contains a search request
      if (response.contains('[SEARCH:')) {
        // Extract the search query
        final searchQuery = response.split('[SEARCH:')[1].split(']')[0];

        // Perform the actual search
        final searchResults = await aiService.performWebSearch(searchQuery);

        // Add the search results to the chat
        await controller.sendMessage(searchResults, isUser: false);
      } else {
        // Add the normal response to the chat
        await controller.sendMessage(response, isUser: false);
      }
    } catch (e) {
      await controller.sendMessage(
        'Sorry, I encountered an error: ${e.toString()}',
        isUser: false,
      );
    } finally {
      controller.setTyping(false);
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isNotEmpty) {
      final controller = Provider.of<AiChatController>(context, listen: false);
      final message = _textController.text.trim();
      await controller.sendMessage(message, isUser: true);
      _textController.clear();
      _scrollToBottom();

      // Handle potential search request
      await _handleSearchRequest(message);
    }
  }

  void _toggleVoiceInput() {
    final controller = Provider.of<AiChatController>(context, listen: false);
    if (controller.isListening) {
      controller.stopListening();
    } else {
      controller.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AiChatController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice AI Assistant'),
        actions: [
          IconButton(
            icon: Icon(
              controller.isListening ? Icons.mic_off : Icons.mic,
              color: controller.isListening ? Colors.red : Colors.white,
            ),
            onPressed: _toggleVoiceInput,
          ),
        ],
      ),
      body: Column(
        children: [
          if (controller.isListening)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: controller.messages.length,
              itemBuilder: (context, index) {
                final message = controller.messages[index];
                return AiMessageBubble(
                  message: message,
                  isUser: message.sender == MessageSender.user,
                );
              },
            ),
          ),
          if (controller.isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('AI is typing...', style: TextStyle(color: Colors.grey)),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: controller.isListening
            ? Colors.red
            : Theme.of(context).primaryColor,
        onPressed: _toggleVoiceInput,
        tooltip: 'Voice Input',
        child: Icon(
          controller.isListening ? Icons.mic_off : Icons.mic,
          color: Colors.white,
        ),
      ),
    );
  }
}