import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

/// Vídeos educativos sobre uso seguro de agrotóxicos.
/// Substitua os links abaixo pelos vídeos reais da pesquisa.
const _videos = [
  _Video(
    titulo: 'O que são agrotóxicos e seus riscos à saúde',
    descricao: 'Entenda os tipos de agrotóxicos, como agem no corpo humano e os principais riscos para quem trabalha no campo.',
    duracao: '8 min',
    icone: Icons.science_outlined,
  ),
  _Video(
    titulo: 'Equipamentos de Proteção Individual (EPI)',
    descricao: 'Como usar corretamente máscara, luvas, botas e roupas de proteção durante a aplicação de agrotóxicos.',
    duracao: '6 min',
    icone: Icons.security_outlined,
  ),
  _Video(
    titulo: 'Boas práticas no manuseio e aplicação',
    descricao: 'Cuidados antes, durante e após a aplicação: mistura, direção do vento, horário e descarte de embalagens.',
    duracao: '10 min',
    icone: Icons.agriculture_outlined,
  ),
  _Video(
    titulo: 'Impactos ambientais e no Rio',
    descricao: 'Como os agrotóxicos afetam a água, o solo, os peixes e a saúde da comunidade ribeirinha.',
    duracao: '7 min',
    icone: Icons.water_outlined,
  ),
  _Video(
    titulo: 'O que fazer em caso de intoxicação',
    descricao: 'Reconheça os sintomas de intoxicação e saiba como agir rapidamente para proteger você e sua família.',
    duracao: '5 min',
    icone: Icons.local_hospital_outlined,
  ),
];

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final Set<int> _assistidos = {};

  @override
  Widget build(BuildContext context) {
    final todos = _assistidos.length == _videos.length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryDark, Color(0xFF1A5276)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Cabeçalho
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.play_lesson_rounded,
                            color: Colors.white70, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Conteúdo Educativo',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Vídeos sobre Agrotóxicos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Barra de progresso de vídeos
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _videos.isEmpty
                            ? 0
                            : _assistidos.length / _videos.length,
                        backgroundColor: Colors.white24,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_assistidos.length} de ${_videos.length} assistidos',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Lista de vídeos
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _videos.length,
                  itemBuilder: (ctx, i) => _videoCard(i),
                ),
              ),
              // Botão continuar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    if (!todos)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Assista todos os vídeos para continuar',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12),
                        ),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            todos ? Colors.white : Colors.white24,
                        foregroundColor: todos
                            ? AppTheme.primaryDark
                            : Colors.white54,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: todos
                          ? () async {
                              await context
                                  .read<AppProvider>()
                                  .finishVideos();
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(
                                    context, '/instruction',
                                    arguments: 'pos');
                              }
                            }
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Continuar para o pós-teste',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _videoCard(int index) {
    final v = _videos[index];
    final assistido = _assistidos.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: assistido
            ? Colors.white
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: assistido
            ? Border.all(color: AppTheme.primaryLight, width: 2)
            : null,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: assistido
                ? AppTheme.primaryPale
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            assistido ? Icons.check_circle_rounded : v.icone,
            color: assistido ? AppTheme.primary : Colors.grey.shade500,
            size: 22,
          ),
        ),
        title: Text(
          v.titulo,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: assistido ? AppTheme.textDark : AppTheme.textDark,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              v.descricao,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textMedium, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer_outlined,
                    size: 11, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Text(v.duracao,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ],
        ),
        trailing: TextButton(
          onPressed: () => setState(() => _assistidos.add(index)),
          style: TextButton.styleFrom(
            backgroundColor: assistido
                ? AppTheme.primaryPale
                : AppTheme.primary,
            foregroundColor:
                assistido ? AppTheme.primary : Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            assistido ? 'Assistido' : 'Assistir',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _Video {
  final String titulo;
  final String descricao;
  final String duracao;
  final IconData icone;
  const _Video({
    required this.titulo,
    required this.descricao,
    required this.duracao,
    required this.icone,
  });
}
