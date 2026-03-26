import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tts_service.dart';
import '../../core/widgets/tts_button.dart';
import '../../providers/accessibility_provider.dart';

class InstructionScreen extends StatefulWidget {
  final String fase;
  const InstructionScreen({super.key, required this.fase});

  @override
  State<InstructionScreen> createState() => _InstructionScreenState();
}

class _InstructionScreenState extends State<InstructionScreen> {
  static const _textoPre =
      'Perguntas iniciais. Antes dos vídeos, vamos conhecer o que você já sabe. '
      'Como funciona? '
      'Primeiro: Toque na resposta. Cada pergunta tem opções para escolher. Toque na que você achar certa. '
      'Segundo: Perguntas com notas. Algumas perguntas pedem para você dar uma nota de um a cinco. Quanto maior a nota, mais você concorda. '
      'Terceiro: Perguntas abertas. Algumas perguntas pedem que você escreva. Não existe resposta certa, escreva o que você pensa. '
      'Quarto: Suas respostas são privadas. Ninguém vai saber o que você respondeu. Os dados são usados só para pesquisa. '
      'Quinto: Sem pressa. Responda com calma. Não tem tempo limite. '
      'Quando estiver pronto, toque em Entendi, vamos começar.';

  static const _textoPos =
      'Perguntas finais. Você já assistiu os vídeos, agora responda de novo as mesmas perguntas. '
      'As instruções são as mesmas de antes. Toque na resposta que você achar certa. '
      'Suas respostas são privadas e não há tempo limite. '
      'Quando estiver pronto, toque em Entendi, vamos começar.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final acc = context.read<AccessibilityProvider>();
      if (acc.autoTtsEnabled) {
        TtsService().speak(
          widget.fase == 'pos' ? _textoPos : _textoPre,
        );
      }
    });
  }

  @override
  void dispose() {
    TtsService().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPos = widget.fase == 'pos';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPos
                ? [AppTheme.primaryDark, const Color(0xFF1A5276)]
                : [AppTheme.primaryDark, AppTheme.primary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 28),

              // Ícone e título
              Text(
                isPos ? '🎓' : '📋',
                style: const TextStyle(fontSize: 56),
              ),
              const SizedBox(height: 12),
              Text(
                isPos ? 'Perguntas finais' : 'Perguntas iniciais',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isPos
                    ? 'Você já assistiu os vídeos — agora responda de novo'
                    : 'Antes dos vídeos, vamos conhecer o que você já sabe',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),
              TtsButton(
                text: isPos ? _textoPos : _textoPre,
                label: 'Ouvir as instruções',
                color: Colors.white,
              ),

              const SizedBox(height: 24),

              // Card de instruções
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Como funciona?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _instrucao(
                          emoji: '👆',
                          titulo: 'Toque na resposta',
                          texto: 'Cada pergunta tem opções para escolher. Toque na que você achar certa.',
                        ),
                        _instrucao(
                          emoji: '⭐',
                          titulo: 'Perguntas com estrelas',
                          texto: 'Algumas perguntas pedem para você dar uma nota de 1 a 5. Quanto mais estrelas, mais você concorda.',
                        ),
                        _instrucao(
                          emoji: '✏️',
                          titulo: 'Perguntas abertas',
                          texto: 'Algumas perguntas pedem que você escreva. Não existe resposta certa — escreva o que você pensa.',
                        ),
                        _instrucao(
                          emoji: '🔒',
                          titulo: 'Suas respostas são privadas',
                          texto: 'Ninguém vai saber o que você respondeu. Os dados são usados só para pesquisa.',
                        ),
                        _instrucao(
                          emoji: '⏱️',
                          titulo: 'Sem pressa',
                          texto: 'Responda com calma. Não tem tempo limite.',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botão iniciar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      '/questionnaire',
                      arguments: widget.fase,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Entendi, vamos começar!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _instrucao({
    required String emoji,
    required String titulo,
    required String texto,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryPale,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMedium,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
