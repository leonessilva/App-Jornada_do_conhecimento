import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/ubs_model.dart';

class UbsRepository {
  static List<UbsModel>? _cache;

  Future<List<UbsModel>> _loadAll() async {
    if (_cache != null) return _cache!;
    final json = await rootBundle.loadString('assets/data/ubs_nordeste.json');
    final list = (jsonDecode(json) as List)
        .map((e) => UbsModel.fromMap(e as Map<String, dynamic>))
        .toList();
    _cache = list;
    return list;
  }

  /// Retorna as [count] UBS mais próximas por GPS.
  Future<List<({UbsModel ubs, double distKm})>> getNearby({
    required double lat,
    required double lng,
    int count = 3,
  }) async {
    final all = await _loadAll();
    final withDist = all
        .map((u) => (ubs: u, distKm: u.distanceTo(lat, lng)))
        .toList()
      ..sort((a, b) => a.distKm.compareTo(b.distKm));
    return withDist.take(count).toList();
  }

  /// Busca UBS por CEP.
  /// Online: consulta ViaCEP para obter cidade → filtra por cidade.
  /// Offline: usa prefixo do CEP para determinar estado → filtra por estado.
  Future<({List<UbsModel> results, String label})> getByCep(String cep) async {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) {
      return (results: <UbsModel>[], label: 'CEP inválido');
    }

    // Tenta ViaCEP online
    try {
      final res = await http
          .get(Uri.parse('https://viacep.com.br/ws/$digits/json/'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['erro'] != true) {
          final cidade = (data['localidade'] as String).toLowerCase();
          final uf = (data['uf'] as String).toUpperCase();
          final all = await _loadAll();
          final byCity = all
              .where((u) =>
                  u.municipio.toLowerCase().contains(cidade) ||
                  cidade.contains(u.municipio.toLowerCase()))
              .toList();
          if (byCity.isNotEmpty) {
            return (results: byCity, label: '${data['localidade']} — $uf');
          }
          // Cidade não tem UBS cadastrada, cai no estado
          final byState =
              all.where((u) => u.estado == uf).toList();
          return (results: byState, label: 'Estado: $uf');
        }
      }
    } catch (_) {
      // Sem internet — usa prefixo offline
    }

    // Offline: determina estado pelo prefixo do CEP
    final prefix = int.tryParse(digits.substring(0, 2)) ?? -1;
    final estado = _estadoDoCep(prefix);
    if (estado == null) {
      return (results: <UbsModel>[], label: 'CEP fora da área coberta');
    }
    final all = await _loadAll();
    final byState = all.where((u) => u.estado == estado).toList();
    return (results: byState, label: 'Estado: $estado (modo offline)');
  }

  /// Mapa prefixo CEP → UF (Nordeste + estados vizinhos comuns)
  String? _estadoDoCep(int prefix) {
    if (prefix >= 40 && prefix <= 48) return 'BA';
    if (prefix == 49) return 'SE';
    if (prefix >= 50 && prefix <= 56) return 'PE';
    if (prefix == 57) return 'AL';
    if (prefix == 58) return 'PB';
    if (prefix == 59) return 'RN';
    if (prefix >= 60 && prefix <= 63) return 'CE';
    if (prefix == 64) return 'PI';
    if (prefix >= 65 && prefix <= 66) return 'MA';
    return null;
  }

  /// Pede permissão e retorna a localização atual.
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
