class Participant {
  final String id;
  final String nome;
  final String cpf;
  final String sexo;
  final String genero;
  final String? gestante;
  final String idadeFaixa;
  final String comunidade;
  final String municipio;
  final String estado;
  final String escolaridade;
  final DateTime createdAt;

  const Participant({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.sexo,
    required this.genero,
    this.gestante,
    required this.idadeFaixa,
    required this.comunidade,
    required this.municipio,
    required this.estado,
    required this.escolaridade,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'cpf': cpf,
        'sexo': sexo,
        'genero': genero,
        'gestante': gestante ?? '',
        'idade_faixa': idadeFaixa,
        'comunidade': comunidade,
        'municipio': municipio,
        'estado': estado,
        'escolaridade': escolaridade,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Participant.fromMap(Map<String, dynamic> map) => Participant(
        id: map['id'],
        nome: map['nome'] ?? '',
        cpf: map['cpf'] ?? '',
        sexo: map['sexo'] ?? '',
        genero: map['genero'] ?? '',
        gestante: (map['gestante'] as String?)?.isEmpty == true
            ? null
            : map['gestante'] as String?,
        idadeFaixa: map['idade_faixa'] ?? '',
        comunidade: map['comunidade'] ?? '',
        municipio: map['municipio'] ?? '',
        estado: map['estado'] ?? '',
        escolaridade: map['escolaridade'] ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      );
}
