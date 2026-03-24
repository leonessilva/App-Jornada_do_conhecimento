enum QuestionType { unica, likert, aberta }

class Question {
  final String id;
  final String texto;
  final QuestionType tipo;
  final List<String>? opcoes;
  final String? respostaCorreta;
  final int ordem;
  final String bloco;

  const Question({
    required this.id,
    required this.texto,
    required this.tipo,
    this.opcoes,
    this.respostaCorreta,
    required this.ordem,
    required this.bloco,
  });

  bool get isScored =>
      tipo == QuestionType.unica || tipo == QuestionType.likert;
}
