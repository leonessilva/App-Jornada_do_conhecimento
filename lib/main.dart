import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/login/login_screen.dart';
import 'features/consent/consent_screen.dart';
import 'features/registration/registration_screen.dart';
import 'features/questionnaire/questionnaire_screen.dart';
import 'features/questionnaire/instruction_screen.dart';
import 'features/videos/video_screen.dart';
import 'features/results/results_screen.dart';
import 'features/admin/admin_login_screen.dart';
import 'features/admin/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWebNoWebWorker;
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: const JornadaApp(),
    ),
  );
}

class JornadaApp extends StatelessWidget {
  const JornadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jornada do Conhecimento',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (ctx) => const SplashScreen(),
        '/login': (ctx) => const LoginScreen(),
        '/consent': (ctx) => const ConsentScreen(),
        '/registration': (ctx) => const RegistrationScreen(),
        '/instruction': (ctx) => InstructionScreen(
              fase: ModalRoute.of(ctx)!.settings.arguments as String? ?? 'pre',
            ),
        '/questionnaire': (ctx) => const QuestionnaireScreen(),
        '/videos': (ctx) => const VideoScreen(),
        '/results': (ctx) => const ResultsScreen(),
        '/admin_login': (ctx) => const AdminLoginScreen(),
        '/admin': (ctx) => const AdminDashboardScreen(),
      },
    );
  }
}
