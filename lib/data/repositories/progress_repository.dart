import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/progress_model.dart';

class ProgressRepository {
  final _db = DatabaseHelper.instance;

  Future<void> saveProgress(ProgressModel progress) async {
    final db = await _db.database;
    await db.insert(
      'progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ProgressModel?> getProgress(String participantId) async {
    final db = await _db.database;
    final result = await db.query(
      'progress',
      where: 'participant_id = ?',
      whereArgs: [participantId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return ProgressModel.fromMap(result.first);
  }
}
