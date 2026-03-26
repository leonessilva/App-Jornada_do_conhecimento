import '../database/database_helper.dart';
import '../models/response_model.dart';

class ResponseRepository {
  final _db = DatabaseHelper.instance;

  static const _validFases = {'pre', 'pos'};
  static const _validQuestionIds = {
    'Q01', 'Q02', 'Q03', 'Q04', 'Q05', 'Q06', 'Q07',
    'Q08', 'Q09', 'Q10', 'Q11', 'Q12', 'Q13', 'Q14',
    'Q15', 'Q16', 'Q17', 'Q18', 'Q19', 'Q20',
  };

  Future<void> saveResponse(ResponseModel response) async {
    // Validação de entrada: previne dados inválidos no banco
    if (!_validFases.contains(response.fase)) {
      throw ArgumentError('Fase inválida: "${response.fase}". Esperado: pre ou pos');
    }
    if (!_validQuestionIds.contains(response.questionId)) {
      throw ArgumentError('ID de pergunta inválido: "${response.questionId}"');
    }
    if (response.participantId.isEmpty) {
      throw ArgumentError('participantId não pode ser vazio');
    }
    // Trunca resposta aberta para evitar abuso de storage
    final safeAnswer = response.answer.length > 2000
        ? response.answer.substring(0, 2000)
        : response.answer;

    final db = await _db.database;
    await db.delete(
      'responses',
      where: 'participant_id = ? AND fase = ? AND question_id = ?',
      whereArgs: [response.participantId, response.fase, response.questionId],
    );
    await db.insert('responses', {
      ...response.toMap(),
      'answer': safeAnswer,
    });
  }

  Future<List<ResponseModel>> getResponsesByFase(
    String participantId,
    String fase,
  ) async {
    if (!_validFases.contains(fase)) return [];
    final db = await _db.database;
    final result = await db.query(
      'responses',
      where: 'participant_id = ? AND fase = ?',
      whereArgs: [participantId, fase],
    );
    return result.map((r) => ResponseModel.fromMap(r)).toList();
  }

  Future<Map<String, String>> getResponsesMapByFase(
    String participantId,
    String fase,
  ) async {
    final responses = await getResponsesByFase(participantId, fase);
    return {for (var r in responses) r.questionId: r.answer};
  }
}
