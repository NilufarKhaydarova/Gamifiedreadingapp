import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Booklify'**
  String get appTitle;

  /// No description provided for @navLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get navLearn;

  /// No description provided for @navBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get navBooks;

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get commonChange;

  /// No description provided for @commonOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get commonOr;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonError;

  /// No description provided for @commonSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get commonSignOut;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @topicTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you\nwant to learn?'**
  String get topicTitle;

  /// No description provided for @topicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll create a personalized reading path with the best books, quizzes, and AI discussions.'**
  String get topicSubtitle;

  /// No description provided for @topicHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Philosophy, AI Engineering…'**
  String get topicHint;

  /// No description provided for @topicPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular topics'**
  String get topicPopular;

  /// No description provided for @topicBuild.
  ///
  /// In en, this message translates to:
  /// **'Build My Curriculum'**
  String get topicBuild;

  /// No description provided for @topicUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload a Book Instead'**
  String get topicUpload;

  /// No description provided for @topicBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building your curriculum...'**
  String get topicBuilding;

  /// No description provided for @topicCurating.
  ///
  /// In en, this message translates to:
  /// **'Curating the best books on\n\"{topic}\"'**
  String topicCurating(String topic);

  /// No description provided for @topicMoment.
  ///
  /// In en, this message translates to:
  /// **'This may take a moment ✨'**
  String get topicMoment;

  /// No description provided for @topicEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you want to learn!'**
  String get topicEmpty;

  /// No description provided for @profileLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String profileLevel(int level);

  /// No description provided for @profileTotalXP.
  ///
  /// In en, this message translates to:
  /// **'{xp} total XP'**
  String profileTotalXP(int xp);

  /// No description provided for @profileToLevel.
  ///
  /// In en, this message translates to:
  /// **'to Level {level}'**
  String profileToLevel(int level);

  /// No description provided for @profileDayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get profileDayStreak;

  /// No description provided for @profileLessonsDone.
  ///
  /// In en, this message translates to:
  /// **'Lessons Done'**
  String get profileLessonsDone;

  /// No description provided for @profileProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get profileProgress;

  /// No description provided for @profileForest.
  ///
  /// In en, this message translates to:
  /// **'Your Learning Forest'**
  String get profileForest;

  /// No description provided for @profileForest0.
  ///
  /// In en, this message translates to:
  /// **'Plant your first tree by finishing a lesson!'**
  String get profileForest0;

  /// No description provided for @profileForest1.
  ///
  /// In en, this message translates to:
  /// **'Your forest is just beginning to grow...'**
  String get profileForest1;

  /// No description provided for @profileForest2.
  ///
  /// In en, this message translates to:
  /// **'A small grove is taking shape!'**
  String get profileForest2;

  /// No description provided for @profileForest3.
  ///
  /// In en, this message translates to:
  /// **'Your forest is thriving!'**
  String get profileForest3;

  /// No description provided for @profileForest4.
  ///
  /// In en, this message translates to:
  /// **'A magnificent forest! You\'re a true scholar.'**
  String get profileForest4;

  /// No description provided for @profileThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get profileThisWeek;

  /// No description provided for @profileStreakBadge.
  ///
  /// In en, this message translates to:
  /// **'🔥 {n} day streak'**
  String profileStreakBadge(int n);

  /// No description provided for @profileCurriculum.
  ///
  /// In en, this message translates to:
  /// **'Current Curriculum'**
  String get profileCurriculum;

  /// No description provided for @profileSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out?'**
  String get profileSignOutTitle;

  /// No description provided for @profileSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to access your progress.'**
  String get profileSignOutBody;

  /// No description provided for @profileChangeTopicTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Topic?'**
  String get profileChangeTopicTitle;

  /// No description provided for @profileChangeTopicBody.
  ///
  /// In en, this message translates to:
  /// **'This will clear your current curriculum. Your XP will be kept.'**
  String get profileChangeTopicBody;

  /// No description provided for @profileChangeTopicBtn.
  ///
  /// In en, this message translates to:
  /// **'Change Topic'**
  String get profileChangeTopicBtn;

  /// No description provided for @profileNoLessons.
  ///
  /// In en, this message translates to:
  /// **'No lessons yet'**
  String get profileNoLessons;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Knowledge Map'**
  String get insightsTitle;

  /// No description provided for @insightsTopic.
  ///
  /// In en, this message translates to:
  /// **'Topic: {topic}'**
  String insightsTopic(String topic);

  /// No description provided for @insightsChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a topic to begin'**
  String get insightsChoose;

  /// No description provided for @insightsNoTopicTitle.
  ///
  /// In en, this message translates to:
  /// **'No learning topic yet'**
  String get insightsNoTopicTitle;

  /// No description provided for @insightsNoTopicBody.
  ///
  /// In en, this message translates to:
  /// **'Go to the Learn tab and choose a topic. Your knowledge map will appear here as you complete lessons.'**
  String get insightsNoTopicBody;

  /// No description provided for @insightsMapLabel.
  ///
  /// In en, this message translates to:
  /// **'KNOWLEDGE MAP'**
  String get insightsMapLabel;

  /// No description provided for @insightsMapSub.
  ///
  /// In en, this message translates to:
  /// **'Your reader profile at a glance'**
  String get insightsMapSub;

  /// No description provided for @insightsComplete.
  ///
  /// In en, this message translates to:
  /// **'{pct}% complete'**
  String insightsComplete(int pct);

  /// No description provided for @insightsConcepts.
  ///
  /// In en, this message translates to:
  /// **'CONCEPTS AT A GLANCE'**
  String get insightsConcepts;

  /// No description provided for @insightsMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get insightsMastered;

  /// No description provided for @insightsInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get insightsInProgress;

  /// No description provided for @insightsGaps.
  ///
  /// In en, this message translates to:
  /// **'Gaps'**
  String get insightsGaps;

  /// No description provided for @insightsUnlock.
  ///
  /// In en, this message translates to:
  /// **'Complete lessons\nto unlock'**
  String get insightsUnlock;

  /// No description provided for @insightsLookingGood.
  ///
  /// In en, this message translates to:
  /// **'Looking good!'**
  String get insightsLookingGood;

  /// No description provided for @insightsDna.
  ///
  /// In en, this message translates to:
  /// **'READING DNA'**
  String get insightsDna;

  /// No description provided for @insightsDnaSub.
  ///
  /// In en, this message translates to:
  /// **'How the AI adapts to you'**
  String get insightsDnaSub;

  /// No description provided for @insightsAvgSpeed.
  ///
  /// In en, this message translates to:
  /// **'Avg speed'**
  String get insightsAvgSpeed;

  /// No description provided for @insightsHighlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get insightsHighlights;

  /// No description provided for @insightsAiChats.
  ///
  /// In en, this message translates to:
  /// **'AI chats'**
  String get insightsAiChats;

  /// No description provided for @insightsBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get insightsBooks;

  /// No description provided for @insightsBooksProfile.
  ///
  /// In en, this message translates to:
  /// **'Books in your profile'**
  String get insightsBooksProfile;

  /// No description provided for @insightsDnaEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your Reading DNA will appear here'**
  String get insightsDnaEmpty;

  /// No description provided for @insightsDnaEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Read books, highlight passages, and chat with the AI.\nThe more you read, the more the app adapts to you.'**
  String get insightsDnaEmptyBody;

  /// No description provided for @insightsTopGaps.
  ///
  /// In en, this message translates to:
  /// **'🔍 TOP GAPS TO CLOSE'**
  String get insightsTopGaps;

  /// No description provided for @insightsThesis.
  ///
  /// In en, this message translates to:
  /// **'🎓 THESIS RELEVANCE'**
  String get insightsThesis;

  /// No description provided for @insightsFocusNext.
  ///
  /// In en, this message translates to:
  /// **'🚀 FOCUS NEXT'**
  String get insightsFocusNext;

  /// No description provided for @insightsGapFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus on this gap to strengthen your understanding.'**
  String get insightsGapFocus;

  /// No description provided for @insightsWhatHighlight.
  ///
  /// In en, this message translates to:
  /// **'🔖 WHAT YOU HIGHLIGHT'**
  String get insightsWhatHighlight;

  /// No description provided for @insightsWhatAsk.
  ///
  /// In en, this message translates to:
  /// **'🤖 WHAT YOU ASK THE AI'**
  String get insightsWhatAsk;

  /// No description provided for @insightsBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building your knowledge map…'**
  String get insightsBuilding;

  /// No description provided for @insightsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh analysis'**
  String get insightsRefresh;

  /// No description provided for @insightsTapNode.
  ///
  /// In en, this message translates to:
  /// **'Tap any node to explore'**
  String get insightsTapNode;

  /// No description provided for @radarProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get radarProgress;

  /// No description provided for @radarSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get radarSpeed;

  /// No description provided for @radarDepth.
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get radarDepth;

  /// No description provided for @radarAi.
  ///
  /// In en, this message translates to:
  /// **'AI\nEngagement'**
  String get radarAi;

  /// No description provided for @radarConsistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get radarConsistency;

  /// No description provided for @insightsMasteredConcept.
  ///
  /// In en, this message translates to:
  /// **'MASTERED CONCEPT'**
  String get insightsMasteredConcept;

  /// No description provided for @insightsKnowledgeGap.
  ///
  /// In en, this message translates to:
  /// **'KNOWLEDGE GAP'**
  String get insightsKnowledgeGap;

  /// No description provided for @insightsInProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get insightsInProgressLabel;

  /// No description provided for @insightsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get insightsUpcoming;

  /// No description provided for @readingCompleteDay.
  ///
  /// In en, this message translates to:
  /// **'Complete Day'**
  String get readingCompleteDay;

  /// No description provided for @readingAskAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get readingAskAi;

  /// No description provided for @readingHighlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get readingHighlight;

  /// No description provided for @readingBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get readingBookmark;

  /// No description provided for @readingSave.
  ///
  /// In en, this message translates to:
  /// **'Save!'**
  String get readingSave;

  /// No description provided for @readingHighlightSaved.
  ///
  /// In en, this message translates to:
  /// **'Highlight saved ✓'**
  String get readingHighlightSaved;

  /// No description provided for @readingBookmarkSaved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark saved at {pct}% ✓'**
  String readingBookmarkSaved(int pct);

  /// No description provided for @readingSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press words to select text, then tap Highlight'**
  String get readingSelectHint;

  /// No description provided for @readingThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get readingThemeLight;

  /// No description provided for @readingThemeSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get readingThemeSepia;

  /// No description provided for @readingThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get readingThemeDark;

  /// No description provided for @readingSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get readingSelected;

  /// No description provided for @readingSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get readingSaving;

  /// No description provided for @readingSessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session Complete! 🎉'**
  String get readingSessionComplete;

  /// No description provided for @readingMinutesRead.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String readingMinutesRead(int n);

  /// No description provided for @readingWpm.
  ///
  /// In en, this message translates to:
  /// **'{n} wpm'**
  String readingWpm(int n);

  /// No description provided for @readingXpEarned.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String readingXpEarned(int xp);

  /// No description provided for @readingDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get readingDone;

  /// No description provided for @readingKeepReading.
  ///
  /// In en, this message translates to:
  /// **'Keep Reading'**
  String get readingKeepReading;

  /// No description provided for @lessonKeepReading.
  ///
  /// In en, this message translates to:
  /// **'Keep reading to continue ↓'**
  String get lessonKeepReading;

  /// No description provided for @lessonQuickCheck.
  ///
  /// In en, this message translates to:
  /// **'Quick Check'**
  String get lessonQuickCheck;

  /// No description provided for @lessonReflect.
  ///
  /// In en, this message translates to:
  /// **'Reflect & Discuss'**
  String get lessonReflect;

  /// No description provided for @lessonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for Now'**
  String get lessonSkip;

  /// No description provided for @lessonLoading.
  ///
  /// In en, this message translates to:
  /// **'Generating questions…'**
  String get lessonLoading;

  /// No description provided for @lessonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get lessonNext;

  /// No description provided for @lessonComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete ✓'**
  String get lessonComplete;

  /// No description provided for @lessonCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct! 🎉'**
  String get lessonCorrect;

  /// No description provided for @lessonWrong.
  ///
  /// In en, this message translates to:
  /// **'Not quite — try again'**
  String get lessonWrong;

  /// No description provided for @lessonExplanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get lessonExplanation;

  /// No description provided for @lessonAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done! 🎉'**
  String get lessonAllDone;

  /// No description provided for @lessonXpEarned.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP earned!'**
  String lessonXpEarned(int xp);

  /// No description provided for @lessonWeek.
  ///
  /// In en, this message translates to:
  /// **'Week {n}'**
  String lessonWeek(int n);

  /// No description provided for @lessonDay.
  ///
  /// In en, this message translates to:
  /// **'Day {n}'**
  String lessonDay(int n);

  /// No description provided for @lessonLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lessonLocked;

  /// No description provided for @lessonCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get lessonCompleted;

  /// No description provided for @booksTitle.
  ///
  /// In en, this message translates to:
  /// **'My Library'**
  String get booksTitle;

  /// No description provided for @booksAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Book'**
  String get booksAdd;

  /// No description provided for @booksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No books yet'**
  String get booksEmpty;

  /// No description provided for @booksEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Upload a PDF or EPUB to get started.'**
  String get booksEmptyBody;

  /// No description provided for @booksReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get booksReading;

  /// No description provided for @booksCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get booksCompleted;

  /// No description provided for @booksNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get booksNotStarted;

  /// No description provided for @booksDays.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String booksDays(int n);

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUp;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get authName;

  /// No description provided for @authForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgot;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get authNoAccount;

  /// No description provided for @authHasAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHasAccount;

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Booklify'**
  String get authWelcome;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Your gamified reading companion'**
  String get authTagline;

  /// No description provided for @deepReader.
  ///
  /// In en, this message translates to:
  /// **'Deep Reader'**
  String get deepReader;

  /// No description provided for @lightReader.
  ///
  /// In en, this message translates to:
  /// **'Light Reader'**
  String get lightReader;

  /// No description provided for @moderateReader.
  ///
  /// In en, this message translates to:
  /// **'Moderate Reader'**
  String get moderateReader;

  /// No description provided for @deepReaderDesc.
  ///
  /// In en, this message translates to:
  /// **'You explore every detail'**
  String get deepReaderDesc;

  /// No description provided for @lightReaderDesc.
  ///
  /// In en, this message translates to:
  /// **'You read at a swift pace'**
  String get lightReaderDesc;

  /// No description provided for @moderateReaderDesc.
  ///
  /// In en, this message translates to:
  /// **'Balanced depth and speed'**
  String get moderateReaderDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
