import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/participant.dart';
import '../../core/security/security_utils.dart';
import '../../core/security/cpf_validator.dart';

class ParticipantRepository {
  final _db = DatabaseHelper.instance;

  /// Versão atual do algoritmo de hash para CPF.
  static const int _currentHashVersion = SecurityUtils.currentHashVersion;

  /// Hash seguro de CPF — usa HMAC-SHA256 com pepper (v2).
  /// Mantido estático para uso em login.
  static String hashCpf(String cpf) {
    final digits = CpfValidator.digits(cpf);
    return SecurityUtils.secureHash(digits);
  }

  /// Hash legado (v1) — mantido para migração de contas existentes.
  static String _legacyHashCpf(String cpf) {
    return SecurityUtils.legacyHash(cpf);
  }

  Future<void> save(Participant participant) async {
    final db = await _db.database;
    final map = participant.toMap();
    map['cpf'] = hashCpf(map['cpf'] as String);
    map['cpf_hash_v'] = _currentHashVersion;
    await db.insert(
      'participants',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Participant?> findById(String id) async {
    final db = await _db.database;
    final result = await db.query(
      'participants',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Participant.fromMap(result.first);
  }

  Future<void> saveConsent(String participantId,
      {String tcleVersion = '1.0'}) async {
    final db = await _db.database;
    await db.insert('consents', {
      'participant_id': participantId,
      'aceito': 1,
      'tcle_version': tcleVersion,
      'accepted_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Participant?> findByCpf(String cpf) async {
    final db = await _db.database;

    // Tenta com hash v2 (atual)
    var result = await db.query(
      'participants',
      where: 'cpf = ? AND cpf_hash_v = 2 AND deleted_at IS NULL',
      whereArgs: [hashCpf(cpf)],
      limit: 1,
    );

    // Fallback para hash v1 (legado SHA-256)
    if (result.isEmpty) {
      result = await db.query(
        'participants',
        where: 'cpf = ? AND cpf_hash_v = 1 AND deleted_at IS NULL',
        whereArgs: [_legacyHashCpf(cpf)],
        limit: 1,
      );
      // Migra para v2 na próxima oportunidade
      if (result.isNotEmpty) {
        final id = result.first['id'] as String;
        await db.update(
          'participants',
          {'cpf': hashCpf(cpf), 'cpf_hash_v': 2},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }

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

  /// LGPD: apaga dados pessoais do participante.
  Future<void> deletePersonalData(String participantId) async {
    await _db.deleteParticipantData(participantId);
  }
}
