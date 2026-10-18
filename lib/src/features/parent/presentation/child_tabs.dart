import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_platform/l10n/app_localizations.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/l10n/enum_labels.dart';
import 'package:school_platform/src/core/media/media_repository.dart';
import 'package:school_platform/src/core/theme/app_theme.dart';
import 'package:school_platform/src/core/utils/dates.dart';
import 'package:school_platform/src/core/utils/formatting.dart';
import 'package:school_platform/src/core/widgets/school_widgets.dart';
import 'package:school_platform/src/core/widgets/state_views.dart';
import 'package:school_platform/src/features/parent/application/parent_providers.dart';
import 'package:school_platform/src/features/parent/domain/parent_models.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------------------------------------------------------------- overview

class OverviewTab extends ConsumerWidget {
  const OverviewTab({required this.child, super.key});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(studentProfileProvider(child.studentId));
    final month = MonthRange(DateTime.now());
    final showAttendance = child.hasModule(SchoolModule.attendance);

    Future<void> refresh() async {
      ref
        ..invalidate(
          studentAttendanceSummaryProvider((
            studentId: child.studentId,
            month: month,
          )),
        )
        ..invalidate(studentProfileProvider(child.studentId));
      await ref.read(studentProfileProvider(child.studentId).future);
    }

    return RefreshableList(
      onRefresh: refresh,
      child: AsyncValueView(
        value: profile,
        onRetry: () => ref.invalidate(studentProfileProvider(child.studentId)),
        data: (p) {
          final name = p.displayName ?? l10n.unnamedStudent;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  StorageAvatar(
                    path: p.photoPath,
                    fallbackText: name,
                    radius: 36,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(child.schoolName),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (showAttendance)
                _AttendanceSummaryCard(
                  studentId: child.studentId,
                  month: month,
                ),
              _SectionCard(
                title: l10n.profileSection,
                rows: [
                  if (p.studentNumber != null)
                    (l10n.studentNumber, p.studentNumber!),
                  if (p.gradeLevel != null) (l10n.gradeLevel, p.gradeLevel!),
                  if (p.section != null) (l10n.section, p.section!),
                  if (p.dateOfBirth != null)
                    (l10n.dateOfBirth, context.formatDate(p.dateOfBirth!)),
                  if (p.gender != null)
                    (l10n.genderLabel, p.gender!.label(l10n)),
                  if (p.enrolledOn != null)
                    (l10n.enrolledOn, context.formatDate(p.enrolledOn!)),
                  (l10n.statusLabel, p.status.label(l10n)),
                ],
              ),
              if (p.customFields.isNotEmpty)
                _SectionCard(
                  title: l10n.additionalInfo,
                  rows: [
                    for (final field in p.customFields)
                      (field.label, formatCustomValue(context, field)),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Formats a guardian-visible custom field value for display.
String formatCustomValue(BuildContext context, VisibleCustomField field) {
  final l10n = AppLocalizations.of(context);
  final value = field.value;
  return switch (value) {
    null => l10n.notSet,
    final bool b => b ? l10n.yes : l10n.no,
    final num n => context.formatNumber(n.toDouble(), decimals: 2),
    final String s when field.type == 'date' =>
      DateTime.tryParse(s) == null ? s : context.formatDate(DateTime.parse(s)),
    final List<Object?> list => list.join(', '),
    _ => value.toString(),
  };
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: MergeSemantics(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(value, style: theme.textTheme.bodyLarge),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceSummaryCard extends ConsumerWidget {
  const _AttendanceSummaryCard({required this.studentId, required this.month});

  final String studentId;
  final MonthRange month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(
      studentAttendanceSummaryProvider((studentId: studentId, month: month)),
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.attendanceThisMonth,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            switch (summary) {
              AsyncData(:final value) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in AttendanceStatus.values)
                    AttendanceChip(status: status, count: value.count(status)),
                ],
              ),
              AsyncError(:final error) => ErrorView(error: error),
              _ => const LinearProgressIndicator(),
            },
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ grades

class GradesTab extends ConsumerWidget {
  const GradesTab({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final grades = ref.watch(studentGradesProvider(studentId));
    return RefreshableList(
      onRefresh: () => ref.refresh(studentGradesProvider(studentId).future),
      child: AsyncValueView(
        value: grades,
        onRetry: () => ref.invalidate(studentGradesProvider(studentId)),
        data: (courses) {
          if (courses.isEmpty) {
            return ScrollableCenter(
              child: EmptyView(
                icon: Icons.grading_outlined,
                message: l10n.noGrades,
              ),
            );
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              for (final course in courses) _CourseGradesCard(course: course),
            ],
          );
        },
      ),
    );
  }
}

class _CourseGradesCard extends StatelessWidget {
  const _CourseGradesCard({required this.course});

  final CourseGrades course;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final average = course.averagePercent;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              course.courseName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: average == null
                ? null
                : Text(l10n.averagePercent(context.formatNumber(average))),
          ),
          const Divider(height: 1),
          for (final grade in course.grades)
            ListTile(
              title: Text(grade.assessmentTitle),
              subtitle: Text(
                [
                  grade.kind.label(l10n),
                  if (grade.assessedOn != null)
                    context.formatDate(grade.assessedOn!),
                  if (grade.comment != null) grade.comment!,
                ].join(' · '),
              ),
              trailing: Text(
                _gradeValue(context, grade),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
        ],
      ),
    );
  }

  String _gradeValue(BuildContext context, GradeEntry grade) {
    final l10n = AppLocalizations.of(context);
    final parts = [
      if (grade.score != null)
        l10n.scoreOutOf(
          context.formatNumber(grade.score!, decimals: 2),
          context.formatNumber(grade.maxScore, decimals: 2),
        ),
      ?grade.letter,
    ];
    return parts.isEmpty ? '–' : parts.join(' · ');
  }
}

// -------------------------------------------------------------- attendance

class AttendanceTab extends ConsumerStatefulWidget {
  const AttendanceTab({required this.studentId, super.key});

  final String studentId;

  @override
  ConsumerState<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends ConsumerState<AttendanceTab> {
  MonthRange _month = MonthRange(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arg = (studentId: widget.studentId, month: _month);
    final records = ref.watch(studentAttendanceProvider(arg));
    final isCurrentMonth = _month == MonthRange(DateTime.now());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.previousMonth,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _month = _month.previous()),
              ),
              Expanded(
                child: Text(
                  context.formatMonth(_month.first),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: l10n.nextMonth,
                icon: const Icon(Icons.chevron_right),
                onPressed: isCurrentMonth
                    ? null
                    : () => setState(() => _month = _month.next()),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: RefreshableList(
            onRefresh: () => ref.refresh(studentAttendanceProvider(arg).future),
            child: AsyncValueView(
              value: records,
              onRetry: () => ref.invalidate(studentAttendanceProvider(arg)),
              data: (items) {
                if (items.isEmpty) {
                  return ScrollableCenter(
                    child: EmptyView(
                      icon: Icons.event_available_outlined,
                      message: l10n.noAttendance,
                    ),
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final record = items[index];
                    final details = [
                      record.courseName ?? l10n.dailyAttendance,
                      ?record.period,
                      if (record.minutesLate != null)
                        l10n.minutesLate(record.minutesLate!),
                      ?record.note,
                    ];
                    return ListTile(
                      title: Text(context.formatWeekdayDate(record.attendedOn)),
                      subtitle: Text(details.join(' · ')),
                      trailing: AttendanceChip(status: record.status),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------- notes

class NotesTab extends ConsumerWidget {
  const NotesTab({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = studentNotesProvider(studentId);
    final notes = ref.watch(provider);

    return RefreshableList(
      onRefresh: () => ref.refresh(provider.future),
      child: AsyncValueView(
        value: notes,
        onRetry: () => ref.invalidate(provider),
        data: (page) {
          if (page.notes.isEmpty) {
            return ScrollableCenter(
              child: EmptyView(
                icon: Icons.sticky_note_2_outlined,
                message: l10n.noNotes,
              ),
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: page.notes.length + (page.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == page.notes.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: page.isLoadingMore
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            if (page.loadMoreError != null)
                              ErrorView(error: page.loadMoreError!),
                            OutlinedButton(
                              onPressed: () =>
                                  ref.read(provider.notifier).loadMore(),
                              child: Text(l10n.loadMore),
                            ),
                          ],
                        ),
                );
              }
              return NoteCard(note: page.notes[index]);
            },
          );
        },
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  const NoteCard({required this.note, super.key});

  final GuardianNote note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final meta = [
      context.formatDate(note.createdAt),
      if (note.teacherName != null) l10n.byTeacher(note.teacherName!),
      ?note.category,
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.title != null)
              Text(note.title!, style: theme.textTheme.titleMedium),
            Text(meta, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(note.body, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ events

class EventsTab extends ConsumerWidget {
  const EventsTab({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final events = ref.watch(studentEventsProvider(studentId));
    return RefreshableList(
      onRefresh: () => ref.refresh(studentEventsProvider(studentId).future),
      child: AsyncValueView(
        value: events,
        onRetry: () => ref.invalidate(studentEventsProvider(studentId)),
        data: (items) {
          if (items.isEmpty) {
            return ScrollableCenter(
              child: EmptyView(
                icon: Icons.event_outlined,
                message: l10n.noEvents,
              ),
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => EventTile(
              title: items[index].title,
              startsAt: items[index].startsAt,
              endsAt: items[index].endsAt,
              allDay: items[index].allDay,
              color: items[index].color,
              details: [
                ?items[index].courseName,
                ?items[index].location,
                ?items[index].description,
              ],
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------------------- courses

class CoursesTab extends ConsumerWidget {
  const CoursesTab({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final courses = ref.watch(studentCoursesProvider(studentId));
    return RefreshableList(
      onRefresh: () => ref.refresh(studentCoursesProvider(studentId).future),
      child: AsyncValueView(
        value: courses,
        onRetry: () => ref.invalidate(studentCoursesProvider(studentId)),
        data: (items) {
          if (items.isEmpty) {
            return ScrollableCenter(
              child: EmptyView(
                icon: Icons.menu_book_outlined,
                message: l10n.noCourses,
              ),
            );
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [for (final course in items) _CourseCard(course: course)],
          );
        },
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final EnrolledCourse course;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  parseHexColor(course.color) ?? scheme.secondaryContainer,
              child: const Icon(Icons.menu_book_outlined),
            ),
            title: Text(
              course.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              [?course.code, ?course.subject, ?course.termName].join(' · '),
            ),
          ),
          for (final teacher in course.teachers)
            ListTile(
              leading: StorageAvatar(
                path: teacher.photoPath,
                fallbackText: teacher.displayName ?? '?',
                radius: 18,
              ),
              title: Text(teacher.displayName ?? '–'),
              subtitle: Text([?teacher.subject, ?teacher.email].join(' · ')),
              trailing: teacher.email == null
                  ? null
                  : IconButton(
                      tooltip: l10n.emailTeacher(
                        teacher.displayName ?? teacher.email!,
                      ),
                      icon: const Icon(Icons.mail_outline),
                      onPressed: () =>
                          launchUrl(Uri(scheme: 'mailto', path: teacher.email)),
                    ),
            ),
        ],
      ),
    );
  }
}
