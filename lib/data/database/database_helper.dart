import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path;
    if (kIsWeb) {
      path = 'jornada.db';
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'jornada.db');
    }

    return await openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE participants ADD COLUMN nome TEXT NOT NULL DEFAULT ''");
      await db.execute("ALTER TABLE participants ADD COLUMN cpf TEXT NOT NULL DEFAULT ''");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE participants ADD COLUMN genero TEXT NOT NULL DEFAULT ''");
      await db.execute("ALTER TABLE participants ADD COLUMN gestante TEXT NOT NULL DEFAULT ''");
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE participants ADD COLUMN estado TEXT NOT NULL DEFAULT ''");
      await db.execute('''
        CREATE TABLE IF NOT EXISTS researchers (
          id TEXT PRIMARY KEY,
          cpf TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          institution TEXT NOT NULL DEFAULT '',
          justification TEXT NOT NULL DEFAULT '',
          password_hash TEXT NOT NULL DEFAULT '',
          approved INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE participants ADD COLUMN synced INTEGER NOT NULL DEFAULT 0");
    }
    if (oldVersion < 6) {
      await db.execute("ALTER TABLE responses ADD COLUMN questionnaire_version TEXT NOT NULL DEFAULT '1.0'");
      await db.execute('''
        CREATE TABLE IF NOT EXISTS audit_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          action TEXT NOT NULL,
          entity TEXT NOT NULL DEFAULT '',
          entity_id TEXT NOT NULL DEFAULT '',
          performed_by TEXT NOT NULL DEFAULT '',
          details TEXT NOT NULL DEFAULT '',
          timestamp INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 7) {
      // Segurança v7: versão do hash de CPF, versão do TCLE, deleted_at, hash_version em researchers
      await db.execute("ALTER TABLE participants ADD COLUMN cpf_hash_v INTEGER NOT NULL DEFAULT 1");
      await db.execute("ALTER TABLE participants ADD COLUMN deleted_at INTEGER");
      await db.execute("ALTER TABLE consents ADD COLUMN tcle_version TEXT NOT NULL DEFAULT '1.0'");
      await db.execute("ALTER TABLE researchers ADD COLUMN hash_version INTEGER NOT NULL DEFAULT 1");
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          participant_id TEXT NOT NULL,
          payload TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE participants (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL DEFAULT '',
        cpf TEXT NOT NULL DEFAULT '',
        cpf_hash_v INTEGER NOT NULL DEFAULT 2,
        sexo TEXT NOT NULL,
        genero TEXT NOT NULL DEFAULT '',
        gestante TEXT NOT NULL DEFAULT '',
        idade_faixa TEXT NOT NULL,
        comunidade TEXT NOT NULL,
        municipio TEXT NOT NULL,
        estado TEXT NOT NULL DEFAULT '',
        escolaridade TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE consents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        participant_id TEXT NOT NULL,
        aceito INTEGER NOT NULL,
        tcle_version TEXT NOT NULL DEFAULT '1.0',
        accepted_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE responses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        participant_id TEXT NOT NULL,
        fase TEXT NOT NULL CHECK(fase IN ('pre','pos')),
        question_id TEXT NOT NULL,
        answer TEXT NOT NULL,
        questionnaire_version TEXT NOT NULL DEFAULT '1.0',
        timestamp INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE progress (
        participant_id TEXT PRIMARY KEY,
        etapa_atual TEXT NOT NULL,
        indice_pergunta INTEGER NOT NULL DEFAULT 0,
        fase TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        entity TEXT NOT NULL DEFAULT '',
        entity_id TEXT NOT NULL DEFAULT '',
        performed_by TEXT NOT NULL DEFAULT '',
        details TEXT NOT NULL DEFAULT '',
        timestamp INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE researchers (
        id TEXT PRIMARY KEY,
        cpf TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        institution TEXT NOT NULL DEFAULT '',
        justification TEXT NOT NULL DEFAULT '',
        password_hash TEXT NOT NULL DEFAULT '',
        hash_version INTEGER NOT NULL DEFAULT 2,
        approved INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        participant_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  // ─── Sync helpers ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPendentesSync() async {
    final db = await database;
    // Exclui participantes com deleted_at preenchido da sincronização
    return db.query('participants',
        where: 'synced = ? AND deleted_at IS NULL', whereArgs: [0]);
  }

  Future<void> marcarSincronizado(String id) async {
    final db = await database;
    await db.update(
      'participants',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── Fila de retry offline ───────────────────────────────────────────────

  Future<void> addToSyncQueue(String id, String type, String participantId, String payload) async {
    final db = await database;
    await db.insert('sync_queue', {
      'id': id,
      'type': type,
      'participant_id': participantId,
      'payload': payload,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return db.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<void> removeSyncQueueItem(String id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  // ─── LGPD: direito ao esquecimento ───────────────────────────────────────

  /// Apaga todos os dados pessoais de um participante (mantém apenas UUID).
  Future<void> deleteParticipantData(String participantId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'participants',
      {
        'nome': '[removido]',
        'cpf': '',
        'cpf_hash_v': 0,
        'sexo': '',
        'genero': '',
        'gestante': '',
        'comunidade': '[removido]',
        'municipio': '[removido]',
        'estado': '',
        'escolaridade': '',
        'deleted_at': now,
      },
      where: 'id = ?',
      whereArgs: [participantId],
    );

    // Mantém respostas para fins de pesquisa (anonymizadas), remove dados pessoais
    await db.delete('consents',
        where: 'participant_id = ?', whereArgs: [participantId]);
  }
}
