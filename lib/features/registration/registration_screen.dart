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

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _sexoBio;
  String? _genero;
  String? _gestante;
  String? _idadeFaixa;
  String? _escolaridade;
  String? _estado;
  final _nomeCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _comunidadeCtrl = TextEditingController();
  final _municipioCtrl = TextEditingController();

  static const _estados = [
    'AC','AL','AP','AM','BA','CE','DF','ES','GO',
    'MA','MT','MS','MG','PA','PB','PR','PE','PI',
    'RJ','RN','RS','RO','RR','SC','SP','SE','TO',
  ];
  bool _loading = false;

  static const _sexoBioOpcoes = [
    'Masculino',
    'Feminino',
    'Intersexo',
    'Prefiro não informar',
  ];

  static const _generoOpcoes = [
    'Homem cisgênero',
    'Mulher cisgênera',
    'Homem transgênero',
    'Mulher transgênera',
    'Não-binário',
    'Prefiro não informar',
  ];

  static const _gestanteOpcoes = ['Sim', 'Não', 'Não sei'];

  static const _idadeOpcoes = [
    'Menos de 18 anos',
    '18 a 29 anos',
    '30 a 39 anos',
    '40 a 59 anos',
    '60 anos ou mais',
  ];

  static const _escolaridadeOpcoes = [
    'Sem escolaridade',
    'Ensino Fundamental incompleto',
    'Ensino Fundamental completo',
    'Ensino Médio incompleto',
    'Ensino Médio completo',
    'Ensino Superior',
  ];

  bool get _isFeminino => _sexoBio == 'Feminino';

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    _comunidadeCtrl.dispose();
    _municipioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isFeminino && _gestante == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe se está grávida')),
      );
      return;
    }
    setState(() => _loading = true);

    if (_estado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o estado')),
      );
      setState(() => _loading = false);
      return;
    }
    try {
      await context.read<AppProvider>().saveParticipant(
            nome: _nomeCtrl.text.trim(),
            cpf: _cpfCtrl.text.replaceAll(RegExp(r'\D'), ''),
            sexo: _sexoBio!,
            genero: _genero!,
            gestante: _isFeminino ? _gestante : null,
            idadeFaixa: _idadeFaixa!,
            comunidade: _comunidadeCtrl.text.trim(),
            municipio: _municipioCtrl.text.trim(),
            estado: _estado!,
            escolaridade: _escolaridade ?? 'Não informado',
          );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/instruction',
          arguments: 'pre');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seus Dados'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoCard(),
              const SizedBox(height: 24),

              // Nome
              _label('Nome completo *'),
              TextFormField(
                controller: _nomeCtrl,
                decoration:
                    const InputDecoration(hintText: 'Seu nome completo'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),

              // CPF
              _label('CPF *'),
              TextFormField(
                controller: _cpfCtrl,
                decoration:
                    const InputDecoration(hintText: '000.000.000-00'),
                keyboardType: TextInputType.number,
                inputFormatters: [_CpfInputFormatter()],
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.length != 11) return 'CPF inválido (11 dígitos)';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sexo biológico
              _label('Sexo biológico *'),
              _dropdown(
                value: _sexoBio,
                items: _sexoBioOpcoes,
                hint: 'Selecione',
                onChanged: (v) => setState(() {
                  _sexoBio = v;
                  if (!_isFeminino) _gestante = null;
                }),
                validator: (v) => v == null ? 'Campo obrigatório' : null,
              ),

              // Pergunta condicional: gestante
              if (_isFeminino) ...[
                const SizedBox(height: 16),
                _gestanteCard(),
              ],
              const SizedBox(height: 16),

              // Identidade de gênero
              _label('Identidade de gênero *'),
              _dropdown(
                value: _genero,
                items: _generoOpcoes,
                hint: 'Selecione',
                onChanged: (v) => setState(() => _genero = v),
                validator: (v) => v == null ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),

              // Faixa etária
              _label('Faixa etária *'),
              _dropdown(
                value: _idadeFaixa,
                items: _idadeOpcoes,
                hint: 'Selecione',
                onChanged: (v) => setState(() => _idadeFaixa = v),
                validator: (v) => v == null ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),

              // Comunidade
              _label('Comunidade *'),
              TextFormField(
                controller: _comunidadeCtrl,
                decoration: const InputDecoration(
                    hintText: 'Nome da sua comunidade'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),

              // Município
              _label('Município *'),
              TextFormField(
                controller: _municipioCtrl,
                decoration: const InputDecoration(
                    hintText: 'Ex: Petrolândia, Jatobá, Glória...'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),

              // Estado
              _label('Estado *'),
              _estadoSelector(),
              const SizedBox(height: 16),

              // Escolaridade
              _label('Escolaridade (opcional)'),
              _dropdown(
                value: _escolaridade,
                items: _escolaridadeOpcoes,
                hint: 'Selecione',
                onChanged: (v) => setState(() => _escolaridade = v),
              ),
              const SizedBox(height: 36),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Iniciar Questionário'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _estadoSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: _estado == null
              ? const Color(0xFFE5DFD3)
              : AppTheme.primary,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_estado != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Selecionado: $_estado',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _estados.map((uf) {
              final selected = _estado == uf;
              return GestureDetector(
                onTap: () => setState(() => _estado = uf),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? AppTheme.primary : const Color(0xFFD0C8BC),
                    ),
                  ),
                  child: Text(
                    uf,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppTheme.textMedium,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _gestanteCard() => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFB74D)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pregnant_woman_rounded,
                    color: Color(0xFFE65100), size: 20),
                SizedBox(width: 8),
                Text(
                  'Você está grávida?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFFE65100),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._gestanteOpcoes.map((op) => InkWell(
                  onTap: () => setState(() => _gestante = op),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _gestante == op
                                  ? const Color(0xFFE65100)
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: _gestante == op
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFE65100),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(op, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      );

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppTheme.primary, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Seus dados são protegidos. O CPF é usado apenas para retomar seu progresso.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMedium),
              ),
            ),
          ],
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
      );

  Widget _dropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
    FormFieldValidator<String>? validator,
  }) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        decoration: const InputDecoration(),
        hint: Text(hint),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: validator,
        isExpanded: true,
      );
}
