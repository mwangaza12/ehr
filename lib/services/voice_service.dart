// lib/services/voice_service.dart
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastResult = '';
  
  Future<bool> initialize() async {
    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted) {
      return false;
    }
    
    final hasSpeech = await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
      },
      onError: (error) {
        print('Speech error: $error');
      },
    );
    
    return hasSpeech;
  }
  
  Future<String?> startListening({
    Function(String text)? onResult,
    Function()? onListeningStarted,
    Function()? onListeningStopped,
  }) async {
    if (!await initialize()) {
      return null;
    }
    
    _speech.listen(
      onResult: (result) {
        _lastResult = result.recognizedWords;
        if (result.finalResult) {
          onResult?.call(_lastResult);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
      cancelOnError: true,
      partialResults: true,
    );
    
    _isListening = true;
    onListeningStarted?.call();
    
    // Wait for completion or timeout
    await Future.delayed(const Duration(seconds: 30));
    
    if (_isListening) {
      await stopListening();
      onListeningStopped?.call();
    }
    
    return _lastResult.isNotEmpty ? _lastResult : null;
  }
  
  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
  }
  
  bool get isListening => _isListening;
  String get lastResult => _lastResult;
  
  Future<List<stt.LocaleName>> getAvailableLanguages() async {
    if (await initialize()) {
      return _speech.locales();
    }
    return [];
  }
  
  void dispose() {
    _speech.cancel();
  }
}