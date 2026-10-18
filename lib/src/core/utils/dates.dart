import 'package:flutter/foundation.dart';

/// Serializes a calendar date for Postgres `date` columns (YYYY-MM-DD).
String toDateParam(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Calendar date without a time component.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// An inclusive calendar month range.
@immutable
class MonthRange {
  MonthRange(DateTime anyDayInMonth)
    : first = DateTime(anyDayInMonth.year, anyDayInMonth.month),
      last = DateTime(anyDayInMonth.year, anyDayInMonth.month + 1, 0);

  final DateTime first;
  final DateTime last;

  MonthRange previous() => MonthRange(DateTime(first.year, first.month - 1));

  MonthRange next() => MonthRange(DateTime(first.year, first.month + 1));

  bool contains(DateTime date) =>
      !dateOnly(date).isBefore(first) && !dateOnly(date).isAfter(last);

  @override
  bool operator ==(Object other) => other is MonthRange && other.first == first;

  @override
  int get hashCode => first.hashCode;
}
