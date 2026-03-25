import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cpfCtrl = TextEditingController();
  bool _loading = false;
  bool _mostrarCpf = false;
  String? _erro;

  @override
  void dispose() {
    _cpfCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _erro = null;
    });

    final cpf = _cpfCtrl.text.replaceAll(RegExp(r'\D'), '');
    final provider = context.read<AppProvider>();
    final encontrado = await provider.loginByCpf(cpf);

    if (!mounted) return;
    setState(() => _loading = false);

    if (!encontrado) {
      setState(() => _erro = 'CPF não encontrado.\nVerifique os números e tente de novo.');
      return;
    }

    final step = provider.currentStep;
    switch (step) {
      case 'registration':
        Navigator.pushReplacementNamed(context, '/registration');
        break;
      case 'questionnaire_pre':
        Navigator.pushReplacementNamed(context, '/questionnaire', arguments: 'pre');
        break;
      case 'questionnaire_pos':
        Navigator.pushReplacementNamed(context, '/questionnaire', arguments: 'pos');
        break;
      case 'results':
        Navigator.pushReplacementNamed(context, '/results');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/consent');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2A1E) : Colors.white;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Ícone + título
            const Icon(Icons.eco_rounded, size: 72, color: Colors.white),
            const SizedBox(height: 12),
            const Text(
              'Jornada do Conhecimento',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 40),

            // Card principal
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                child: SingleChildScrollView(
                  child: _mostrarCpf ? _campoCpf(colorScheme) : _opcoes(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tela inicial — dois botões grandes
  Widget _opcoes() {
    return Column(
      children: [
        const Text(
          'O que você quer fazer?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),

        // Botão: primeira vez
        _BotaoGrande(
          icone: Icons.person_add_alt_1_rounded,
          titulo: 'É minha primeira vez',
          subtitulo: 'Quero começar agora',
          cor: AppTheme.primary,
          onTap: () => Navigator.pushReplacementNamed(context, '/consent'),
        ),

        const SizedBox(height: 16),

        // Botão: já participou
        _BotaoGrande(
          icone: Icons.login_rounded,
          titulo: 'Já participei antes',
          subtitulo: 'Quero continuar de onde parei',
          cor: AppTheme.primaryDark,
          onTap: () => setState(() => _mostrarCpf = true),
        ),

        const SizedBox(height: 40),
        TextButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/admin_login'),
          icon: const Icon(Icons.admin_panel_settings_outlined,
              size: 16, color: AppTheme.textMedium),
          label: const Text(
            'Acesso do pesquisador',
            style: TextStyle(color: AppTheme.textMedium, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // Campo CPF
  Widget _campoCpf(ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voltar
          GestureDetector(
            onTap: () => setState(() {
              _mostrarCpf = false;
              _erro = null;
              _cpfCtrl.clear();
            }),
            child: Row(
              children: const [
                Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppTheme.primary),
                SizedBox(width: 4),
                Text('Voltar',
                    style: TextStyle(color: AppTheme.primary, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          const Text(
            'Digite seu CPF',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'São os 11 números do seu documento.',
            style: TextStyle(fontSize: 16, color: AppTheme.textMedium),
          ),
          const SizedBox(height: 28),

          TextFormField(
            controller: _cpfCtrl,
            decoration: const InputDecoration(
              hintText: '000.000.000-00',
              prefixIcon: Icon(Icons.badge_outlined),
              hintStyle: TextStyle(fontSize: 18),
            ),
            style: const TextStyle(fontSize: 22, letterSpacing: 2),
            keyboardType: TextInputType.number,
            inputFormatters: [_CpfInputFormatter()],
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
              if (digits.length != 11) return 'Digite os 11 números do CPF';
              return null;
            },
          ),

          if (_erro != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _erro!,
                      style: const TextStyle(color: Colors.red, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _loading ? null : _entrar,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            child: _loading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}

class _BotaoGrande extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final Color cor;
  final VoidCallback onTap;

  const _BotaoGrande({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icone, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white70, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
