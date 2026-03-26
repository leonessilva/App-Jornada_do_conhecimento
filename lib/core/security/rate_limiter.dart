import 'package:shared_preferences/shared_preferences.dart';

/// Proteção contra brute-force: bloqueia após [maxAttempts] falhas
/// dentro de [windowMinutes] minutos.
class RateLimiter {
  final String key;
  final int maxAttempts;
  final int windowMinutes;

  const RateLimiter({
    required this.key,
    this.maxAttempts = 5,
    this.windowMinutes = 15,
  });

  Future<bool> isBlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final lockUntil = prefs.getInt('rl_lock_$key') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return lockUntil > now;
  }

  /// Retorna quantos minutos restam até desbloquear (0 se não bloqueado).
  Future<int> minutesUntilUnlock() async {
    final prefs = await SharedPreferences.getInstance();
    final lockUntil = prefs.getInt('rl_lock_$key') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (lockUntil <= now) return 0;
    return ((lockUntil - now) / 60000).ceil();
  }

  /// Registra uma tentativa falha. Retorna true se bloqueou agora.
  Future<bool> recordFailure() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowMs = windowMinutes * 60 * 1000;

    final attemptsJson = prefs.getStringList('rl_attempts_$key') ?? [];
    final recent = attemptsJson
        .map(int.parse)
        .where((t) => now - t < windowMs)
        .toList();

    recent.add(now);
    await prefs.setStringList(
        'rl_attempts_$key', recent.map((t) => t.toString()).toList());

    if (recent.length >= maxAttempts) {
      final lockUntil = now + windowMs;
      await prefs.setInt('rl_lock_$key', lockUntil);
      return true;
    }
    return false;
  }

  /// Limpa o histórico de tentativas (chamado em login bem-sucedido).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rl_attempts_$key');
    await prefs.remove('rl_lock_$key');
  }

  Future<int> failureCount() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowMs = windowMinutes * 60 * 1000;
    final attemptsJson = prefs.getStringList('rl_attempts_$key') ?? [];
    return attemptsJson
        .map(int.parse)
        .where((t) => now - t < windowMs)
        .length;
  }
}
