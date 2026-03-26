import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Serviço TTS global — use TtsService() para acessar o singleton.
///
/// Permite narrar qualquer texto em pt-BR sem criar múltiplas instâncias
/// do FlutterTts (o que causaria conflitos de áudio).
class TtsService {
  static final TtsService _instance = TtsService._();
  factory TtsService() => _instance;
  TtsService._() {
    _init();
  }

  final FlutterTts _tts = FlutterTts();

  /// true enquanto o áudio está tocando.
  final isSpeaking = ValueNotifier<bool>(false);

  void _init() {
    if (kIsWeb) return;
    _tts.setLanguage('pt-BR');
    _tts.setSpeechRate(0.45);   // fala devagar, fácil de acompanhar
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
    _tts.setCompletionHandler(() => isSpeaking.value = false);
    _tts.setCancelHandler(() => isSpeaking.value = false);
    _tts.setErrorHandler((_) => isSpeaking.value = false);
  }

  /// Inicia a narração do [text].
  Future<void> speak(String text) async {
    if (kIsWeb) return;
    isSpeaking.value = true;
    await _tts.speak(text);
  }

  /// Para a narração em curso.
  Future<void> stop() async {
    if (kIsWeb) return;
    await _tts.stop();
    isSpeaking.value = false;
  }

  /// Alterna entre iniciar e parar a narração.
  Future<void> toggle(String text) async {
    if (isSpeaking.value) {
      await stop();
    } else {
      await speak(text);
    }
  }
}
