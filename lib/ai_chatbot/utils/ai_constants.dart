class AiConstants {
  static const String searchEngineUrl = 'https://www.google.com/search?q=';
  static const String wikipediaApiUrl = 'https://en.wikipedia.org/w/api.php';
  static const String duckDuckGoApiUrl = 'https://api.duckduckgo.com/';

  // Add these new constants for web search functionality
  static const String webSearchPrompt = '''
  When you need to search for current information, include this tag in your response: 
  [SEARCH:your search query here]
  ''';

  static const String searchResultPrefix = '[SEARCH_RESULT]';
}