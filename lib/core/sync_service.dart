import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/database/database_helper.dart';

/// Sincroniza dados locais (SQLite) com o Firestore quando há conexão.
class SyncService {
  static final SyncService _instance = SyncService._();
  SyncService._();
  factory SyncService() => _instance;

  final _db = DatabaseHelper.instance;
  final _firestore = FirebaseFirestore.instance;

  /// Inicia escuta de conectividade e sincroniza ao reconectar.
  void init() {
    Connectivity().onConnectivityChanged.listen((results) {
      final connected = results.any((r) =>
          r == ConnectivityResult.wifi || r == ConnectivityResult.mobile);
      if (connected) syncPendentes();
    });
  }

  /// Envia participantes ainda não sincronizados para o Firestore.
  Future<void> syncPendentes() async {
    try {
      final pendentes = await _db.getPendentesSync();
      for (final p in pendentes) {
        await _firestore
            .collection('participantes')
            .doc(p['id'] as String)
            .set(p, SetOptions(merge: true));
        await _db.marcarSincronizado(p['id'] as String);
      }
    } catch (_) {
      // Silencioso — tenta de novo na próxima conexão
    }
  }
}
