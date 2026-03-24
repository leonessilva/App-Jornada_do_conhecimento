import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/csv_exporter.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/models/participant.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _repo = AdminRepository();
  List<ParticipantStats> _all = [];
  bool _loading = true;

  String? _filterSexo;
  String? _filterMunicipio;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _export(String tipo) async {
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}';
    if (tipo == 'resumo') {
      final csv = CsvExporter.buildSummary(_all);
      CsvExporter.download(csv, 'jornada_resumo_$stamp.csv');
    } else {
      final rows = await _repo.getAllResponses();
      final csv = CsvExporter.buildResponses(rows);
      CsvExporter.download(csv, 'jornada_respostas_$stamp.csv');
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _repo.getAllStats();
    if (mounted) setState(() { _all = data; _loading = false; });
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
            tooltip: 'Atualizar',
            onPressed: _load,
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
                    _sectionTitle('Participantes (${_filtered.length})'),
                    const SizedBox(height: 12),
                    _participantsTable(),
                    const SizedBox(height: 32),
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
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Nome')),
              DataColumn(label: Text('CPF')),
              DataColumn(label: Text('Sexo')),
              DataColumn(label: Text('Faixa')),
              DataColumn(label: Text('Município')),
              DataColumn(label: Text('Pré')),
              DataColumn(label: Text('Pós')),
              DataColumn(label: Text('Ganho')),
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
                ],
              );
            }),
          ),
        ),
      ),
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

  String _maskCpf(String cpf) {
    final d = cpf.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) return cpf;
    return '${d.substring(0, 3)}.***.***.${d.substring(9)}';
  }
}

class _GroupStats {
  final List<double> pre = [];
  final List<double> pos = [];
}
