import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;

import '../../core/theme/app_theme.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/database/database_helper.dart';
import '../../core/utils/csv_exporter.dart';
import '../../core/utils/pdf_exporter.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/researcher_repository.dart';
import '../../data/repositories/audit_repository.dart';
import '../../data/repositories/participant_repository.dart';
import '../../data/models/participant.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _repo = AdminRepository();
  final _researcherRepo = ResearcherRepository();
  final _auditRepo = AuditRepository();
  List<ParticipantStats> _all = [];
  List<Researcher> _pending = [];
  List<AuditLog> _auditLogs = [];
  CollectionFunnel? _funnel;
  List<MunicipioStats> _municipioStats = [];
  bool _loading = true;
  bool _syncing = false;
  int? _cloudTotal;
  String _role = 'master';

  String? _filterSexo;
  String? _filterMunicipio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['role'] == 'researcher') {
        setState(() => _role = 'researcher');
      }
    });
    _load();
  }

  Future<void> _export(String tipo) async {
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}';
    await _auditRepo.log(
      action: 'export',
      entity: 'data',
      performedBy: _role,
      details: 'Tipo: $tipo',
    );
    if (tipo == 'resumo') {
      final csv = CsvExporter.buildSummary(_all);
      await CsvExporter.download(csv, 'jornada_resumo_$stamp.csv');
    } else if (tipo == 'respostas') {
      final rows = await _repo.getAllResponses();
      final csv = CsvExporter.buildResponses(rows);
      await CsvExporter.download(csv, 'jornada_respostas_$stamp.csv');
    } else if (tipo == 'pdf') {
      await PdfExporter.exportSummary(_all);
    }
    _loadAuditLogs();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _repo.getAllStats();
    final pending = await _researcherRepo.getPending();
    final funnel = await _repo.getCollectionFunnel();
    final municipioStats = await _repo.getMunicipioStats();
    if (mounted) {
      setState(() {
        _all = data;
        _pending = pending;
        _funnel = funnel;
        _municipioStats = municipioStats;
        _loading = false;
      });
    }
    _fetchCloudCount();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    final logs = await _auditRepo.getRecent();
    if (mounted) setState(() => _auditLogs = logs);
  }

  Future<void> _fetchCloudCount() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('participantes')
          .count()
          .get();
      if (mounted) setState(() => _cloudTotal = snap.count ?? 0);
    } catch (_) {}
  }

  Future<void> _syncFromCloud() async {
    if (Firebase.apps.isEmpty) {
      setState(() => _syncing = false);
      return;
    }
    setState(() => _syncing = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('participantes')
          .get();
      final db = await DatabaseHelper.instance.database;
      for (final doc in snap.docs) {
        final data = doc.data();
        await db.insert(
          'participants',
          {
            'id': doc.id,
            'nome': data['nome'] ?? '',
            'cpf': data['cpf'] ?? '',
            'sexo': data['sexo'] ?? '',
            'genero': data['genero'] ?? '',
            'gestante': data['gestante'],
            'idade_faixa': data['idade_faixa'] ?? '',
            'comunidade': data['comunidade'] ?? '',
            'municipio': data['municipio'] ?? '',
            'estado': data['estado'] ?? '',
            'escolaridade': data['escolaridade'] ?? '',
            'synced': 1,
            'created_at': data['created_at'] ?? 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sincronizar: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  List<ParticipantStats> get _filtered {
    return _all.where((s) {
      if (_filterSexo != null && s.participant.genero != _filterSexo) return false;
      if (_filterMunicipio != null && s.participant.municipio != _filterMunicipio) return false;
      return true;
    }).toList();
  }

  Set<String> get _municipios =>
      _all.map((s) => s.participant.municipio).toSet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        title: const Text('Painel Admin'),
        leading: const Icon(Icons.admin_panel_settings_rounded,
            color: Colors.white),
        leadingWidth: 48,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Atualizar local',
            onPressed: _load,
          ),
          IconButton(
            icon: _syncing
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.cloud_sync_rounded, color: Colors.white),
                      if (_cloudTotal != null)
                        Positioned(
                          right: -4, top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            constraints: const BoxConstraints(minWidth: 16),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$_cloudTotal',
                                style: const TextStyle(
                                    fontSize: 9, color: Colors.black,
                                    fontWeight: FontWeight.w800),
                                textAlign: TextAlign.center),
                          ),
                        ),
                    ],
                  ),
            tooltip: 'Sincronizar da nuvem',
            onPressed: _syncing ? null : _syncFromCloud,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Exportar dados',
            onSelected: _export,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'resumo',
                child: Row(children: [
                  Icon(Icons.table_chart_outlined, size: 18),
                  SizedBox(width: 10),
                  Text('Exportar resumo (CSV)'),
                ]),
              ),
              PopupMenuItem(
                value: 'respostas',
                child: Row(children: [
                  Icon(Icons.list_alt_outlined, size: 18),
                  SizedBox(width: 10),
                  Text('Exportar respostas (CSV)'),
                ]),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(children: [
                  Icon(Icons.picture_as_pdf_outlined, size: 18, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Exportar relatório (PDF)'),
                ]),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair',
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _filterRow(),
                    const SizedBox(height: 16),
                    _statsGrid(),
                    const SizedBox(height: 20),
                    _sectionTitle('Progresso da Coleta'),
                    const SizedBox(height: 12),
                    if (_funnel != null) _collectionFunnel(_funnel!),
                    const SizedBox(height: 20),
                    _sectionTitle('Evolução Pré × Pós por Gênero'),
                    const SizedBox(height: 12),
                    _dumbellChart(_groupBy((p) => p.genero.isNotEmpty ? p.genero : p.sexo)),
                    const SizedBox(height: 20),
                    _sectionTitle('Evolução Pré × Pós por Faixa Etária'),
                    const SizedBox(height: 12),
                    _dumbellChart(_groupByIdade()),
                    const SizedBox(height: 20),
                    _sectionTitle('Evolução Pré × Pós por Sexo Biológico'),
                    const SizedBox(height: 12),
                    _dumbellChart(_groupBy((p) => p.sexo)),
                    const SizedBox(height: 20),
                    if (_filtered.any((s) => s.participant.gestante != null)) ...[
                      _sectionTitle('Evolução — Gestantes'),
                      const SizedBox(height: 12),
                      _dumbellChart(_groupBy((p) => p.gestante != null ? 'Grávida: ${p.gestante}' : 'Não se aplica')),
                      const SizedBox(height: 20),
                    ],
                    if (_municipioStats.isNotEmpty) ...[
                      _sectionTitle('Desempenho por Município'),
                      const SizedBox(height: 12),
                      _municipioHeatmap(),
                      const SizedBox(height: 20),
                    ],
                    if (_role == 'master' && _pending.isNotEmpty) ...[
                      _sectionTitle('Solicitações de Acesso (${_pending.length})'),
                      const SizedBox(height: 12),
                      _pendingRequests(),
                      const SizedBox(height: 20),
                    ],
                    _sectionTitle('Participantes (${_filtered.length})'),
                    const SizedBox(height: 12),
                    _participantsTable(),
                    const SizedBox(height: 20),
                    if (_role == 'master' && _auditLogs.isNotEmpty) ...[
                      _sectionTitle('Log de Auditoria'),
                      const SizedBox(height: 12),
                      _auditLogSection(),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Filtros ────────────────────────────────────────────────────

  Widget _filterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('Todos', _filterSexo == null && _filterMunicipio == null,
              () => setState(() { _filterSexo = null; _filterMunicipio = null; })),
          const SizedBox(width: 8),
          _chip('Homem cis', _filterSexo == 'Homem cisgênero',
              () => setState(() => _filterSexo = _filterSexo == 'Homem cisgênero' ? null : 'Homem cisgênero')),
          const SizedBox(width: 8),
          _chip('Mulher cis', _filterSexo == 'Mulher cisgênera',
              () => setState(() => _filterSexo = _filterSexo == 'Mulher cisgênera' ? null : 'Mulher cisgênera')),
          const SizedBox(width: 8),
          _chip('Homem trans', _filterSexo == 'Homem transgênero',
              () => setState(() => _filterSexo = _filterSexo == 'Homem transgênero' ? null : 'Homem transgênero')),
          const SizedBox(width: 8),
          _chip('Mulher trans', _filterSexo == 'Mulher transgênera',
              () => setState(() => _filterSexo = _filterSexo == 'Mulher transgênera' ? null : 'Mulher transgênera')),
          const SizedBox(width: 8),
          _chip('Não-binário', _filterSexo == 'Não-binário',
              () => setState(() => _filterSexo = _filterSexo == 'Não-binário' ? null : 'Não-binário')),
          const SizedBox(width: 8),
          ..._municipios.map((m) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _chip(m, _filterMunicipio == m,
                    () => setState(() =>
                        _filterMunicipio = _filterMunicipio == m ? null : m)),
              )),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? AppTheme.primary : AppTheme.backgroundAlt,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppTheme.textMedium,
              fontWeight: active ? FontWeight.w700 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      );

  // ─── Cards de estatísticas ───────────────────────────────────────

  Widget _statsGrid() {
    final data = _filtered;
    final total = data.length;
    final comPre = data.where((s) => s.scorePre != null).toList();
    final comPos = data.where((s) => s.scorePos != null).toList();
    final ambos = data.where((s) => s.scorePre != null && s.scorePos != null).toList();

    final avgPre = comPre.isEmpty
        ? null
        : comPre.map((s) => s.pctPre!).reduce((a, b) => a + b) / comPre.length;
    final avgPos = comPos.isEmpty
        ? null
        : comPos.map((s) => s.pctPos!).reduce((a, b) => a + b) / comPos.length;
    final avgGanho = ambos.isEmpty
        ? null
        : ambos.map((s) => s.ganho!).reduce((a, b) => a + b) / ambos.length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _statCard('Participantes', '$total', Icons.people_alt_outlined,
            AppTheme.primary, ''),
        _statCard(
          'Média Pré',
          avgPre != null ? '${avgPre.toStringAsFixed(1)}%' : '—',
          Icons.assignment_outlined,
          const Color(0xFF2980B9),
          '${comPre.length} responderam',
        ),
        _statCard(
          'Média Pós',
          avgPos != null ? '${avgPos.toStringAsFixed(1)}%' : '—',
          Icons.assignment_turned_in_outlined,
          const Color(0xFF27AE60),
          '${comPos.length} concluíram',
        ),
        _statCard(
          'Ganho Médio',
          avgGanho != null
              ? '${avgGanho >= 0 ? '+' : ''}${avgGanho.toStringAsFixed(1)}%'
              : '—',
          Icons.trending_up,
          avgGanho != null && avgGanho >= 0
              ? const Color(0xFFF39C12)
              : Colors.red,
          '${ambos.length} com pré e pós',
        ),
      ],
    );
  }

  Widget _statCard(
      String title, String value, IconData icon, Color color, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(title,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
              if (sub.isNotEmpty)
                Text(sub,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMedium)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Gráficos ────────────────────────────────────────────────────

  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppTheme.textDark,
        ),
      );

  /// Agrupa os dados por [groupBy] e calcula médias de pré e pós
  Map<String, _GroupStats> _groupBy(String Function(Participant) keyFn) {
    final map = <String, _GroupStats>{};
    for (final s in _filtered) {
      final key = keyFn(s.participant);
      map.putIfAbsent(key, () => _GroupStats());
      if (s.pctPre != null) map[key]!.pre.add(s.pctPre!);
      if (s.pctPos != null) map[key]!.pos.add(s.pctPos!);
    }
    return map;
  }

  Map<String, _GroupStats> _groupByIdade() {
    const order = [
      'Menos de 18 anos', '18 a 29 anos', '30 a 39 anos',
      '40 a 59 anos', '60 anos ou mais',
    ];
    final map = _groupBy((p) => p.idadeFaixa);
    return Map.fromEntries(
      order.where(map.containsKey).map((k) => MapEntry(k, map[k]!)),
    );
  }

  Widget _emptyChart() => Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('Sem dados suficientes',
            style: TextStyle(color: AppTheme.textMedium)),
      );

  /// Dumbbell chart — gráfico de pontos conectados (ideal para pré×pós)
  Widget _dumbellChart(Map<String, _GroupStats> groups) {
    if (groups.isEmpty) return _emptyChart();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legenda
          Row(
            children: [
              _legendDot(AppTheme.primary, 'Pré-teste'),
              const SizedBox(width: 20),
              _legendDot(AppTheme.accent, 'Pós-teste'),
              const Spacer(),
              const Text('n = participantes',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMedium)),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(),
          const SizedBox(height: 8),
          // Escala no topo
          Row(
            children: [
              const SizedBox(width: 130),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['0%', '25%', '50%', '75%', '100%']
                      .map((l) => Text(l,
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.textMedium)))
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...groups.entries.map((e) {
            final avgPre = e.value.pre.isEmpty
                ? null
                : e.value.pre.reduce((a, b) => a + b) / e.value.pre.length;
            final avgPos = e.value.pos.isEmpty
                ? null
                : e.value.pos.reduce((a, b) => a + b) / e.value.pos.length;
            final n = e.value.pre.isNotEmpty
                ? e.value.pre.length
                : e.value.pos.length;
            return _dumbellRow(e.key, avgPre, avgPos, n);
          }),
        ],
      ),
    );
  }

  Widget _dumbellRow(String label, double? pre, double? pos, int n) {
    final ganho = (pre != null && pos != null) ? pos - pre : null;
    final ganhoColor = ganho == null
        ? Colors.grey
        : ganho > 0
            ? const Color(0xFF27AE60)
            : ganho < 0
                ? Colors.red
                : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Label do grupo
          SizedBox(
            width: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark),
                  overflow: TextOverflow.ellipsis,
                ),
                Text('n=$n',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textMedium)),
              ],
            ),
          ),
          // Trilha com pontos
          Expanded(
            child: LayoutBuilder(builder: (ctx, constraints) {
              final w = constraints.maxWidth;
              final preX = pre != null ? (pre / 100 * w).clamp(0.0, w) : null;
              final posX = pos != null ? (pos / 100 * w).clamp(0.0, w) : null;
              return SizedBox(
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Linha de fundo (0 a 100%)
                    Container(
                      height: 2,
                      color: Colors.grey.shade200,
                    ),
                    // Linha conectora pré→pós
                    if (preX != null && posX != null)
                      Positioned(
                        left: preX < posX ? preX : posX,
                        child: Container(
                          height: 3,
                          width: (preX - posX).abs(),
                          decoration: BoxDecoration(
                            color: ganhoColor.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    // Ponto PRÉ
                    if (preX != null && pre != null)
                      Positioned(
                        left: preX - 8,
                        child: _dot(
                          AppTheme.primary,
                          '${pre.toStringAsFixed(0)}%',
                          pre < 50,
                        ),
                      ),
                    // Ponto PÓS
                    if (posX != null && pos != null)
                      Positioned(
                        left: posX - 8,
                        child: _dot(
                          AppTheme.accent,
                          '${pos.toStringAsFixed(0)}%',
                          pos < 50,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          // Ganho à direita
          SizedBox(
            width: 52,
            child: Text(
              ganho == null
                  ? '—'
                  : '${ganho >= 0 ? '+' : ''}${ganho.toStringAsFixed(0)}%',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ganhoColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color, String label, bool labelAbove) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!labelAbove)
          Text(label,
              style: TextStyle(
                  fontSize: 9, color: color, fontWeight: FontWeight.w700)),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)
            ],
          ),
        ),
        if (labelAbove)
          Text(label,
              style: TextStyle(
                  fontSize: 9, color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _legendDot(Color color, String label) => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
        ],
      );

  // ─── Tabela de participantes ─────────────────────────────────────

  Widget _participantsTable() {
    final data = _filtered;
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('Nenhum participante encontrado.',
            style: TextStyle(color: AppTheme.textMedium)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.primaryDark),
            headingTextStyle: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            dataRowMaxHeight: 52,
            columnSpacing: 16,
            columns: [
              const DataColumn(label: Text('#')),
              const DataColumn(label: Text('Nome')),
              const DataColumn(label: Text('CPF')),
              const DataColumn(label: Text('Sexo')),
              const DataColumn(label: Text('Faixa')),
              const DataColumn(label: Text('Município')),
              const DataColumn(label: Text('UF')),
              const DataColumn(label: Text('Pré')),
              const DataColumn(label: Text('Pós')),
              const DataColumn(label: Text('Ganho')),
              if (_role == 'master')
                const DataColumn(label: Text('LGPD')),
            ],
            rows: List.generate(data.length, (i) {
              final s = data[i];
              final p = s.participant;
              final ganho = s.ganho;
              return DataRow(
                color: WidgetStateProperty.all(
                    i.isEven ? Colors.white : AppTheme.background),
                cells: [
                  DataCell(Text('${i + 1}',
                      style: const TextStyle(color: AppTheme.textMedium))),
                  DataCell(Text(p.nome.isEmpty ? '—' : p.nome,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(_maskCpf(p.cpf),
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          color: AppTheme.textMedium))),
                  DataCell(Text(p.sexo)),
                  DataCell(Text(p.idadeFaixa,
                      style: const TextStyle(fontSize: 12))),
                  DataCell(Text(p.municipio,
                      style: const TextStyle(fontSize: 12))),
                  DataCell(Text(p.estado.isEmpty ? '—' : p.estado,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600))),
                  DataCell(_scoreChip(s.pctPre, AppTheme.primary)),
                  DataCell(_scoreChip(s.pctPos, const Color(0xFF27AE60))),
                  DataCell(ganho == null
                      ? const Text('—',
                          style: TextStyle(color: AppTheme.textMedium))
                      : Text(
                          '${ganho >= 0 ? '+' : ''}${ganho.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ganho >= 0
                                ? const Color(0xFF27AE60)
                                : Colors.red,
                          ),
                        )),
                  if (_role == 'master')
                    DataCell(
                      Tooltip(
                        message: 'Apagar dados pessoais (LGPD)',
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.red, size: 18),
                          onPressed: () => _confirmDeleteParticipant(p.id, p.nome),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _pendingRequests() {
    return Column(
      children: _pending.map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF39C12), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(r.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF5E7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Pendente',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE67E22),
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(r.institution,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMedium)),
              const SizedBox(height: 4),
              Text(r.justification,
                  style: const TextStyle(fontSize: 12, height: 1.4)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _researcherRepo.reject(r.id);
                        await _auditRepo.log(
                          action: 'reject',
                          entity: 'researcher',
                          entityId: r.id,
                          performedBy: 'master',
                          details: r.name,
                        );
                        _load();
                      },
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeitar'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _researcherRepo.approve(r.id);
                        await _auditRepo.log(
                          action: 'approve',
                          entity: 'researcher',
                          entityId: r.id,
                          performedBy: 'master',
                          details: r.name,
                        );
                        _load();
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Aprovar'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _scoreChip(double? pct, Color color) {
    if (pct == null) {
      return const Text('—', style: TextStyle(color: AppTheme.textMedium));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${pct.toStringAsFixed(0)}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteParticipant(String id, String nome) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Apagar dados pessoais'),
        ]),
        content: Text(
          'Isso remove nome, CPF e dados de identificação de "$nome" '
          'em conformidade com a LGPD (direito ao esquecimento).\n\n'
          'As respostas do questionário serão mantidas de forma anônima.\n\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Apagar dados'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ParticipantRepository().deletePersonalData(id);
      await _auditRepo.log(
        action: 'delete',
        entity: 'participant',
        entityId: id,
        performedBy: _role,
        details: 'Exclusão LGPD — dados pessoais removidos',
      );
      _load();
    }
  }

  String _maskCpf(String cpf) {
    final d = cpf.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) return cpf;
    return '${d.substring(0, 3)}.***.***.${d.substring(9)}';
  }

  // ─── Funil de coleta ────────────────────────────────────────────

  Widget _collectionFunnel(CollectionFunnel f) {
    final steps = [
      _FunnelStep('Cadastrados', f.cadastrados, Icons.person_add_outlined, AppTheme.primary),
      _FunnelStep('Pré-teste', f.comPreTeste, Icons.assignment_outlined, const Color(0xFF2980B9)),
      _FunnelStep('Vídeos', f.comVideos, Icons.play_lesson_rounded, const Color(0xFF8E44AD)),
      _FunnelStep('Pós-teste', f.comPosTeste, Icons.assignment_turned_in_outlined, const Color(0xFF27AE60)),
      _FunnelStep('Concluídos', f.concluidos, Icons.emoji_events_rounded, AppTheme.accent),
    ];
    final maxVal = f.cadastrados == 0 ? 1 : f.cadastrados;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        children: steps.map((s) {
          final pct = maxVal > 0 ? s.count / maxVal : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 130,
                  child: Row(
                    children: [
                      Icon(s.icon, size: 16, color: s.color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(s.label,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: AppTheme.textDark)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          )),
                      FractionallySizedBox(
                        widthFactor: pct.clamp(0.0, 1.0),
                        child: Container(
                          height: 22,
                          decoration: BoxDecoration(
                            color: s.color.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 50,
                  child: Text(
                    '${s.count} (${(pct * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: s.color),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Mapa de calor por município ────────────────────────────────

  Widget _municipioHeatmap() {
    if (_municipioStats.isEmpty) return _emptyChart();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _legendDot(AppTheme.primary, 'Pré-teste'),
            const SizedBox(width: 16),
            _legendDot(AppTheme.accent, 'Pós-teste'),
          ]),
          const SizedBox(height: 12),
          ..._municipioStats.map((s) {
            final maxBar = 100.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${s.municipio}  (n=${s.count})',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark),
                        ),
                      ),
                      if (s.avgPos != null && s.avgPre != null)
                        Text(
                          '${(s.avgPos! - s.avgPre!) >= 0 ? '+' : ''}${(s.avgPos! - s.avgPre!).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: (s.avgPos! - s.avgPre!) >= 0
                                ? const Color(0xFF27AE60)
                                : Colors.red,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Barra pré
                  if (s.avgPre != null)
                    _heatBar(s.avgPre! / maxBar, AppTheme.primary,
                        '${s.avgPre!.toStringAsFixed(0)}%'),
                  const SizedBox(height: 3),
                  // Barra pós
                  if (s.avgPos != null)
                    _heatBar(s.avgPos! / maxBar, AppTheme.accent,
                        '${s.avgPos!.toStringAsFixed(0)}%'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _heatBar(double fraction, Color color, String label) {
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      return Stack(
        children: [
          Container(
            height: 16,
            width: w,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            height: 16,
            width: (fraction.clamp(0.0, 1.0) * w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Positioned(
            right: 4,
            top: 1,
            child: Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
        ],
      );
    });
  }

  // ─── Log de auditoria ───────────────────────────────────────────

  Widget _auditLogSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: _auditLogs.take(20).map((log) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade100),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _auditColor(log.action).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_auditIcon(log.action),
                        size: 16, color: _auditColor(log.action)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${log.action.toUpperCase()} — ${log.entity}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: AppTheme.textDark),
                        ),
                        if (log.details.isNotEmpty)
                          Text(log.details,
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textMedium)),
                      ],
                    ),
                  ),
                  Text(
                    _fmtTime(log.timestamp),
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textMedium),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _auditIcon(String action) {
    switch (action) {
      case 'export': return Icons.download_rounded;
      case 'login': return Icons.login_rounded;
      case 'approve': return Icons.check_circle_outline;
      case 'reject': return Icons.cancel_outlined;
      case 'sync': return Icons.cloud_sync_rounded;
      default: return Icons.info_outline;
    }
  }

  Color _auditColor(String action) {
    switch (action) {
      case 'export': return const Color(0xFF2980B9);
      case 'login': return AppTheme.primary;
      case 'approve': return const Color(0xFF27AE60);
      case 'reject': return Colors.red;
      case 'sync': return const Color(0xFF8E44AD);
      default: return AppTheme.textMedium;
    }
  }

  String _fmtTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2,'0')}/'
        '${dt.month.toString().padLeft(2,'0')} '
        '${dt.hour.toString().padLeft(2,'0')}:'
        '${dt.minute.toString().padLeft(2,'0')}';
  }
}

class _GroupStats {
  final List<double> pre = [];
  final List<double> pos = [];
}

class _FunnelStep {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  const _FunnelStep(this.label, this.count, this.icon, this.color);
}
