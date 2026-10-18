import 'package:flutter/material.dart';
import 'package:school_platform/l10n/app_localizations.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/l10n/enum_labels.dart';
import 'package:school_platform/src/core/theme/app_theme.dart';
import 'package:school_platform/src/core/utils/formatting.dart';

// Domain widgets shared by the parent and school sides.

/// Color-coded attendance status chip. Color is never the only signal: the
/// label is always shown.
class AttendanceChip extends StatelessWidget {
  const AttendanceChip({required this.status, super.key, this.count});

  final AttendanceStatus status;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (bg, fg) = attendanceColors(Theme.of(context).colorScheme, status);
    final text = count == null
        ? status.label(l10n)
        : '${status.label(l10n)}: $count';
    return Chip(
      avatar: Icon(attendanceIcon(status), size: 18, color: fg),
      label: Text(text, style: TextStyle(color: fg)),
      backgroundColor: bg,
      side: BorderSide.none,
    );
  }
}

IconData attendanceIcon(AttendanceStatus status) => switch (status) {
  AttendanceStatus.present => Icons.check_circle_outline,
  AttendanceStatus.absent => Icons.cancel_outlined,
  AttendanceStatus.late => Icons.schedule,
  AttendanceStatus.excused => Icons.verified_outlined,
};

(Color, Color) attendanceColors(ColorScheme scheme, AttendanceStatus status) =>
    switch (status) {
      AttendanceStatus.present => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      AttendanceStatus.absent => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      AttendanceStatus.late => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      AttendanceStatus.excused => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
    };

/// An event row shared by the parent and school sides.
class EventTile extends StatelessWidget {
  const EventTile({
    required this.title,
    required this.startsAt,
    required this.allDay,
    super.key,
    this.endsAt,
    this.color,
    this.details = const [],
    this.trailing,
  });

  final String title;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool allDay;
  final String? color;
  final List<String> details;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = parseHexColor(color) ?? scheme.primary;
    final when = allDay
        ? '${context.formatWeekdayDate(startsAt)} · ${l10n.allDay}'
        : [
            context.formatWeekdayDate(startsAt),
            context.formatTime(startsAt),
            if (endsAt != null) '– ${context.formatTime(endsAt!)}',
          ].join(' ');
    return ListTile(
      leading: Container(
        width: 6,
        height: 40,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      title: Text(title),
      subtitle: Text([when, ...details].join('\n')),
      isThreeLine: details.isNotEmpty,
      trailing: trailing,
    );
  }
}
