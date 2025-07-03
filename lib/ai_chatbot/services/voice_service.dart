import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _isListening = false;

  Future<bool> initialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    return await _stt.initialize();
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<String?> listen() async {
    if (_isListening) return null;
    _isListening = true;

    String? result;
    await _stt.listen(
      onResult: (stt.SpeechRecognitionResult res) {
        result = res.recognizedWords;
        _isListening = false;
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );

    while (_isListening) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return result;
  }

  void stop() {
    _stt.stop();
    _tts.stop();
    _isListening = false;
  }
}