import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/database/database_helper.dart';
import '../data/models/progress_model.dart';
import '../data/models/response_model.dart';

enum SyncStatus { idle, syncing, done, error }

/// Sincroniza dados locais (SQLite) com o Firestore quando há conexão.
class SyncService {
  static final SyncService _instance = SyncService._();
  SyncService._();
  factory SyncService() => _instance;

  final _db = DatabaseHelper.instance;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  FirebaseFirestore? get _firestore =>
      _firebaseReady ? FirebaseFirestore.instance : null;

  final status = ValueNotifier<SyncStatus>(SyncStatus.idle);
  final pendingCount = ValueNotifier<int>(0);

  /// Garante que há um usuário anônimo autenticado antes de acessar o Firestore.
  Future<void> _ensureAuth() async {
    if (!_firebaseReady) return;
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
      debugPrint('[SyncService] signed in anonymously: ${auth.currentUser?.uid}');
    }
  }

  /// Inicia escuta de conectividade e sincroniza ao reconectar.
  void init() {
    _refreshPendingCount();
    _ensureAuth();
    Connectivity().onConnectivityChanged.listen((results) {
      final connected = results.any((r) =>
          r == ConnectivityResult.wifi || r == ConnectivityResult.mobile);
      if (connected) _syncAll();
    });
  }

  Future<void> _syncAll() async {
    await _ensureAuth();
    await syncPendentes();
    await _processQueue();
  }

  Future<void> _refreshPendingCount() async {
    final pendentes = await _db.getPendentesSync();
    pendingCount.value = pendentes.length;
  }

  // ─── Upload inicial de participantes pendentes ────────────────────────────

  /// Envia participantes não sincronizados para o Firestore.
  Future<void> syncPendentes() async {
    if (!_firebaseReady) return;
    await _refreshPendingCount();
    if (pendingCount.value == 0) return;

    status.value = SyncStatus.syncing;
    try {
      final firestore = _firestore!;
      final pendentes = await _db.getPendentesSync();
      for (final p in pendentes) {
        // Privacidade: nome não vai para nuvem.
        // cpf (HMAC hash) é renomeado para cpf_hash — necessário para restore.
        final payload = Map<String, dynamic>.from(p)
          ..remove('nome')
          ..remove('deleted_at')
          ..['cpf_hash'] = p['cpf']
          ..remove('cpf')
          ..remove('cpf_hash_v');
        await firestore
            .collection('participantes')
            .doc(p['id'] as String)
            .set(payload, SetOptions(merge: true));
        await _db.marcarSincronizado(p['id'] as String);
      }
      await _refreshPendingCount();
      status.value = SyncStatus.done;
      Future.delayed(const Duration(seconds: 3), () {
        if (status.value == SyncStatus.done) status.value = SyncStatus.idle;
      });
    } catch (_) {
      status.value = SyncStatus.error;
      Future.delayed(const Duration(seconds: 5), () {
        if (status.value == SyncStatus.error) status.value = SyncStatus.idle;
      });
    }
  }

  // ─── Sync de progresso ────────────────────────────────────────────────────

  /// Atualiza etapa/progresso do participante no Firestore.
  /// Se offline ou Firebase indisponível, enfileira para retry.
  Future<void> updateProgress(String participantId, ProgressModel progress) async {
    final payload = {
      'etapa_atual': progress.etapaAtual,
      'indice_pergunta': progress.indicePergunta,
      'fase': progress.fase,
      'progress_updated_at': progress.updatedAt.millisecondsSinceEpoch,
    };
    if (!_firebaseReady) {
      await _enqueue('progress', participantId, payload);
      return;
    }
    try {
      await _firestore!
          .collection('participantes')
          .doc(participantId)
          .set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SyncService] updateProgress error: $e — enfileirando');
      await _enqueue('progress', participantId, payload);
    }
  }

  // ─── Sync de respostas ────────────────────────────────────────────────────

  /// Grava uma resposta na subcoleção do participante no Firestore.
  /// Se offline ou Firebase indisponível, enfileira para retry.
  Future<void> syncResponse(String participantId, ResponseModel response) async {
    final docId = '${response.fase}_${response.questionId}';
    final payload = {...response.toMap(), '_doc_id': docId};
    if (!_firebaseReady) {
      await _enqueue('response', participantId, payload);
      return;
    }
    try {
      await _firestore!
          .collection('participantes')
          .doc(participantId)
          .collection('respostas')
          .doc(docId)
          .set(response.toMap());
    } catch (e) {
      debugPrint('[SyncService] syncResponse error: $e — enfileirando');
      await _enqueue('response', participantId, payload);
    }
  }

  // ─── Fila de retry offline ────────────────────────────────────────────────

  Future<void> _enqueue(String type, String participantId, Map<String, dynamic> payload) async {
    final id = const Uuid().v4();
    await _db.addToSyncQueue(id, type, participantId, jsonEncode(payload));
  }

  /// Processa todos os itens pendentes na fila de retry.
  Future<void> _processQueue() async {
    if (!_firebaseReady) return;
    final items = await _db.getSyncQueue();
    if (items.isEmpty) return;

    for (final item in items) {
      try {
        final id = item['id'] as String;
        final type = item['type'] as String;
        final participantId = item['participant_id'] as String;
        final payload = jsonDecode(item['payload'] as String) as Map<String, dynamic>;

        if (type == 'progress') {
          await _firestore!
              .collection('participantes')
              .doc(participantId)
              .set(payload, SetOptions(merge: true));
        } else if (type == 'response') {
          final docId = payload['_doc_id'] as String;
          final data = Map<String, dynamic>.from(payload)..remove('_doc_id');
          await _firestore!
              .collection('participantes')
              .doc(participantId)
              .collection('respostas')
              .doc(docId)
              .set(data);
        }
        await _db.removeSyncQueueItem(id);
      } catch (e) {
        debugPrint('[SyncService] _processQueue error: $e');
        break; // Para na primeira falha — tenta novamente ao reconectar
      }
    }
  }

  // ─── Restauração a partir da nuvem ───────────────────────────────────────

  /// Busca participante no Firestore pelo hash do CPF.
  /// Retorna mapa com dados do participante + progresso + lista de respostas,
  /// ou null se não encontrado.
  Future<Map<String, dynamic>?> restoreParticipant(String cpfHash) async {
    if (!_firebaseReady) return null;
    try {
      final snap = await _firestore!
          .collection('participantes')
          .where('cpf_hash', isEqualTo: cpfHash)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;

      final doc = snap.docs.first;
      final data = Map<String, dynamic>.from(doc.data());

      // Carrega respostas da subcoleção
      final respostasSnap = await _firestore!
          .collection('participantes')
          .doc(doc.id)
          .collection('respostas')
          .get();
      data['respostas'] =
          respostasSnap.docs.map((d) => Map<String, dynamic>.from(d.data())).toList();

      return data;
    } catch (e) {
      debugPrint('[SyncService] restoreParticipant error: $e');
      return null;
    }
  }
}
