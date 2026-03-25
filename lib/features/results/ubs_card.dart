import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/ubs_model.dart';
import '../../data/repositories/ubs_repository.dart';

class UbsCard extends StatefulWidget {
  const UbsCard({super.key});

  @override
  State<UbsCard> createState() => _UbsCardState();
}

enum _Mode { escolha, gps, cep }

class _UbsCardState extends State<UbsCard> {
  final _repo = UbsRepository();
  final _cepCtrl = TextEditingController();

  _Mode _mode = _Mode.escolha;
  List<UbsModel> _results = [];
  bool _loading = false;
  String? _label;
  String? _erro;

  @override
  void dispose() {
    _cepCtrl.dispose();
    super.dispose();
  }

  // ─── GPS ─────────────────────────────────────────────────────────
  Future<void> _buscarPorGps() async {
    setState(() { _mode = _Mode.gps; _loading = true; _erro = null; });

    final pos = await _repo.getCurrentPosition();
    if (!mounted) return;

    if (pos == null) {
      setState(() { _loading = false; _erro = 'Não foi possível obter sua localização.'; });
      return;
    }

    final nearby = await _repo.getNearby(lat: pos.latitude, lng: pos.longitude);
    if (!mounted) return;
    setState(() {
      _results = nearby.map((e) => e.ubs).toList();
      _label = 'UBS próximas à sua localização';
      _loading = false;
    });
  }

  // ─── CEP ─────────────────────────────────────────────────────────
  Future<void> _buscarPorCep() async {
    final cep = _cepCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) {
      setState(() => _erro = 'Digite um CEP válido com 8 dígitos.');
      return;
    }
    setState(() { _loading = true; _erro = null; });

    final res = await _repo.getByCep(cep);
    if (!mounted) return;
    setState(() {
      _results = res.results;
      _label = res.label;
      _loading = false;
      if (res.results.isEmpty) _erro = 'Nenhuma UBS encontrada para este CEP.';
    });
  }

  void _voltar() => setState(() {
        _mode = _Mode.escolha;
        _results = [];
        _label = null;
        _erro = null;
        _loading = false;
        _cepCtrl.clear();
      });

  // ─── Ações externas ──────────────────────────────────────────────
  Future<void> _openMaps(UbsModel ubs) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${ubs.nome} ${ubs.municipio}')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _call(String telefone) async {
    final digits = telefone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$digits');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ─── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade700.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_hospital_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Em caso de intoxicação',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                    Text('Procure atendimento na UBS mais próxima',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              if (_mode != _Mode.escolha)
                IconButton(
                  onPressed: _voltar,
                  icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                  tooltip: 'Voltar',
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Conteúdo por modo
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                    color: Colors.white70, strokeWidth: 2),
              ),
            )
          else if (_mode == _Mode.escolha)
            _escolhaWidget()
          else if (_mode == _Mode.cep && _results.isEmpty)
            _campoCepWidget()
          else if (_erro != null)
            _erroWidget()
          else ...[
            if (_label != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_label!,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
              ),
            ..._results.take(3).map(_ubsItem),
          ],
        ],
      ),
    );
  }

  // ─── Widgets de estado ────────────────────────────────────────────

  Widget _escolhaWidget() {
    return Column(
      children: [
        const Text(
          'Como quer buscar a UBS?',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _opcaoBtn(
                icone: Icons.gps_fixed_rounded,
                label: 'Usar GPS',
                onTap: _buscarPorGps,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _opcaoBtn(
                icone: Icons.pin_outlined,
                label: 'Usar CEP',
                onTap: () => setState(() { _mode = _Mode.cep; _erro = null; }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _opcaoBtn({
    required IconData icone,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icone, color: Colors.white, size: 26),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoCepWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _cepCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
          decoration: InputDecoration(
            hintText: '00000-000',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.pin_outlined, color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white70),
            ),
          ),
          onSubmitted: (_) => _buscarPorCep(),
        ),
        if (_erro != null) ...[
          const SizedBox(height: 6),
          Text(_erro!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _buscarPorCep,
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('Buscar UBS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Funciona mesmo sem internet.',
          style: TextStyle(color: Colors.white38, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _erroWidget() {
    return Column(
      children: [
        Text(_erro!,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _voltar,
          icon: const Icon(Icons.arrow_back, color: Colors.white60, size: 16),
          label: const Text('Tentar outra opção',
              style: TextStyle(color: Colors.white60)),
        ),
      ],
    );
  }

  // ─── Item de UBS ─────────────────────────────────────────────────

  Widget _ubsItem(UbsModel ubs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ubs.nome,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 3),
          Text('${ubs.municipio} — ${ubs.estado}',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          if (ubs.endereco.isNotEmpty)
            Text(ubs.endereco,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      ubs.telefone.isNotEmpty ? () => _call(ubs.telefone) : null,
                  icon: const Icon(Icons.phone, size: 15),
                  label: Text(
                    ubs.telefone.isNotEmpty ? ubs.telefone : 'Sem telefone',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _openMaps(ubs),
                icon: const Icon(Icons.directions, size: 15),
                label: const Text('Rota', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
