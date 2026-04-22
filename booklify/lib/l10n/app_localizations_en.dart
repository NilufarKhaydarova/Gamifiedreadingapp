// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Booklify';

  @override
  String get navLearn => 'Learn';

  @override
  String get navBooks => 'Books';

  @override
  String get navInsights => 'Insights';

  @override
  String get navProfile => 'Profile';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonChange => 'Change';

  @override
  String get commonOr => 'or';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonError => 'Something went wrong. Please try again.';

  @override
  String get commonSignOut => 'Sign Out';

  @override
  String get commonClose => 'Close';

  @override
  String get topicTitle => 'What do you\nwant to learn?';

  @override
  String get topicSubtitle =>
      'We\'ll create a personalized reading path with the best books, quizzes, and AI discussions.';

  @override
  String get topicHint => 'e.g. Philosophy, AI Engineering…';

  @override
  String get topicPopular => 'Popular topics';

  @override
  String get topicBuild => 'Build My Curriculum';

  @override
  String get topicUpload => 'Upload a Book Instead';

  @override
  String get topicBuilding => 'Building your curriculum...';

  @override
  String topicCurating(String topic) {
    return 'Curating the best books on\n\"$topic\"';
  }

  @override
  String get topicMoment => 'This may take a moment ✨';

  @override
  String get topicEmpty => 'Tell us what you want to learn!';

  @override
  String profileLevel(int level) {
    return 'Level $level';
  }

  @override
  String profileTotalXP(int xp) {
    return '$xp total XP';
  }

  @override
  String profileToLevel(int level) {
    return 'to Level $level';
  }

  @override
  String get profileDayStreak => 'Day Streak';

  @override
  String get profileLessonsDone => 'Lessons Done';

  @override
  String get profileProgress => 'Progress';

  @override
  String get profileForest => 'Your Learning Forest';

  @override
  String get profileForest0 => 'Plant your first tree by finishing a lesson!';

  @override
  String get profileForest1 => 'Your forest is just beginning to grow...';

  @override
  String get profileForest2 => 'A small grove is taking shape!';

  @override
  String get profileForest3 => 'Your forest is thriving!';

  @override
  String get profileForest4 => 'A magnificent forest! You\'re a true scholar.';

  @override
  String get profileThisWeek => 'This Week';

  @override
  String profileStreakBadge(int n) {
    return '🔥 $n day streak';
  }

  @override
  String get profileCurriculum => 'Current Curriculum';

  @override
  String get profileSignOutTitle => 'Sign Out?';

  @override
  String get profileSignOutBody =>
      'You\'ll need to sign in again to access your progress.';

  @override
  String get profileChangeTopicTitle => 'Change Topic?';

  @override
  String get profileChangeTopicBody =>
      'This will clear your current curriculum. Your XP will be kept.';

  @override
  String get profileChangeTopicBtn => 'Change Topic';

  @override
  String get profileNoLessons => 'No lessons yet';

  @override
  String get profileLanguage => 'Language';

  @override
  String get insightsTitle => 'Knowledge Map';

  @override
  String insightsTopic(String topic) {
    return 'Topic: $topic';
  }

  @override
  String get insightsChoose => 'Choose a topic to begin';

  @override
  String get insightsNoTopicTitle => 'No learning topic yet';

  @override
  String get insightsNoTopicBody =>
      'Go to the Learn tab and choose a topic. Your knowledge map will appear here as you complete lessons.';

  @override
  String get insightsMapLabel => 'KNOWLEDGE MAP';

  @override
  String get insightsMapSub => 'Your reader profile at a glance';

  @override
  String insightsComplete(int pct) {
    return '$pct% complete';
  }

  @override
  String get insightsConcepts => 'CONCEPTS AT A GLANCE';

  @override
  String get insightsMastered => 'Mastered';

  @override
  String get insightsInProgress => 'In Progress';

  @override
  String get insightsGaps => 'Gaps';

  @override
  String get insightsUnlock => 'Complete lessons\nto unlock';

  @override
  String get insightsLookingGood => 'Looking good!';

  @override
  String get insightsDna => 'READING DNA';

  @override
  String get insightsDnaSub => 'How the AI adapts to you';

  @override
  String get insightsAvgSpeed => 'Avg speed';

  @override
  String get insightsHighlights => 'Highlights';

  @override
  String get insightsAiChats => 'AI chats';

  @override
  String get insightsBooks => 'Books';

  @override
  String get insightsBooksProfile => 'Books in your profile';

  @override
  String get insightsDnaEmpty => 'Your Reading DNA will appear here';

  @override
  String get insightsDnaEmptyBody =>
      'Read books, highlight passages, and chat with the AI.\nThe more you read, the more the app adapts to you.';

  @override
  String get insightsTopGaps => '🔍 TOP GAPS TO CLOSE';

  @override
  String get insightsThesis => '🎓 THESIS RELEVANCE';

  @override
  String get insightsFocusNext => '🚀 FOCUS NEXT';

  @override
  String get insightsGapFocus =>
      'Focus on this gap to strengthen your understanding.';

  @override
  String get insightsWhatHighlight => '🔖 WHAT YOU HIGHLIGHT';

  @override
  String get insightsWhatAsk => '🤖 WHAT YOU ASK THE AI';

  @override
  String get insightsBuilding => 'Building your knowledge map…';

  @override
  String get insightsRefresh => 'Refresh analysis';

  @override
  String get insightsTapNode => 'Tap any node to explore';

  @override
  String get radarProgress => 'Progress';

  @override
  String get radarSpeed => 'Speed';

  @override
  String get radarDepth => 'Depth';

  @override
  String get radarAi => 'AI\nEngagement';

  @override
  String get radarConsistency => 'Consistency';

  @override
  String get insightsMasteredConcept => 'MASTERED CONCEPT';

  @override
  String get insightsKnowledgeGap => 'KNOWLEDGE GAP';

  @override
  String get insightsInProgressLabel => 'IN PROGRESS';

  @override
  String get insightsUpcoming => 'UPCOMING';

  @override
  String get readingCompleteDay => 'Complete Day';

  @override
  String get readingAskAi => 'Ask AI';

  @override
  String get readingHighlight => 'Highlight';

  @override
  String get readingBookmark => 'Bookmark';

  @override
  String get readingSave => 'Save!';

  @override
  String get readingHighlightSaved => 'Highlight saved ✓';

  @override
  String readingBookmarkSaved(int pct) {
    return 'Bookmark saved at $pct% ✓';
  }

  @override
  String get readingSelectHint =>
      'Long-press words to select text, then tap Highlight';

  @override
  String get readingThemeLight => 'Light';

  @override
  String get readingThemeSepia => 'Sepia';

  @override
  String get readingThemeDark => 'Dark';

  @override
  String get readingSelected => 'Selected';

  @override
  String get readingSaving => 'Saving…';

  @override
  String get readingSessionComplete => 'Session Complete! 🎉';

  @override
  String readingMinutesRead(int n) {
    return '$n min';
  }

  @override
  String readingWpm(int n) {
    return '$n wpm';
  }

  @override
  String readingXpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String get readingDone => 'Done';

  @override
  String get readingKeepReading => 'Keep Reading';

  @override
  String get lessonKeepReading => 'Keep reading to continue ↓';

  @override
  String get lessonQuickCheck => 'Quick Check';

  @override
  String get lessonReflect => 'Reflect & Discuss';

  @override
  String get lessonSkip => 'Skip for Now';

  @override
  String get lessonLoading => 'Generating questions…';

  @override
  String get lessonNext => 'Next';

  @override
  String get lessonComplete => 'Complete ✓';

  @override
  String get lessonCorrect => 'Correct! 🎉';

  @override
  String get lessonWrong => 'Not quite — try again';

  @override
  String get lessonExplanation => 'Explanation';

  @override
  String get lessonAllDone => 'All done! 🎉';

  @override
  String lessonXpEarned(int xp) {
    return '+$xp XP earned!';
  }

  @override
  String lessonWeek(int n) {
    return 'Week $n';
  }

  @override
  String lessonDay(int n) {
    return 'Day $n';
  }

  @override
  String get lessonLocked => 'Locked';

  @override
  String get lessonCompleted => 'Completed';

  @override
  String get booksTitle => 'My Library';

  @override
  String get booksAdd => 'Add Book';

  @override
  String get booksEmpty => 'No books yet';

  @override
  String get booksEmptyBody => 'Upload a PDF or EPUB to get started.';

  @override
  String get booksReading => 'Reading';

  @override
  String get booksCompleted => 'Completed';

  @override
  String get booksNotStarted => 'Not started';

  @override
  String booksDays(int n) {
    return '$n days';
  }

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authSignUp => 'Sign Up';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authName => 'Your name';

  @override
  String get authForgot => 'Forgot password?';

  @override
  String get authNoAccount => 'Don\'t have an account? Sign up';

  @override
  String get authHasAccount => 'Already have an account? Sign in';

  @override
  String get authWelcome => 'Welcome to Booklify';

  @override
  String get authTagline => 'Your gamified reading companion';

  @override
  String get deepReader => 'Deep Reader';

  @override
  String get lightReader => 'Light Reader';

  @override
  String get moderateReader => 'Moderate Reader';

  @override
  String get deepReaderDesc => 'You explore every detail';

  @override
  String get lightReaderDesc => 'You read at a swift pace';

  @override
  String get moderateReaderDesc => 'Balanced depth and speed';
}
