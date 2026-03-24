class ResponseModel {
  final int? id;
  final String participantId;
  final String fase;
  final String questionId;
  final String answer;
  final DateTime timestamp;

  const ResponseModel({
    this.id,
    required this.participantId,
    required this.fase,
    required this.questionId,
    required this.answer,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'participant_id': participantId,
        'fase': fase,
        'question_id': questionId,
        'answer': answer,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory ResponseModel.fromMap(Map<String, dynamic> map) => ResponseModel(
        id: map['id'],
        participantId: map['participant_id'],
        fase: map['fase'],
        questionId: map['question_id'],
        answer: map['answer'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      );
}
