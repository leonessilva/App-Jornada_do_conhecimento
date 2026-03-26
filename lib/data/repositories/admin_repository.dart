import '../database/database_helper.dart';
import '../models/participant.dart';
import '../questions_data.dart';

class ParticipantStats {
  final Participant participant;
  final int? scorePre;
  final int? scorePos;
  static final int total = _answerKey.length;

  const ParticipantStats({
    required this.participant,
    this.scorePre,
    this.scorePos,
  });

  double? get pctPre => scorePre != null ? scorePre! / total * 100 : null;
  double? get pctPos => scorePos != null ? scorePos! / total * 100 : null;
  double? get ganho => (pctPre != null && pctPos != null) ? pctPos! - pctPre! : null;
}

// Gabarito: questionId → resposta correta (somente questões pontuáveis)
final Map<String, String> _answerKey = {
  for (final q in kQuestions)
    if (q.respostaCorreta != null) q.id: q.respostaCorreta!,
};

class AdminRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Participant>> getAllParticipants() async {
    final db = await _db.database;
    final rows = await db.query('participants', orderBy: 'created_at DESC');
    return rows.map(Participant.fromMap).toList();
  }

  Future<int?> _score(String participantId, String fase) async {
    final db = await _db.database;
    final rows = await db.query(
      'responses',
      where: 'participant_id = ? AND fase = ?',
      whereArgs: [participantId, fase],
    );
    if (rows.isEmpty) return null;
    int count = 0;
    for (final r in rows) {
      final qId = r['question_id'] as String;
      final answer = r['answer'] as String;
      if (_answerKey[qId] == answer) count++;
    }
    return count;
  }

  /// Retorna todas as respostas anonimizadas (para CSV detalhado).
  /// CPF não é incluído (hash irreversível, desnecessário no relatório).
  /// Nome é mascarado: "João Silva" → "João S***"
  Future<List<Map<String, dynamic>>> getAllResponses() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT p.id AS participant_id,
             p.municipio, p.estado, p.comunidade,
             p.sexo, p.genero, p.idade_faixa, p.escolaridade,
             r.fase, r.question_id, r.answer,
             datetime(r.timestamp / 1000, 'unixepoch', 'localtime') AS ts
      FROM responses r
      JOIN participants p ON p.id = r.participant_id
      WHERE p.deleted_at IS NULL
      ORDER BY p.id, r.fase, r.question_id
    ''');
    return rows;
  }

  Future<List<ParticipantStats>> getAllStats() async {
    final participants = await getAllParticipants();
    final result = <ParticipantStats>[];
    for (final p in participants) {
      result.add(ParticipantStats(
        participant: p,
        scorePre: await _score(p.id, 'pre'),
        scorePos: await _score(p.id, 'pos'),
      ));
    }
    return result;
  }

  /// Retorna contagens por etapa do fluxo (para o funil de coleta)
  Future<CollectionFunnel> getCollectionFunnel() async {
    final db = await _db.database;

    final totalRows = await db.rawQuery('SELECT COUNT(*) as c FROM participants');
    final total = (totalRows.first['c'] as int?) ?? 0;

    final preRows = await db.rawQuery(
      "SELECT COUNT(DISTINCT participant_id) as c FROM responses WHERE fase = 'pre'");
    final comPre = (preRows.first['c'] as int?) ?? 0;

    final videosRows = await db.rawQuery(
      "SELECT COUNT(*) as c FROM progress WHERE etapa_atual IN ('videos','questionnaire_pos','results')");
    final comVideos = (videosRows.first['c'] as int?) ?? 0;

    final posRows = await db.rawQuery(
      "SELECT COUNT(DISTINCT participant_id) as c FROM responses WHERE fase = 'pos'");
    final comPos = (posRows.first['c'] as int?) ?? 0;

    final resultRows = await db.rawQuery(
      "SELECT COUNT(*) as c FROM progress WHERE etapa_atual = 'results'");
    final concluidos = (resultRows.first['c'] as int?) ?? 0;

    return CollectionFunnel(
      cadastrados: total,
      comPreTeste: comPre,
      comVideos: comVideos,
      comPosTeste: comPos,
      concluidos: concluidos,
    );
  }

  /// Retorna desempenho médio por município
  Future<List<MunicipioStats>> getMunicipioStats() async {
    final stats = await getAllStats();
    final map = <String, _MunicipioAcc>{};
    for (final s in stats) {
      final m = s.participant.municipio;
      if (m.isEmpty) continue;
      map.putIfAbsent(m, () => _MunicipioAcc());
      if (s.pctPre != null) map[m]!.pre.add(s.pctPre!);
      if (s.pctPos != null) map[m]!.pos.add(s.pctPos!);
    }
    return map.entries.map((e) {
      final avgPre = e.value.pre.isEmpty ? null :
          e.value.pre.reduce((a, b) => a + b) / e.value.pre.length;
      final avgPos = e.value.pos.isEmpty ? null :
          e.value.pos.reduce((a, b) => a + b) / e.value.pos.length;
      return MunicipioStats(
        municipio: e.key,
        avgPre: avgPre,
        avgPos: avgPos,
        count: e.value.pre.isNotEmpty ? e.value.pre.length : e.value.pos.length,
      );
    }).toList()
      ..sort((a, b) => (b.avgPos ?? 0).compareTo(a.avgPos ?? 0));
  }
}

class CollectionFunnel {
  final int cadastrados;
  final int comPreTeste;
  final int comVideos;
  final int comPosTeste;
  final int concluidos;

  const CollectionFunnel({
    required this.cadastrados,
    required this.comPreTeste,
    required this.comVideos,
    required this.comPosTeste,
    required this.concluidos,
  });
}

class MunicipioStats {
  final String municipio;
  final double? avgPre;
  final double? avgPos;
  final int count;

  const MunicipioStats({
    required this.municipio,
    required this.avgPre,
    required this.avgPos,
    required this.count,
  });
}

class _MunicipioAcc {
  final List<double> pre = [];
  final List<double> pos = [];
}
