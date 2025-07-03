import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_message.dart';
import '../utils/ai_constants.dart';
import '../utils/ai_prompt_templates.dart';

class AiService {
  Future<String> getAiResponse(List<AiMessage> messages) async {
    try {
      // First check if the user message contains a search request
      final lastUserMessage = messages.lastWhere(
            (msg) => msg.sender == MessageSender.user,
        orElse: () => AiMessage(content: '', sender: MessageSender.user),
      );

      if (lastUserMessage.content.toLowerCase().contains('search') ||
          lastUserMessage.content.toLowerCase().contains('find')) {
        // Extract search query from message
        final query = Uri.encodeComponent(lastUserMessage.content
            .replaceAll('search', '')
            .replaceAll('find', '')
            .trim());

        // Return search instruction with the query
        return '${AiConstants.searchResultPrefix}I found these results for "${lastUserMessage.content}": '
            '[SEARCH:$query]';
      }

      // If no search request, proceed with normal response
      return _generateLocalResponse(lastUserMessage.content);
    } catch (e) {
      throw Exception('Error processing request: $e');
    }
  }

  String _generateLocalResponse(String query) {
    // Simple local responses for common queries
    if (query.toLowerCase().contains('hello') ||
        query.toLowerCase().contains('hi')) {
      return 'Hello! How can I help you today?';
    }
    if (query.toLowerCase().contains('weather')) {
      return '${AiConstants.searchResultPrefix}For accurate weather information, I can search online for you. '
          'Would you like me to check the weather for your location? [SEARCH:current weather]';
    }
    if (query.toLowerCase().contains('news')) {
      return '${AiConstants.searchResultPrefix}Here are some current news headlines: [SEARCH:latest news]';
    }

    // Default response for other queries
    return '${AiConstants.searchResultPrefix}I can help you find information about that. '
        'Would you like me to search online for "$query"? [SEARCH:$query]';
  }

  Future<String> performWebSearch(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${AiConstants.searchEngineUrl}$query'),
      );

      if (response.statusCode == 200) {
        // In a real app, you would parse the HTML response here
        // For simplicity, we'll just return a message with the search URL
        return 'I found results for "$query". You can view them here: '
            '${AiConstants.searchEngineUrl}$query';
      } else {
        throw Exception('Failed to perform search: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error performing search: $e');
    }
  }
}