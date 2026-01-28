import 'dart:math';

/// Code Service - Random Invite Code Generator
class CodeService {
  CodeService._();

  static final _random = Random();
  static const _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _digits = '0123456789';

  /// Rastgele invite code üret (XXXX-9999 formatında)
  /// Örnek: HMGL-2321, ZKTR-8841
  static String generateCode() {
    // 4 büyük harf
    final letters = List.generate(
      4,
      (_) => _letters[_random.nextInt(_letters.length)],
    ).join();

    // 4 rakam
    final digits = List.generate(
      4,
      (_) => _digits[_random.nextInt(_digits.length)],
    ).join();

    return '$letters-$digits';
  }

  /// Kod formatını doğrula (XXXX-9999)
  static bool validateFormat(String code) {
    final regex = RegExp(r'^[A-Z]{4}-[0-9]{4}$');
    return regex.hasMatch(code);
  }

  /// Kodu normalize et (küçük harfleri büyült, boşlukları temizle)
  static String normalizeCode(String code) {
    return code.toUpperCase().trim();
  }
}
