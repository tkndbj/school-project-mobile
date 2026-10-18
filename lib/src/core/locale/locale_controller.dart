import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_platform/l10n/app_localizations.dart';
import 'package:school_platform/src/core/providers.dart';

/// Preference keys stored in shared preferences. Kept in one place so the
/// allow-list passed to `SharedPreferencesWithCache` stays complete.
abstract final class PreferenceKeys {
  static const locale = 'locale';
  static const activeSide = 'active_side';
  static const selectedSchoolId = 'selected_school_id';

  static const all = {locale, activeSide, selectedSchoolId};
}

/// The user's explicit language choice; `null` follows the device locale.
final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = ref
        .watch(sharedPreferencesProvider)
        .getString(PreferenceKeys.locale);
    return supportedLocaleFor(code);
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(PreferenceKeys.locale);
    } else {
      await prefs.setString(PreferenceKeys.locale, locale.languageCode);
    }
    state = locale;
  }

  /// Returns the supported locale for a language code, or `null`.
  static Locale? supportedLocaleFor(String? languageCode) {
    if (languageCode == null) return null;
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == languageCode) return locale;
    }
    return null;
  }
}
