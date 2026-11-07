import 'package:intl/intl.dart';

/// Symbol used for the Bangladesh Taka.
const String takaSymbol = '৳';

/// Number formatting is available out of the box for every locale shipped
/// with `intl`, but if the locale data ever fails to load we fall back to a
/// plain `en_US` formatter that still writes the Taka symbol.
NumberFormat _currencyFormat(int decimalDigits) {
  try {
    return NumberFormat.currency(
      locale: 'bn_BD',
      symbol: takaSymbol,
      decimalDigits: decimalDigits,
    );
  } catch (_) {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: takaSymbol,
      decimalDigits: decimalDigits,
    );
  }
}

DateFormat _dateFormat(DateFormat Function() create) {
  try {
    return create();
  } catch (_) {
    // Locale data was not initialised; en_US is always available.
    return DateFormat.yMMMd('en_US');
  }
}

late final NumberFormat _bdtWhole = _currencyFormat(0);
late final NumberFormat _bdtFraction = _currencyFormat(2);

late final DateFormat _shortDate = _dateFormat(() => DateFormat.yMMMd('bn_BD'));
late final DateFormat _shortDateWithWeekday = _dateFormat(
  () => DateFormat('EEE, d MMM y', 'bn_BD'),
);
late final DateFormat _dateTime = _dateFormat(
  () => DateFormat.yMMMd('bn_BD').add_Hm(),
);

/// Formats [amount] as Taka, e.g. `৳১,২৫০`.
String formatBdt(num amount) {
  final formatter =
      amount == amount.roundToDouble() ? _bdtWhole : _bdtFraction;
  return formatter.format(amount);
}

/// Formats a whole number without a currency symbol, e.g. `১০`.
String formatNumber(num value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toString();
}

/// Formats [date] for lists and labels, e.g. `৭ নভেম্বর ২০২৬`.
String formatDate(DateTime date) => _shortDate.format(date);

/// Formats [date] including the weekday, e.g. `শুক্র, ৭ নভেম্বর ২০২৬`.
String formatDateWithWeekday(DateTime date) =>
    _shortDateWithWeekday.format(date);

/// Formats a moment in time with a time of day.
String formatDateTime(DateTime date) => _dateTime.format(date);

/// Formats a journey length given in minutes, e.g. `৪ ঘ ৩০ মিনিট`.
String formatDuration(int minutes) {
  if (minutes <= 0) return '—';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '$rest মিনিট';
  if (rest == 0) return '$hours ঘণ্টা';
  return '$hours ঘ $rest মিনিট';
}
