import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @aLongWhile.
  ///
  /// In en, this message translates to:
  /// **'A long while'**
  String get aLongWhile;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addBookmark.
  ///
  /// In en, this message translates to:
  /// **'Add Bookmark'**
  String get addBookmark;

  /// No description provided for @addNewGroup.
  ///
  /// In en, this message translates to:
  /// **'Add New Group'**
  String get addNewGroup;

  /// No description provided for @addPiece.
  ///
  /// In en, this message translates to:
  /// **'Add Piece'**
  String get addPiece;

  /// No description provided for @addPracticeSession.
  ///
  /// In en, this message translates to:
  /// **'Add Practice Session'**
  String get addPracticeSession;

  /// No description provided for @addStage.
  ///
  /// In en, this message translates to:
  /// **'Add Stage'**
  String get addStage;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTag;

  /// No description provided for @addTagGroup.
  ///
  /// In en, this message translates to:
  /// **'Add Tag Group'**
  String get addTagGroup;

  /// No description provided for @addToRepertoire.
  ///
  /// In en, this message translates to:
  /// **'Add to Repertoire'**
  String get addToRepertoire;

  /// No description provided for @adithyaJayan.
  ///
  /// In en, this message translates to:
  /// **'Adithya Jayan'**
  String get adithyaJayan;

  /// No description provided for @adithyajayanInMyrepertoirapp.
  ///
  /// In en, this message translates to:
  /// **'adithyajayan.in/MyRepertoirApp/'**
  String get adithyajayanInMyrepertoirapp;

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettings;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @allPieces.
  ///
  /// In en, this message translates to:
  /// **'All Pieces'**
  String get allPieces;

  /// No description provided for @allowAddingNotesToSessions.
  ///
  /// In en, this message translates to:
  /// **'Allow adding notes to sessions'**
  String get allowAddingNotesToSessions;

  /// No description provided for @alphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get alphabetical;

  /// No description provided for @anyTime.
  ///
  /// In en, this message translates to:
  /// **'Any Time'**
  String get anyTime;

  /// No description provided for @apache20.
  ///
  /// In en, this message translates to:
  /// **'Apache 2.0'**
  String get apache20;

  /// No description provided for @appDocuments.
  ///
  /// In en, this message translates to:
  /// **'App Documents'**
  String get appDocuments;

  /// No description provided for @appInformation.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get appInformation;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @languageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @appTheme.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get appTheme;

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Music Repertoire'**
  String get appTitle;

  /// No description provided for @appearanceAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings > Personalization to switch themes, accent colors, and layout options.'**
  String get appearanceAnswer;

  /// No description provided for @appearanceQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I change the app\'s appearance?'**
  String get appearanceQuestion;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @applyAndClose.
  ///
  /// In en, this message translates to:
  /// **'Apply & Close'**
  String get applyAndClose;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @areYouSureYouWantToDeleteTheDebugLogFile.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the debug log file?'**
  String get areYouSureYouWantToDeleteTheDebugLogFile;

  /// No description provided for @areYouSureYouWantToDeleteThisMusicPiece.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this music piece?'**
  String get areYouSureYouWantToDeleteThisMusicPiece;

  /// No description provided for @areYouSureYouWantToDeleteThisPracticeSessionThisAction.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this practice session? This action cannot be undone.'**
  String get areYouSureYouWantToDeleteThisPracticeSessionThisAction;

  /// No description provided for @artistComposer.
  ///
  /// In en, this message translates to:
  /// **'Artist / Composer'**
  String get artistComposer;

  /// No description provided for @associatedTags.
  ///
  /// In en, this message translates to:
  /// **'Associated Tags:'**
  String get associatedTags;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @audioFile.
  ///
  /// In en, this message translates to:
  /// **'Audio File'**
  String get audioFile;

  /// No description provided for @audioFileDoesNotExist.
  ///
  /// In en, this message translates to:
  /// **'Audio file does not exist'**
  String get audioFileDoesNotExist;

  /// No description provided for @audioMidi.
  ///
  /// In en, this message translates to:
  /// **'Audio/MIDI'**
  String get audioMidi;

  /// No description provided for @audioNotLoadedYetPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Audio not loaded yet. Please wait.'**
  String get audioNotLoadedYetPleaseWait;

  /// No description provided for @autoBackupCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Auto-backup completed successfully!'**
  String get autoBackupCompletedSuccessfully;

  /// Localized message for autoBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Auto-backup failed: {error}'**
  String autoBackupFailed(String error);

  /// No description provided for @autoBackupFailedStoragePathNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Auto-backup failed: Storage path not configured.'**
  String get autoBackupFailedStoragePathNotConfigured;

  /// No description provided for @autoBackupStartingInAFewSeconds.
  ///
  /// In en, this message translates to:
  /// **'Auto-backup starting in a few seconds...'**
  String get autoBackupStartingInAFewSeconds;

  /// No description provided for @autoScrollEnabled.
  ///
  /// In en, this message translates to:
  /// **'Auto Scroll Enabled'**
  String get autoScrollEnabled;

  /// Explanation shown when an automatic backup is discovered during setup.
  ///
  /// In en, this message translates to:
  /// **'An automatic backup was found in the selected storage folder. Would you like to restore it?\n\nNote: This will replace any template data created during installation.'**
  String get automaticBackupFoundMessage;

  /// No description provided for @automaticBackups.
  ///
  /// In en, this message translates to:
  /// **'Automatic Backups'**
  String get automaticBackups;

  /// No description provided for @automaticallyCreateBackupsAtRegularIntervals.
  ///
  /// In en, this message translates to:
  /// **'Automatically create backups at regular intervals'**
  String get automaticallyCreateBackupsAtRegularIntervals;

  /// No description provided for @averageTime.
  ///
  /// In en, this message translates to:
  /// **'Average Time'**
  String get averageTime;

  /// No description provided for @back1sHoldForFrameSkip.
  ///
  /// In en, this message translates to:
  /// **'Back 1s (Hold for frame skip)'**
  String get back1sHoldForFrameSkip;

  /// No description provided for @back5s.
  ///
  /// In en, this message translates to:
  /// **'Back 5s'**
  String get back5s;

  /// No description provided for @backingUpData.
  ///
  /// In en, this message translates to:
  /// **'Backing up data...'**
  String get backingUpData;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// No description provided for @backupAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes, visit Settings > Backup & Restore to perform manual or automatic local backups.'**
  String get backupAnswer;

  /// No description provided for @backupCancelled.
  ///
  /// In en, this message translates to:
  /// **'Backup cancelled.'**
  String get backupCancelled;

  /// Localized message for backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailed(String error);

  /// No description provided for @backupFailedStoragePathNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: Storage path not configured.'**
  String get backupFailedStoragePathNotConfigured;

  /// No description provided for @backupFrequencyDays.
  ///
  /// In en, this message translates to:
  /// **'Backup Frequency (days)'**
  String get backupFrequencyDays;

  /// No description provided for @backupQuestion.
  ///
  /// In en, this message translates to:
  /// **'Is there a way to backup my data?'**
  String get backupQuestion;

  /// No description provided for @backupRestoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully.'**
  String get backupRestoredSuccessfully;

  /// No description provided for @basicDetails.
  ///
  /// In en, this message translates to:
  /// **'Basic Details'**
  String get basicDetails;

  /// No description provided for @beenAWhile.
  ///
  /// In en, this message translates to:
  /// **'Been a while'**
  String get beenAWhile;

  /// No description provided for @beenTooLong.
  ///
  /// In en, this message translates to:
  /// **'Been too long'**
  String get beenTooLong;

  /// No description provided for @blank.
  ///
  /// In en, this message translates to:
  /// **'Blank'**
  String get blank;

  /// Localized message for bookmarkDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Bookmark {number}'**
  String bookmarkDefaultName(int number);

  /// Localized message for bookmarkDeleted.
  ///
  /// In en, this message translates to:
  /// **'{bookmarkName} deleted'**
  String bookmarkDeleted(String bookmarkName);

  /// Localized message for bookmarkDismissed.
  ///
  /// In en, this message translates to:
  /// **'{bookmarkName} dismissed'**
  String bookmarkDismissed(String bookmarkName);

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @browseAndManageInternalAppFiles.
  ///
  /// In en, this message translates to:
  /// **'Browse and manage internal app files'**
  String get browseAndManageInternalAppFiles;

  /// No description provided for @browserDownloads.
  ///
  /// In en, this message translates to:
  /// **'Browser Downloads'**
  String get browserDownloads;

  /// No description provided for @bulkEditTagGroupsAndColors.
  ///
  /// In en, this message translates to:
  /// **'Bulk edit tag groups and colors'**
  String get bulkEditTagGroupsAndColors;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @captureTechnicalLogsForTroubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Capture technical logs for troubleshooting'**
  String get captureTechnicalLogsForTroubleshooting;

  /// No description provided for @changeColor.
  ///
  /// In en, this message translates to:
  /// **'Change Color'**
  String get changeColor;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// No description provided for @changeStorageFolder.
  ///
  /// In en, this message translates to:
  /// **'Change Storage Folder'**
  String get changeStorageFolder;

  /// Localized message for channelDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Channel {number}'**
  String channelDefaultName(int number);

  /// No description provided for @checkForUpdatesNow.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates Now'**
  String get checkForUpdatesNow;

  /// No description provided for @checkGithubForAppUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check GitHub for app updates'**
  String get checkGithubForAppUpdates;

  /// No description provided for @chooseGroupColor.
  ///
  /// In en, this message translates to:
  /// **'Choose Group Color'**
  String get chooseGroupColor;

  /// No description provided for @chooseYourAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Choose your accent color:'**
  String get chooseYourAccentColor;

  /// No description provided for @classification.
  ///
  /// In en, this message translates to:
  /// **'Classification'**
  String get classification;

  /// No description provided for @cleanup.
  ///
  /// In en, this message translates to:
  /// **'Cleanup'**
  String get cleanup;

  /// Localized message for cleanupPartialMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleted {deletedCount, plural, =1{1 file} other{{deletedCount} files}} but encountered {errorCount, plural, =1{1 error} other{{errorCount} errors}}.'**
  String cleanupPartialMessage(int deletedCount, int errorCount);

  /// Localized message for cleanupSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Successfully deleted {count, plural, =1{1 unused file} other{{count} unused files}} ({size} freed).'**
  String cleanupSuccessMessage(int count, String size);

  /// No description provided for @cleanupSummary.
  ///
  /// In en, this message translates to:
  /// **'Cleanup Summary'**
  String get cleanupSummary;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get clearFilter;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @columns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get columns;

  /// No description provided for @count.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// No description provided for @configureAutoScroll.
  ///
  /// In en, this message translates to:
  /// **'Configure Auto Scroll'**
  String get configureAutoScroll;

  /// No description provided for @configureLearningProgress.
  ///
  /// In en, this message translates to:
  /// **'Configure Learning Progress'**
  String get configureLearningProgress;

  /// No description provided for @configureMidiTracks.
  ///
  /// In en, this message translates to:
  /// **'Configure MIDI Tracks'**
  String get configureMidiTracks;

  /// No description provided for @configurePdfViewer.
  ///
  /// In en, this message translates to:
  /// **'Configure PDF Viewer'**
  String get configurePdfViewer;

  /// No description provided for @configureProgressBar.
  ///
  /// In en, this message translates to:
  /// **'Configure Progress Bar'**
  String get configureProgressBar;

  /// No description provided for @confirmRestore.
  ///
  /// In en, this message translates to:
  /// **'Confirm Restore'**
  String get confirmRestore;

  /// Localized message for confirmRestoreMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore from this backup? This will replace all your current data.'**
  String get confirmRestoreMessage;

  /// No description provided for @contentAndDisplay.
  ///
  /// In en, this message translates to:
  /// **'Content & Display'**
  String get contentAndDisplay;

  /// Localized message for contributionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 contribution} other{{count} contributions}}'**
  String contributionCount(int count);

  /// No description provided for @contributors.
  ///
  /// In en, this message translates to:
  /// **'Contributors'**
  String get contributors;

  /// No description provided for @coral.
  ///
  /// In en, this message translates to:
  /// **'Coral'**
  String get coral;

  /// No description provided for @couldNotOpenLogFile.
  ///
  /// In en, this message translates to:
  /// **'Could not open log file'**
  String get couldNotOpenLogFile;

  /// Localized message for countProgress.
  ///
  /// In en, this message translates to:
  /// **'Count: {current} / {max}'**
  String countProgress(int current, int max);

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createABackupOfAllYourData.
  ///
  /// In en, this message translates to:
  /// **'Create a backup of all your data'**
  String get createABackupOfAllYourData;

  /// No description provided for @createLocalBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Local Backup'**
  String get createLocalBackup;

  /// No description provided for @createNewPiece.
  ///
  /// In en, this message translates to:
  /// **'Create New Piece'**
  String get createNewPiece;

  /// Localized message for createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String createdAt(String date);

  /// No description provided for @creatingAutoBackup.
  ///
  /// In en, this message translates to:
  /// **'Creating auto-backup...'**
  String get creatingAutoBackup;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// Localized message for currentStage.
  ///
  /// In en, this message translates to:
  /// **'Current Stage: {stage}'**
  String currentStage(String stage);

  /// No description provided for @customCategoriesAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes, navigate to Settings > Groups to create and manage custom groups for your pieces.'**
  String get customCategoriesAnswer;

  /// No description provided for @customCategoriesQuestion.
  ///
  /// In en, this message translates to:
  /// **'Can I organize my music into custom categories?'**
  String get customCategoriesQuestion;

  /// No description provided for @customColor.
  ///
  /// In en, this message translates to:
  /// **'Custom Color'**
  String get customColor;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @dataBackedUpSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Data backed up successfully!'**
  String get dataBackedUpSuccessfully;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @dataRestoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully!'**
  String get dataRestoredSuccessfully;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateAndTime;

  /// Localized message for daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @defaultColor.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultColor;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteBookmark.
  ///
  /// In en, this message translates to:
  /// **'Delete bookmark'**
  String get deleteBookmark;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete Confirmation'**
  String get deleteConfirmation;

  /// Localized message for deleteFileItemsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count, plural, =1{1 item} other{{count} items}}? This might break links in your music pieces.'**
  String deleteFileItemsConfirmation(int count);

  /// No description provided for @deleteFiles.
  ///
  /// In en, this message translates to:
  /// **'Delete Files'**
  String get deleteFiles;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// Localized message for deleteGroupConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the group \"{groupName}\"?'**
  String deleteGroupConfirmation(String groupName);

  /// Localized message for deleteGroupWithItemsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the group \"{groupName}\"?\n\nThis group contains {count, plural, =1{1 item} other{{count} items}}. Music pieces associated ONLY with this group will be moved to the \"Ungrouped\" group.'**
  String deleteGroupWithItemsConfirmation(String groupName, int count);

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get deleteItem;

  /// No description provided for @deleteItems.
  ///
  /// In en, this message translates to:
  /// **'Delete Items?'**
  String get deleteItems;

  /// No description provided for @deleteLogFile.
  ///
  /// In en, this message translates to:
  /// **'Delete Log File?'**
  String get deleteLogFile;

  /// No description provided for @deleteLogs.
  ///
  /// In en, this message translates to:
  /// **'Delete Logs'**
  String get deleteLogs;

  /// No description provided for @deleteLogs2.
  ///
  /// In en, this message translates to:
  /// **'Delete Logs?'**
  String get deleteLogs2;

  /// No description provided for @deleteMediaItem.
  ///
  /// In en, this message translates to:
  /// **'Delete media item'**
  String get deleteMediaItem;

  /// No description provided for @deleteMusicPiece.
  ///
  /// In en, this message translates to:
  /// **'Delete Music Piece'**
  String get deleteMusicPiece;

  /// Localized message for deleteNamedItem.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"'**
  String deleteNamedItem(String name);

  /// No description provided for @deletePracticeSession.
  ///
  /// In en, this message translates to:
  /// **'Delete Practice Session'**
  String get deletePracticeSession;

  /// Localized message for deleteSelectedItemsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count, plural, =1{1 selected item} other{{count} selected items}}?'**
  String deleteSelectedItemsConfirmation(int count);

  /// No description provided for @deleteTag.
  ///
  /// In en, this message translates to:
  /// **'Delete Tag'**
  String get deleteTag;

  /// No description provided for @deleteTagGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Tag Group'**
  String get deleteTagGroup;

  /// No description provided for @deleteTagGroup2.
  ///
  /// In en, this message translates to:
  /// **'Delete tag group'**
  String get deleteTagGroup2;

  /// Localized message for deleteTagGroupConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the tag group \"{groupName}\" and remove it from all pieces?'**
  String deleteTagGroupConfirmation(String groupName);

  /// No description provided for @deny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get deny;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @developedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by'**
  String get developedBy;

  /// No description provided for @developerTools.
  ///
  /// In en, this message translates to:
  /// **'Developer Tools'**
  String get developerTools;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @displayOptions.
  ///
  /// In en, this message translates to:
  /// **'Display Options'**
  String get displayOptions;

  /// No description provided for @doNotShowGroupsWithNoMatchingPieces.
  ///
  /// In en, this message translates to:
  /// **'Do not show groups with no matching pieces'**
  String get doNotShowGroupsWithNoMatchingPieces;

  /// No description provided for @documentsRepertoireApp.
  ///
  /// In en, this message translates to:
  /// **'Documents/RepertoireApp'**
  String get documentsRepertoireApp;

  /// No description provided for @doubleTapNameToEdit.
  ///
  /// In en, this message translates to:
  /// **'(Double tap name to edit)'**
  String get doubleTapNameToEdit;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// Localized message for durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}}'**
  String durationHours(int hours);

  /// Localized message for durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}} {minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String durationHoursMinutes(int hours, int minutes);

  /// Localized message for durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String durationMinutes(int minutes);

  /// No description provided for @durationMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes)'**
  String get durationMinutesLabel;

  /// No description provided for @eG30.
  ///
  /// In en, this message translates to:
  /// **'e.g., 30'**
  String get eG30;

  /// No description provided for @eGWorkedOnDynamicsFocusedOnDifficultPassages.
  ///
  /// In en, this message translates to:
  /// **'e.g., Worked on dynamics, focused on difficult passages'**
  String get eGWorkedOnDynamicsFocusedOnDifficultPassages;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editGroupName.
  ///
  /// In en, this message translates to:
  /// **'Edit Group Name'**
  String get editGroupName;

  /// No description provided for @editPiece.
  ///
  /// In en, this message translates to:
  /// **'Edit Piece'**
  String get editPiece;

  /// No description provided for @editPracticeSession.
  ///
  /// In en, this message translates to:
  /// **'Edit Practice Session'**
  String get editPracticeSession;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @enableAutomaticBackups.
  ///
  /// In en, this message translates to:
  /// **'Enable Automatic Backups'**
  String get enableAutomaticBackups;

  /// No description provided for @enableDebugLogs.
  ///
  /// In en, this message translates to:
  /// **'Enable Debug Logs'**
  String get enableDebugLogs;

  /// No description provided for @enablePracticeTracking.
  ///
  /// In en, this message translates to:
  /// **'Enable Practice Tracking'**
  String get enablePracticeTracking;

  /// No description provided for @enterFilterName.
  ///
  /// In en, this message translates to:
  /// **'Enter filter name'**
  String get enterFilterName;

  /// No description provided for @enterTitleForTheNewPiece.
  ///
  /// In en, this message translates to:
  /// **'Enter title for the new piece'**
  String get enterTitleForTheNewPiece;

  /// Localized message for errorAddingGroup.
  ///
  /// In en, this message translates to:
  /// **'Error adding group: {error}'**
  String errorAddingGroup(String error);

  /// Shown when shared media cannot be added to a piece.
  ///
  /// In en, this message translates to:
  /// **'Error adding media: {error}'**
  String errorAddingMedia(String error);

  /// Shown after shared media is added to an existing piece.
  ///
  /// In en, this message translates to:
  /// **'Media added to \"{title}\"'**
  String mediaAddedToPiece(String title);

  /// Shown after creating a piece from shared media.
  ///
  /// In en, this message translates to:
  /// **'New piece \"{title}\" created with shared media'**
  String newPieceCreatedWithSharedMedia(String title);

  /// No description provided for @repertoireAppDebugLog.
  ///
  /// In en, this message translates to:
  /// **'Repertoire app debug log'**
  String get repertoireAppDebugLog;

  /// No description provided for @sharedMedia.
  ///
  /// In en, this message translates to:
  /// **'Shared Media'**
  String get sharedMedia;

  /// Localized message for errorChangingStorageFolder.
  ///
  /// In en, this message translates to:
  /// **'Error changing storage folder: {error}'**
  String errorChangingStorageFolder(String error);

  /// Localized message for errorDeletingGroup.
  ///
  /// In en, this message translates to:
  /// **'Error deleting group: {error}'**
  String errorDeletingGroup(String error);

  /// Localized message for errorDeletingLogFile.
  ///
  /// In en, this message translates to:
  /// **'Error deleting log file: {error}'**
  String errorDeletingLogFile(String error);

  /// Localized message for errorDeletingLogs.
  ///
  /// In en, this message translates to:
  /// **'Error deleting logs: {error}'**
  String errorDeletingLogs(String error);

  /// Localized message for errorDeletingMusicPieces.
  ///
  /// In en, this message translates to:
  /// **'Error deleting music pieces: {error}'**
  String errorDeletingMusicPieces(String error);

  /// Localized message for errorDeletingPracticeSession.
  ///
  /// In en, this message translates to:
  /// **'Error deleting practice session: {error}'**
  String errorDeletingPracticeSession(String error);

  /// Localized message for errorDuplicatingMusicPiece.
  ///
  /// In en, this message translates to:
  /// **'Error duplicating music piece: {error}'**
  String errorDuplicatingMusicPiece(String error);

  /// Localized message for errorExportingBackup.
  ///
  /// In en, this message translates to:
  /// **'Error exporting backup: {error}'**
  String errorExportingBackup(String error);

  /// Localized message for errorFetchingThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Error fetching thumbnail: {error}'**
  String errorFetchingThumbnail(String error);

  /// Localized message for errorGeneratingThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Error generating thumbnail: {error}'**
  String errorGeneratingThumbnail(String error);

  /// Localized message for errorInitializingAudio.
  ///
  /// In en, this message translates to:
  /// **'Error initializing audio: {error}'**
  String errorInitializingAudio(String error);

  /// Localized message for errorInitializingPlayer.
  ///
  /// In en, this message translates to:
  /// **'Error initializing player: {error}'**
  String errorInitializingPlayer(String error);

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading'**
  String get errorLoading;

  /// Localized message for errorLoadingGroups.
  ///
  /// In en, this message translates to:
  /// **'Error loading groups: {error}'**
  String errorLoadingGroups(String error);

  /// Localized message for errorLoggingPracticeSession.
  ///
  /// In en, this message translates to:
  /// **'Error logging practice session: {error}'**
  String errorLoggingPracticeSession(String error);

  /// Localized message for errorPerformingCleanup.
  ///
  /// In en, this message translates to:
  /// **'Error performing cleanup: {error}'**
  String errorPerformingCleanup(String error);

  /// Localized message for errorPlayingAudio.
  ///
  /// In en, this message translates to:
  /// **'Error playing audio: {error}'**
  String errorPlayingAudio(String error);

  /// Localized message for errorProcessingFile.
  ///
  /// In en, this message translates to:
  /// **'Error processing {fileName}: {error}'**
  String errorProcessingFile(String fileName, String error);

  /// Localized message for errorSavingGroupOrder.
  ///
  /// In en, this message translates to:
  /// **'Error saving group order: {error}'**
  String errorSavingGroupOrder(String error);

  /// Localized message for errorSavingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings: {error}'**
  String errorSavingSettings(String error);

  /// Localized message for errorScanningUnusedMedia.
  ///
  /// In en, this message translates to:
  /// **'Error scanning for unused media: {error}'**
  String errorScanningUnusedMedia(String error);

  /// Localized message for errorSharing.
  ///
  /// In en, this message translates to:
  /// **'Error sharing: {error}'**
  String errorSharing(String error);

  /// Localized message for errorTogglingGroupVisibility.
  ///
  /// In en, this message translates to:
  /// **'Error toggling group visibility: {error}'**
  String errorTogglingGroupVisibility(String error);

  /// Localized message for errorUpdatingGroup.
  ///
  /// In en, this message translates to:
  /// **'Error updating group: {error}'**
  String errorUpdatingGroup(String error);

  /// Localized message for errorUpdatingPracticeSession.
  ///
  /// In en, this message translates to:
  /// **'Error updating practice session: {error}'**
  String errorUpdatingPracticeSession(String error);

  /// Localized message for errorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithDetails(String error);

  /// No description provided for @errorsEncountered.
  ///
  /// In en, this message translates to:
  /// **'Errors encountered:'**
  String get errorsEncountered;

  /// No description provided for @existingBackupFound.
  ///
  /// In en, this message translates to:
  /// **'Existing Backup Found'**
  String get existingBackupFound;

  /// No description provided for @fDRoid.
  ///
  /// In en, this message translates to:
  /// **'F-Droid'**
  String get fDRoid;

  /// No description provided for @fDroidOrgMyrepertoirapp.
  ///
  /// In en, this message translates to:
  /// **'f-droid.org/.../myrepertoirapp'**
  String get fDroidOrgMyrepertoirapp;

  /// Localized message for failedToDeleteFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete {fileName}: {error}'**
  String failedToDeleteFile(String fileName, String error);

  /// No description provided for @failedToFetchThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch thumbnail.'**
  String get failedToFetchThumbnail;

  /// No description provided for @failedToGeneratePdfThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate PDF thumbnail.'**
  String get failedToGeneratePdfThumbnail;

  /// No description provided for @failedToGenerateVideoThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate video thumbnail.'**
  String get failedToGenerateVideoThumbnail;

  /// No description provided for @failedToInitializeBackupSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize backup settings'**
  String get failedToInitializeBackupSettings;

  /// Localized message for failedToLoadGroups.
  ///
  /// In en, this message translates to:
  /// **'Failed to load groups: {error}'**
  String failedToLoadGroups(String error);

  /// Localized message for failedToLoadMusicPieces.
  ///
  /// In en, this message translates to:
  /// **'Failed to load music pieces: {error}'**
  String failedToLoadMusicPieces(String error);

  /// Localized message for failedToUpdateImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to update image: {error}'**
  String failedToUpdateImage(String error);

  /// No description provided for @fetching.
  ///
  /// In en, this message translates to:
  /// **'Fetching...'**
  String get fetching;

  /// No description provided for @fileCategories.
  ///
  /// In en, this message translates to:
  /// **'File Categories'**
  String get fileCategories;

  /// No description provided for @fileExplorer.
  ///
  /// In en, this message translates to:
  /// **'File Explorer'**
  String get fileExplorer;

  /// No description provided for @fileMissing.
  ///
  /// In en, this message translates to:
  /// **'File missing'**
  String get fileMissing;

  /// No description provided for @fileNotFoundToShare.
  ///
  /// In en, this message translates to:
  /// **'File not found to share.'**
  String get fileNotFoundToShare;

  /// Localized message for fileTypeAndName.
  ///
  /// In en, this message translates to:
  /// **'{fileType} • {fileName}'**
  String fileTypeAndName(String fileType, String fileName);

  /// No description provided for @fileTypes.
  ///
  /// In en, this message translates to:
  /// **'File Types'**
  String get fileTypes;

  /// No description provided for @filesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Files Deleted'**
  String get filesDeleted;

  /// No description provided for @filesToDelete.
  ///
  /// In en, this message translates to:
  /// **'Files to delete'**
  String get filesToDelete;

  /// No description provided for @filterByTags.
  ///
  /// In en, this message translates to:
  /// **'Filter by Tags'**
  String get filterByTags;

  /// No description provided for @filterOptions.
  ///
  /// In en, this message translates to:
  /// **'Filter Options'**
  String get filterOptions;

  /// Localized message for filterSaved.
  ///
  /// In en, this message translates to:
  /// **'Filter \"{name}\" saved'**
  String filterSaved(String name);

  /// No description provided for @foldAll.
  ///
  /// In en, this message translates to:
  /// **'Fold All'**
  String get foldAll;

  /// No description provided for @folderSelectionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Folder selection cancelled'**
  String get folderSelectionCancelled;

  /// No description provided for @folderSelectionCancelled2.
  ///
  /// In en, this message translates to:
  /// **'Folder selection cancelled.'**
  String get folderSelectionCancelled2;

  /// No description provided for @forward1sHoldFor50msFineSkip.
  ///
  /// In en, this message translates to:
  /// **'Forward 1s (Hold for 50ms fine skip)'**
  String get forward1sHoldFor50msFineSkip;

  /// No description provided for @forward1sHoldForFrameSkip.
  ///
  /// In en, this message translates to:
  /// **'Forward 1s (Hold for frame skip)'**
  String get forward1sHoldForFrameSkip;

  /// No description provided for @forward5s.
  ///
  /// In en, this message translates to:
  /// **'Forward 5s'**
  String get forward5s;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @functionality.
  ///
  /// In en, this message translates to:
  /// **'Functionality'**
  String get functionality;

  /// No description provided for @galleryLayout.
  ///
  /// In en, this message translates to:
  /// **'Gallery Layout'**
  String get galleryLayout;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @getPdfThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Get PDF thumbnail'**
  String get getPdfThumbnail;

  /// No description provided for @getVideoThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Get video thumbnail'**
  String get getVideoThumbnail;

  /// No description provided for @github.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get github;

  /// No description provided for @githubComAdithyaJayanMyrepertoirapp.
  ///
  /// In en, this message translates to:
  /// **'github.com/Adithya-Jayan/MyRepertoirApp'**
  String get githubComAdithyaJayanMyrepertoirapp;

  /// No description provided for @githubComMyrepertoirapp.
  ///
  /// In en, this message translates to:
  /// **'github.com/.../MyRepertoirApp'**
  String get githubComMyrepertoirapp;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @goToPage.
  ///
  /// In en, this message translates to:
  /// **'Go to Page'**
  String get goToPage;

  /// No description provided for @gradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get gradient;

  /// No description provided for @gradientOverlay.
  ///
  /// In en, this message translates to:
  /// **'Gradient Overlay'**
  String get gradientOverlay;

  /// No description provided for @grant.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get grant;

  /// No description provided for @groupByPiece.
  ///
  /// In en, this message translates to:
  /// **'Group by Piece'**
  String get groupByPiece;

  /// No description provided for @groupByType.
  ///
  /// In en, this message translates to:
  /// **'Group by Type'**
  String get groupByType;

  /// Localized message for groupItemCount.
  ///
  /// In en, this message translates to:
  /// **'{groupName} ({count})'**
  String groupItemCount(String groupName, int count);

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// Localized message for groupPieceCount.
  ///
  /// In en, this message translates to:
  /// **'{groupName} ({count})'**
  String groupPieceCount(String groupName, int count);

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @guidesAndTroubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Guides and troubleshooting'**
  String get guidesAndTroubleshooting;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpAndFaq.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get helpAndFaq;

  /// No description provided for @hideEmptyGroups.
  ///
  /// In en, this message translates to:
  /// **'Hide Empty Groups'**
  String get hideEmptyGroups;

  /// No description provided for @hold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get hold;

  /// No description provided for @homeRepertoireApp.
  ///
  /// In en, this message translates to:
  /// **'Home/RepertoireApp'**
  String get homeRepertoireApp;

  /// Localized message for hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @howFindPieceAnswer.
  ///
  /// In en, this message translates to:
  /// **'Use the search bar at the top of the main library screen. You can search by title, artist/composer, or tags.'**
  String get howFindPieceAnswer;

  /// No description provided for @howFindPieceQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I quickly find a specific music piece?'**
  String get howFindPieceQuestion;

  /// No description provided for @howOftenToCreateAutomaticBackups.
  ///
  /// In en, this message translates to:
  /// **'How often to create automatic backups'**
  String get howOftenToCreateAutomaticBackups;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @imageUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Image updated successfully'**
  String get imageUpdatedSuccessfully;

  /// No description provided for @imageViewer.
  ///
  /// In en, this message translates to:
  /// **'Image Viewer'**
  String get imageViewer;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @initializingBackupSettings.
  ///
  /// In en, this message translates to:
  /// **'Initializing backup settings...'**
  String get initializingBackupSettings;

  /// No description provided for @inspiredBy.
  ///
  /// In en, this message translates to:
  /// **'Inspired by'**
  String get inspiredBy;

  /// No description provided for @internalFileExplorer.
  ///
  /// In en, this message translates to:
  /// **'Internal File Explorer'**
  String get internalFileExplorer;

  /// No description provided for @internalStorageRepertoireApp.
  ///
  /// In en, this message translates to:
  /// **'Internal Storage/RepertoireApp'**
  String get internalStorageRepertoireApp;

  /// Localized message for invalidAudioFileType.
  ///
  /// In en, this message translates to:
  /// **'Invalid audio file type. Supported: {extensions}'**
  String invalidAudioFileType(String extensions);

  /// No description provided for @itemNameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An item with that name already exists.'**
  String get itemNameAlreadyExists;

  /// Localized message for itemsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String itemsSelected(int count);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @keepTrackOfSessionsAndStatus.
  ///
  /// In en, this message translates to:
  /// **'Keep track of sessions and status'**
  String get keepTrackOfSessionsAndStatus;

  /// No description provided for @lastAutomaticBackup.
  ///
  /// In en, this message translates to:
  /// **'Last Automatic Backup'**
  String get lastAutomaticBackup;

  /// No description provided for @lastPracticed.
  ///
  /// In en, this message translates to:
  /// **'Last Practiced'**
  String get lastPracticed;

  /// Localized message for lastPracticedAt.
  ///
  /// In en, this message translates to:
  /// **'Last practiced: {date}'**
  String lastPracticedAt(String date);

  /// Localized message for lastPracticedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Last practiced: {count, plural, =1{1 day ago} other{{count} days ago}}'**
  String lastPracticedDaysAgo(int count);

  /// No description provided for @lastPracticedToday.
  ///
  /// In en, this message translates to:
  /// **'Last practiced: Today'**
  String get lastPracticedToday;

  /// No description provided for @lastPracticedYesterday.
  ///
  /// In en, this message translates to:
  /// **'Last practiced: Yesterday'**
  String get lastPracticedYesterday;

  /// No description provided for @learningProgress.
  ///
  /// In en, this message translates to:
  /// **'Learning Progress'**
  String get learningProgress;

  /// No description provided for @letSGetYourRepertoireSetUpYouCanAlwaysChangeThese.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get your repertoire set up. You can always change these settings later.'**
  String get letSGetYourRepertoireSetUpYouCanAlwaysChangeThese;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @lightPink.
  ///
  /// In en, this message translates to:
  /// **'Light Pink'**
  String get lightPink;

  /// No description provided for @lightSalmon.
  ///
  /// In en, this message translates to:
  /// **'Light Salmon'**
  String get lightSalmon;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @localVideo.
  ///
  /// In en, this message translates to:
  /// **'Local Video'**
  String get localVideo;

  /// No description provided for @logFileDeleted.
  ///
  /// In en, this message translates to:
  /// **'Log file deleted.'**
  String get logFileDeleted;

  /// No description provided for @logPractice.
  ///
  /// In en, this message translates to:
  /// **'Log Practice'**
  String get logPractice;

  /// No description provided for @loggingAndDeveloperOptions.
  ///
  /// In en, this message translates to:
  /// **'Logging and developer options'**
  String get loggingAndDeveloperOptions;

  /// No description provided for @logsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Logs deleted.'**
  String get logsDeleted;

  /// No description provided for @longOverdue.
  ///
  /// In en, this message translates to:
  /// **'Long overdue'**
  String get longOverdue;

  /// No description provided for @manageAndReorderGroups.
  ///
  /// In en, this message translates to:
  /// **'Manage and reorder groups'**
  String get manageAndReorderGroups;

  /// Localized message for manageFilter.
  ///
  /// In en, this message translates to:
  /// **'Manage Filter: {name}'**
  String manageFilter(String name);

  /// No description provided for @manageGroups.
  ///
  /// In en, this message translates to:
  /// **'Manage Groups'**
  String get manageGroups;

  /// No description provided for @manageTags.
  ///
  /// In en, this message translates to:
  /// **'Manage Tags'**
  String get manageTags;

  /// No description provided for @manualBackupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Manual Backup & Restore'**
  String get manualBackupAndRestore;

  /// No description provided for @manuallyTriggerAnAutomaticBackup.
  ///
  /// In en, this message translates to:
  /// **'Manually trigger an automatic backup'**
  String get manuallyTriggerAnAutomaticBackup;

  /// No description provided for @markdownContent.
  ///
  /// In en, this message translates to:
  /// **'Markdown Content'**
  String get markdownContent;

  /// No description provided for @markdownText.
  ///
  /// In en, this message translates to:
  /// **'Markdown Text'**
  String get markdownText;

  /// No description provided for @maxCount.
  ///
  /// In en, this message translates to:
  /// **'Max Count'**
  String get maxCount;

  /// No description provided for @maximumNumberOfAutomaticBackupsToRetain.
  ///
  /// In en, this message translates to:
  /// **'Maximum number of automatic backups to retain'**
  String get maximumNumberOfAutomaticBackupsToRetain;

  /// No description provided for @media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get media;

  /// No description provided for @mediaName.
  ///
  /// In en, this message translates to:
  /// **'Media Name'**
  String get mediaName;

  /// No description provided for @midiChannelNames.
  ///
  /// In en, this message translates to:
  /// **'MIDI Channel Names'**
  String get midiChannelNames;

  /// Localized message for midiChannelNumber.
  ///
  /// In en, this message translates to:
  /// **'Ch {number}:'**
  String midiChannelNumber(int number);

  /// No description provided for @midiDesktopUnsupported.
  ///
  /// In en, this message translates to:
  /// **'MIDI playback is currently not supported on desktop platforms.'**
  String get midiDesktopUnsupported;

  /// Localized message for midiFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'MIDI file not found at {path}'**
  String midiFileNotFound(String path);

  /// No description provided for @midi.
  ///
  /// In en, this message translates to:
  /// **'MIDI'**
  String get midi;

  /// No description provided for @midiPlaybackIsNotSupportedOnWeb.
  ///
  /// In en, this message translates to:
  /// **'MIDI playback is not supported on Web.'**
  String get midiPlaybackIsNotSupportedOnWeb;

  /// No description provided for @mihon.
  ///
  /// In en, this message translates to:
  /// **'Mihon'**
  String get mihon;

  /// No description provided for @mintGreen.
  ///
  /// In en, this message translates to:
  /// **'Mint Green'**
  String get mintGreen;

  /// Localized message for minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String minutesAgo(int count);

  /// Localized message for missingBackupWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: Last backup file missing (expected at {date}). Creating new backup.'**
  String missingBackupWarning(String date);

  /// No description provided for @modifyGroup.
  ///
  /// In en, this message translates to:
  /// **'Modify Group'**
  String get modifyGroup;

  /// No description provided for @modifyGroups.
  ///
  /// In en, this message translates to:
  /// **'Modify Groups'**
  String get modifyGroups;

  /// No description provided for @musicPieceUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Music piece updated successfully.'**
  String get musicPieceUpdatedSuccessfully;

  /// No description provided for @musicPieces.
  ///
  /// In en, this message translates to:
  /// **'Music Pieces'**
  String get musicPieces;

  /// No description provided for @musicRepertoireApp.
  ///
  /// In en, this message translates to:
  /// **'Music Repertoire App'**
  String get musicRepertoireApp;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get needsAttention;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @neverPracticed.
  ///
  /// In en, this message translates to:
  /// **'Never practiced'**
  String get neverPracticed;

  /// No description provided for @newName.
  ///
  /// In en, this message translates to:
  /// **'New Name'**
  String get newName;

  /// No description provided for @newPieceTitle.
  ///
  /// In en, this message translates to:
  /// **'New Piece Title'**
  String get newPieceTitle;

  /// No description provided for @newStageName.
  ///
  /// In en, this message translates to:
  /// **'New Stage Name'**
  String get newStageName;

  /// No description provided for @newTagName.
  ///
  /// In en, this message translates to:
  /// **'New Tag Name'**
  String get newTagName;

  /// No description provided for @newUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'New Update Available!'**
  String get newUpdateAvailable;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noAppWasFoundToOpenTheLogFileWouldYouLike.
  ///
  /// In en, this message translates to:
  /// **'No app was found to open the log file. Would you like to share it instead?'**
  String get noAppWasFoundToOpenTheLogFileWouldYouLike;

  /// No description provided for @noAutomaticBackupsFound.
  ///
  /// In en, this message translates to:
  /// **'No automatic backups found.'**
  String get noAutomaticBackupsFound;

  /// No description provided for @noBookmarksAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks added yet'**
  String get noBookmarksAddedYet;

  /// No description provided for @noContributorsFound.
  ///
  /// In en, this message translates to:
  /// **'No contributors found.'**
  String get noContributorsFound;

  /// No description provided for @noDurationRecorded.
  ///
  /// In en, this message translates to:
  /// **'No duration recorded'**
  String get noDurationRecorded;

  /// No description provided for @noLogFileFound.
  ///
  /// In en, this message translates to:
  /// **'No log file found.'**
  String get noLogFileFound;

  /// No description provided for @noPiecesFound.
  ///
  /// In en, this message translates to:
  /// **'No pieces found.'**
  String get noPiecesFound;

  /// No description provided for @noPracticeSessionsRecordedYetTapThePlusButtonToAddYour.
  ///
  /// In en, this message translates to:
  /// **'No practice sessions recorded yet.\nTap the + button to add your first practice session.'**
  String get noPracticeSessionsRecordedYetTapThePlusButtonToAddYour;

  /// No description provided for @noShareableFilesSelected.
  ///
  /// In en, this message translates to:
  /// **'No shareable files selected.'**
  String get noShareableFilesSelected;

  /// No description provided for @noStagesDefined.
  ///
  /// In en, this message translates to:
  /// **'No stages defined'**
  String get noStagesDefined;

  /// No description provided for @noStorageLocationSet.
  ///
  /// In en, this message translates to:
  /// **'No storage location set'**
  String get noStorageLocationSet;

  /// No description provided for @noTagFiltersActive.
  ///
  /// In en, this message translates to:
  /// **'No tag filters active'**
  String get noTagFiltersActive;

  /// No description provided for @noTagGroupsFoundInYourLibrary.
  ///
  /// In en, this message translates to:
  /// **'No tag groups found in your library.'**
  String get noTagGroupsFoundInYourLibrary;

  /// No description provided for @noTagsInThisGroup.
  ///
  /// In en, this message translates to:
  /// **'No tags in this group.'**
  String get noTagsInThisGroup;

  /// No description provided for @noUnusedFilesFoundToCleanUp.
  ///
  /// In en, this message translates to:
  /// **'No unused files found to clean up.'**
  String get noUnusedFilesFoundToCleanUp;

  /// No description provided for @noVisibleGroups.
  ///
  /// In en, this message translates to:
  /// **'No visible groups.'**
  String get noVisibleGroups;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @notInLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Not in last 30 days'**
  String get notInLast30Days;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @noteFDRoidMayTakeAFewDaysToReflectThe.
  ///
  /// In en, this message translates to:
  /// **'Note: F-Droid may take a few days to reflect the new version.'**
  String get noteFDRoidMayTakeAFewDaysToReflectThe;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @notifyNewReleases.
  ///
  /// In en, this message translates to:
  /// **'Notify New Releases'**
  String get notifyNewReleases;

  /// No description provided for @numberOfBackupsToKeep.
  ///
  /// In en, this message translates to:
  /// **'Number of Backups to Keep'**
  String get numberOfBackupsToKeep;

  /// Localized message for numberedStage.
  ///
  /// In en, this message translates to:
  /// **'{number}. {stage}'**
  String numberedStage(int number, String stage);

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open Link'**
  String get openLink;

  /// No description provided for @openLogs.
  ///
  /// In en, this message translates to:
  /// **'Open Logs'**
  String get openLogs;

  /// No description provided for @openingFolderSelector.
  ///
  /// In en, this message translates to:
  /// **'Opening folder selector...'**
  String get openingFolderSelector;

  /// No description provided for @organizeYourMusicPiecesAttachMediaAndTrackYourPracticeJourney.
  ///
  /// In en, this message translates to:
  /// **'Organize your music pieces, attach media, and track your practice journey.'**
  String get organizeYourMusicPiecesAttachMediaAndTrackYourPracticeJourney;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @outline.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get outline;

  /// No description provided for @outlineText.
  ///
  /// In en, this message translates to:
  /// **'Outline Text'**
  String get outlineText;

  /// Localized message for pageIndicator.
  ///
  /// In en, this message translates to:
  /// **'{currentPage} / {totalPages}'**
  String pageIndicator(int currentPage, int totalPages);

  /// Localized message for pageNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter page number (1-{totalPages})'**
  String pageNumberHint(int totalPages);

  /// No description provided for @partialSuccess.
  ///
  /// In en, this message translates to:
  /// **'Partial Success'**
  String get partialSuccess;

  /// No description provided for @pathOrUrl.
  ///
  /// In en, this message translates to:
  /// **'Path or URL'**
  String get pathOrUrl;

  /// Localized message for pathValue.
  ///
  /// In en, this message translates to:
  /// **'Path: {path}'**
  String pathValue(String path);

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @pdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdf;

  /// No description provided for @pdfFilePathIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'PDF file path is empty'**
  String get pdfFilePathIsEmpty;

  /// No description provided for @pdfThumbnailGeneratedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PDF thumbnail generated successfully!'**
  String get pdfThumbnailGeneratedSuccessfully;

  /// No description provided for @pdfViewer.
  ///
  /// In en, this message translates to:
  /// **'PDF Viewer'**
  String get pdfViewer;

  /// No description provided for @pdfs.
  ///
  /// In en, this message translates to:
  /// **'PDFs'**
  String get pdfs;

  /// No description provided for @personalization.
  ///
  /// In en, this message translates to:
  /// **'Personalization'**
  String get personalization;

  /// No description provided for @percentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get percentage;

  /// No description provided for @physicalView.
  ///
  /// In en, this message translates to:
  /// **'Physical View'**
  String get physicalView;

  /// No description provided for @pieceDuplicatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Piece duplicated successfully'**
  String get pieceDuplicatedSuccessfully;

  /// No description provided for @pitch.
  ///
  /// In en, this message translates to:
  /// **'Pitch:'**
  String get pitch;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get playbackSpeed;

  /// No description provided for @pleaseEnterATitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterATitle;

  /// No description provided for @pleaseGenerateAThumbnailFirst.
  ///
  /// In en, this message translates to:
  /// **'Please generate a thumbnail first.'**
  String get pleaseGenerateAThumbnailFirst;

  /// No description provided for @pleaseUseTheAndroidWindowsOrLinuxVersionForMidiSupport.
  ///
  /// In en, this message translates to:
  /// **'Please use the Android, Windows, or Linux version for MIDI support.'**
  String get pleaseUseTheAndroidWindowsOrLinuxVersionForMidiSupport;

  /// Localized message for practiceCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Practice count: {count}'**
  String practiceCountLabel(int count);

  /// Localized message for practiceLogsForPiece.
  ///
  /// In en, this message translates to:
  /// **'Practice Logs - {pieceTitle}'**
  String practiceLogsForPiece(String pieceTitle);

  /// No description provided for @practiceNotes.
  ///
  /// In en, this message translates to:
  /// **'Practice Notes'**
  String get practiceNotes;

  /// No description provided for @practiceOptions.
  ///
  /// In en, this message translates to:
  /// **'Practice Options'**
  String get practiceOptions;

  /// No description provided for @practiceSessionDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Practice session deleted successfully'**
  String get practiceSessionDeletedSuccessfully;

  /// No description provided for @practiceSessionLoggedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Practice session logged successfully'**
  String get practiceSessionLoggedSuccessfully;

  /// No description provided for @practiceSessionUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Practice session updated successfully'**
  String get practiceSessionUpdatedSuccessfully;

  /// No description provided for @practiceStagesAndStatistics.
  ///
  /// In en, this message translates to:
  /// **'Practice stages and statistics'**
  String get practiceStagesAndStatistics;

  /// No description provided for @practiceStatus.
  ///
  /// In en, this message translates to:
  /// **'Practice Status'**
  String get practiceStatus;

  /// No description provided for @practiceSummary.
  ///
  /// In en, this message translates to:
  /// **'Practice Summary'**
  String get practiceSummary;

  /// No description provided for @practiceTimeStats.
  ///
  /// In en, this message translates to:
  /// **'Practice Time Stats'**
  String get practiceTimeStats;

  /// No description provided for @practiceTracking.
  ///
  /// In en, this message translates to:
  /// **'Practice Tracking'**
  String get practiceTracking;

  /// No description provided for @practicedRecently.
  ///
  /// In en, this message translates to:
  /// **'Practiced recently'**
  String get practicedRecently;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// Localized message for progressPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String progressPercent(int value);

  /// No description provided for @protectAndSyncYourData.
  ///
  /// In en, this message translates to:
  /// **'Protect and sync your data'**
  String get protectAndSyncYourData;

  /// No description provided for @purgeUnusedMedia.
  ///
  /// In en, this message translates to:
  /// **'Purge Unused Media'**
  String get purgeUnusedMedia;

  /// No description provided for @purging.
  ///
  /// In en, this message translates to:
  /// **'Purging...'**
  String get purging;

  /// No description provided for @quickFilters.
  ///
  /// In en, this message translates to:
  /// **'Quick Filters'**
  String get quickFilters;

  /// No description provided for @recentlyPracticed.
  ///
  /// In en, this message translates to:
  /// **'Recently practiced'**
  String get recentlyPracticed;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @releaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Release Notes'**
  String get releaseNotes;

  /// No description provided for @removeMediaFilesNoLongerReferenced.
  ///
  /// In en, this message translates to:
  /// **'Remove media files no longer referenced'**
  String get removeMediaFilesNoLongerReferenced;

  /// Localized message for removeTagFromGroupConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Remove tag \"{tagName}\" from group \"{groupName}\" across all pieces?'**
  String removeTagFromGroupConfirmation(String tagName, String groupName);

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @renameBookmark.
  ///
  /// In en, this message translates to:
  /// **'Rename Bookmark'**
  String get renameBookmark;

  /// No description provided for @renameFile.
  ///
  /// In en, this message translates to:
  /// **'Rename File'**
  String get renameFile;

  /// Localized message for renameFileWarning.
  ///
  /// In en, this message translates to:
  /// **'WARNING: Renaming files may break links if not handled correctly. The app will attempt to update all piece references automatically.'**
  String get renameFileWarning;

  /// No description provided for @renameGroup.
  ///
  /// In en, this message translates to:
  /// **'Rename Group'**
  String get renameGroup;

  /// Localized message for renameMedia.
  ///
  /// In en, this message translates to:
  /// **'Rename: {name}'**
  String renameMedia(String name);

  /// Localized message for renameNamedItem.
  ///
  /// In en, this message translates to:
  /// **'Rename \"{name}\"'**
  String renameNamedItem(String name);

  /// No description provided for @renameQuickFilter.
  ///
  /// In en, this message translates to:
  /// **'Rename Quick Filter'**
  String get renameQuickFilter;

  /// No description provided for @renameStage.
  ///
  /// In en, this message translates to:
  /// **'Rename Stage'**
  String get renameStage;

  /// No description provided for @renameTagGroup.
  ///
  /// In en, this message translates to:
  /// **'Rename Tag Group'**
  String get renameTagGroup;

  /// Localized message for renameTagInGroup.
  ///
  /// In en, this message translates to:
  /// **'Rename Tag in \"{groupName}\"'**
  String renameTagInGroup(String groupName);

  /// No description provided for @renamedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Renamed successfully.'**
  String get renamedSuccessfully;

  /// No description provided for @reorderMediaAnswer.
  ///
  /// In en, this message translates to:
  /// **'On the Edit Piece screen, use the drag handles on the left of media items to reorder them.'**
  String get reorderMediaAnswer;

  /// No description provided for @reorderMediaQuestion.
  ///
  /// In en, this message translates to:
  /// **'How can I reorder media or tags?'**
  String get reorderMediaQuestion;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetControls.
  ///
  /// In en, this message translates to:
  /// **'Reset Controls'**
  String get resetControls;

  /// No description provided for @resetZoom.
  ///
  /// In en, this message translates to:
  /// **'Reset Zoom'**
  String get resetZoom;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restoreCancelled.
  ///
  /// In en, this message translates to:
  /// **'Restore cancelled.'**
  String get restoreCancelled;

  /// No description provided for @restoreDataFromAPreviousBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore data from a previous backup'**
  String get restoreDataFromAPreviousBackup;

  /// Localized message for restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(String error);

  /// No description provided for @restoreFailedStoragePathNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: Storage path not configured.'**
  String get restoreFailedStoragePathNotConfigured;

  /// No description provided for @restoreFromLocalBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from Local Backup'**
  String get restoreFromLocalBackup;

  /// No description provided for @restoreInProgress.
  ///
  /// In en, this message translates to:
  /// **'Restore in progress...'**
  String get restoreInProgress;

  /// No description provided for @restoreLatest.
  ///
  /// In en, this message translates to:
  /// **'Restore Latest'**
  String get restoreLatest;

  /// No description provided for @restoreThisBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup'**
  String get restoreThisBackup;

  /// No description provided for @restoringBackup.
  ///
  /// In en, this message translates to:
  /// **'Restoring backup...'**
  String get restoringBackup;

  /// No description provided for @restoringData.
  ///
  /// In en, this message translates to:
  /// **'Restoring data...'**
  String get restoringData;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Localized message for revertedToDefaultStoragePath.
  ///
  /// In en, this message translates to:
  /// **'Reverted to default app storage path: {path}'**
  String revertedToDefaultStoragePath(String path);

  /// No description provided for @rewind1sHoldFor50msFineSkip.
  ///
  /// In en, this message translates to:
  /// **'Rewind 1s (Hold for 50ms fine skip)'**
  String get rewind1sHoldFor50msFineSkip;

  /// No description provided for @rewind5s.
  ///
  /// In en, this message translates to:
  /// **'Rewind 5s'**
  String get rewind5s;

  /// No description provided for @root.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get root;

  /// No description provided for @runAutoBackupNow.
  ///
  /// In en, this message translates to:
  /// **'Run Auto-backup Now'**
  String get runAutoBackupNow;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveAll.
  ///
  /// In en, this message translates to:
  /// **'Save All'**
  String get saveAll;

  /// No description provided for @saveAsQuickFilter.
  ///
  /// In en, this message translates to:
  /// **'Save as Quick Filter'**
  String get saveAsQuickFilter;

  /// No description provided for @saveQuickFilter.
  ///
  /// In en, this message translates to:
  /// **'Save Quick Filter'**
  String get saveQuickFilter;

  /// No description provided for @scanResults.
  ///
  /// In en, this message translates to:
  /// **'Scan Results'**
  String get scanResults;

  /// No description provided for @searchExistingPiece.
  ///
  /// In en, this message translates to:
  /// **'Search Existing Piece'**
  String get searchExistingPiece;

  /// No description provided for @searchItems.
  ///
  /// In en, this message translates to:
  /// **'Search items...'**
  String get searchItems;

  /// No description provided for @searchTags.
  ///
  /// In en, this message translates to:
  /// **'Search tags...'**
  String get searchTags;

  /// No description provided for @selectAFolder.
  ///
  /// In en, this message translates to:
  /// **'Select a folder'**
  String get selectAFolder;

  /// No description provided for @selectAFolderWhereTheAppWillStoreItsFiles.
  ///
  /// In en, this message translates to:
  /// **'Select a folder where the app will store its files:'**
  String get selectAFolderWhereTheAppWillStoreItsFiles;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColor;

  /// No description provided for @selectManually.
  ///
  /// In en, this message translates to:
  /// **'Select Manually'**
  String get selectManually;

  /// No description provided for @selectOrderedTags.
  ///
  /// In en, this message translates to:
  /// **'Select Ordered Tags'**
  String get selectOrderedTags;

  /// Localized message for selectedPathNotWritable.
  ///
  /// In en, this message translates to:
  /// **'Selected path is not writable: {error}. Please choose a different location.'**
  String selectedPathNotWritable(String error);

  /// No description provided for @selectedPieceNoLongerExists.
  ///
  /// In en, this message translates to:
  /// **'Selected piece no longer exists.'**
  String get selectedPieceNoLongerExists;

  /// Localized message for semitonesValue.
  ///
  /// In en, this message translates to:
  /// **'{value} st'**
  String semitonesValue(String value);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareExportBackup.
  ///
  /// In en, this message translates to:
  /// **'Share/Export backup'**
  String get shareExportBackup;

  /// No description provided for @shareLogFile.
  ///
  /// In en, this message translates to:
  /// **'Share Log File'**
  String get shareLogFile;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get showAll;

  /// No description provided for @showDotPattern.
  ///
  /// In en, this message translates to:
  /// **'Show Dot Pattern'**
  String get showDotPattern;

  /// No description provided for @showDurationAndStatsInLogs.
  ///
  /// In en, this message translates to:
  /// **'Show duration and stats in logs'**
  String get showDurationAndStatsInLogs;

  /// No description provided for @showGradientBackground.
  ///
  /// In en, this message translates to:
  /// **'Show Gradient Background'**
  String get showGradientBackground;

  /// No description provided for @showLastPracticed.
  ///
  /// In en, this message translates to:
  /// **'Show Last Practiced'**
  String get showLastPracticed;

  /// No description provided for @showPracticeCount.
  ///
  /// In en, this message translates to:
  /// **'Show Practice Count'**
  String get showPracticeCount;

  /// No description provided for @showScrollControlsInTheViewer.
  ///
  /// In en, this message translates to:
  /// **'Show scroll controls in the viewer'**
  String get showScrollControlsInTheViewer;

  /// No description provided for @silver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get silver;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @skyBlue.
  ///
  /// In en, this message translates to:
  /// **'Sky Blue'**
  String get skyBlue;

  /// No description provided for @someThemeChangesMayRequireAnAppRestartToTakeFullEffect.
  ///
  /// In en, this message translates to:
  /// **'Some theme changes may require an app restart to take full effect.'**
  String get someThemeChangesMayRequireAnAppRestartToTakeFullEffect;

  /// No description provided for @sortOptions.
  ///
  /// In en, this message translates to:
  /// **'Sort Options'**
  String get sortOptions;

  /// No description provided for @sourceCodeOnGithub.
  ///
  /// In en, this message translates to:
  /// **'Source Code on GitHub'**
  String get sourceCodeOnGithub;

  /// No description provided for @spaceFreed.
  ///
  /// In en, this message translates to:
  /// **'Space Freed'**
  String get spaceFreed;

  /// No description provided for @spaceToFree.
  ///
  /// In en, this message translates to:
  /// **'Space to free'**
  String get spaceToFree;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed:'**
  String get speed;

  /// Localized message for speedMultiplier.
  ///
  /// In en, this message translates to:
  /// **'{speed}x'**
  String speedMultiplier(String speed);

  /// No description provided for @stageAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Stage already exists'**
  String get stageAlreadyExists;

  /// Localized message for stageDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Stage {number}'**
  String stageDefaultName(int number);

  /// No description provided for @stageNameExists.
  ///
  /// In en, this message translates to:
  /// **'Stage name exists'**
  String get stageNameExists;

  /// No description provided for @stages.
  ///
  /// In en, this message translates to:
  /// **'Stages:'**
  String get stages;

  /// No description provided for @stagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Stages'**
  String get stagesLabel;

  /// No description provided for @stagesForPracticeIndicatorsDragToReorderDoubleTapNameToEdit.
  ///
  /// In en, this message translates to:
  /// **'Stages for practice indicators. Drag to reorder. Double tap name to edit.'**
  String get stagesForPracticeIndicatorsDragToReorderDoubleTapNameToEdit;

  /// No description provided for @startApp.
  ///
  /// In en, this message translates to:
  /// **'Start App'**
  String get startApp;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @storageFolder.
  ///
  /// In en, this message translates to:
  /// **'Storage Folder'**
  String get storageFolder;

  /// No description provided for @storageFolderSelectionNotAvailableOnThisPlatform.
  ///
  /// In en, this message translates to:
  /// **'Storage folder selection not available on this platform'**
  String get storageFolderSelectionNotAvailableOnThisPlatform;

  /// No description provided for @storageFolderUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Storage folder updated successfully'**
  String get storageFolderUpdatedSuccessfully;

  /// No description provided for @storageLocation.
  ///
  /// In en, this message translates to:
  /// **'Storage Location'**
  String get storageLocation;

  /// No description provided for @storagePathUpdated.
  ///
  /// In en, this message translates to:
  /// **'Storage path updated.'**
  String get storagePathUpdated;

  /// Localized message for storagePermissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'This app needs \"All files access\" (Manage External Storage) to manage backups in your chosen external storage folder, and to access media files that you link from arbitrary locations. Without this, backup/restore and linking external media may not work correctly.'**
  String get storagePermissionExplanation;

  /// No description provided for @storagePermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Storage Permission Needed'**
  String get storagePermissionNeeded;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @supportAndResources.
  ///
  /// In en, this message translates to:
  /// **'Support & Resources'**
  String get supportAndResources;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @systemAndMaintenance.
  ///
  /// In en, this message translates to:
  /// **'System & Maintenance'**
  String get systemAndMaintenance;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @tagGroups.
  ///
  /// In en, this message translates to:
  /// **'Tag Groups'**
  String get tagGroups;

  /// No description provided for @tagName.
  ///
  /// In en, this message translates to:
  /// **'Tag Name'**
  String get tagName;

  /// No description provided for @tagNameOrCommaSeparatedList.
  ///
  /// In en, this message translates to:
  /// **'Tag name (or comma-separated list)'**
  String get tagNameOrCommaSeparatedList;

  /// Localized message for tagSetsActive.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 tag set active} other{{count} tag sets active}}'**
  String tagSetsActive(int count);

  /// No description provided for @tagging.
  ///
  /// In en, this message translates to:
  /// **'Tagging'**
  String get tagging;

  /// No description provided for @taggingManagement.
  ///
  /// In en, this message translates to:
  /// **'Tagging Management'**
  String get taggingManagement;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @tagsAndCategories.
  ///
  /// In en, this message translates to:
  /// **'Tags & Categories'**
  String get tagsAndCategories;

  /// No description provided for @tan.
  ///
  /// In en, this message translates to:
  /// **'Tan'**
  String get tan;

  /// No description provided for @tapToEdit.
  ///
  /// In en, this message translates to:
  /// **'(Tap to edit)'**
  String get tapToEdit;

  /// No description provided for @teal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get teal;

  /// No description provided for @textSearch.
  ///
  /// In en, this message translates to:
  /// **'Text Search'**
  String get textSearch;

  /// No description provided for @theAppHasBeenUpdatedCheckTheReleaseNotesOnGithubFor.
  ///
  /// In en, this message translates to:
  /// **'The app has been updated! Check the release notes on GitHub for details.'**
  String get theAppHasBeenUpdatedCheckTheReleaseNotesOnGithubFor;

  /// No description provided for @theFollowingFilesAreNotReferencedByAnyPiecesAndCanBe.
  ///
  /// In en, this message translates to:
  /// **'The following files are not referenced by any pieces and can be safely purged.'**
  String get theFollowingFilesAreNotReferencedByAnyPiecesAndCanBe;

  /// No description provided for @themeColorsAndLayout.
  ///
  /// In en, this message translates to:
  /// **'Theme, colors, and layout'**
  String get themeColorsAndLayout;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @thisActionCannotBeUndoneMakeSureYouHaveABackupBefore.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. Make sure you have a backup before proceeding.'**
  String get thisActionCannotBeUndoneMakeSureYouHaveABackupBefore;

  /// No description provided for @thisGroupIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'This group is empty.'**
  String get thisGroupIsEmpty;

  /// No description provided for @thisWillPermanentlyDeleteUnusedMediaFilesThatAreNoLongerReferenced.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete unused media files that are no longer referenced by any music pieces.'**
  String get thisWillPermanentlyDeleteUnusedMediaFilesThatAreNoLongerReferenced;

  /// No description provided for @thumbnail.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail'**
  String get thumbnail;

  /// No description provided for @thumbnailFetchedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail fetched successfully!'**
  String get thumbnailFetchedSuccessfully;

  /// No description provided for @thumbnailStyle.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail Style'**
  String get thumbnailStyle;

  /// No description provided for @thumbnailWidgetVisibleInEditModeOnly.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail Widget (Visible in Edit Mode only)'**
  String get thumbnailWidgetVisibleInEditModeOnly;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @titleContains.
  ///
  /// In en, this message translates to:
  /// **'Title contains...'**
  String get titleContains;

  /// Localized message for todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String todayAt(String time);

  /// No description provided for @toggleControls.
  ///
  /// In en, this message translates to:
  /// **'Toggle Controls'**
  String get toggleControls;

  /// No description provided for @totalFiles.
  ///
  /// In en, this message translates to:
  /// **'Total Files'**
  String get totalFiles;

  /// No description provided for @totalSessions.
  ///
  /// In en, this message translates to:
  /// **'Total Sessions'**
  String get totalSessions;

  /// No description provided for @totalSize.
  ///
  /// In en, this message translates to:
  /// **'Total Size'**
  String get totalSize;

  /// No description provided for @totalTime.
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get totalTime;

  /// No description provided for @trackControls.
  ///
  /// In en, this message translates to:
  /// **'Track Controls'**
  String get trackControls;

  /// No description provided for @tracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get tracking;

  /// No description provided for @trackingDisabled.
  ///
  /// In en, this message translates to:
  /// **'Tracking Disabled'**
  String get trackingDisabled;

  /// No description provided for @trackingEnabled.
  ///
  /// In en, this message translates to:
  /// **'Tracking Enabled'**
  String get trackingEnabled;

  /// No description provided for @trackingStages.
  ///
  /// In en, this message translates to:
  /// **'Tracking Stages'**
  String get trackingStages;

  /// No description provided for @trans.
  ///
  /// In en, this message translates to:
  /// **'Trans'**
  String get trans;

  /// No description provided for @trueBlackBackgroundInDarkMode.
  ///
  /// In en, this message translates to:
  /// **'True black background in dark mode'**
  String get trueBlackBackgroundInDarkMode;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @ungrouped.
  ///
  /// In en, this message translates to:
  /// **'Ungrouped'**
  String get ungrouped;

  /// Localized message for unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @unknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown Artist'**
  String get unknownArtist;

  /// Localized message for unknownPiece.
  ///
  /// In en, this message translates to:
  /// **'Unknown Piece ({pieceId})'**
  String unknownPiece(String pieceId);

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// No description provided for @unusedFiles.
  ///
  /// In en, this message translates to:
  /// **'Unused Files'**
  String get unusedFiles;

  /// No description provided for @unusedMediaDetails.
  ///
  /// In en, this message translates to:
  /// **'Unused Media Details'**
  String get unusedMediaDetails;

  /// No description provided for @unusedSize.
  ///
  /// In en, this message translates to:
  /// **'Unused Size'**
  String get unusedSize;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @updateAll.
  ///
  /// In en, this message translates to:
  /// **'Update All?'**
  String get updateAll;

  /// Localized message for updateTagGroupColorQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you want to update the color of tag group \"{groupName}\" across all pieces?'**
  String updateTagGroupColorQuestion(String groupName);

  /// Localized message for updatedToVersion.
  ///
  /// In en, this message translates to:
  /// **'Updated to v{version}'**
  String updatedToVersion(String version);

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @updatesAreManagedByTheGooglePlayStore.
  ///
  /// In en, this message translates to:
  /// **'Updates are managed by the Google Play Store.'**
  String get updatesAreManagedByTheGooglePlayStore;

  /// No description provided for @urlIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'URL is empty'**
  String get urlIsEmpty;

  /// No description provided for @useOledBlack.
  ///
  /// In en, this message translates to:
  /// **'Use OLED Black'**
  String get useOledBlack;

  /// No description provided for @useThePlusSignToAddMedia.
  ///
  /// In en, this message translates to:
  /// **'Use the \'+\' sign to add media'**
  String get useThePlusSignToAddMedia;

  /// Localized message for usedInPieces.
  ///
  /// In en, this message translates to:
  /// **'Used in {count, plural, =1{1 piece} other{{count} pieces}}'**
  String usedInPieces(int count);

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @versionAndContributorInfo.
  ///
  /// In en, this message translates to:
  /// **'Version and contributor info'**
  String get versionAndContributorInfo;

  /// Localized message for versionAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available.'**
  String versionAvailable(String version);

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @videoControls.
  ///
  /// In en, this message translates to:
  /// **'Video Controls'**
  String get videoControls;

  /// No description provided for @videoFilePathIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Video file path is empty'**
  String get videoFilePathIsEmpty;

  /// No description provided for @videoThumbnailGeneratedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Video thumbnail generated successfully!'**
  String get videoThumbnailGeneratedSuccessfully;

  /// No description provided for @viewAllContributors.
  ///
  /// In en, this message translates to:
  /// **'View All Contributors'**
  String get viewAllContributors;

  /// No description provided for @viewPdf.
  ///
  /// In en, this message translates to:
  /// **'View PDF'**
  String get viewPdf;

  /// No description provided for @viewUnusedFiles.
  ///
  /// In en, this message translates to:
  /// **'View Unused Files'**
  String get viewUnusedFiles;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @websiteAndDocumentation.
  ///
  /// In en, this message translates to:
  /// **'Website & Documentation'**
  String get websiteAndDocumentation;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// Localized message for whatsNewInVersion.
  ///
  /// In en, this message translates to:
  /// **'What\'s New in v{version}'**
  String whatsNewInVersion(String version);

  /// No description provided for @withinLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Within last 7 days'**
  String get withinLast7Days;

  /// No description provided for @wouldYouLikeToDeleteTheExistingDebugLogs.
  ///
  /// In en, this message translates to:
  /// **'Would you like to delete the existing debug logs?'**
  String get wouldYouLikeToDeleteTheExistingDebugLogs;

  /// No description provided for @yellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get yellow;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @yesDelete.
  ///
  /// In en, this message translates to:
  /// **'Yes, delete'**
  String get yesDelete;

  /// Localized message for yesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday at {time}'**
  String yesterdayAt(String time);

  /// No description provided for @youAreOnTheLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'You are on the latest version.'**
  String get youAreOnTheLatestVersion;

  /// No description provided for @youHaveUnsavedChangesAreYouSureYouWantToDiscardThem.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to discard them?'**
  String get youHaveUnsavedChangesAreYouSureYouWantToDiscardThem;

  /// No description provided for @yourMediaLibraryIsClean.
  ///
  /// In en, this message translates to:
  /// **'Your media library is clean!'**
  String get yourMediaLibraryIsClean;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom In'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom Out'**
  String get zoomOut;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
