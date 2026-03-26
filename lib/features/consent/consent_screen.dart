import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/tts_service.dart';
import '../../core/widgets/tts_button.dart';
import '../../providers/app_provider.dart';

/// Versão atual do TCLE — incrementar a cada alteração do texto do termo.
const kTcleVersion = '1.0';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _check1 = false;
  bool _check2 = false;
  bool _check3 = false;
  bool _loading = false;

  bool get _canProceed => _check1 && _check2 && _check3;

  static const _textoTcle =
      'Termo de Consentimento Livre e Esclarecido. '
      'Título da pesquisa: Intervenção educativa sobre percepção de risco e uso seguro de agrotóxicos com agricultores ribeirinhos. '
      'Do que se trata? Você está sendo convidado a participar de uma pesquisa que avalia o conhecimento e a percepção de risco de agricultores ribeirinhos sobre o uso de agrotóxicos, seus efeitos na saúde e no meio ambiente. '
      'O que vai acontecer? Você responderá um questionário antes e após assistir a vídeos educativos. As perguntas abordam suas práticas de trabalho, saúde e percepção ambiental. Não há respostas certas ou erradas. '
      'Riscos e benefícios: Os riscos são mínimos. Sua participação pode contribuir para políticas públicas de saúde no campo. '
      'Sobre o anonimato: Seus dados serão identificados apenas por um código numérico. Nenhuma informação pessoal será publicada. '
      'Participação voluntária: Você pode desistir a qualquer momento, sem qualquer prejuízo. '
      'Para continuar, você precisa confirmar três itens: '
      'Primeiro: que leu e compreendeu o Termo de Consentimento. '
      'Segundo: que aceita que suas respostas sejam usadas anonimamente para a pesquisa. '
      'Terceiro: que está ciente de que sua participação é voluntária e pode desistir a qualquer momento.';

  @override
  void dispose() {
    TtsService().stop();
    super.dispose();
  }

  Future<void> _accept() async {
    TtsService().stop();
    setState(() => _loading = true);
    try {
      await context.read<AppProvider>().acceptConsent(tcleVersion: kTcleVersion);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/registration');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _reject() {
    TtsService().stop();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Participação encerrada'),
        content: const Text(
          'Você optou por não participar da pesquisa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tcleCard(),
                    const SizedBox(height: 20),
                    const Text(
                      'Para continuar, confirme os itens abaixo:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _checkCard(
                      value: _check1,
                      onTap: () => setState(() => _check1 = !_check1),
                      label: 'Li e compreendi integralmente o Termo de Consentimento Livre e Esclarecido',
                    ),
                    _checkCard(
                      value: _check2,
                      onTap: () => setState(() => _check2 = !_check2),
                      label: 'Aceito que minhas respostas sejam utilizadas anonimamente para fins desta pesquisa',
                    ),
                    _checkCard(
                      value: _check3,
                      onTap: () => setState(() => _check3 = !_check3),
                      label: 'Estou ciente de que minha participação é voluntária e posso desistir a qualquer momento',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _bottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryDark, AppTheme.primary],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PESQUISA CIENTÍFICA',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Termo de Consentimento\nLivre e Esclarecido',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Leia com atenção antes de prosseguir',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TtsButton(
              text: _textoTcle,
              label: 'Ouvir o termo completo',
              color: Colors.white,
            ),
          ],
        ),
      );

  Widget _tcleCard() => Container(
        padding: const EdgeInsets.all(18),
        constraints: const BoxConstraints(maxHeight: 280),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.backgroundAlt),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tcleSection('Título da pesquisa',
                  'Intervenção educativa sobre percepção de risco e uso seguro de agrotóxicos com agricultores ribeirinhos.'),
              _tcleSection('Pesquisadora responsável',
                  'Programa de Pós-Graduação em Saúde Coletiva. Contato pelo e-mail institucional disponível ao final da pesquisa.'),
              _tcleSection('Do que se trata?',
                  'Você está sendo convidado(a) a participar de uma pesquisa que avalia o conhecimento e a percepção de risco de agricultores ribeirinhos sobre o uso de agrotóxicos, seus efeitos na saúde e no meio ambiente.'),
              _tcleSection('O que vai acontecer?',
                  'Você responderá um questionário antes e após assistir a vídeos educativos. As perguntas abordam suas práticas de trabalho, saúde e percepção ambiental. Não há respostas certas ou erradas.'),
              _tcleSection('Riscos e benefícios',
                  'Os riscos são mínimos. Sua participação pode contribuir para políticas públicas de saúde no campo e melhoria das condições de trabalho rural.'),
              _tcleSection('Sobre o anonimato',
                  'Seus dados serão identificados apenas por um código numérico. Nenhuma informação pessoal identificável será publicada.'),
              _tcleSection('Participação voluntária',
                  'Você pode desistir a qualquer momento, sem qualquer prejuízo. Esta pesquisa segue a Resolução CNS 466/2012 e a LGPD.'),
            ],
          ),
        ),
      );

  Widget _tcleSection(String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
                fontSize: 13.5, height: 1.6, color: AppTheme.textDark),
            children: [
              TextSpan(
                text: '$title\n',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              TextSpan(text: body),
            ],
          ),
        ),
      );

  Widget _checkCard({
    required bool value,
    required VoidCallback onTap,
    required String label,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: value ? AppTheme.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: value ? AppTheme.primary : Colors.transparent,
                  border: Border.all(
                    color: value ? AppTheme.primary : const Color(0xFFD0C9BC),
                    width: 2,
                  ),
                ),
                child: value
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: value ? AppTheme.primaryDark : AppTheme.textDark,
                    fontWeight:
                        value ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _bottomButtons() => Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: (_canProceed && !_loading) ? _accept : null,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Aceitar e Iniciar →'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _reject,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
              ),
              child: const Text('Recusar participação'),
            ),
          ],
        ),
      );
}
