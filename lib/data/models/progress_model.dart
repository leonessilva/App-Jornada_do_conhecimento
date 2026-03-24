class ProgressModel {
  final String participantId;
  final String etapaAtual;
  final int indicePergunta;
  final String? fase;
  final DateTime updatedAt;

  const ProgressModel({
    required this.participantId,
    required this.etapaAtual,
    this.indicePergunta = 0,
    this.fase,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'participant_id': participantId,
        'etapa_atual': etapaAtual,
        'indice_pergunta': indicePergunta,
        'fase': fase,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory ProgressModel.fromMap(Map<String, dynamic> map) => ProgressModel(
        participantId: map['participant_id'],
        etapaAtual: map['etapa_atual'],
        indicePergunta: map['indice_pergunta'] ?? 0,
        fase: map['fase'],
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      );

  ProgressModel copyWith({
    String? etapaAtual,
    int? indicePergunta,
    String? fase,
  }) =>
      ProgressModel(
        participantId: participantId,
        etapaAtual: etapaAtual ?? this.etapaAtual,
        indicePergunta: indicePergunta ?? this.indicePergunta,
        fase: fase ?? this.fase,
        updatedAt: DateTime.now(),
      );
}
