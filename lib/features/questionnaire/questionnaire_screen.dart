import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/questions_data.dart';
import '../../providers/app_provider.dart';
import 'widgets/question_widget.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  late String _fase;
  late PageController _pageController;
  int _currentIndex = 0;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _fase = (ModalRoute.of(context)?.settings.arguments as String?) ?? 'pre';
      final provider = context.read<AppProvider>();
      final savedIndex = _fase == provider.progress?.fase
          ? (provider.progress?.indicePergunta ?? 0)
          : 0;
      _currentIndex = savedIndex;
      _pageController = PageController(initialPage: savedIndex);
      provider.loadAnswersForFase(_fase);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onAnswer(String questionId, String answer) async {
    await context.read<AppProvider>().saveAnswer(questionId, answer, _fase);
  }

  Future<void> _goNext() async {
    final provider = context.read<AppProvider>();
    if (_currentIndex < kQuestions.length - 1) {
      final next = _currentIndex + 1;
      await provider.updateQuestionIndex(next, _fase);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentIndex = next);
    } else {
      await _finish();
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      final prev = _currentIndex - 1;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentIndex = prev);
    }
  }

  Future<void> _finish() async {
    final provider = context.read<AppProvider>();
    if (_fase == 'pre') {
      await provider.finishPre();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/videos');
    } else {
      await provider.finishPos();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/results');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPos = _fase == 'pos';
    final total = kQuestions.length;
    final progress = (_currentIndex + 1) / total;

    return Scaffold(
      body: SafeArea(
        child: Column(
        children: [
          _gradientHeader(isPos, progress, total),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: total,
              itemBuilder: (context, index) {
                final q = kQuestions[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Consumer<AppProvider>(
                    builder: (_, provider, __) => QuestionWidget(
                      question: q,
                      selectedAnswer: provider.getAnswer(q.id),
                      onAnswerSelected: (answer) => _onAnswer(q.id, answer),
                    ),
                  ),
                );
              },
            ),
          ),
          Consumer<AppProvider>(
            builder: (_, provider, __) => _navigationBar(provider),
          ),
        ],
        ),
      ),
    );
  }

  Widget _gradientHeader(bool isPos, double progress, int total) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPos
                ? [AppTheme.primaryDark, const Color(0xFF1A5276)]
                : [AppTheme.primaryDark, AppTheme.primary],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isPos
                      ? '✅ Pós-teste — Após o Conteúdo'
                      : '📋 Pré-teste — Conhecimento Atual',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/$total',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white24,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isPos
                  ? 'Mesmas perguntas — para comparação de evolução'
                  : 'Responda conforme sua situação atual',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      );

  Widget _navigationBar(AppProvider provider) {
    final q = kQuestions[_currentIndex];
    final answer = provider.getAnswer(q.id);
    final answered = answer != null && answer.isNotEmpty;
    final isLast = _currentIndex == kQuestions.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentIndex > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _goPrev,
                child: const Icon(Icons.arrow_back),
              ),
            ),
          if (_currentIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: answered ? _goNext : null,
              child: Text(
                isLast
                    ? (_fase == 'pre' ? 'Concluir Pré' : 'Concluir Pós')
                    : 'Próxima',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
