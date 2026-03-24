import '../database/database_helper.dart';
import '../models/response_model.dart';

class ResponseRepository {
  final _db = DatabaseHelper.instance;

  Future<void> saveResponse(ResponseModel response) async {
    final db = await _db.database;
    await db.delete(
      'responses',
      where: 'participant_id = ? AND fase = ? AND question_id = ?',
      whereArgs: [response.participantId, response.fase, response.questionId],
    );
    await db.insert('responses', response.toMap());
  }

  Future<List<ResponseModel>> getResponsesByFase(
    String participantId,
    String fase,
  ) async {
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
