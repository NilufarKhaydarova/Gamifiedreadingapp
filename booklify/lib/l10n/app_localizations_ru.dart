// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Booklify';

  @override
  String get navLearn => 'Учёба';

  @override
  String get navBooks => 'Книги';

  @override
  String get navInsights => 'Анализ';

  @override
  String get navProfile => 'Профиль';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonChange => 'Изменить';

  @override
  String get commonOr => 'или';

  @override
  String get commonLoading => 'Загрузка…';

  @override
  String get commonError => 'Что-то пошло не так. Попробуйте снова.';

  @override
  String get commonSignOut => 'Выйти';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get topicTitle => 'Что вы хотите\nизучить?';

  @override
  String get topicSubtitle =>
      'Мы создадим персональный план чтения с лучшими книгами, тестами и AI-дискуссиями.';

  @override
  String get topicHint => 'например, Философия, Психология…';

  @override
  String get topicPopular => 'Популярные темы';

  @override
  String get topicBuild => 'Создать учебный план';

  @override
  String get topicUpload => 'Загрузить книгу';

  @override
  String get topicBuilding => 'Создаём учебный план...';

  @override
  String topicCurating(String topic) {
    return 'Подбираем лучшие книги по теме\n\"$topic\"';
  }

  @override
  String get topicMoment => 'Это займёт немного времени ✨';

  @override
  String get topicEmpty => 'Расскажите, что вы хотите изучить!';

  @override
  String profileLevel(int level) {
    return 'Уровень $level';
  }

  @override
  String profileTotalXP(int xp) {
    return '$xp XP всего';
  }

  @override
  String profileToLevel(int level) {
    return 'до уровня $level';
  }

  @override
  String get profileDayStreak => 'Дней подряд';

  @override
  String get profileLessonsDone => 'Уроков пройдено';

  @override
  String get profileProgress => 'Прогресс';

  @override
  String get profileForest => 'Ваш лес знаний';

  @override
  String get profileForest0 => 'Завершите первый урок, чтобы посадить дерево!';

  @override
  String get profileForest1 => 'Ваш лес только начинает расти...';

  @override
  String get profileForest2 => 'Маленькая роща набирает форму!';

  @override
  String get profileForest3 => 'Ваш лес процветает!';

  @override
  String get profileForest4 => 'Великолепный лес! Вы настоящий учёный.';

  @override
  String get profileThisWeek => 'Эта неделя';

  @override
  String profileStreakBadge(int n) {
    return '🔥 $n дней подряд';
  }

  @override
  String get profileCurriculum => 'Текущий учебный план';

  @override
  String get profileSignOutTitle => 'Выйти из аккаунта?';

  @override
  String get profileSignOutBody =>
      'Для доступа к прогрессу нужно будет войти снова.';

  @override
  String get profileChangeTopicTitle => 'Сменить тему?';

  @override
  String get profileChangeTopicBody =>
      'Текущий учебный план будет удалён. Ваши XP сохранятся.';

  @override
  String get profileChangeTopicBtn => 'Сменить тему';

  @override
  String get profileNoLessons => 'Уроков пока нет';

  @override
  String get profileLanguage => 'Язык';

  @override
  String get insightsTitle => 'Карта знаний';

  @override
  String insightsTopic(String topic) {
    return 'Тема: $topic';
  }

  @override
  String get insightsChoose => 'Выберите тему для начала';

  @override
  String get insightsNoTopicTitle => 'Тема ещё не выбрана';

  @override
  String get insightsNoTopicBody =>
      'Перейдите во вкладку «Учёба» и выберите тему. Карта знаний появится здесь по мере прохождения уроков.';

  @override
  String get insightsMapLabel => 'КАРТА ЗНАНИЙ';

  @override
  String get insightsMapSub => 'Ваш профиль читателя';

  @override
  String insightsComplete(int pct) {
    return '$pct% пройдено';
  }

  @override
  String get insightsConcepts => 'КОНЦЕПЦИИ';

  @override
  String get insightsMastered => 'Изучено';

  @override
  String get insightsInProgress => 'В процессе';

  @override
  String get insightsGaps => 'Пробелы';

  @override
  String get insightsUnlock => 'Проходите уроки\nдля разблокировки';

  @override
  String get insightsLookingGood => 'Отлично!';

  @override
  String get insightsDna => 'ДНК ЧИТАТЕЛЯ';

  @override
  String get insightsDnaSub => 'Как ИИ адаптируется к вам';

  @override
  String get insightsAvgSpeed => 'Ср. скорость';

  @override
  String get insightsHighlights => 'Выделений';

  @override
  String get insightsAiChats => 'AI-диалогов';

  @override
  String get insightsBooks => 'Книг';

  @override
  String get insightsBooksProfile => 'Книги в вашем профиле';

  @override
  String get insightsDnaEmpty => 'Ваша ДНК читателя появится здесь';

  @override
  String get insightsDnaEmptyBody =>
      'Читайте книги, выделяйте отрывки и общайтесь с ИИ.\nЧем больше вы читаете, тем точнее приложение адаптируется к вам.';

  @override
  String get insightsTopGaps => '🔍 КЛЮЧЕВЫЕ ПРОБЕЛЫ';

  @override
  String get insightsThesis => '🎓 СВЯЗЬ С ДИПЛОМНОЙ РАБОТОЙ';

  @override
  String get insightsFocusNext => '🚀 СЛЕДУЮЩИЙ ШАГ';

  @override
  String get insightsGapFocus =>
      'Сосредоточьтесь на этом пробеле, чтобы укрепить понимание.';

  @override
  String get insightsWhatHighlight => '🔖 ЧТО ВЫ ВЫДЕЛЯЕТЕ';

  @override
  String get insightsWhatAsk => '🤖 О ЧЁМ ВЫ СПРАШИВАЕТЕ ИИ';

  @override
  String get insightsBuilding => 'Строим карту знаний…';

  @override
  String get insightsRefresh => 'Обновить анализ';

  @override
  String get insightsTapNode => 'Нажмите на узел для подробностей';

  @override
  String get radarProgress => 'Прогресс';

  @override
  String get radarSpeed => 'Скорость';

  @override
  String get radarDepth => 'Глубина';

  @override
  String get radarAi => 'ИИ-\nвзаимодействие';

  @override
  String get radarConsistency => 'Постоянство';

  @override
  String get insightsMasteredConcept => 'ОСВОЕННАЯ КОНЦЕПЦИЯ';

  @override
  String get insightsKnowledgeGap => 'ПРОБЕЛ В ЗНАНИЯХ';

  @override
  String get insightsInProgressLabel => 'В ПРОЦЕССЕ';

  @override
  String get insightsUpcoming => 'ПРЕДСТОИТ';

  @override
  String get readingCompleteDay => 'Завершить день';

  @override
  String get readingAskAi => 'Спросить ИИ';

  @override
  String get readingHighlight => 'Выделить';

  @override
  String get readingBookmark => 'Закладка';

  @override
  String get readingSave => 'Сохранить!';

  @override
  String get readingHighlightSaved => 'Выделение сохранено ✓';

  @override
  String readingBookmarkSaved(int pct) {
    return 'Закладка сохранена на $pct% ✓';
  }

  @override
  String get readingSelectHint =>
      'Удерживайте слово для выделения, затем нажмите «Выделить»';

  @override
  String get readingThemeLight => 'Светлая';

  @override
  String get readingThemeSepia => 'Сепия';

  @override
  String get readingThemeDark => 'Тёмная';

  @override
  String get readingSelected => 'Выделено';

  @override
  String get readingSaving => 'Сохранение…';

  @override
  String get readingSessionComplete => 'Сессия завершена! 🎉';

  @override
  String readingMinutesRead(int n) {
    return '$n мин';
  }

  @override
  String readingWpm(int n) {
    return '$n сл/мин';
  }

  @override
  String readingXpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String get readingDone => 'Готово';

  @override
  String get readingKeepReading => 'Продолжить чтение';

  @override
  String get lessonKeepReading => 'Читайте дальше, чтобы продолжить ↓';

  @override
  String get lessonQuickCheck => 'Быстрая проверка';

  @override
  String get lessonReflect => 'Размышление и обсуждение';

  @override
  String get lessonSkip => 'Пропустить';

  @override
  String get lessonLoading => 'Генерация вопросов…';

  @override
  String get lessonNext => 'Далее';

  @override
  String get lessonComplete => 'Готово ✓';

  @override
  String get lessonCorrect => 'Правильно! 🎉';

  @override
  String get lessonWrong => 'Не совсем — попробуйте снова';

  @override
  String get lessonExplanation => 'Объяснение';

  @override
  String get lessonAllDone => 'Всё готово! 🎉';

  @override
  String lessonXpEarned(int xp) {
    return '+$xp XP получено!';
  }

  @override
  String lessonWeek(int n) {
    return 'Неделя $n';
  }

  @override
  String lessonDay(int n) {
    return 'День $n';
  }

  @override
  String get lessonLocked => 'Закрыто';

  @override
  String get lessonCompleted => 'Пройдено';

  @override
  String get booksTitle => 'Моя библиотека';

  @override
  String get booksAdd => 'Добавить книгу';

  @override
  String get booksEmpty => 'Книг пока нет';

  @override
  String get booksEmptyBody => 'Загрузите PDF или EPUB, чтобы начать.';

  @override
  String get booksReading => 'Читаю';

  @override
  String get booksCompleted => 'Прочитано';

  @override
  String get booksNotStarted => 'Не начато';

  @override
  String booksDays(int n) {
    return '$n дн.';
  }

  @override
  String get authSignIn => 'Войти';

  @override
  String get authSignUp => 'Зарегистрироваться';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Пароль';

  @override
  String get authName => 'Ваше имя';

  @override
  String get authForgot => 'Забыли пароль?';

  @override
  String get authNoAccount => 'Нет аккаунта? Зарегистрируйтесь';

  @override
  String get authHasAccount => 'Уже есть аккаунт? Войдите';

  @override
  String get authWelcome => 'Добро пожаловать в Booklify';

  @override
  String get authTagline => 'Ваш геймифицированный помощник в чтении';

  @override
  String get deepReader => 'Глубокий читатель';

  @override
  String get lightReader => 'Лёгкий читатель';

  @override
  String get moderateReader => 'Умеренный читатель';

  @override
  String get deepReaderDesc => 'Вы изучаете каждую деталь';

  @override
  String get lightReaderDesc => 'Вы читаете в быстром темпе';

  @override
  String get moderateReaderDesc => 'Баланс глубины и скорости';
}
