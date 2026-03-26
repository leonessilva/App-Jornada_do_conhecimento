import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/question.dart';
import '../../../providers/accessibility_provider.dart';

class QuestionWidget extends StatefulWidget {
  final Question question;
  final String? selectedAnswer;
  final ValueChanged<String> onAnswerSelected;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.onAnswerSelected,
  });

  @override
  State<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _tts.setLanguage('pt-BR');
      _tts.setSpeechRate(0.45);
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
    }
    // Auto-narra a pergunta se o modo de baixa escolaridade estiver ativo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || kIsWeb) return;
      if (context.read<AccessibilityProvider>().autoTtsEnabled) {
        setState(() => _speaking = true);
        _tts.speak(widget.question.texto);
      }
    });
  }

  @override
  void didUpdateWidget(QuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      if (!kIsWeb) _tts.stop();
      setState(() => _speaking = false);
      // Auto-narra a nova pergunta ao virar a página
      if (!kIsWeb) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (context.read<AccessibilityProvider>().autoTtsEnabled) {
            setState(() => _speaking = true);
            _tts.speak(widget.question.texto);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) _tts.stop();
    super.dispose();
  }

  Future<void> _toggleSpeak() async {
    if (kIsWeb) return; // TTS não suportado na web
    if (_speaking) {
      await _tts.stop();
      setState(() => _speaking = false);
    } else {
      setState(() => _speaking = true);
      await _tts.speak(widget.question.texto);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _blocoChip(),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.question.texto,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: _speaking ? 'Parar narração' : 'Ouvir pergunta',
              child: InkWell(
                onTap: _toggleSpeak,
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _speaking
                        ? AppTheme.primary.withValues(alpha: 0.15)
                        : (isDark
                            ? const Color(0xFF243024)
                            : AppTheme.backgroundAlt),
                    shape: BoxShape.circle,
                    border: _speaking
                        ? Border.all(color: AppTheme.primary, width: 1.5)
                        : null,
                  ),
                  child: Icon(
                    _speaking
                        ? Icons.stop_rounded
                        : Icons.volume_up_rounded,
                    size: 22,
                    color: _speaking
                        ? AppTheme.primary
                        : cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (widget.question.tipo == QuestionType.aberta)
          _openField(cs)
        else if (widget.question.tipo == QuestionType.likert)
          _likertScale(cs, isDark)
        else
          _optionsList(cs, isDark),
      ],
    );
  }

  Widget _blocoChip() {
    final palette = AppTheme.blocoColor(widget.question.bloco);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.dot,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.question.bloco,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionsList(ColorScheme cs, bool isDark) => Column(
        children: (widget.question.opcoes ?? []).map((opcao) {
          final selected = widget.selectedAnswer == opcao;
          final cardColor = selected
              ? (isDark
                  ? AppTheme.primary.withValues(alpha: 0.28)
                  : AppTheme.primaryPale)
              : cs.surface;
          final borderColor = selected
              ? AppTheme.primary
              : (isDark ? const Color(0xFF3A4F3A) : const Color(0xFFE5DFD3));
          return GestureDetector(
            onTap: () => widget.onAnswerSelected(opcao),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: selected ? 2 : 1.5),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppTheme.primary : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : (isDark
                                ? Colors.white38
                                : const Color(0xFFC8C0B3)),
                        width: 2.5,
                      ),
                    ),
                    child: selected
                        ? const Center(
                            child: CircleAvatar(
                              radius: 4,
                              backgroundColor: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      opcao,
                      style: TextStyle(
                        color: selected
                            ? (isDark ? AppTheme.primaryLight : AppTheme.primaryDark)
                            : cs.onSurface,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _likertScale(ColorScheme cs, bool isDark) {
    final opcoes = widget.question.opcoes!;
    final labelColor = cs.onSurface.withValues(alpha: 0.55);
    final circleUnselectedColor =
        isDark ? const Color(0xFF1E2A1E) : Colors.white;
    final circleBorderColor =
        isDark ? const Color(0xFF3A4F3A) : const Color(0xFFE5DFD3);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(opcoes.length, (i) {
            final val = opcoes[i];
            final selected = widget.selectedAnswer == val;
            return GestureDetector(
              onTap: () => widget.onAnswerSelected(val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppTheme.primary : circleUnselectedColor,
                  border: Border.all(
                    color: selected ? AppTheme.primary : circleBorderColor,
                    width: selected ? 2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: selected ? Colors.white : cs.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              opcoes.first.replaceAll(RegExp(r'^\d — '), ''),
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
            Text(
              opcoes.last.replaceAll(RegExp(r'^\d — '), ''),
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
          ],
        ),
        if (widget.selectedAnswer != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.primary.withValues(alpha: 0.25)
                  : AppTheme.primaryPale,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.selectedAnswer!.replaceAll(RegExp(r'^\d — '), ''),
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _openField(ColorScheme cs) => TextField(
        maxLines: 4,
        onChanged: widget.onAnswerSelected,
        controller: TextEditingController(text: widget.selectedAnswer),
        decoration: InputDecoration(
          hintText: 'Digite sua resposta aqui...',
          hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
          alignLabelWithHint: true,
        ),
        style: TextStyle(fontSize: 15, color: cs.onSurface),
      );
}
