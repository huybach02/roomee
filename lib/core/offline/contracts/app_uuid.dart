import 'dart:math';

abstract final class AppUuid {
  static final Random _random = Random.secure();

  /// Sinh mã UUID v4 chuẩn RFC 4122 (dùng an toàn cho khóa chính PostgreSQL)
  static String v4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant RFC 4122

    return [
      bytes.sublist(0, 4),
      bytes.sublist(4, 6),
      bytes.sublist(6, 8),
      bytes.sublist(8, 10),
      bytes.sublist(10, 16),
    ]
        .map((chunk) =>
            chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join())
        .join('-');
  }
}
