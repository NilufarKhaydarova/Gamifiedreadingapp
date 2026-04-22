// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'Booklify';

  @override
  String get navLearn => 'O\'rganish';

  @override
  String get navBooks => 'Kitoblar';

  @override
  String get navInsights => 'Tahlil';

  @override
  String get navProfile => 'Profil';

  @override
  String get commonCancel => 'Bekor qilish';

  @override
  String get commonSave => 'Saqlash';

  @override
  String get commonChange => 'O\'zgartirish';

  @override
  String get commonOr => 'yoki';

  @override
  String get commonLoading => 'Yuklanmoqda…';

  @override
  String get commonError => 'Xatolik yuz berdi. Qayta urinib ko\'ring.';

  @override
  String get commonSignOut => 'Chiqish';

  @override
  String get commonClose => 'Yopish';

  @override
  String get topicTitle => 'Nima o\'rganmoqchi\nsiz?';

  @override
  String get topicSubtitle =>
      'Eng yaxshi kitoblar, testlar va AI muhokamasi bilan shaxsiy o\'quv rejasini tuzamiz.';

  @override
  String get topicHint => 'masalan, Falsafa, Sun\'iy intellekt…';

  @override
  String get topicPopular => 'Mashhur mavzular';

  @override
  String get topicBuild => 'O\'quv rejasini yaratish';

  @override
  String get topicUpload => 'Kitob yuklash';

  @override
  String get topicBuilding => 'O\'quv rejasi tayyorlanmoqda...';

  @override
  String topicCurating(String topic) {
    return '«$topic» mavzusidagi\neng yaxshi kitoblar tanlanmoqda';
  }

  @override
  String get topicMoment => 'Bu biroz vaqt olishi mumkin ✨';

  @override
  String get topicEmpty => 'Nima o\'rganmoqchi ekanligingizni ayting!';

  @override
  String profileLevel(int level) {
    return '$level-daraja';
  }

  @override
  String profileTotalXP(int xp) {
    return 'Jami $xp XP';
  }

  @override
  String profileToLevel(int level) {
    return '$level-darajaga qadar';
  }

  @override
  String get profileDayStreak => 'Ketma-ket kun';

  @override
  String get profileLessonsDone => 'O\'tilgan darslar';

  @override
  String get profileProgress => 'Jarayon';

  @override
  String get profileForest => 'Bilimlar o\'rmoningiz';

  @override
  String get profileForest0 => 'Birinchi darsni tugating va daraxt oting!';

  @override
  String get profileForest1 => 'O\'rmoning o\'sib bormoqda...';

  @override
  String get profileForest2 => 'Kichik daracha shakllanmoqda!';

  @override
  String get profileForest3 => 'O\'rmoningiz gullab-yashnayapti!';

  @override
  String get profileForest4 => 'Ajoyib o\'rmon! Siz haqiqiy olimssiz.';

  @override
  String get profileThisWeek => 'Bu hafta';

  @override
  String profileStreakBadge(int n) {
    return '🔥 $n kun ketma-ket';
  }

  @override
  String get profileCurriculum => 'Joriy o\'quv rejasi';

  @override
  String get profileSignOutTitle => 'Chiqish?';

  @override
  String get profileSignOutBody =>
      'Hisobingizga qayta kirish uchun tizimga kirishingiz kerak bo\'ladi.';

  @override
  String get profileChangeTopicTitle => 'Mavzuni o\'zgartirish?';

  @override
  String get profileChangeTopicBody =>
      'Joriy o\'quv rejasi o\'chiriladi. XP ballaringiz saqlanib qoladi.';

  @override
  String get profileChangeTopicBtn => 'Mavzuni o\'zgartirish';

  @override
  String get profileNoLessons => 'Hozircha darslar yo\'q';

  @override
  String get profileLanguage => 'Til';

  @override
  String get insightsTitle => 'Bilimlar xaritasi';

  @override
  String insightsTopic(String topic) {
    return 'Mavzu: $topic';
  }

  @override
  String get insightsChoose => 'Boshlash uchun mavzu tanlang';

  @override
  String get insightsNoTopicTitle => 'Mavzu hali tanlanmagan';

  @override
  String get insightsNoTopicBody =>
      '«O\'rganish» bo\'limiga o\'ting va mavzu tanlang. Bilimlar xaritasi darslarni o\'tgan sayin ko\'rinadi.';

  @override
  String get insightsMapLabel => 'BILIMLAR XARITASI';

  @override
  String get insightsMapSub => 'O\'quvchi profilingiz';

  @override
  String insightsComplete(int pct) {
    return '$pct% bajarildi';
  }

  @override
  String get insightsConcepts => 'TUSHUNCHALAR';

  @override
  String get insightsMastered => 'O\'rganildi';

  @override
  String get insightsInProgress => 'Jarayonda';

  @override
  String get insightsGaps => 'Bo\'shliqlar';

  @override
  String get insightsUnlock => 'Ochish uchun\ndarslarni o\'ting';

  @override
  String get insightsLookingGood => 'Ajoyib!';

  @override
  String get insightsDna => 'O\'QUVCHI DNK';

  @override
  String get insightsDnaSub => 'AI sizga qanday moslashadi';

  @override
  String get insightsAvgSpeed => 'O\'rtacha tezlik';

  @override
  String get insightsHighlights => 'Ajratmalar';

  @override
  String get insightsAiChats => 'AI suhbatlari';

  @override
  String get insightsBooks => 'Kitoblar';

  @override
  String get insightsBooksProfile => 'Profilingizdagi kitoblar';

  @override
  String get insightsDnaEmpty => 'O\'quvchi DNK bu yerda paydo bo\'ladi';

  @override
  String get insightsDnaEmptyBody =>
      'Kitoblarni o\'qing, parchalarni ajrating va AI bilan suhbatlashing.\nQancha ko\'p o\'qisangiz, ilova shuncha moslashadi.';

  @override
  String get insightsTopGaps => '🔍 ASOSIY BO\'SHLIQLAR';

  @override
  String get insightsThesis => '🎓 DIPLOM ISHI BILAN BOG\'LIQLIGI';

  @override
  String get insightsFocusNext => '🚀 KEYINGI QADAM';

  @override
  String get insightsGapFocus =>
      'Tushunchani mustahkamlash uchun bu bo\'shliqqa e\'tibor bering.';

  @override
  String get insightsWhatHighlight => '🔖 NIMA AJRATASIZ';

  @override
  String get insightsWhatAsk => '🤖 AI DAN NIMA SO\'RAYSIZ';

  @override
  String get insightsBuilding => 'Bilimlar xaritasi qurilmoqda…';

  @override
  String get insightsRefresh => 'Tahlilni yangilash';

  @override
  String get insightsTapNode => 'Tafsilot uchun tugunni bosing';

  @override
  String get radarProgress => 'Jarayon';

  @override
  String get radarSpeed => 'Tezlik';

  @override
  String get radarDepth => 'Chuqurlik';

  @override
  String get radarAi => 'AI\nbilan ishlash';

  @override
  String get radarConsistency => 'Muntazamlik';

  @override
  String get insightsMasteredConcept => 'O\'RGANILGAN TUSHUNCHA';

  @override
  String get insightsKnowledgeGap => 'BILIM BO\'SHLIG\'I';

  @override
  String get insightsInProgressLabel => 'JARAYONDA';

  @override
  String get insightsUpcoming => 'OLDINDA';

  @override
  String get readingCompleteDay => 'Kunni yakunlash';

  @override
  String get readingAskAi => 'AI dan so\'rash';

  @override
  String get readingHighlight => 'Ajratish';

  @override
  String get readingBookmark => 'Xatchet';

  @override
  String get readingSave => 'Saqlash!';

  @override
  String get readingHighlightSaved => 'Ajratma saqlandi ✓';

  @override
  String readingBookmarkSaved(int pct) {
    return '$pct% joyida xatchet saqlandi ✓';
  }

  @override
  String get readingSelectHint =>
      'Matn ajratish uchun uzoq bosing, keyin «Ajratish» tugmasini bosing';

  @override
  String get readingThemeLight => 'Yorqin';

  @override
  String get readingThemeSepia => 'Sepiya';

  @override
  String get readingThemeDark => 'Qoʻngʻir';

  @override
  String get readingSelected => 'Ajratildi';

  @override
  String get readingSaving => 'Saqlanmoqda…';

  @override
  String get readingSessionComplete => 'Seans tugadi! 🎉';

  @override
  String readingMinutesRead(int n) {
    return '$n daq';
  }

  @override
  String readingWpm(int n) {
    return '$n so\'z/daq';
  }

  @override
  String readingXpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String get readingDone => 'Tayyor';

  @override
  String get readingKeepReading => 'O\'qishni davom ettirish';

  @override
  String get lessonKeepReading => 'Davom etish uchun o\'qishda davom eting ↓';

  @override
  String get lessonQuickCheck => 'Tezkor tekshiruv';

  @override
  String get lessonReflect => 'Mulohaza va muhokama';

  @override
  String get lessonSkip => 'O\'tkazib yuborish';

  @override
  String get lessonLoading => 'Savollar yaratilmoqda…';

  @override
  String get lessonNext => 'Keyingi';

  @override
  String get lessonComplete => 'Tayyor ✓';

  @override
  String get lessonCorrect => 'To\'g\'ri! 🎉';

  @override
  String get lessonWrong => 'Uncha ham emas — qayta urinib ko\'ring';

  @override
  String get lessonExplanation => 'Tushuntirish';

  @override
  String get lessonAllDone => 'Hammasi tugadi! 🎉';

  @override
  String lessonXpEarned(int xp) {
    return '+$xp XP qo\'lga kiritildi!';
  }

  @override
  String lessonWeek(int n) {
    return '$n-hafta';
  }

  @override
  String lessonDay(int n) {
    return '$n-kun';
  }

  @override
  String get lessonLocked => 'Qulflangan';

  @override
  String get lessonCompleted => 'Bajarildi';

  @override
  String get booksTitle => 'Mening kutubxonam';

  @override
  String get booksAdd => 'Kitob qo\'shish';

  @override
  String get booksEmpty => 'Hozircha kitob yo\'q';

  @override
  String get booksEmptyBody => 'Boshlash uchun PDF yoki EPUB yuklang.';

  @override
  String get booksReading => 'O\'qilmoqda';

  @override
  String get booksCompleted => 'O\'qildi';

  @override
  String get booksNotStarted => 'Boshlanmagan';

  @override
  String booksDays(int n) {
    return '$n kun';
  }

  @override
  String get authSignIn => 'Kirish';

  @override
  String get authSignUp => 'Ro\'yxatdan o\'tish';

  @override
  String get authEmail => 'Elektron pochta';

  @override
  String get authPassword => 'Parol';

  @override
  String get authName => 'Ismingiz';

  @override
  String get authForgot => 'Parolni unutdingizmi?';

  @override
  String get authNoAccount => 'Hisobingiz yo\'qmi? Ro\'yxatdan o\'ting';

  @override
  String get authHasAccount => 'Hisobingiz bormi? Kiring';

  @override
  String get authWelcome => 'Booklify ga xush kelibsiz';

  @override
  String get authTagline => 'Geymifikatsiyali o\'qish hamkoringiz';

  @override
  String get deepReader => 'Chuqur o\'quvchi';

  @override
  String get lightReader => 'Yengil o\'quvchi';

  @override
  String get moderateReader => 'O\'rtacha o\'quvchi';

  @override
  String get deepReaderDesc => 'Siz har bir tafsilotni o\'rganasiz';

  @override
  String get lightReaderDesc => 'Siz tez sur\'atda o\'qiysiz';

  @override
  String get moderateReaderDesc => 'Chuqurlik va tezlik balansi';
}
