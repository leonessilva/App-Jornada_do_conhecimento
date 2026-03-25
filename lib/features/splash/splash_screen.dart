import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Aguarda inicialização do provider e navega
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigate();
    });
  }

  Future<void> _navigate() async {
    // Aguarda o carregamento do provider
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final provider = context.read<AppProvider>();
    // Espera terminar de carregar
    while (provider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final step = provider.currentStep;

    if (step == null) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      switch (step) {
        case 'registration':
          Navigator.pushReplacementNamed(context, '/registration');
          break;
        case 'questionnaire_pre':
          Navigator.pushReplacementNamed(context, '/instruction',
              arguments: 'pre');
          break;
        case 'videos':
          Navigator.pushReplacementNamed(context, '/videos');
          break;
        case 'questionnaire_pos':
          Navigator.pushReplacementNamed(context, '/instruction',
              arguments: 'pos');
          break;
        case 'results':
          Navigator.pushReplacementNamed(context, '/results');
          break;
        default:
          Navigator.pushReplacementNamed(context, '/consent');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeIn,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Foto de fundo
            Image.asset(
              'assets/images/splash_bg.jpeg',
              fit: BoxFit.cover,
            ),
            // Overlay escuro para legibilidade
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.70),
                  ],
                ),
              ),
            ),
            Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Jornada do',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 22,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      'Conhecimento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Intervenção educativa\npara agricultores ribeirinhos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 56),
                    SizedBox(
                      width: 200,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'CARREGANDO',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          ],
        ),
      ),
    );
  }
}
