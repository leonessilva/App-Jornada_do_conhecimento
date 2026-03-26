import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../tts_service.dart';
import '../theme/app_theme.dart';

/// Botão "Ouvir / Parar" que narra [text] em pt-BR via TtsService.
///
/// Uso básico:
/// ```dart
/// TtsButton(text: 'Texto que será narrado')
/// ```
///
/// Em plataformas web retorna SizedBox.shrink() pois flutter_tts
/// não suporta web sem plugin adicional.
class TtsButton extends StatelessWidget {
  /// Texto que será narrado ao tocar.
  final String text;

  /// Rótulo visível no botão quando em modo "Ouvir".
  final String label;

  /// Cor do botão (padrão: AppTheme.primary).
  final Color? color;

  const TtsButton({
    super.key,
    required this.text,
    this.label = 'Ouvir',
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();

    final baseColor = color ?? AppTheme.primary;

    return ValueListenableBuilder<bool>(
      valueListenable: TtsService().isSpeaking,
      builder: (context, speaking, _) {
        return GestureDetector(
          onTap: () => TtsService().toggle(text),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: speaking ? baseColor : baseColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: speaking
                    ? baseColor
                    : baseColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                  color: speaking ? Colors.white : baseColor,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  speaking ? 'Parar' : label,
                  style: TextStyle(
                    color: speaking ? Colors.white : baseColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
