import 'dart:math';

class UbsModel {
  final String nome;
  final String endereco;
  final String municipio;
  final String estado;
  final String telefone;
  final double lat;
  final double lng;

  const UbsModel({
    required this.nome,
    required this.endereco,
    required this.municipio,
    required this.estado,
    required this.telefone,
    required this.lat,
    required this.lng,
  });

  factory UbsModel.fromMap(Map<String, dynamic> map) => UbsModel(
        nome: map['nome'] as String,
        endereco: map['endereco'] as String? ?? '',
        municipio: map['municipio'] as String,
        estado: map['estado'] as String,
        telefone: map['telefone'] as String? ?? '',
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
      );

  /// Distância em km usando fórmula de Haversine
  double distanceTo(double userLat, double userLng) {
    const R = 6371.0;
    final dLat = _rad(lat - userLat);
    final dLng = _rad(lng - userLng);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(userLat)) * cos(_rad(lat)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _rad(double deg) => deg * pi / 180;

  String get distanceLabel {
    return '';
  }
}
