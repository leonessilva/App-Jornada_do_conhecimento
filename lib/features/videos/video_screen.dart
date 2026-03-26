import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

const _videos = [
  _Video(
    titulo: 'O que são agrotóxicos e seus riscos à saúde',
    descricao: 'Entenda os tipos de agrotóxicos, como agem no corpo humano e os principais riscos para quem trabalha no campo.',
    duracao: 8,
    icone: Icons.science_outlined,
  ),
  _Video(
    titulo: 'Equipamentos de Proteção Individual (EPI)',
    descricao: 'Como usar corretamente máscara, luvas, botas e roupas de proteção durante a aplicação de agrotóxicos.',
    duracao: 6,
    icone: Icons.security_outlined,
  ),
  _Video(
    titulo: 'Boas práticas no manuseio e aplicação',
    descricao: 'Cuidados antes, durante e após a aplicação: mistura, direção do vento, horário e descarte de embalagens.',
    duracao: 10,
    icone: Icons.agriculture_outlined,
  ),
  _Video(
    titulo: 'Impactos ambientais e no Rio',
    descricao: 'Como os agrotóxicos afetam a água, o solo, os peixes e a saúde da comunidade ribeirinha.',
    duracao: 7,
    icone: Icons.water_outlined,
  ),
  _Video(
    titulo: 'O que fazer em caso de intoxicação',
    descricao: 'Reconheça os sintomas de intoxicação e saiba como agir rapidamente para proteger você e sua família.',
    duracao: 5,
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
  int? _expanded; // índice do card expandido

  Future<void> _showSummaryAndContinue(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _VideoSummarySheet(),
    );
    if (!context.mounted) return;
    await context.read<AppProvider>().finishVideos();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/instruction', arguments: 'pos');
    }
  }

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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.play_lesson_rounded, color: Colors.white70, size: 20),
                        SizedBox(width: 8),
                        Text('Conteúdo Educativo',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Vídeos sobre Agrotóxicos',
                      style: TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _videos.isEmpty ? 0 : _assistidos.length / _videos.length,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_assistidos.length} de ${_videos.length} assistidos',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _videos.length,
                  itemBuilder: (ctx, i) => _videoCard(i),
                ),
              ),
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
                              color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                        ),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: todos ? Colors.white : Colors.white24,
                        foregroundColor: todos ? AppTheme.primaryDark : Colors.white54,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: todos
                          ? () => _showSummaryAndContinue(context)
                          : null,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Continuar para o pós-teste',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
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
    final expandido = _expanded == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: assistido ? Colors.white : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: assistido ? Border.all(color: AppTheme.primaryLight, width: 2) : null,
      ),
      child: Column(
        children: [
          // Linha principal do card
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = expandido ? null : index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: assistido ? AppTheme.primaryPale : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      assistido ? Icons.check_circle_rounded : v.icone,
                      color: assistido ? AppTheme.primary : Colors.grey.shade500,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.titulo,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 11, color: Colors.grey.shade400),
                            const SizedBox(width: 3),
                            Text('${v.duracao} min',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade400)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expandido ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textMedium,
                  ),
                ],
              ),
            ),
          ),

          // Painel expansível com o player
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _PlayerPanel(
              videoIndex: index,
              duracaoMinutos: v.duracao,
              descricao: v.descricao,
              jaAssistido: assistido,
              onConcluido: () => setState(() {
                _assistidos.add(index);
                _expanded = null;
              }),
            ),
            crossFadeState:
                expandido ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

// ─── Player placeholder ──────────────────────────────────────────────────────

class _PlayerPanel extends StatefulWidget {
  final int videoIndex;
  final int duracaoMinutos;
  final String descricao;
  final bool jaAssistido;
  final VoidCallback onConcluido;

  const _PlayerPanel({
    required this.videoIndex,
    required this.duracaoMinutos,
    required this.descricao,
    required this.jaAssistido,
    required this.onConcluido,
  });

  @override
  State<_PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends State<_PlayerPanel> {
  bool _playing = false;
  double _progress = 0.0;
  Timer? _timer;

  // Simulação: cada segundo = 1% de progresso (para facilitar teste)
  // Na versão final com vídeo real, esta lógica será substituída pelo player
  static const _ticksTotal = 100;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    if (_progress >= 1.0) return;
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
    } else {
      setState(() => _playing = true);
      _timer = Timer.periodic(
        Duration(milliseconds: (widget.duracaoMinutos * 600 / _ticksTotal).round()),
        (t) {
          if (!mounted) { t.cancel(); return; }
          setState(() {
            _progress += 1 / _ticksTotal;
            if (_progress >= 1.0) {
              _progress = 1.0;
              _playing = false;
              t.cancel();
            }
          });
          // Ao completar, marca automaticamente como assistido
          if (_progress >= 1.0 && !widget.jaAssistido) {
            widget.onConcluido();
          }
        },
      );
    }
  }

  String _formatTime(double progress, int totalMin) {
    final totalSec = totalMin * 60;
    final current = (progress * totalSec).round();
    final m = current ~/ 60;
    final s = current % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalMin = widget.duracaoMinutos;
    final totalStr =
        '${(totalMin).toString().padLeft(2, '0')}:00';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Área do vídeo
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Fundo
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.smart_display_outlined,
                            size: 48, color: Colors.white.withValues(alpha: 0.15)),
                        const SizedBox(height: 8),
                        Text(
                          'Vídeo em preparação',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                // Botão play/pause central
                if (_progress < 1.0)
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white38, width: 2),
                      ),
                      child: Icon(
                        _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                if (_progress >= 1.0)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 36),
                  ),
              ],
            ),
          ),

          // Controles
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Column(
              children: [
                // Barra de progresso
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: AppTheme.primaryLight,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white12,
                  ),
                  child: Slider(
                    value: _progress,
                    onChanged: (v) {
                      _timer?.cancel();
                      setState(() {
                        _progress = v;
                        _playing = false;
                      });
                    },
                  ),
                ),
                // Tempo + botões
                Row(
                  children: [
                    Text(
                      _formatTime(_progress, totalMin),
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    const Spacer(),
                    Text(
                      totalStr,
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Descrição + botão concluir
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.descricao,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      height: 1.4),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.jaAssistido ? null : widget.onConcluido,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.jaAssistido
                          ? Colors.white12
                          : AppTheme.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(widget.jaAssistido
                        ? Icons.check_circle_rounded
                        : Icons.done_rounded),
                    label: Text(widget.jaAssistido
                        ? 'Já assistido'
                        : 'Marcar como assistido'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Video {
  final String titulo;
  final String descricao;
  final int duracao; // em minutos
  final IconData icone;
  const _Video({
    required this.titulo,
    required this.descricao,
    required this.duracao,
    required this.icone,
  });
}

// ─── Resumo pós-vídeo ─────────────────────────────────────────────────────────

const _summaryPoints = [
  _SummaryPoint(
    icon: Icons.science_outlined,
    color: Color(0xFF8E44AD),
    titulo: 'Tipos de agrotóxicos',
    texto: 'Cada agrotóxico age de forma diferente no corpo. Inseticidas, herbicidas e fungicidas têm vias de intoxicação distintas.',
  ),
  _SummaryPoint(
    icon: Icons.security_outlined,
    color: Color(0xFF2980B9),
    titulo: 'EPI salva vidas',
    texto: 'O uso completo do EPI (máscara, luvas, botas e roupa protetora) reduz drasticamente a absorção de agrotóxicos.',
  ),
  _SummaryPoint(
    icon: Icons.agriculture_outlined,
    color: Color(0xFF27AE60),
    titulo: 'Boas práticas no campo',
    texto: 'Respeite o período de carência, devolva embalagens, faça a tríplice lavagem e nunca misture produtos sem orientação.',
  ),
  _SummaryPoint(
    icon: Icons.water_outlined,
    color: Color(0xFF16A085),
    titulo: 'Proteção ambiental',
    texto: 'Agrotóxicos contaminam rios, solos e animais. O uso consciente protege o Rio e garante água limpa para a comunidade.',
  ),
  _SummaryPoint(
    icon: Icons.local_hospital_outlined,
    color: Color(0xFFE74C3C),
    titulo: 'Em caso de intoxicação',
    texto: 'Tontura, náusea, visão turva ou formigamento são sinais de alerta. Procure a UBS imediatamente e leve a embalagem do produto.',
  ),
];

class _SummaryPoint {
  final IconData icon;
  final Color color;
  final String titulo;
  final String texto;
  const _SummaryPoint({
    required this.icon,
    required this.color,
    required this.titulo,
    required this.texto,
  });
}

class _VideoSummarySheet extends StatelessWidget {
  const _VideoSummarySheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPale,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lightbulb_rounded,
                        color: AppTheme.primary, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'O que você aprendeu',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pontos-chave dos vídeos sobre agrotóxicos',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMedium),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(),
            // Lista de pontos
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                itemCount: _summaryPoints.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final p = _summaryPoints[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: p.color.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: p.color.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: p.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(p.icon, color: p.color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.titulo,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: p.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.texto,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textDark,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Botão continuar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded),
                    SizedBox(width: 10),
                    Text('Entendi! Ir para o pós-teste',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
