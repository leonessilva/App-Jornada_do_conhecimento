import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/question.dart';

class QuestionWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _blocoChip(),
        const SizedBox(height: 14),
        Text(
          question.texto,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        if (question.tipo == QuestionType.aberta)
          _openField()
        else if (question.tipo == QuestionType.likert)
          _likertScale()
        else
          _optionsList(),
      ],
    );
  }

  Widget _blocoChip() {
    final palette = AppTheme.blocoColor(question.bloco);
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
            question.bloco.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: palette.text,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionsList() => Column(
        children: question.opcoes!.map((opcao) {
          final selected = selectedAnswer == opcao;
          return GestureDetector(
            onTap: () => onAnswerSelected(opcao),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primaryPale : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppTheme.primary : const Color(0xFFE5DFD3),
                  width: selected ? 2 : 1.5,
                ),
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
                            : const Color(0xFFC8C0B3),
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
                            ? AppTheme.primaryDark
                            : AppTheme.textDark,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
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

  Widget _likertScale() {
    final opcoes = question.opcoes!;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(opcoes.length, (i) {
            final val = opcoes[i];
            final selected = selectedAnswer == val;
            return GestureDetector(
              onTap: () => onAnswerSelected(val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppTheme.primary : Colors.white,
                  border: Border.all(
                    color: selected
                        ? AppTheme.primary
                        : const Color(0xFFE5DFD3),
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
                      color: selected ? Colors.white : AppTheme.textMedium,
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
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textMedium),
            ),
            Text(
              opcoes.last.replaceAll(RegExp(r'^\d — '), ''),
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textMedium),
            ),
          ],
        ),
        if (selectedAnswer != null) ...[
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryPale,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              selectedAnswer!.replaceAll(RegExp(r'^\d — '), ''),
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

  Widget _openField() => TextField(
        maxLines: 4,
        onChanged: onAnswerSelected,
        controller: TextEditingController(text: selectedAnswer),
        decoration: InputDecoration(
          hintText: 'Digite sua resposta aqui...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          alignLabelWithHint: true,
        ),
        style: const TextStyle(fontSize: 15, color: AppTheme.textDark),
      );
}
