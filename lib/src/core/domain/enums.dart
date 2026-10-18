// Dart mirrors of the Postgres enums (see supabase/migrations in the web repo).
// Each enum carries its wire value; parsing unknown values never throws for
// enums that may grow (modules), so older app versions keep working when the
// database adds a value.

/// Looks up an enum by its wire value.
T? _byWire<T extends Enum>(List<T> values, String? wire, String Function(T) w) {
  if (wire == null) return null;
  for (final value in values) {
    if (w(value) == wire) return value;
  }
  return null;
}

enum SchoolModule {
  teachers('teachers'),
  courses('courses'),
  grades('grades'),
  attendance('attendance'),
  notes('notes'),
  events('events')
  ;

  const SchoolModule(this.wire);

  final String wire;

  static SchoolModule? fromWire(String? wire) =>
      _byWire(values, wire, (v) => v.wire);

  /// Parses a module list, skipping values this app version doesn't know.
  static Set<SchoolModule> parseList(List<String> wires) => {
    for (final w in wires) ?fromWire(w),
  };
}

enum SchoolRole {
  admin('admin'),
  staff('staff')
  ;

  const SchoolRole(this.wire);

  final String wire;

  /// Unknown future roles are treated as the least privileged known role.
  static SchoolRole fromWire(String? wire) =>
      _byWire(values, wire, (v) => v.wire) ?? SchoolRole.staff;
}

enum StudentStatus {
  active('active'),
  inactive('inactive'),
  graduated('graduated'),
  transferred('transferred')
  ;

  const StudentStatus(this.wire);

  final String wire;

  static StudentStatus fromWire(String? wire) =>
      _byWire(values, wire, (v) => v.wire) ?? StudentStatus.active;
}

enum Gender {
  female('female'),
  male('male'),
  other('other'),
  undisclosed('undisclosed')
  ;

  const Gender(this.wire);

  final String wire;

  static Gender? fromWire(String? wire) => _byWire(values, wire, (v) => v.wire);
}

enum AttendanceStatus {
  present('present'),
  absent('absent'),
  late('late'),
  excused('excused')
  ;

  const AttendanceStatus(this.wire);

  final String wire;

  static AttendanceStatus? fromWire(String? wire) =>
      _byWire(values, wire, (v) => v.wire);
}

enum GuardianRelationship {
  mother('mother'),
  father('father'),
  guardian('guardian'),
  grandparent('grandparent'),
  sibling('sibling'),
  other('other')
  ;

  const GuardianRelationship(this.wire);

  final String wire;

  static GuardianRelationship? fromWire(String? wire) =>
      _byWire(values, wire, (v) => v.wire);
}

enum AssessmentKind {
  exam('exam'),
  quiz('quiz'),
  homework('homework'),
  project('project'),
  participation('participation'),
  termGrade('term_grade'),
  other('other')
  ;

  const AssessmentKind(this.wire);

  final String wire;

  static AssessmentKind fromWire(String? wire) =>
      _byWire(values, wire, (v) => v.wire) ?? AssessmentKind.other;
}
