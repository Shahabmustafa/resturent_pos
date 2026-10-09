import 'package:intl/intl.dart';

/// The restaurant trades in pounds sterling; every price on screen, on
/// receipts and on the website goes through [formatMoney].
const kCurrencySymbol = '£';

final _moneyFormat = NumberFormat('#,##0.00', 'en_GB');

/// e.g. 8.5 → "£8.50", 1200 → "£1,200.00".
String formatMoney(num value) => '$kCurrencySymbol${_moneyFormat.format(value)}';

/// Short form for charts and tight stat cards, e.g. "£1.2k", "£3.4M".
String formatMoneyCompact(num value) {
  if (value >= 1000000) return '$kCurrencySymbol${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '$kCurrencySymbol${(value / 1000).toStringAsFixed(1)}k';
  return formatMoney(value);
}

/// Text for an editable amount field: "8" stays "8", 8.5 becomes "8.50",
/// so pence are never rounded away when a form is opened and saved again.
String amountInputText(num value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
