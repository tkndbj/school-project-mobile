import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_platform/l10n/app_localizations.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/l10n/enum_labels.dart';
import 'package:school_platform/src/core/media/media_repository.dart';
import 'package:school_platform/src/core/routing/route_gate.dart';
import 'package:school_platform/src/core/widgets/state_views.dart';
import 'package:school_platform/src/features/school/application/school_providers.dart';
import 'package:school_platform/src/features/school/domain/school_models.dart';
import 'package:school_platform/src/features/school/presentation/school_shell.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  static const _debounce = Duration(milliseconds: 350);

  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String? get _schoolId => ref.read(activeMembershipProvider)?.schoolId;

  void _onScroll() {
    final schoolId = _schoolId;
    if (schoolId == null || !_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 400) {
      unawaited(ref.read(studentListProvider(schoolId).notifier).loadMore());
    }
  }

  void _onQueryChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      final schoolId = _schoolId;
      if (schoolId != null) {
        unawaited(
          ref.read(studentListProvider(schoolId).notifier).search(value),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final membership = ref.watch(activeMembershipProvider);
    if (membership == null) return const Scaffold(body: LoadingView());
    final provider = studentListProvider(membership.schoolId);
    final list = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.students),
        actions: const [SchoolAppBarActions()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchBar(
              controller: _search,
              hintText: l10n.searchStudents,
              leading: const Icon(Icons.search),
              onChanged: _onQueryChanged,
              trailing: [
                if (_search.text.isNotEmpty)
                  IconButton(
                    tooltip: l10n.clearValue,
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _search.clear();
                      _onQueryChanged('');
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.schoolStudentNew),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l10n.addStudent),
      ),
      body: RefreshableList(
        onRefresh: () => ref.refresh(provider.future),
        child: AsyncValueView(
          value: list,
          onRetry: () => ref.invalidate(provider),
          data: (state) {
            if (state.students.isEmpty) {
              return ScrollableCenter(
                child: EmptyView(message: l10n.noStudents),
              );
            }
            return Column(
              children: [
                if (state.isSearching) const LinearProgressIndicator(),
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: state.students.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.students.length) {
                        return state.loadMoreError != null
                            ? ErrorView(
                                error: state.loadMoreError!,
                                onRetry: () =>
                                    ref.read(provider.notifier).loadMore(),
                              )
                            : const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                      }
                      return StudentTile(student: state.students[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class StudentTile extends StatelessWidget {
  const StudentTile({
    required this.student,
    super.key,
    this.trailing,
    this.onTap,
  });

  final StudentSummary student;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = student.displayName ?? l10n.unnamedStudent;
    final classCode = student.classCode;
    return ListTile(
      leading: StorageAvatar(path: student.photoPath, fallbackText: name),
      title: Text(name),
      subtitle: Text(
        [
          ?student.studentNumber,
          if (classCode != null) l10n.classLabel(classCode),
          if (student.status != StudentStatus.active)
            student.status.label(l10n),
        ].join(' · '),
      ),
      trailing: trailing,
      onTap: onTap ?? () => context.push(Routes.schoolStudent(student.id)),
    );
  }
}
