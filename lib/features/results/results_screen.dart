import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/sync_service.dart';
import '../../core/tts_service.dart';
import '../../core/widgets/tts_button.dart';
import '../../data/repositories/admin_repository.dart';
import '../../providers/accessibility_provider.dart';
import '../../providers/app_provider.dart';
import 'ubs_card.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  ParticipantStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    TtsService().stop();
    super.dispose();
  }

  String _buildTextoResultado(String primeiroNome) {
    final buffer = StringBuffer();
    buffer.write(
        primeiroNome.isNotEmpty ? 'Parabéns, $primeiroNome! ' : 'Parabéns! ');
    buffer.write('Você completou toda a jornada! ');
    buffer.write(
        'Sua participação é muito importante para entendermos como proteger melhor a saúde de agricultores ribeirinhos. ');
    if (_stats != null) {
      if (_stats!.pctPre != null) {
        buffer.write(
            'Antes dos vídeos, você acertou ${_stats!.pctPre!.toStringAsFixed(0)} por cento das questões. ');
      }
      if (_stats!.pctPos != null) {
        buffer.write(
            'Depois dos vídeos, você acertou ${_stats!.pctPos!.toStringAsFixed(0)} por cento. ');
      }
      if (_stats!.ganho != null && _stats!.ganho! > 0) {
        buffer.write(
            'Você aprendeu ${_stats!.ganho!.toStringAsFixed(0)} por cento a mais sobre agrotóxicos! ');
      }
    }
    buffer.write('Conhecimento é proteção. Continue cuidando de você e da sua família!');
    return buffer.toString();
  }

  Future<void> _loadStats() async {
    final provider = context.read<AppProvider>();
    if (provider.participantId == null) return;
    final repo = AdminRepository();
    final all = await repo.getAllStats();
    if (!mounted) return;
    final mine = all.where((s) => s.participant.id == provider.participantId).firstOrNull;
    setState(() => _stats = mine);

    // Auto-narra o resultado se modo baixa escolaridade ativo
    if (!mounted) return;
    if (context.read<AccessibilityProvider>().autoTtsEnabled) {
      final nome = provider.participant?.nome.split(' ').first ?? '';
      TtsService().speak(_buildTextoResultado(nome));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = context.watch<AppProvider>().participant?.nome ?? '';
    final primeiroNome = nome.split(' ').first;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Ícone
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 2),
                  ),
                  child: const Icon(Icons.emoji_events_rounded,
                      size: 56, color: Colors.amber),
                ),
                const SizedBox(height: 24),

                Text(
                  primeiroNome.isNotEmpty ? 'Parabéns, $primeiroNome!' : 'Parabéns!',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'Você completou toda a jornada!\n\n'
                    'Sua participação é muito importante para entendermos como '
                    'proteger melhor a saúde de agricultores ribeirinhos.',
                    style: TextStyle(
                        color: Colors.white, fontSize: 15, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 12),
                TtsButton(
                  text: _buildTextoResultado(primeiroNome),
                  label: 'Ouvir resultado',
                  color: Colors.white,
                ),

                const SizedBox(height: 16),

                // Indicador de sincronização
                _SyncStatusBanner(),

                const SizedBox(height: 16),

                // Gráfico pré/pós
                if (_stats != null) _resultChart(_stats!),

                const SizedBox(height: 20),

                // Badges de conquista
                if (_stats != null) _badgesSection(_stats!),

                const SizedBox(height: 20),

                // Frase de incentivo
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          color: Colors.amber, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Conhecimento é proteção. Continue cuidando de você e da sua família!',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // UBS mais próxima
                const UbsCard(),

                const SizedBox(height: 32),

                OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Novo participante?'),
                        content: const Text(
                            'Isso irá encerrar a sessão atual e iniciar um novo registro.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Confirmar'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await context.read<AppProvider>().reset();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Iniciar para novo participante'),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultChart(ParticipantStats stats) {
    final pre = stats.pctPre;
    final pos = stats.pctPos;
    final ganho = stats.ganho;

    return Column(
      children: [
        // Título
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_graph_rounded, color: Colors.white70, size: 18),
            SizedBox(width: 8),
            Text('Seu resultado',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 16),

        // Cards antes / depois
        Row(
          children: [
            Expanded(child: _knowledgeCard('Antes\ndos vídeos', pre,
                AppTheme.primaryLight, _faceIcon(pre))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Icon(
                    ganho != null && ganho >= 0
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_forward_rounded,
                    color: ganho != null && ganho >= 0
                        ? Colors.greenAccent
                        : Colors.white38,
                    size: 32,
                  ),
                  if (ganho != null)
                    Text(
                      '${ganho >= 0 ? '+' : ''}${ganho.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: ganho >= 0
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _knowledgeCard('Depois\ndos vídeos', pos,
                Colors.amber, _faceIcon(pos))),
          ],
        ),

        // Mensagem de conquista
        if (ganho != null && ganho > 0) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.greenAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🌱', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Você aprendeu ${ganho.toStringAsFixed(0)}% a mais sobre agrotóxicos!',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (pre == null && pos == null)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Resultados ainda não disponíveis.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _knowledgeCard(String label, double? pct, Color color, String face) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(face, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            pct != null ? '${pct.toStringAsFixed(0)}%' : '—',
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          // Barra de progresso
          if (pct != null)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct / 100),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOut,
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _badgesSection(ParticipantStats stats) {
    final badges = <_Badge>[];

    // Sempre ganha por completar
    badges.add(const _Badge(
      emoji: '🌾',
      titulo: 'Agricultor Consciente',
      descricao: 'Completou a jornada educativa',
      color: Color(0xFF2D6A4F),
    ));

    // Ganho significativo
    if (stats.ganho != null && stats.ganho! >= 20) {
      badges.add(const _Badge(
        emoji: '🚀',
        titulo: 'Evolução Notável',
        descricao: 'Aumentou seu conhecimento em 20% ou mais',
        color: Color(0xFF8E44AD),
      ));
    }

    // Score pós alto
    if (stats.pctPos != null && stats.pctPos! >= 80) {
      badges.add(const _Badge(
        emoji: '🏆',
        titulo: 'Mestre do Conhecimento',
        descricao: 'Acertou 80% ou mais no pós-teste',
        color: Color(0xFFF39C12),
      ));
    }

    // Pontuação perfeita
    if (stats.pctPos != null && stats.pctPos! >= 100) {
      badges.add(const _Badge(
        emoji: '⭐',
        titulo: 'Campeão do Campo',
        descricao: 'Acertou todas as questões!',
        color: Color(0xFFE74C3C),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium_rounded,
                color: Colors.amber, size: 18),
            SizedBox(width: 8),
            Text('Conquistas',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 12),
        ...badges.map((b) => _badgeCard(b)),
      ],
    );
  }

  Widget _badgeCard(_Badge b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: b.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: b.color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Text(b.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.titulo,
                  style: TextStyle(
                    color: b.color == const Color(0xFFF39C12)
                        ? Colors.amber
                        : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  b.descricao,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _faceIcon(double? pct) {
    if (pct == null) return '❓';
    if (pct >= 80) return '😄';
    if (pct >= 60) return '🙂';
    if (pct >= 40) return '😐';
    return '😕';
  }
}


class _SyncStatusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: SyncService().status,
      builder: (_, status, __) {
        if (status == SyncStatus.idle) {
          return ValueListenableBuilder<int>(
            valueListenable: SyncService().pendingCount,
            builder: (_, pending, __) {
              if (pending == 0) return const SizedBox.shrink();
              return _banner(
                Icons.cloud_upload_outlined,
                'Dados salvos localmente',
                'Serão enviados ao conectar ao Wi-Fi',
                Colors.orange,
              );
            },
          );
        }
        if (status == SyncStatus.syncing) {
          return _banner(
            Icons.cloud_sync_rounded,
            'Sincronizando dados...',
            'Enviando para a nuvem',
            Colors.blue,
          );
        }
        if (status == SyncStatus.done) {
          return _banner(
            Icons.cloud_done_rounded,
            'Dados sincronizados!',
            'Enviados com sucesso para a nuvem',
            Colors.green,
          );
        }
        if (status == SyncStatus.error) {
          return _banner(
            Icons.cloud_off_rounded,
            'Sem conexão',
            'Dados salvos e serão enviados depois',
            Colors.red,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _banner(
      IconData icon, String title, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text(sub,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge {
  final String emoji;
  final String titulo;
  final String descricao;
  final Color color;
  const _Badge({
    required this.emoji,
    required this.titulo,
    required this.descricao,
    required this.color,
  });
}
