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
      setState(() => _erro = 'CPF não encontrado. Verifique ou inicie como novo participante.');
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
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            // Logo / título
            const Icon(Icons.eco_rounded, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Jornada do',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
            const Text(
              'Conhecimento',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 48),
            // Card de login
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.all(28),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bem-vindo de volta',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Digite seu CPF para retomar de onde parou.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'CPF',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cpfCtrl,
                          decoration: const InputDecoration(
                            hintText: '000.000.000-00',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [_CpfInputFormatter()],
                          validator: (v) {
                            final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                            if (digits.length != 11) return 'CPF inválido (11 dígitos)';
                            return null;
                          },
                        ),
                        if (_erro != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _erro!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loading ? null : _entrar,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Entrar'),
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                'Primeira vez no app?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textMedium,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () => Navigator.pushReplacementNamed(
                                    context, '/consent'),
                                child: const Text('Novo participante'),
                              ),
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/admin_login'),
                                icon: const Icon(
                                    Icons.admin_panel_settings_outlined,
                                    size: 16,
                                    color: AppTheme.textMedium),
                                label: const Text(
                                  'Acesso do pesquisador',
                                  style: TextStyle(
                                    color: AppTheme.textMedium,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
