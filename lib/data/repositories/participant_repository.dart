import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/participant.dart';

class ParticipantRepository {
  final _db = DatabaseHelper.instance;

  Future<void> save(Participant participant) async {
    final db = await _db.database;
    await db.insert(
      'participants',
      participant.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Participant?> findById(String id) async {
    final db = await _db.database;
    final result = await db.query(
      'participants',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Participant.fromMap(result.first);
  }

  Future<void> saveConsent(String participantId) async {
    final db = await _db.database;
    await db.insert('consents', {
      'participant_id': participantId,
      'aceito': 1,
      'accepted_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Participant?> findByCpf(String cpf) async {
    final db = await _db.database;
    final result = await db.query(
      'participants',
      where: 'cpf = ?',
      whereArgs: [cpf],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Participant.fromMap(result.first);
  }

  Future<bool> hasConsent(String participantId) async {
    final db = await _db.database;
    final result = await db.query(
      'consents',
      where: 'participant_id = ? AND aceito = 1',
      whereArgs: [participantId],
    );
    return result.isNotEmpty;
  }
}
