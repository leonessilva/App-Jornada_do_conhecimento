import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import '../../core/theme/app_theme.dart';
import '../../core/config/app_config.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _passwordCtrl = TextEditingController();
  String? _erro;
  bool _obscure = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _entrar() {
    final input = _passwordCtrl.text;
    final hash = sha256.convert(utf8.encode(input)).toString();
    if (hash == AppConfig.adminPasswordHash) {
      Navigator.pushReplacementNamed(context, '/admin');
    } else {
      setState(() => _erro = 'Senha incorreta.');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 64),
              const Icon(Icons.admin_panel_settings_rounded,
                  size: 72, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'Painel Administrativo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Acesso restrito a pesquisadores',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Senha de acesso',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        onSubmitted: (_) => _entrar(),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      if (_erro != null) ...[
                        const SizedBox(height: 10),
                        Text(_erro!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13)),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _entrar,
                        child: const Text('Acessar painel'),
                      ),
                      const Spacer(),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: const Text(
                            '← Voltar ao app',
                            style: TextStyle(color: AppTheme.textMedium),
                          ),
                        ),
                      ),
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
