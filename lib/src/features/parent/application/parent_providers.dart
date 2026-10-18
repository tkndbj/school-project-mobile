import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_platform/src/core/utils/dates.dart';
import 'package:school_platform/src/features/auth/data/auth_repository.dart';
import 'package:school_platform/src/features/parent/data/parent_repository.dart';
import 'package:school_platform/src/features/parent/domain/parent_models.dart';

/// The signed-in parent's children. Re-fetched when the user changes.
final childrenProvider = FutureProvider<List<Child>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(parentRepositoryProvider).fetchChildren();
});

/// One child from [childrenProvider], or `null` if not (or no longer) linked.
final childProvider = Provider.family<AsyncValue<Child?>, String>((
  ref,
  studentId,
) {
  return ref
      .watch(childrenProvider)
      .whenData(
        (children) =>
            children.where((c) => c.studentId == studentId).firstOrNull,
      );
});

final studentProfileProvider = FutureProvider.autoDispose
    .family<StudentProfile, String>(
      (ref, studentId) =>
          ref.watch(parentRepositoryProvider).fetchProfile(studentId),
    );

final studentCoursesProvider = FutureProvider.autoDispose
    .family<List<EnrolledCourse>, String>(
      (ref, studentId) =>
          ref.watch(parentRepositoryProvider).fetchCourses(studentId),
    );

final studentGradesProvider = FutureProvider.autoDispose
    .family<List<CourseGrades>, String>(
      (ref, studentId) async => CourseGrades.group(
        await ref.watch(parentRepositoryProvider).fetchGrades(studentId),
      ),
    );

typedef StudentMonth = ({String studentId, MonthRange month});

final studentAttendanceProvider = FutureProvider.autoDispose
    .family<List<AttendanceEntry>, StudentMonth>(
      (ref, arg) => ref
          .watch(parentRepositoryProvider)
          .fetchAttendance(arg.studentId, arg.month),
    );

final studentAttendanceSummaryProvider = FutureProvider.autoDispose
    .family<AttendanceSummary, StudentMonth>(
      (ref, arg) => ref
          .watch(parentRepositoryProvider)
          .fetchAttendanceSummary(arg.studentId, arg.month),
    );

/// Upcoming events: from the start of today for the next 120 days.
final studentEventsProvider = FutureProvider.autoDispose
    .family<List<GuardianEvent>, String>(
      (ref, studentId) {
        final from = dateOnly(DateTime.now());
        return ref
            .watch(parentRepositoryProvider)
            .fetchEvents(
              studentId,
              from: from,
              to: from.add(const Duration(days: 120)),
            );
      },
    );

@immutable
class NotesPage {
  const NotesPage({
    required this.notes,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<GuardianNote> notes;
  final bool hasMore;
  final bool isLoadingMore;
  final Object? loadMoreError;

  NotesPage copyWith({
    List<GuardianNote>? notes,
    bool? hasMore,
    bool? isLoadingMore,
    Object? loadMoreError,
  }) => NotesPage(
    notes: notes ?? this.notes,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreError: loadMoreError,
  );
}

final studentNotesProvider = AsyncNotifierProvider.autoDispose
    .family<StudentNotesController, NotesPage, String>(
      StudentNotesController.new,
    );

/// Notes with keyset pagination (`p_before` = oldest loaded `created_at`).
class StudentNotesController extends AsyncNotifier<NotesPage> {
  StudentNotesController(this.studentId);

  final String studentId;

  @override
  Future<NotesPage> build() async {
    final notes = await ref
        .watch(parentRepositoryProvider)
        .fetchNotes(studentId);
    return NotesPage(
      notes: notes,
      hasMore: notes.length == ParentRepository.notesPageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final older = await ref
          .read(parentRepositoryProvider)
          .fetchNotes(
            studentId,
            before: current.notes.last.createdAt,
            beforeId: current.notes.last.noteId,
          );
      if (!ref.mounted) return;
      state = AsyncData(
        current.copyWith(
          notes: [...current.notes, ...older],
          hasMore: older.length == ParentRepository.notesPageSize,
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      state = AsyncData(current.copyWith(loadMoreError: e));
    }
  }
}
