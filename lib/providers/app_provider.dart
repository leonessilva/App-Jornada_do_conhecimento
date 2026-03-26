import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/models/participant.dart';
import '../data/models/progress_model.dart';
import '../data/models/response_model.dart';
import '../data/database/database_helper.dart';
import '../data/repositories/participant_repository.dart';
import '../data/repositories/response_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../core/sync_service.dart';

// Etapas do fluxo
class AppStep {
  static const String splash = 'splash';
  static const String consent = 'consent';
  static const String registration = 'registration';
  static const String questionnairePre = 'questionnaire_pre';
  static const String videos = 'videos';
  static const String questionnairePos = 'questionnaire_pos';
  static const String results = 'results';
}

class AppProvider extends ChangeNotifier {
  final _participantRepo = ParticipantRepository();
  final _responseRepo = ResponseRepository();
  final _progressRepo = ProgressRepository();

  Participant? _participant;
  ProgressModel? _progress;
  Map<String, String> _currentAnswers = {};
  bool _isLoading = true;
  String? _participantId;

  Participant? get participant => _participant;
  ProgressModel? get progress => _progress;
  Map<String, String> get currentAnswers => _currentAnswers;
  bool get isLoading => _isLoading;
  String? get participantId => _participantId;
  String? get currentStep => _progress?.etapaAtual;
  int get currentIndex => _progress?.indicePergunta ?? 0;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Abre o banco antecipadamente para evitar travamento na primeira ação
      await DatabaseHelper.instance.database;

      final prefs = await SharedPreferences.getInstance();
      _participantId = prefs.getString('participant_id');

      if (_participantId != null) {
        _participant = await _participantRepo.findById(_participantId!);
        _progress = await _progressRepo.getProgress(_participantId!);
      }
    } catch (e) {
      debugPrint('AppProvider.initialize error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── TCLE aceito ──────────────────────────────────────────────
  Future<void> acceptConsent({String tcleVersion = '1.0'}) async {
    final prefs = await SharedPreferences.getInstance();
    _participantId ??= const Uuid().v4();
    await prefs.setString('participant_id', _participantId!);
    await _participantRepo.saveConsent(_participantId!, tcleVersion: tcleVersion);
    await _saveProgress(AppStep.registration);
    notifyListeners();
  }

  // ── Salvar cadastro ─────────────────────────────────────────
  Future<void> saveParticipant({
    required String nome,
    required String cpf,
    required String sexo,
    required String genero,
    String? gestante,
    required String idadeFaixa,
    required String comunidade,
    required String municipio,
    required String estado,
    required String escolaridade,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('participant_cpf', ParticipantRepository.hashCpf(cpf));

    _participant = Participant(
      id: _participantId!,
      nome: nome,
      cpf: cpf,
      sexo: sexo,
      genero: genero,
      gestante: gestante,
      idadeFaixa: idadeFaixa,
      comunidade: comunidade,
      municipio: municipio,
      estado: estado,
      escolaridade: escolaridade,
      createdAt: DateTime.now(),
    );
    await _participantRepo.save(_participant!);
    SyncService().syncPendentes();
    await _saveProgress(AppStep.questionnairePre, fase: 'pre', index: 0);
    notifyListeners();
  }

  // ── Login por CPF (retomar sessão) ──────────────────────────
  Future<bool> loginByCpf(String cpf) async {
    // 1. Tenta localmente
    var participant = await _participantRepo.findByCpf(cpf);

    // 2. Se não encontrou localmente, tenta restaurar da nuvem
    if (participant == null) {
      final cpfHash = ParticipantRepository.hashCpf(cpf);
      final cloudData = await SyncService().restoreParticipant(cpfHash);
      if (cloudData == null) return false;

      // Reconstrói participante (nome não está na nuvem — privacidade)
      participant = Participant(
        id: cloudData['id'] as String,
        nome: '',
        cpf: cpf,
        sexo: cloudData['sexo'] as String? ?? '',
        genero: cloudData['genero'] as String? ?? '',
        gestante: cloudData['gestante'] as String?,
        idadeFaixa: cloudData['idade_faixa'] as String? ?? '',
        comunidade: cloudData['comunidade'] as String? ?? '',
        municipio: cloudData['municipio'] as String? ?? '',
        estado: cloudData['estado'] as String? ?? '',
        escolaridade: cloudData['escolaridade'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (cloudData['created_at'] as int?) ?? 0),
      );
      await _participantRepo.save(participant);
      await _participantRepo.saveConsent(participant.id);

      // Restaura progresso
      if (cloudData['etapa_atual'] != null) {
        final progress = ProgressModel(
          participantId: participant.id,
          etapaAtual: cloudData['etapa_atual'] as String,
          indicePergunta: (cloudData['indice_pergunta'] as int?) ?? 0,
          fase: cloudData['fase'] as String?,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(
              (cloudData['progress_updated_at'] as int?) ?? 0),
        );
        await _progressRepo.saveProgress(progress);
      }

      // Restaura respostas
      final respostas =
          (cloudData['respostas'] as List<dynamic>? ?? []);
      for (final r in respostas) {
        try {
          await _responseRepo.saveResponse(
              ResponseModel.fromMap(Map<String, dynamic>.from(r as Map)));
        } catch (_) {
          // Ignora resposta com dados inválidos
        }
      }

      // Recarrega participante com cpf_hash correto do SQLite
      participant = await _participantRepo.findByCpf(cpf) ?? participant;
    }

    _participantId = participant.id;
    _participant = participant;
    _progress = await _progressRepo.getProgress(_participantId!);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('participant_id', _participantId!);
    await prefs.setString('participant_cpf', cpf);

    notifyListeners();
    return true;
  }

  // ── Salvar resposta individual ──────────────────────────────
  Future<void> saveAnswer(String questionId, String answer, String fase) async {
    if (_participantId == null) return;
    _currentAnswers[questionId] = answer;
    notifyListeners();
    final response = ResponseModel(
      participantId: _participantId!,
      fase: fase,
      questionId: questionId,
      answer: answer,
      timestamp: DateTime.now(),
    );
    await _responseRepo.saveResponse(response);
    SyncService().syncResponse(_participantId!, response);
  }

  // ── Avançar índice da pergunta ──────────────────────────────
  Future<void> updateQuestionIndex(int index, String fase) async {
    final etapa = fase == 'pre'
        ? AppStep.questionnairePre
        : AppStep.questionnairePos;
    await _saveProgress(etapa, fase: fase, index: index);
  }

  // ── Pré concluído → ir para vídeos ─────────────────────────
  Future<void> finishPre() async {
    await _saveProgress(AppStep.videos);
    notifyListeners();
  }

  // ── Vídeos concluídos → ir para pós ────────────────────────
  Future<void> finishVideos() async {
    await _saveProgress(AppStep.questionnairePos, fase: 'pos', index: 0);
    _currentAnswers = await _responseRepo.getResponsesMapByFase(
      _participantId!,
      'pos',
    );
    notifyListeners();
  }

  // ── Pós concluído → resultados ─────────────────────────────
  Future<void> finishPos() async {
    await _saveProgress(AppStep.results);
    notifyListeners();
  }

  // ── Carregar respostas de uma fase ─────────────────────────
  Future<void> loadAnswersForFase(String fase) async {
    _currentAnswers =
        await _responseRepo.getResponsesMapByFase(_participantId!, fase);
    notifyListeners();
  }

  // ── Buscar respostas de uma fase ───────────────────────────
  Future<Map<String, String>> getResponsesForFase(String fase) async {
    return _responseRepo.getResponsesMapByFase(_participantId!, fase);
  }

  String? getAnswer(String questionId) => _currentAnswers[questionId];

  // ── Resetar participante (novo início) ──────────────────────
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('participant_id');
    _participant = null;
    _progress = null;
    _currentAnswers = {};
    _participantId = null;
    notifyListeners();
  }

  // ── Interno: salvar progresso ───────────────────────────────
  Future<void> _saveProgress(
    String etapa, {
    String? fase,
    int index = 0,
  }) async {
    _progress = ProgressModel(
      participantId: _participantId!,
      etapaAtual: etapa,
      indicePergunta: index,
      fase: fase,
      updatedAt: DateTime.now(),
    );
    await _progressRepo.saveProgress(_progress!);
    SyncService().updateProgress(_participantId!, _progress!);
    notifyListeners();
  }
}
