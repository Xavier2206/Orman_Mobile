/// Formateadores centralizados para importes y fechas del portal móvil.
abstract final class Formatters {
  static const _months = <String>[
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static String currency(double? amount) {
    if (amount == null || !amount.isFinite) return '—';
    final cents = (amount.abs() * 100).round();
    return _currencyFromCents(cents, negative: amount < 0);
  }

  static String currencyFromCents(int amountCents) =>
      _currencyFromCents(amountCents.abs(), negative: amountCents < 0);

  static String _currencyFromCents(int cents, {required bool negative}) {
    final whole = (cents ~/ 100).toString();
    final grouped = StringBuffer();
    for (var index = 0; index < whole.length; index++) {
      if (index > 0 && (whole.length - index) % 3 == 0) {
        grouped.write('.');
      }
      grouped.write(whole[index]);
    }
    final decimal = (cents % 100).toString().padLeft(2, '0');
    final sign = negative ? '-' : '';
    return 'Bs $sign${grouped.toString()},$decimal';
  }

  static String date(DateTime? value) {
    if (value == null) return '—';
    return '${_two(value.day)}/${_two(value.month)}/${value.year}';
  }

  static String period(DateTime? value) {
    if (value == null) return 'Período sin fecha';
    final month = _months[value.month - 1];
    return '${month[0].toUpperCase()}${month.substring(1)} ${value.year}';
  }

  static String dateTime(DateTime? value) {
    if (value == null) return '—';
    return '${date(value)} · ${_two(value.hour)}:${_two(value.minute)}';
  }

  static String fileSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KiB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
  }

  /// Lee importes españoles o anglosajones simples, sin separadores de miles.
  static int? amountToCents(String value) {
    final normalized = value.trim();
    if (!RegExp(r'^\d+(?:[.,]\d{1,2})?$').hasMatch(normalized)) return null;
    final parts = normalized.split(RegExp(r'[.,]'));
    final whole = int.tryParse(parts.first);
    if (whole == null) return null;
    final decimals = parts.length == 1
        ? 0
        : int.tryParse(parts.last.padRight(2, '0'));
    if (decimals == null) return null;
    return whole * 100 + decimals;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
