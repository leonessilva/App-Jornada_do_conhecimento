import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityProvider extends ChangeNotifier {
  bool _largeFontEnabled = false;
  bool _highContrastEnabled = false;
  bool _autoTtsEnabled = false;

  bool get largeFontEnabled => _largeFontEnabled;
  bool get highContrastEnabled => _highContrastEnabled;

  /// true quando o participante tem baixa escolaridade —
  /// faz com que todas as telas narrem o conteúdo automaticamente ao abrir.
  bool get autoTtsEnabled => _autoTtsEnabled;

  double get textScaleFactor => _largeFontEnabled ? 1.3 : 1.0;

  /// Escolaridades que ativam o modo de narração automática.
  static const _baixaEscolaridade = {
    'Sem escolaridade',
    'Ensino Fundamental incompleto',
  };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _largeFontEnabled = prefs.getBool('acc_large_font') ?? false;
    _highContrastEnabled = prefs.getBool('acc_high_contrast') ?? false;
    _autoTtsEnabled = prefs.getBool('acc_auto_tts') ?? false;
    notifyListeners();
  }

  /// Ativa o modo de narração automática com base na escolaridade informada.
  Future<void> avaliarEscolaridade(String escolaridade) async {
    final ativar = _baixaEscolaridade.contains(escolaridade);
    if (_autoTtsEnabled == ativar) return;
    _autoTtsEnabled = ativar;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acc_auto_tts', ativar);
    notifyListeners();
  }

  Future<void> toggleLargeFont() async {
    _largeFontEnabled = !_largeFontEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acc_large_font', _largeFontEnabled);
    notifyListeners();
  }

  Future<void> toggleHighContrast() async {
    _highContrastEnabled = !_highContrastEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acc_high_contrast', _highContrastEnabled);
    notifyListeners();
  }
}
