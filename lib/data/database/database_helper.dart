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
      version: 5,
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
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE participants (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL DEFAULT '',
        cpf TEXT NOT NULL DEFAULT '',
        sexo TEXT NOT NULL,
        genero TEXT NOT NULL DEFAULT '',
        gestante TEXT NOT NULL DEFAULT '',
        idade_faixa TEXT NOT NULL,
        comunidade TEXT NOT NULL,
        municipio TEXT NOT NULL,
        estado TEXT NOT NULL DEFAULT '',
        escolaridade TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE consents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        participant_id TEXT NOT NULL,
        aceito INTEGER NOT NULL,
        accepted_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE responses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        participant_id TEXT NOT NULL,
        fase TEXT NOT NULL,
        question_id TEXT NOT NULL,
        answer TEXT NOT NULL,
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
      CREATE TABLE researchers (
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

  // ─── Sync helpers ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPendentesSync() async {
    final db = await database;
    return db.query('participants', where: 'synced = ?', whereArgs: [0]);
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
}
