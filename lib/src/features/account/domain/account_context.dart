import 'package:flutter/foundation.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/utils/json.dart';

/// The two halves of the mobile app.
enum AppSide { school, parent }

/// A school the user works at, from `my_account_context().memberships`.
@immutable
class SchoolMembership {
  const SchoolMembership({
    required this.schoolId,
    required this.schoolName,
    required this.slug,
    required this.role,
    required this.enabledModules,
    required this.timezone,
    this.logoPath,
    this.primaryColor,
    this.defaultLocale,
  });

  factory SchoolMembership.fromJson(Json json) => SchoolMembership(
    schoolId: json.requireString('school_id'),
    schoolName: json.requireString('school_name'),
    slug: json.requireString('slug'),
    role: SchoolRole.fromWire(json.optString('role')),
    enabledModules: SchoolModule.parseList(
      json.optStringList('enabled_modules'),
    ),
    timezone: json.optString('timezone') ?? 'UTC',
    logoPath: json.optString('logo_path'),
    primaryColor: json.optString('primary_color'),
    defaultLocale: json.optString('default_locale'),
  );

  final String schoolId;
  final String schoolName;
  final String slug;
  final SchoolRole role;
  final Set<SchoolModule> enabledModules;
  final String timezone;
  final String? logoPath;
  final String? primaryColor;
  final String? defaultLocale;

  bool hasModule(SchoolModule module) => enabledModules.contains(module);
}

/// An active school with a guardian record linked to the signed-in account.
@immutable
class GuardianSchool {
  const GuardianSchool({required this.schoolId, required this.schoolName});

  factory GuardianSchool.fromJson(Json json) => GuardianSchool(
    schoolId: json.requireString('school_id'),
    schoolName: json.requireString('school_name'),
  );

  final String schoolId;
  final String schoolName;
}

/// Result of `my_account_context()`: everything needed to route a user.
@immutable
class AccountContext {
  const AccountContext({
    required this.userId,
    required this.isPlatformAdmin,
    required this.memberships,
    required this.childrenCount,
    this.guardianSchools = const [],
  });

  factory AccountContext.fromJson(Json json) => AccountContext(
    userId: json.requireString('user_id'),
    isPlatformAdmin: json.optBool('is_platform_admin') ?? false,
    memberships: [
      for (final m in json.optObjectList('memberships'))
        SchoolMembership.fromJson(m),
    ],
    childrenCount: json.optInt('children_count') ?? 0,
    guardianSchools: [
      for (final school in json.optObjectList('guardian_schools'))
        GuardianSchool.fromJson(school),
    ],
  );

  final String userId;
  final bool isPlatformAdmin;
  final List<SchoolMembership> memberships;
  final int childrenCount;
  final List<GuardianSchool> guardianSchools;

  /// Sides of the mobile app this account can use.
  Set<AppSide> get availableSides => {
    if (memberships.isNotEmpty) AppSide.school,
    if (childrenCount > 0 || guardianSchools.isNotEmpty) AppSide.parent,
  };

  SchoolMembership? membershipFor(String? schoolId) {
    for (final m in memberships) {
      if (m.schoolId == schoolId) return m;
    }
    return null;
  }
}

/// Outcome of `redeem_guardian_invite`.
enum InviteRedemptionStatus {
  linked,
  invalid,
  alreadyLinked,
  rateLimited
  ;

  static InviteRedemptionStatus fromWire(String? wire) => switch (wire) {
    'linked' => linked,
    'already_linked' => alreadyLinked,
    'rate_limited' => rateLimited,
    _ => invalid,
  };
}

@immutable
class InviteRedemption {
  const InviteRedemption({required this.status, this.schoolName});

  factory InviteRedemption.fromJson(Json json) => InviteRedemption(
    status: InviteRedemptionStatus.fromWire(json.optString('status')),
    schoolName: json.optString('school_name'),
  );

  final InviteRedemptionStatus status;
  final String? schoolName;
}

/// Normalizes user input to the canonical `XXXXX-XXXXX` invite code format
/// (Crockford base32: case-insensitive, O→0, I/L→1), or returns `null` when
/// the input can't be a valid code. The server applies the same rules.
String? normalizeInviteCode(String input) {
  final cleaned = input
      .toUpperCase()
      .replaceAll(RegExp('[^A-Z0-9]'), '')
      .replaceAll('O', '0')
      .replaceAll(RegExp('[IL]'), '1');
  if (!RegExp(r'^[0-9A-HJKMNP-TV-Z]{10}$').hasMatch(cleaned)) return null;
  return '${cleaned.substring(0, 5)}-${cleaned.substring(5)}';
}
