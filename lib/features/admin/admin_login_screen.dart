import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/config/app_config.dart';
import '../../core/security/security_utils.dart';
import '../../core/security/rate_limiter.dart';
import '../../core/security/cpf_validator.dart';
import '../../data/repositories/researcher_repository.dart';
import '../../data/repositories/audit_repository.dart';

class _CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    final d = nv.text.replaceAll(RegExp(r'\D'), '');
    final b = StringBuffer();
    for (int i = 0; i < d.length && i < 11; i++) {
      if (i == 3 || i == 6) b.write('.');
      if (i == 9) b.write('-');
      b.write(d[i]);
    }
    final f = b.toString();
    return TextEditingValue(
        text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2A1E) : Colors.white;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryDark, AppTheme.primary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              const Icon(Icons.admin_panel_settings_rounded,
                  size: 64, color: Colors.white),
              const SizedBox(height: 12),
              const Text(
                'Acesso Restrito',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text('Área do pesquisador',
                  style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 24),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabs,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: AppTheme.primaryDark,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Senha mestre'),
                    Tab(text: 'CPF + Senha'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _MasterLoginTab(cardBg: cardBg),
                      _ResearcherLoginTab(cardBg: cardBg),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Aba: Senha mestre ───────────────────────────────────────────────────────

class _MasterLoginTab extends StatefulWidget {
  final Color cardBg;
  const _MasterLoginTab({required this.cardBg});

  @override
  State<_MasterLoginTab> createState() => _MasterLoginTabState();
}

class _MasterLoginTabState extends State<_MasterLoginTab> {
  final _ctrl = TextEditingController();
  final _limiter = const RateLimiter(key: 'admin_master', maxAttempts: 5, windowMinutes: 15);
  bool _obscure = true;
  String? _erro;
  bool _blocked = false;
  int _minutesLeft = 0;

  @override
  void initState() {
    super.initState();
    _checkBlock();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _checkBlock() async {
    final blocked = await _limiter.isBlocked();
    final minutes = await _limiter.minutesUntilUnlock();
    if (mounted) setState(() { _blocked = blocked; _minutesLeft = minutes; });
  }

  void _entrar() async {
    await _checkBlock();
    if (_blocked) return;

    // Verifica conforme a versão configurada em AppConfig.adminPasswordHashVersion
    final valid = SecurityUtils.verify(
      _ctrl.text,
      AppConfig.adminPasswordHash,
      AppConfig.adminPasswordHashVersion,
    );

    if (valid) {
      await _limiter.reset();
      await AuditRepository().log(
        action: 'login',
        entity: 'admin',
        performedBy: 'master',
        details: 'Login via senha mestre',
      );
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/admin',
          arguments: {'role': 'master'});
    } else {
      final nowBlocked = await _limiter.recordFailure();
      final count = await _limiter.failureCount();
      final minutes = await _limiter.minutesUntilUnlock();
      if (mounted) {
        setState(() {
          _blocked = nowBlocked;
          _minutesLeft = minutes;
          _erro = nowBlocked
              ? 'Acesso bloqueado por $_minutesLeft minuto(s) após $count tentativas.'
              : 'Senha incorreta. ${5 - count} tentativa(s) restante(s).';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Senha de acesso mestre',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          const SizedBox(height: 4),
          const Text('Acesso completo a todos os dados.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMedium)),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            obscureText: _obscure,
            onSubmitted: (_) => _entrar(),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          if (_blocked)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.lock_clock_rounded,
                    color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Acesso bloqueado por $_minutesLeft minuto(s).',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                )),
              ]),
            )
          else if (_erro != null) ...[
            const SizedBox(height: 10),
            Text(_erro!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _blocked ? null : _entrar,
            child: const Text('Acessar painel'),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('← Voltar ao app',
                  style: TextStyle(color: AppTheme.textMedium)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Aba: CPF + Senha (pesquisador aprovado) ─────────────────────────────────

class _ResearcherLoginTab extends StatefulWidget {
  final Color cardBg;
  const _ResearcherLoginTab({required this.cardBg});

  @override
  State<_ResearcherLoginTab> createState() => _ResearcherLoginTabState();
}

class _ResearcherLoginTabState extends State<_ResearcherLoginTab> {
  final _repo = ResearcherRepository();
  final _cpfCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _limiter = const RateLimiter(key: 'admin_researcher', maxAttempts: 5, windowMinutes: 15);
  bool _obscure = true;
  bool _loading = false;
  bool _blocked = false;
  int _minutesLeft = 0;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _checkBlock();
  }

  @override
  void dispose() {
    _cpfCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBlock() async {
    final blocked = await _limiter.isBlocked();
    final minutes = await _limiter.minutesUntilUnlock();
    if (mounted) setState(() { _blocked = blocked; _minutesLeft = minutes; });
  }

  Future<void> _entrar() async {
    await _checkBlock();
    if (_blocked) return;

    final cpf = _cpfCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (!CpfValidator.isValid(cpf)) {
      setState(() => _erro = 'CPF inválido.');
      return;
    }
    if (_senhaCtrl.text.isEmpty) {
      setState(() => _erro = 'Preencha a senha.');
      return;
    }

    setState(() { _loading = true; _erro = null; });
    final ok = await _repo.login(cpf, _senhaCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      await _limiter.reset();
      await AuditRepository().log(
        action: 'login',
        entity: 'researcher',
        performedBy: '${cpf.substring(0, 3)}***',
        details: 'Login de pesquisador',
      );
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/admin',
          arguments: {'role': 'researcher'});
    } else {
      final nowBlocked = await _limiter.recordFailure();
      final count = await _limiter.failureCount();
      final minutes = await _limiter.minutesUntilUnlock();
      if (mounted) {
        setState(() {
          _blocked = nowBlocked;
          _minutesLeft = minutes;
          _erro = nowBlocked
              ? 'Acesso bloqueado por $_minutesLeft minuto(s) após $count tentativas.'
              : 'CPF ou senha incorretos. ${5 - count} tentativa(s) restante(s).';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Entrar como pesquisador',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          const SizedBox(height: 4),
          const Text('Use o CPF e a senha cadastrados na sua solicitação.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMedium)),
          const SizedBox(height: 20),
          TextField(
            controller: _cpfCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [_CpfFormatter()],
            decoration: const InputDecoration(
              labelText: 'CPF',
              hintText: '000.000.000-00',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _senhaCtrl,
            obscureText: _obscure,
            onSubmitted: (_) => _entrar(),
            decoration: InputDecoration(
              labelText: 'Senha',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          if (_blocked)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.lock_clock_rounded,
                    color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Acesso bloqueado por $_minutesLeft minuto(s).',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                )),
              ]),
            )
          else if (_erro != null) ...[
            const SizedBox(height: 10),
            Text(_erro!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_loading || _blocked) ? null : _entrar,
            child: _loading
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Entrar'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                const Text('Ainda não tem acesso?',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textMedium)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _showRequestDialog(context),
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: const Text('Solicitar acesso como pesquisador'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('← Voltar ao app',
                  style: TextStyle(color: AppTheme.textMedium)),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _RequestAccessSheet(repo: _repo),
    );
  }
}

// ─── Sheet: Solicitar acesso ─────────────────────────────────────────────────

class _RequestAccessSheet extends StatefulWidget {
  final ResearcherRepository repo;
  const _RequestAccessSheet({required this.repo});

  @override
  State<_RequestAccessSheet> createState() => _RequestAccessSheetState();
}

class _RequestAccessSheetState extends State<_RequestAccessSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _instCtrl = TextEditingController();
  final _justCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    _instCtrl.dispose();
    _justCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _erro = null; });

    final cpf = _cpfCtrl.text.replaceAll(RegExp(r'\D'), '');
    final exists = await widget.repo.cpfAlreadyExists(cpf);
    if (!mounted) return;

    if (exists) {
      setState(() {
        _loading = false;
        _erro = 'Este CPF já possui uma solicitação cadastrada.';
      });
      return;
    }

    await widget.repo.saveRequest(
      cpf: cpf,
      name: _nomeCtrl.text.trim(),
      institution: _instCtrl.text.trim(),
      justification: _justCtrl.text.trim(),
      password: _senhaCtrl.text,
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Solicitação enviada! Aguarde aprovação do administrador.'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.send_outlined, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Text('Solicitar acesso',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                'Preencha os dados abaixo. Sua solicitação será analisada pelo administrador.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMedium),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome completo *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cpfCtrl,
                decoration: const InputDecoration(
                    labelText: 'CPF *', hintText: '000.000.000-00'),
                keyboardType: TextInputType.number,
                inputFormatters: [_CpfFormatter()],
                validator: (v) {
                  final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  return d.length != 11 ? 'CPF inválido' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _instCtrl,
                decoration:
                    const InputDecoration(labelText: 'Instituição / Universidade *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _justCtrl,
                decoration: const InputDecoration(
                    labelText: 'Justificativa *',
                    hintText: 'Por que você precisa de acesso?'),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _senhaCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Senha de acesso *',
                  hintText: 'Crie uma senha',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) =>
                    v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              if (_erro != null) ...[
                const SizedBox(height: 10),
                Text(_erro!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _enviar,
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Enviar solicitação'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
