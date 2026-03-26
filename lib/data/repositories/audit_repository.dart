import '../database/database_helper.dart';

class AuditLog {
  final int? id;
  final String action;
  final String entity;
  final String entityId;
  final String performedBy;
  final String details;
  final DateTime timestamp;

  const AuditLog({
    this.id,
    required this.action,
    this.entity = '',
    this.entityId = '',
    this.performedBy = '',
    this.details = '',
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'action': action,
        'entity': entity,
        'entity_id': entityId,
        'performed_by': performedBy,
        'details': details,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory AuditLog.fromMap(Map<String, dynamic> m) => AuditLog(
        id: m['id'] as int?,
        action: m['action'] as String,
        entity: m['entity'] as String? ?? '',
        entityId: m['entity_id'] as String? ?? '',
        performedBy: m['performed_by'] as String? ?? '',
        details: m['details'] as String? ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int),
      );
}

class AuditRepository {
  final _db = DatabaseHelper.instance;

  Future<void> log({
    required String action,
    String entity = '',
    String entityId = '',
    String performedBy = '',
    String details = '',
  }) async {
    final db = await _db.database;
    await db.insert('audit_logs', AuditLog(
      action: action,
      entity: entity,
      entityId: entityId,
      performedBy: performedBy,
      details: details,
      timestamp: DateTime.now(),
    ).toMap());
  }

  Future<List<AuditLog>> getRecent({int limit = 50}) async {
    final db = await _db.database;
    final rows = await db.query(
      'audit_logs',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(AuditLog.fromMap).toList();
  }
}
