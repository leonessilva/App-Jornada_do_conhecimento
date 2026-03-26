import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utilitários criptográficos centralizados.
///
/// Usa HMAC-SHA256 com pepper fixo, muito mais resistente a rainbow tables
/// do que SHA-256 puro. O pepper está no código, então não é perfeito, mas
/// garante que tabelas pré-computadas genéricas não funcionem.
class SecurityUtils {
  SecurityUtils._();

  // Pepper fixo — nunca alterar após deploy para não quebrar logins existentes.
  // Em produção real, mover para variável de ambiente ou keystore.
  static const _kPepper = 'jornada-2024-sec-v2-NE-ribeirinho';

  /// Versão atual do algoritmo de hash (1 = SHA-256 legacy, 2 = HMAC atual).
  static const int currentHashVersion = 2;

  /// Hash seguro para CPF e senhas — HMAC-SHA256 com pepper.
  /// Determinístico: mesmo input sempre produz mesmo output.
  static String secureHash(String input) {
    final key = utf8.encode(_kPepper);
    final data = utf8.encode(input.trim());
    return Hmac(sha256, key).convert(data).toString();
  }

  /// Hash legado SHA-256 puro (mantido para migração de contas antigas).
  static String legacyHash(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    return sha256.convert(utf8.encode(digits.isNotEmpty ? digits : input)).toString();
  }

  /// Verifica se um valor corresponde ao hash, tentando a versão atual primeiro
  /// e depois a legada (para migração suave).
  static bool verify(String input, String storedHash, int hashVersion) {
    if (hashVersion == 2) {
      return secureHash(input) == storedHash;
    }
    // versão 1 (legado): SHA-256 nos dígitos
    return legacyHash(input) == storedHash;
  }
}
