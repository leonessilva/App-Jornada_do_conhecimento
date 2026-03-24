import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class InstructionScreen extends StatelessWidget {
  final String fase;
  const InstructionScreen({super.key, required this.fase});

  @override
  Widget build(BuildContext context) {
    final isPos = fase == 'pos';

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
              const SizedBox(height: 32),
              const Icon(Icons.help_outline_rounded,
                  color: Colors.white70, size: 48),
              const SizedBox(height: 12),
              Text(
                isPos ? 'Pós-teste' : 'Pré-teste',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isPos
                    ? 'Após o conteúdo educativo'
                    : 'Antes do conteúdo educativo',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPos
                              ? 'Você assistiu aos vídeos educativos.\nAgora responda as mesmas perguntas.'
                              : 'Antes de começar, leia as instruções abaixo.',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _item(Icons.touch_app_outlined, 'Como responder',
                            'Toque na opção que melhor representa sua situação ou opinião. Para passar para a próxima pergunta, o botão "Próxima" ficará verde após você selecionar uma resposta.'),
                        _item(Icons.linear_scale_rounded, 'Escala de concordância',
                            'Algumas perguntas têm escala de 1 a 5. Escolha o número que melhor representa o quanto você concorda (1 = discordo totalmente, 5 = concordo totalmente).'),
                        _item(Icons.edit_note_rounded, 'Perguntas abertas',
                            'Algumas perguntas pedem que você escreva com suas próprias palavras. Não há resposta certa ou errada.'),
                        _item(Icons.lock_outline_rounded, 'Privacidade',
                            'Suas respostas são confidenciais e usadas apenas para fins científicos. Não há respostas certas ou erradas.'),
                        _item(Icons.access_time_rounded, 'Tempo',
                            'Responda com calma. Não há limite de tempo.'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    '/questionnaire',
                    arguments: fase,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isPos ? 'Iniciar pós-teste' : 'Iniciar questionário',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded),
                    ],
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

  Widget _item(IconData icon, String title, String desc) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryPale,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 3),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMedium,
                          height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
}
