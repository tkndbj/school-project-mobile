import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_platform/l10n/app_localizations.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/errors/failure_messages.dart';
import 'package:school_platform/src/core/l10n/enum_labels.dart';
import 'package:school_platform/src/core/routing/route_gate.dart';
import 'package:school_platform/src/core/utils/formatting.dart';
import 'package:school_platform/src/core/utils/names.dart';
import 'package:school_platform/src/core/widgets/state_views.dart';
import 'package:school_platform/src/features/school/application/school_providers.dart';
import 'package:school_platform/src/features/school/data/school_repository.dart';
import 'package:school_platform/src/features/school/domain/school_models.dart';

/// Create (studentId == null) or edit a student.
class StudentFormScreen extends ConsumerWidget {
  const StudentFormScreen({super.key, this.studentId});

  final String? studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final membership = ref.watch(activeMembershipProvider);
    if (membership == null) return const Scaffold(body: LoadingView());
    final id = studentId;
    if (id == null) {
      return _StudentForm(
        schoolId: membership.schoolId,
        initial: const StudentDraft(),
      );
    }
    final key = (schoolId: membership.schoolId, studentId: id);
    return ref
        .watch(studentRecordProvider(key))
        .when(
          loading: () => const Scaffold(body: LoadingView()),
          error: (e, _) => Scaffold(
            appBar: AppBar(title: Text(l10n.editStudent)),
            body: ErrorView(
              error: e,
              onRetry: () => ref.invalidate(studentRecordProvider(key)),
            ),
          ),
          data: (record) => _StudentForm(
            schoolId: membership.schoolId,
            studentId: id,
            initial: record.draft,
          ),
        );
  }
}

class _StudentForm extends ConsumerStatefulWidget {
  const _StudentForm({
    required this.schoolId,
    required this.initial,
    this.studentId,
  });

  final String schoolId;
  final String? studentId;
  final StudentDraft initial;

  @override
  ConsumerState<_StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends ConsumerState<_StudentForm> {
  final _formKey = GlobalKey<FormState>();
  late final _number = TextEditingController(
    text: widget.initial.studentNumber,
  );
  late final _first = TextEditingController(text: widget.initial.firstName);
  late final _last = TextEditingController(text: widget.initial.lastName);
  late final _preferred = TextEditingController(
    text: widget.initial.preferredName,
  );
  late final _grade = TextEditingController(text: widget.initial.gradeLevel);
  late final _section = TextEditingController(text: widget.initial.section);
  late final _email = TextEditingController(text: widget.initial.email);
  late final _phone = TextEditingController(text: widget.initial.phone);
  late final _address = TextEditingController(text: widget.initial.address);
  late final _notes = TextEditingController(text: widget.initial.notes);
  late DateTime? _dateOfBirth = widget.initial.dateOfBirth;
  late DateTime? _enrolledOn = widget.initial.enrolledOn;
  late Gender? _gender = widget.initial.gender;
  late StudentStatus _status = widget.initial.status;
  bool _saving = false;
  String? _formError;

  List<TextEditingController> get _controllers => [
    _number,
    _first,
    _last,
    _preferred,
    _grade,
    _section,
    _email,
    _phone,
    _address,
    _notes,
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  StudentDraft get _draft => StudentDraft(
    studentNumber: _number.text,
    firstName: _first.text,
    lastName: _last.text,
    preferredName: _preferred.text,
    dateOfBirth: _dateOfBirth,
    gender: _gender,
    gradeLevel: _grade.text,
    section: _section.text,
    email: _email.text,
    phone: _phone.text,
    address: _address.text,
    enrolledOn: _enrolledOn,
    status: _status,
    notes: _notes.text,
  );

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final draft = _draft;
    setState(
      () => _formError = draft.isIdentifiable ? null : l10n.identifiableHint,
    );
    if (!(_formKey.currentState?.validate() ?? false) ||
        !draft.isIdentifiable) {
      return;
    }

    setState(() => _saving = true);
    final repository = ref.read(schoolRepositoryProvider);
    try {
      final existingId = widget.studentId;
      final String id;
      if (existingId == null) {
        id = await repository.createStudent(widget.schoolId, draft);
      } else {
        await repository.updateStudent(widget.schoolId, existingId, draft);
        id = existingId;
        ref.invalidate(
          studentRecordProvider((schoolId: widget.schoolId, studentId: id)),
        );
      }
      ref.invalidate(studentListProvider(widget.schoolId));
      if (!mounted) return;
      showSnack(context, l10n.studentSaved);
      if (existingId == null) {
        context.pushReplacement(Routes.schoolStudent(id));
      } else {
        context.pop();
      }
    } on Object catch (e) {
      if (mounted) setState(() => _formError = failureMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isNew = widget.studentId == null;

    Widget text(
      TextEditingController controller,
      String label, {
      int maxLength = 100,
      TextInputType? keyboard,
      String? Function(String?)? validator,
      int maxLines = 1,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, counterText: ''),
        maxLength: maxLength,
        validator: validator,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? l10n.newStudent : l10n.editStudent),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.identifiableHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            text(_first, l10n.firstName),
            text(_last, l10n.lastName),
            text(_preferred, l10n.preferredName),
            text(_number, l10n.studentNumber, maxLength: 64),
            Row(
              children: [
                Expanded(child: text(_grade, l10n.gradeLevel, maxLength: 50)),
                const SizedBox(width: 12),
                Expanded(child: text(_section, l10n.section, maxLength: 50)),
              ],
            ),
            _DateField(
              label: l10n.dateOfBirth,
              value: _dateOfBirth,
              enabled: !_saving,
              onChanged: (v) => setState(() => _dateOfBirth = v),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<Gender?>(
                initialValue: _gender,
                decoration: InputDecoration(labelText: l10n.genderLabel),
                items: [
                  DropdownMenuItem(child: Text(l10n.notSet)),
                  for (final g in Gender.values)
                    DropdownMenuItem(value: g, child: Text(g.label(l10n))),
                ],
                onChanged: _saving ? null : (v) => setState(() => _gender = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<StudentStatus>(
                initialValue: _status,
                decoration: InputDecoration(labelText: l10n.statusLabel),
                items: [
                  for (final s in StudentStatus.values)
                    DropdownMenuItem(value: s, child: Text(s.label(l10n))),
                ],
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _status = v ?? _status),
              ),
            ),
            _DateField(
              label: l10n.enrolledOn,
              value: _enrolledOn,
              enabled: !_saving,
              onChanged: (v) => setState(() => _enrolledOn = v),
            ),
            text(
              _email,
              l10n.emailLabel,
              maxLength: 320,
              keyboard: TextInputType.emailAddress,
              validator: (v) => (blankToNull(v) == null || isValidEmail(v!))
                  ? null
                  : l10n.validationEmail,
            ),
            text(
              _phone,
              l10n.phone,
              maxLength: 50,
              keyboard: TextInputType.phone,
            ),
            text(_address, l10n.address, maxLength: 500, maxLines: 2),
            text(_notes, l10n.internalNotes, maxLength: 10000, maxLines: 4),
            if (_formError != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  _formError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.customFieldsOnWeb,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today_outlined)
              : IconButton(
                  tooltip: l10n.clearValue,
                  icon: const Icon(Icons.clear),
                  onPressed: enabled ? () => onChanged(null) : null,
                ),
        ),
        child: InkWell(
          onTap: !enabled
              ? null
              : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: value ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2200),
                  );
                  if (picked != null) onChanged(picked);
                },
          child: Text(value == null ? l10n.notSet : context.formatDate(value!)),
        ),
      ),
    );
  }
}
