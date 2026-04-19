import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'es_ES',
    symbol: '€',
    decimalDigits: 2,
  );
  static final NumberFormat _integer = NumberFormat('#,##0', 'es_ES');
  static final DateFormat _dateShort = DateFormat('d MMM', 'es_ES');
  static final DateFormat _dateLong =
      DateFormat("d 'de' MMMM 'de' y", 'es_ES');
  static final DateFormat _dateTime = DateFormat('d MMM · HH:mm', 'es_ES');

  static String money(num value) => _currency.format(value);
  static String integer(num value) => _integer.format(value);
  static String dateShort(DateTime d) => _dateShort.format(d);
  static String dateLong(DateTime d) => _dateLong.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);

  static String relative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'ahora mismo';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    return dateShort(date);
  }

  static String stockStatus(int stock, int stockMin) {
    if (stock <= 0) return 'Agotado';
    if (stock <= stockMin) return 'Stock bajo';
    return 'En stock';
  }
}
