import 'dart:convert';
import 'package:web/web.dart' as web;

import '../../data/repositories/admin_repository.dart';

class CsvExporter {
  /// Exporta resumo: um participante por linha
  static String buildSummary(List<ParticipantStats> data) {
    final buf = StringBuffer();
    buf.writeln(
      'ID,Nome,CPF,Sexo Biologico,Genero,Gestante,'
      'Faixa Etaria,Comunidade,Municipio,Escolaridade,'
      'Data Cadastro,Score Pre,Score Pos,Pct Pre (%),Pct Pos (%),Ganho (%)',
    );
    for (final s in data) {
      final p = s.participant;
      buf.writeln([
        _q(p.id),
        _q(p.nome),
        _q(_maskCpf(p.cpf)),
        _q(p.sexo),
        _q(p.genero),
        _q(p.gestante ?? ''),
        _q(p.idadeFaixa),
        _q(p.comunidade),
        _q(p.municipio),
        _q(p.escolaridade),
        _q(_fmt(p.createdAt)),
        s.scorePre?.toString() ?? '',
        s.scorePos?.toString() ?? '',
        s.pctPre?.toStringAsFixed(1) ?? '',
        s.pctPos?.toStringAsFixed(1) ?? '',
        s.ganho?.toStringAsFixed(1) ?? '',
      ].join(','));
    }
    return buf.toString();
  }

  /// Exporta respostas individuais: uma linha por resposta
  static String buildResponses(List<Map<String, dynamic>> rows) {
    final buf = StringBuffer();
    buf.writeln('CPF,Nome,Fase,Pergunta ID,Resposta,Data');
    for (final r in rows) {
      buf.writeln([
        _q(_maskCpf(r['cpf'] as String? ?? '')),
        _q(r['nome'] as String? ?? ''),
        _q(r['fase'] as String? ?? ''),
        _q(r['question_id'] as String? ?? ''),
        _q(r['answer'] as String? ?? ''),
        _q(r['ts'] as String? ?? ''),
      ].join(','));
    }
    return buf.toString();
  }

  /// Dispara o download no browser
  static void download(String csvContent, String filename) {
    // BOM UTF-8 para Excel reconhecer acentos
    final bytes = utf8.encode('\uFEFF$csvContent');
    final base64str = base64Encode(bytes);
    final dataUri = 'data:text/csv;charset=utf-8;base64,$base64str';

    final anchor =
        web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = dataUri;
    anchor.download = filename;
    web.document.body!.appendChild(anchor);
    anchor.click();
    anchor.remove();
  }

  static String _q(String s) =>
      '"${s.replaceAll('"', '""')}"';

  static String _maskCpf(String cpf) {
    final d = cpf.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) return cpf;
    return '${d.substring(0, 3)}.***.***.${d.substring(9)}';
  }

  static String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}
