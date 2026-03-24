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

  /// Retorna todas as respostas com nome/cpf do participante (para CSV detalhado)
  Future<List<Map<String, dynamic>>> getAllResponses() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT p.cpf, p.nome, r.fase, r.question_id, r.answer,
             datetime(r.timestamp / 1000, 'unixepoch', 'localtime') AS ts
      FROM responses r
      JOIN participants p ON p.id = r.participant_id
      ORDER BY p.nome, r.fase, r.question_id
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
}
