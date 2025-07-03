class AiPromptTemplates {
  static const String systemPrompt = '''
You are a helpful AI assistant. Your responses should be:
- Clear and concise
- Friendly and professional
- Factually accurate
- Helpful for the user's needs

If you don't know something, say you don't know rather than making up information.
''';

  static const List<String> quickPrompts = [
    "What's the weather like today?",
    "Tell me a fun fact",
    "Help me plan my day",
    "Explain quantum computing simply",
    "Give me a recipe idea"
  ];
}