import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_platform/l10n/app_localizations.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/errors/failure_messages.dart';
import 'package:school_platform/src/core/l10n/enum_labels.dart';
import 'package:school_platform/src/core/media/media_repository.dart';
import 'package:school_platform/src/core/routing/route_gate.dart';
import 'package:school_platform/src/core/utils/formatting.dart';
import 'package:school_platform/src/core/widgets/state_views.dart';
import 'package:school_platform/src/features/school/application/school_providers.dart';
import 'package:school_platform/src/features/school/data/school_repository.dart';
import 'package:school_platform/src/features/school/domain/school_models.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final membership = ref.watch(activeMembershipProvider);
    if (membership == null) return const Scaffold(body: LoadingView());
    final key = (schoolId: membership.schoolId, studentId: studentId);
    final record = ref.watch(studentRecordProvider(key));
    final notesEnabled = membership.hasModule(SchoolModule.notes);

    Future<void> refresh() async {
      ref
        ..invalidate(staffStudentNotesProvider(key))
        ..invalidate(studentRecordProvider(key));
      await ref.read(studentRecordProvider(key).future);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(record.value?.displayName ?? l10n.students),
        actions: [
          IconButton(
            tooltip: l10n.editStudent,
            icon: const Icon(Icons.edit_outlined),
            onPressed: record.hasValue
                ? () => context.push(Routes.schoolStudentEdit(studentId))
                : null,
          ),
        ],
      ),
      floatingActionButton: notesEnabled && record.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => showAddNoteSheet(context, key),
              icon: const Icon(Icons.note_add_outlined),
              label: Text(l10n.addNote),
            )
          : null,
      body: RefreshableList(
        onRefresh: refresh,
        child: AsyncValueView(
          value: record,
          onRetry: () => ref.invalidate(studentRecordProvider(key)),
          data: (student) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _Header(student: student),
              const SizedBox(height: 16),
              _DetailsCard(student: student),
              _GuardiansCard(guardians: student.guardians),
              if (notesEnabled) _NotesCard(studentKey: key),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.customFieldsOnWeb,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.student});

  final StudentRecord student;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = student.displayName ?? l10n.unnamedStudent;
    final classCode = [
      student.draft.gradeLevel,
      student.draft.section,
    ].whereType<String>().join();
    return Row(
      children: [
        StorageAvatar(
          path: student.draft.photoPath,
          fallbackText: name,
          radius: 36,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.headlineSmall),
              Text(
                [
                  ?student.draft.studentNumber,
                  if (classCode.isNotEmpty) l10n.classLabel(classCode),
                  student.draft.status.label(l10n),
                ].join(' · '),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.student});

  final StudentRecord student;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final d = student.draft;
    final rows = <(String, String)>[
      if (d.preferredName != null) (l10n.preferredName, d.preferredName!),
      if (d.dateOfBirth != null)
        (l10n.dateOfBirth, context.formatDate(d.dateOfBirth!)),
      if (d.gender != null) (l10n.genderLabel, d.gender!.label(l10n)),
      if (d.email != null) (l10n.emailLabel, d.email!),
      if (d.phone != null) (l10n.phone, d.phone!),
      if (d.address != null) (l10n.address, d.address!),
      if (d.enrolledOn != null)
        (l10n.enrolledOn, context.formatDate(d.enrolledOn!)),
      if (d.notes != null) (l10n.internalNotes, d.notes!),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (final (label, value) in rows)
              ListTile(
                dense: true,
                title: Text(label),
                subtitle: SelectableText(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GuardiansCard extends StatelessWidget {
  const _GuardiansCard({required this.guardians});

  final List<GuardianLink> guardians;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              l10n.guardiansSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (guardians.isEmpty)
            ListTile(title: Text(l10n.noGuardians))
          else
            for (final g in guardians)
              ListTile(
                leading: Icon(
                  g.isAppLinked ? Icons.phone_iphone : Icons.person_outline,
                  color: g.isAppLinked
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                title: Text(
                  [
                    g.displayName ?? '–',
                    if (g.relationship != null)
                      '(${g.relationship!.label(l10n)})',
                  ].join(' '),
                ),
                subtitle: Text(
                  [
                    ?g.email,
                    ?g.phone,
                    if (g.isAppLinked)
                      l10n.guardianLinked
                    else
                      l10n.guardianNotLinked,
                  ].join(' · '),
                ),
                trailing: g.isPrimary ? const Icon(Icons.star_outline) : null,
              ),
        ],
      ),
    );
  }
}

class _NotesCard extends ConsumerWidget {
  const _NotesCard({required this.studentKey});

  final StudentKey studentKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notes = ref.watch(staffStudentNotesProvider(studentKey));
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              l10n.notesSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          switch (notes) {
            AsyncData(:final value) when value.isEmpty => ListTile(
              title: Text(l10n.noNotes),
            ),
            AsyncData(:final value) => Column(
              children: [
                for (final note in value)
                  ListTile(
                    title: Text(
                      note.title ?? note.body,
                      maxLines: note.title == null ? 3 : 1,
                    ),
                    subtitle: Text(
                      [
                        if (note.title != null) note.body,
                        [
                          context.formatDate(note.createdAt),
                          if (note.visibleToGuardians)
                            l10n.noteVisibleToGuardians
                          else
                            l10n.internalNote,
                        ].join(' · '),
                      ].join('\n'),
                    ),
                    leading: Icon(
                      note.visibleToGuardians
                          ? Icons.visibility_outlined
                          : Icons.lock_outline,
                    ),
                  ),
              ],
            ),
            AsyncError(:final error) => ErrorView(
              error: error,
              onRetry: () =>
                  ref.invalidate(staffStudentNotesProvider(studentKey)),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          },
        ],
      ),
    );
  }
}

/// Bottom sheet to write a quick note about a student.
Future<void> showAddNoteSheet(BuildContext context, StudentKey key) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => AddNoteSheet(studentKey: key),
  );
}

class AddNoteSheet extends ConsumerStatefulWidget {
  const AddNoteSheet({required this.studentKey, super.key});

  final StudentKey studentKey;

  @override
  ConsumerState<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<AddNoteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _visibleToGuardians = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(schoolRepositoryProvider)
          .addStudentNote(
            widget.studentKey.schoolId,
            widget.studentKey.studentId,
            title: _title.text,
            body: _body.text,
            visibleToGuardians: _visibleToGuardians,
          );
      ref.invalidate(staffStudentNotesProvider(widget.studentKey));
      if (!mounted) return;
      Navigator.of(context).pop();
      showSnack(context, l10n.noteSaved);
    } on Object catch (e) {
      if (mounted) showSnack(context, failureMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.addNote, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              maxLength: 200,
              decoration: InputDecoration(labelText: l10n.noteTitle),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _body,
              autofocus: true,
              minLines: 3,
              maxLines: 8,
              maxLength: 10000,
              decoration: InputDecoration(labelText: l10n.noteBody),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.validationRequired
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _visibleToGuardians,
              onChanged: (v) => setState(() => _visibleToGuardians = v),
              title: Text(l10n.noteVisibleToGuardians),
              subtitle: Text(l10n.noteVisibleToGuardiansHint),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
