import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_platform/l10n/app_localizations.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/errors/failure_messages.dart';
import 'package:school_platform/src/core/l10n/enum_labels.dart';
import 'package:school_platform/src/core/utils/dates.dart';
import 'package:school_platform/src/core/utils/formatting.dart';
import 'package:school_platform/src/core/widgets/school_widgets.dart';
import 'package:school_platform/src/core/widgets/state_views.dart';
import 'package:school_platform/src/features/school/application/school_providers.dart';
import 'package:school_platform/src/features/school/domain/school_models.dart';
import 'package:school_platform/src/features/school/presentation/school_shell.dart';
import 'package:school_platform/src/features/school/presentation/students_screen.dart';

typedef _SchoolClass = ({String? gradeLevel, String? section});

/// Daily attendance for one date and (optionally) one class.
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _date = dateOnly(DateTime.now());
  _SchoolClass? _class;
  bool _saving = false;

  AttendanceSheetKey _key(String schoolId) => (
    schoolId: schoolId,
    date: _date,
    gradeLevel: _class?.gradeLevel,
    section: _class?.section,
  );

  /// Asks before throwing away unsaved marks when changing date or class.
  Future<bool> _confirmDiscard(String schoolId) async {
    final sheet = ref.read(attendanceSheetProvider(_key(schoolId))).value;
    if (sheet == null || sheet.changes.isEmpty) return true;
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.discardChangesTitle),
        content: Text(l10n.discardChangesBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _pickDate(String schoolId) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: dateOnly(DateTime.now()).add(const Duration(days: 365)),
    );
    if (picked == null || !mounted || !await _confirmDiscard(schoolId)) return;
    setState(() => _date = dateOnly(picked));
  }

  Future<void> _save(String schoolId) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(attendanceSheetProvider(_key(schoolId)).notifier).save();
      ref.invalidate(dashboardProvider(schoolId));
      if (mounted) showSnack(context, l10n.attendanceSaved);
    } on Object catch (e) {
      if (mounted) showSnack(context, failureMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final membership = ref.watch(activeMembershipProvider);
    if (membership == null) return const Scaffold(body: LoadingView());
    if (!membership.hasModule(SchoolModule.attendance)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.attendance)),
        body: EmptyView(message: l10n.moduleDisabled),
      );
    }
    final schoolId = membership.schoolId;
    final key = _key(schoolId);
    final sheet = ref.watch(attendanceSheetProvider(key));
    final classes =
        ref.watch(schoolClassesProvider(schoolId)).value ?? const [];
    final changes = sheet.value?.changes.length ?? 0;

    // Unsaved marks survive tab switches (the shell keeps branches alive);
    // changing the date or class asks before discarding them.
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.attendance),
        actions: const [SchoolAppBarActions()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(schoolId),
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(context.formatWeekdayDate(_date)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<_SchoolClass?>(
                    initialValue: _class,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.filterClass,
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(child: Text(l10n.allClasses)),
                      for (final c in classes)
                        DropdownMenuItem(
                          value: c,
                          child: Text(
                            l10n.classLabel(
                              [
                                c.gradeLevel,
                                c.section,
                              ].whereType<String>().join(),
                            ),
                          ),
                        ),
                    ],
                    onChanged: (value) async {
                      if (!await _confirmDiscard(schoolId)) return;
                      setState(() => _class = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: AsyncValueView(
              value: sheet,
              onRetry: () => ref.invalidate(attendanceSheetProvider(key)),
              data: (data) {
                if (data.students.isEmpty) {
                  return EmptyView(message: l10n.noStudents);
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: data.students.length,
                  itemBuilder: (context, index) {
                    final student = data.students[index];
                    return _AttendanceRow(
                      student: student,
                      status: data.statusOf(student.id),
                      changed: data.changes.containsKey(student.id),
                      onChanged: (status) => ref
                          .read(attendanceSheetProvider(key).notifier)
                          .mark(student.id, status),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          sheet.hasValue && sheet.requireValue.students.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => ref
                                  .read(attendanceSheetProvider(key).notifier)
                                  .markUnmarkedPresent(),
                        child: Text(l10n.markAllPresent),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving || changes == 0
                            ? null
                            : () => _save(schoolId),
                        child: _saving
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.saveAttendance(changes)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.student,
    required this.status,
    required this.changed,
    required this.onChanged,
  });

  final StudentSummary student;
  final AttendanceStatus? status;
  final bool changed;
  final ValueChanged<AttendanceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentTile(
          student: student,
          onTap: () {},
          trailing: changed
              ? Icon(
                  Icons.edit_note,
                  color: scheme.primary,
                  semanticLabel: l10n.unsavedChanges(1),
                )
              : null,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SegmentedButton<AttendanceStatus>(
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            segments: [
              for (final s in AttendanceStatus.values)
                ButtonSegment(
                  value: s,
                  icon: Icon(attendanceIcon(s)),
                  tooltip: s.label(l10n),
                  label: Text(s.label(l10n), overflow: TextOverflow.ellipsis),
                ),
            ],
            selected: {?status},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) onChanged(selection.first);
            },
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
