import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';

class Researcher {
  final String id;
  final String cpf;
  final String name;
  final String institution;
  final String justification;
  final bool approved;
  final DateTime createdAt;

  const Researcher({
    required this.id,
    required this.cpf,
    required this.name,
    required this.institution,
    required this.justification,
    required this.approved,
    required this.createdAt,
  });

  factory Researcher.fromMap(Map<String, dynamic> map) => Researcher(
        id: map['id'] as String,
        cpf: map['cpf'] as String,
        name: map['name'] as String,
        institution: map['institution'] as String? ?? '',
        justification: map['justification'] as String? ?? '',
        approved: (map['approved'] as int) == 1,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}

class ResearcherRepository {
  final _db = DatabaseHelper.instance;

  static String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  Future<void> saveRequest({
    required String cpf,
    required String name,
    required String institution,
    required String justification,
    required String password,
  }) async {
    final db = await _db.database;
    await db.insert('researchers', {
      'id': const Uuid().v4(),
      'cpf': cpf.replaceAll(RegExp(r'\D'), ''),
      'name': name,
      'institution': institution,
      'justification': justification,
      'password_hash': _hash(password),
      'approved': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<bool> login(String cpf, String password) async {
    final db = await _db.database;
    final rows = await db.query(
      'researchers',
      where: 'cpf = ? AND password_hash = ? AND approved = 1',
      whereArgs: [cpf.replaceAll(RegExp(r'\D'), ''), _hash(password)],
      limit: 1,
    );
    return rows.isNotEmpty;
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

  Future<void> reject(String id) async {
    final db = await _db.database;
    await db.delete('researchers', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> cpfAlreadyExists(String cpf) async {
    final db = await _db.database;
    final rows = await db.query(
      'researchers',
      where: 'cpf = ?',
      whereArgs: [cpf.replaceAll(RegExp(r'\D'), '')],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
