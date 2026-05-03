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
  static final DateFormat _dateLong = DateFormat("d 'de' MMMM 'de' y", 'es_ES');
  static final DateFormat _dateTime = DateFormat('d MMM · HH:mm', 'es_ES');
  static final DateFormat _time = DateFormat('HH:mm', 'es_ES');

  static String money(num value) => _currency.format(value);
  static String integer(num value) => _integer.format(value);

  // ← .toLocal() convierte UTC → hora local del dispositivo
  static String dateShort(DateTime d) => _dateShort.format(d.toLocal());
  static String dateLong(DateTime d) => _dateLong.format(d.toLocal());
  static String dateTime(DateTime d) => _dateTime.format(d.toLocal());
  static String time(DateTime d) => _time.format(d.toLocal());

  static String relative(DateTime date) {
    final now = DateTime.now();
    final local = date.toLocal();
    final diff = now.difference(local);
    if (diff.inSeconds < 60) return 'ahora mismo';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    return dateShort(local);
  }

  static String stockStatus(int stock, int stockMin) {
    if (stock <= 0) return 'Agotado';
    if (stock <= stockMin) return 'Stock bajo';
    return 'En stock';
  }
}