// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'School Platform';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get save => 'Kaydet';

  @override
  String get close => 'Kapat';

  @override
  String get edit => 'Düzenle';

  @override
  String get notSet => 'Belirtilmemiş';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get settings => 'Ayarlar';

  @override
  String get manageOnWeb => 'Bunu web panelinden yönetin';

  @override
  String get manageOnWebDetails =>
      'Not defterleri, içe aktarma, özel alanlar ve okul ayarları web panelinde bulunur.';

  @override
  String get moduleDisabled => 'Bu özellik okulunuz için kapalı.';

  @override
  String get errorPermissionDenied => 'Bu işlem için yetkiniz yok.';

  @override
  String get errorSessionExpired =>
      'Oturumunuzun süresi doldu. Lütfen tekrar giriş yapın.';

  @override
  String get errorNotFound => 'Aradığınız kayıt bulunamadı.';

  @override
  String get errorNetwork =>
      'Bağlantı yok. İnternetinizi kontrol edip tekrar deneyin.';

  @override
  String get errorServer =>
      'Sunucuda bir sorun oluştu. Lütfen biraz sonra tekrar deneyin.';

  @override
  String get errorUnknown => 'Bir şeyler ters gitti. Lütfen tekrar deneyin.';

  @override
  String get errorInvalidInput => 'Bazı değerlerin biçimi geçersiz.';

  @override
  String get errorDuplicate => 'Aynı bilgilere sahip bir kayıt zaten var.';

  @override
  String get errorDuplicateStudentNumber =>
      'Bu öğrenci numarası başka bir öğrencide kayıtlı.';

  @override
  String get errorConstraint => 'Bazı değerlere izin verilmiyor.';

  @override
  String get errorStudentIdentifiable =>
      'En az ad, soyad veya öğrenci numarası girin.';

  @override
  String get errorReference =>
      'İlgili bir kayıt artık mevcut değil. Yenileyip tekrar deneyin.';

  @override
  String errorCustomField(String field) {
    return '\"$field\" alanının değeri geçersiz.';
  }

  @override
  String get errorInvalidSetting => 'Bu ayar değeri geçersiz.';

  @override
  String get errorSchoolRequiresAdmin =>
      'Bir okulun her zaman en az bir yöneticisi olmalıdır.';

  @override
  String get errorInvalidDateRange => 'Seçilen tarih aralığı geçersiz.';

  @override
  String get errorImport => 'İçe aktarılan veriler beklenen biçimde değil.';

  @override
  String get errorAuthInvalidCredentials => 'E-posta veya şifre hatalı.';

  @override
  String get errorAuthEmailNotConfirmed =>
      'Lütfen önce e-posta adresinizi doğrulayın.';

  @override
  String get errorAuthUserBanned => 'Bu hesap devre dışı bırakıldı.';

  @override
  String get errorAuthRateLimited =>
      'Çok fazla deneme yapıldı. Lütfen biraz bekleyip tekrar deneyin.';

  @override
  String get errorGoogleNotAvailable =>
      'Google ile giriş bu cihazda kullanılamıyor.';

  @override
  String get errorAuthUnknown => 'Giriş başarısız oldu. Lütfen tekrar deneyin.';

  @override
  String get errorAccountDeletionBlocked =>
      'Bir okulun tek yöneticisisiniz. Önce web panelinden yönetici rolünü başka birine devredin.';

  @override
  String get signInTitle => 'Hoş geldiniz';

  @override
  String get signInSubtitle =>
      'Veliler: Google ile devam edin. Okul personeli davet e-postasındaki e-posta ve şifreyle de giriş yapabilir.';

  @override
  String get signInWithGoogle => 'Google ile devam et';

  @override
  String get orDivider => 'veya';

  @override
  String get staffSignInHeading => 'Okul personeli girişi';

  @override
  String get emailLabel => 'E-posta';

  @override
  String get passwordLabel => 'Şifre';

  @override
  String get signInButton => 'Giriş yap';

  @override
  String get forgotPassword => 'Şifremi unuttum';

  @override
  String get resetPasswordTitle => 'Şifre sıfırlama';

  @override
  String get resetPasswordBody =>
      'Yeni bir şifre belirlemeniz için size bir bağlantı göndereceğiz.';

  @override
  String get resetPasswordSend => 'Bağlantı gönder';

  @override
  String resetPasswordSent(String email) {
    return '$email için bir hesap varsa sıfırlama bağlantısı gönderildi.';
  }

  @override
  String get validationEmail => 'Geçerli bir e-posta adresi girin';

  @override
  String get validationRequired => 'Zorunlu';

  @override
  String get showPassword => 'Şifreyi göster';

  @override
  String get hidePassword => 'Şifreyi gizle';

  @override
  String get loadingAccount => 'Hesabınız yükleniyor…';

  @override
  String get accountLoadFailed => 'Hesabınız yüklenemedi.';

  @override
  String get platformAdminTitle => 'Web panelini kullanın';

  @override
  String get platformAdminBody =>
      'Platform yönetimi yalnızca web panelinde kullanılabilir.';

  @override
  String get chooseSideTitle => 'Nasıl devam etmek istersiniz?';

  @override
  String get sideSchool => 'Okul';

  @override
  String get sideSchoolDescription =>
      'Öğrencileri, yoklamayı ve notları yönetin';

  @override
  String get sideParent => 'Veli';

  @override
  String get sideParentDescription => 'Çocuklarınızın okul hayatını takip edin';

  @override
  String get switchToSchool => 'Okul görünümüne geç';

  @override
  String get switchToParent => 'Veli görünümüne geç';

  @override
  String get onboardingTitle => 'Çocuğunuzun okuluna bağlanın';

  @override
  String onboardingBody(String email) {
    return 'Çocuğunuzun okulu giriş yaptığınız e-posta adresini ($email) kaydettiğinde hesabınız otomatik olarak bağlanır. Okul size bir davet kodu verdiyse aşağıya girin.';
  }

  @override
  String get inviteCodeLabel => 'Davet kodu';

  @override
  String get inviteCodeHint => 'XXXXX-XXXXX';

  @override
  String get inviteCodeInvalidFormat =>
      'Davet kodları 10 harf veya rakamdan oluşur.';

  @override
  String get redeemButton => 'Bağlan';

  @override
  String inviteLinked(String school) {
    return '$school okuluna bağlandınız.';
  }

  @override
  String get inviteInvalid => 'Bu kod geçersiz veya süresi dolmuş.';

  @override
  String get inviteAlreadyLinked =>
      'Bu davet başka bir hesap tarafından kullanılmış. Okuldan yeni bir kod isteyin.';

  @override
  String get inviteRateLimited =>
      'Çok fazla deneme yapıldı. Lütfen bir saat sonra tekrar deneyin.';

  @override
  String get checkAgain => 'Tekrar kontrol et';

  @override
  String get addChildWithCode => 'Davet koduyla çocuk ekle';

  @override
  String get childrenTitle => 'Çocuklarım';

  @override
  String get noChildren => 'Hesabınıza henüz bağlı bir çocuk yok.';

  @override
  String get tabOverview => 'Genel';

  @override
  String get tabGrades => 'Notlar';

  @override
  String get tabAttendance => 'Devamsızlık';

  @override
  String get tabNotes => 'Görüşler';

  @override
  String get tabEvents => 'Etkinlikler';

  @override
  String get tabCourses => 'Dersler';

  @override
  String get profileSection => 'Profil';

  @override
  String get studentNumber => 'Öğrenci numarası';

  @override
  String get dateOfBirth => 'Doğum tarihi';

  @override
  String get gradeLevel => 'Sınıf';

  @override
  String get section => 'Şube';

  @override
  String classLabel(String grade) {
    return '$grade. sınıf';
  }

  @override
  String get enrolledOn => 'Kayıt tarihi';

  @override
  String get statusLabel => 'Durum';

  @override
  String get attendanceThisMonth => 'Bu ayki devam durumu';

  @override
  String get additionalInfo => 'Ek bilgiler';

  @override
  String get yes => 'Evet';

  @override
  String get no => 'Hayır';

  @override
  String get studentStatusActive => 'Aktif';

  @override
  String get studentStatusInactive => 'Pasif';

  @override
  String get studentStatusGraduated => 'Mezun';

  @override
  String get studentStatusTransferred => 'Nakil';

  @override
  String get genderLabel => 'Cinsiyet';

  @override
  String get genderFemale => 'Kadın';

  @override
  String get genderMale => 'Erkek';

  @override
  String get genderOther => 'Diğer';

  @override
  String get genderUndisclosed => 'Belirtmek istemiyor';

  @override
  String get relationshipMother => 'Anne';

  @override
  String get relationshipFather => 'Baba';

  @override
  String get relationshipGuardian => 'Vasi';

  @override
  String get relationshipGrandparent => 'Büyükanne/Büyükbaba';

  @override
  String get relationshipSibling => 'Kardeş';

  @override
  String get relationshipOther => 'Diğer';

  @override
  String get attendancePresent => 'Geldi';

  @override
  String get attendanceAbsent => 'Gelmedi';

  @override
  String get attendanceLate => 'Geç kaldı';

  @override
  String get attendanceExcused => 'İzinli';

  @override
  String minutesLate(int minutes) {
    return '$minutes dk geç';
  }

  @override
  String get dailyAttendance => 'Günlük';

  @override
  String get noGrades => 'Henüz yayınlanmış not yok.';

  @override
  String averagePercent(String percent) {
    return 'Ortalama %$percent';
  }

  @override
  String scoreOutOf(String score, String max) {
    return '$score / $max';
  }

  @override
  String get assessmentExam => 'Sınav';

  @override
  String get assessmentQuiz => 'Kısa sınav';

  @override
  String get assessmentHomework => 'Ödev';

  @override
  String get assessmentProject => 'Proje';

  @override
  String get assessmentParticipation => 'Derse katılım';

  @override
  String get assessmentTermGrade => 'Dönem notu';

  @override
  String get assessmentOther => 'Diğer';

  @override
  String get noAttendance => 'Bu ay için devam kaydı yok.';

  @override
  String get previousMonth => 'Önceki ay';

  @override
  String get nextMonth => 'Sonraki ay';

  @override
  String get noNotes => 'Henüz görüş yok.';

  @override
  String get loadMore => 'Daha fazla yükle';

  @override
  String byTeacher(String name) {
    return '$name tarafından';
  }

  @override
  String get noEvents => 'Yaklaşan etkinlik yok.';

  @override
  String get allDay => 'Tüm gün';

  @override
  String get noCourses => 'Kayıtlı ders yok.';

  @override
  String get teachersLabel => 'Öğretmenler';

  @override
  String emailTeacher(String name) {
    return '$name adlı öğretmene e-posta gönder';
  }

  @override
  String get schoolDashboard => 'Özet';

  @override
  String get students => 'Öğrenciler';

  @override
  String get attendance => 'Yoklama';

  @override
  String get events => 'Etkinlikler';

  @override
  String get activeStudents => 'Aktif öğrenciler';

  @override
  String get teachers => 'Öğretmenler';

  @override
  String get courses => 'Dersler';

  @override
  String get guardians => 'Veliler';

  @override
  String get linkedGuardians => 'Bağlı veliler';

  @override
  String get upcomingEventsCount => 'Önümüzdeki 30 gündeki etkinlikler';

  @override
  String get attendanceToday => 'Bugünkü yoklama';

  @override
  String get noAttendanceToday => 'Bugün henüz yoklama alınmadı.';

  @override
  String get takeAttendance => 'Yoklama al';

  @override
  String get searchStudents => 'Ad veya numaraya göre ara';

  @override
  String get noStudents => 'Öğrenci bulunamadı.';

  @override
  String get addStudent => 'Öğrenci ekle';

  @override
  String get editStudent => 'Öğrenciyi düzenle';

  @override
  String get newStudent => 'Yeni öğrenci';

  @override
  String get studentSaved => 'Öğrenci kaydedildi.';

  @override
  String get unnamedStudent => 'İsimsiz öğrenci';

  @override
  String get firstName => 'Ad';

  @override
  String get lastName => 'Soyad';

  @override
  String get preferredName => 'Hitap adı';

  @override
  String get phone => 'Telefon';

  @override
  String get address => 'Adres';

  @override
  String get internalNotes => 'Dahili notlar (yalnızca personel)';

  @override
  String get identifiableHint => 'En az ad, soyad veya öğrenci numarası girin.';

  @override
  String get clearValue => 'Temizle';

  @override
  String get customFieldsOnWeb => 'Özel alanlar web panelinden düzenlenebilir.';

  @override
  String get guardiansSection => 'Veliler';

  @override
  String get guardianLinked => 'Uygulamaya bağlı';

  @override
  String get guardianNotLinked => 'Henüz bağlanmadı';

  @override
  String get noGuardians => 'Veli eklenmemiş.';

  @override
  String get notesSection => 'Görüşler';

  @override
  String get addNote => 'Görüş ekle';

  @override
  String get noteTitle => 'Başlık (isteğe bağlı)';

  @override
  String get noteBody => 'Görüş';

  @override
  String get noteVisibleToGuardians => 'Veliler görebilir';

  @override
  String get noteVisibleToGuardiansHint =>
      'Veliler bu görüşü uygulamada görür.';

  @override
  String get noteSaved => 'Görüş kaydedildi.';

  @override
  String get internalNote => 'Yalnızca personel';

  @override
  String get attendanceDate => 'Tarih';

  @override
  String get filterClass => 'Sınıfa göre filtrele';

  @override
  String get allClasses => 'Tüm sınıflar';

  @override
  String get markAllPresent => 'Hepsini geldi işaretle';

  @override
  String saveAttendance(int count) {
    return 'Kaydet ($count)';
  }

  @override
  String get attendanceSaved => 'Yoklama kaydedildi.';

  @override
  String unsavedChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kaydedilmemiş değişiklik',
      one: '1 kaydedilmemiş değişiklik',
    );
    return '$_temp0';
  }

  @override
  String get notMarked => 'İşaretlenmedi';

  @override
  String get discardChangesTitle => 'Değişiklikler silinsin mi?';

  @override
  String get discardChangesBody =>
      'Kaydedilmemiş yoklama değişiklikleriniz var.';

  @override
  String get discard => 'Sil';

  @override
  String get staffOnly => 'Yalnızca personel';

  @override
  String get schoolWide => 'Tüm okul';

  @override
  String get switchSchool => 'Okul değiştir';

  @override
  String get roleAdmin => 'Yönetici';

  @override
  String get roleStaff => 'Personel';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get fullName => 'Ad soyad';

  @override
  String get nameSaved => 'Ad güncellendi.';

  @override
  String get languageSection => 'Dil';

  @override
  String get languageSystem => 'Sistem varsayılanı';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get accountSection => 'Hesap';

  @override
  String signedInAs(String email) {
    return '$email olarak giriş yapıldı';
  }

  @override
  String get deleteAccount => 'Hesabı sil';

  @override
  String get deleteAccountTitle => 'Hesabınız silinsin mi?';

  @override
  String get deleteAccountBody =>
      'Bu işlem hesabınızı kalıcı olarak siler ve çocuklarınızın okullarıyla bağlantınızı kaldırır. Okul kayıtları etkilenmez. Bu işlem geri alınamaz.';

  @override
  String get deleteAccountConfirm => 'Kalıcı olarak sil';

  @override
  String get accountDeleted => 'Hesabınız silindi.';
}
