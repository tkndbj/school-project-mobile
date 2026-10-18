import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Locale-aware formatting for the current [BuildContext].
extension Formatting on BuildContext {
  String get _locale => Localizations.localeOf(this).toLanguageTag();

  String formatDate(DateTime date) => DateFormat.yMMMd(_locale).format(date);

  String formatDateTime(DateTime dateTime) =>
      DateFormat.yMMMd(_locale).add_Hm().format(dateTime);

  String formatTime(DateTime dateTime) =>
      DateFormat.Hm(_locale).format(dateTime);

  String formatWeekdayDate(DateTime date) =>
      DateFormat.MMMEd(_locale).format(date);

  String formatMonth(DateTime date) => DateFormat.yMMMM(_locale).format(date);

  /// Up to [decimals] fraction digits, trailing zeros dropped (91.5, 91).
  String formatNumber(double value, {int decimals = 1}) =>
      (NumberFormat.decimalPattern(
        _locale,
      )..maximumFractionDigits = decimals).format(value);
}
