import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../../core/security/security_utils.dart';
import '../../core/security/cpf_validator.dart';

class Researcher {
  final String id;
  final String cpf;
  final String name;
  final String institution;
  final String justification;
  final bool approved;
  final bool rejected;
  final DateTime createdAt;

  const Researcher({
    required this.id,
    required this.cpf,
    required this.name,
    required this.institution,
    required this.justification,
    required this.approved,
    required this.rejected,
    required this.createdAt,
  });

  factory Researcher.fromMap(Map<String, dynamic> map) => Researcher(
        id: map['id'] as String,
        cpf: map['cpf'] as String,
        name: map['name'] as String,
        institution: map['institution'] as String? ?? '',
        justification: map['justification'] as String? ?? '',
        approved: (map['approved'] as int) == 1,
        rejected: (map['approved'] as int) == -1,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}

class ResearcherRepository {
  final _db = DatabaseHelper.instance;

  /// Hash seguro de senha usando HMAC-SHA256 com pepper (v2).
  static String _hash(String password) =>
      SecurityUtils.secureHash(password);

  Future<void> saveRequest({
    required String cpf,
    required String name,
    required String institution,
    required String justification,
    required String password,
  }) async {
    final db = await _db.database;
    final cleanCpf = CpfValidator.digits(cpf);
    await db.insert('researchers', {
      'id': const Uuid().v4(),
      'cpf': cleanCpf,
      'name': name.trim(),
      'institution': institution.trim(),
      'justification': justification.trim(),
      'password_hash': _hash(password),
      'hash_version': SecurityUtils.currentHashVersion,
      'approved': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Login com suporte a migração de hash v1 → v2.
  Future<bool> login(String cpf, String password) async {
    final db = await _db.database;
    final cleanCpf = CpfValidator.digits(cpf);

    final rows = await db.query(
      'researchers',
      where: 'cpf = ? AND approved = 1',
      whereArgs: [cleanCpf],
      limit: 1,
    );

    if (rows.isEmpty) return false;

    final row = rows.first;
    final storedHash = row['password_hash'] as String;
    final hashVersion = (row['hash_version'] as int?) ?? 1;

    final valid = SecurityUtils.verify(password, storedHash, hashVersion);

    // Migra hash legado para v2 em login bem-sucedido
    if (valid && hashVersion < SecurityUtils.currentHashVersion) {
      await db.update(
        'researchers',
        {
          'password_hash': _hash(password),
          'hash_version': SecurityUtils.currentHashVersion,
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }

    return valid;
  }

  Future<List<Researcher>> getPending() async {
    final db = await _db.database;
    final rows = await db.query(
      'researchers',
      where: 'approved = 0',
      orderBy: 'created_at DESC',
    );
    return rows.map(Researcher.fromMap).toList();
  }

  Future<List<Researcher>> getApproved() async {
    final db = await _db.database;
    final rows = await db.query(
      'researchers',
      where: 'approved = 1',
      orderBy: 'name ASC',
    );
    return rows.map(Researcher.fromMap).toList();
  }

  Future<void> approve(String id) async {
    final db = await _db.database;
    await db.update(
      'researchers',
      {'approved': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Soft-delete: marca como rejeitado (-1) em vez de apagar.
  /// Preserva trilha de auditoria.
  Future<void> reject(String id) async {
    final db = await _db.database;
    await db.update(
      'researchers',
      {'approved': -1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> cpfAlreadyExists(String cpf) async {
    final db = await _db.database;
    final cleanCpf = CpfValidator.digits(cpf);
    final rows = await db.query(
      'researchers',
      where: 'cpf = ? AND approved != -1',
      whereArgs: [cleanCpf],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
