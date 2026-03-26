/// Validação de CPF com o algoritmo oficial dos dígitos verificadores.
class CpfValidator {
  CpfValidator._();

  /// Retorna true se o CPF for estruturalmente válido.
  static bool isValid(String cpf) {
    final digits = cpf.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 11) return false;

    // Sequências inválidas (todos iguais: 000...000, 111...111, etc.)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;

    // Calcula 1º dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(digits[i]) * (10 - i);
    }
    int remainder = (sum * 10) % 11;
    if (remainder == 10 || remainder == 11) remainder = 0;
    if (remainder != int.parse(digits[9])) return false;

    // Calcula 2º dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(digits[i]) * (11 - i);
    }
    remainder = (sum * 10) % 11;
    if (remainder == 10 || remainder == 11) remainder = 0;
    if (remainder != int.parse(digits[10])) return false;

    return true;
  }

  /// Formata CPF para exibição: XXX.XXX.XXX-XX
  static String format(String cpf) {
    final d = cpf.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) return cpf;
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }

  /// Retorna apenas os dígitos (sem formatação)
  static String digits(String cpf) => cpf.replaceAll(RegExp(r'\D'), '');
}
