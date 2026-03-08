import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ky.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of Strings
/// returned by `Strings.of(context)`.
///
/// Applications need to include `Strings.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: Strings.localizationsDelegates,
///   supportedLocales: Strings.supportedLocales,
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
/// be consistent with the languages listed in the Strings.supportedLocales
/// property.
abstract class Strings {
  Strings(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static Strings of(BuildContext context) {
    return Localizations.of<Strings>(context, Strings)!;
  }

  static const LocalizationsDelegate<Strings> delegate = _StringsDelegate();

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
    Locale('ja'),
    Locale('ky'),
    Locale('ru'),
    Locale('zh')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Picell'**
  String get appName;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Picell'**
  String get aboutTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Picell!'**
  String get welcome;

  /// No description provided for @aboutAppDescription.
  ///
  /// In en, this message translates to:
  /// **'Picell is your gateway to creating amazing pixel art. Whether you\'re a seasoned artist or just starting out, our app provides the tools you need to bring your pixelated visions to life.'**
  String get aboutAppDescription;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Intuitive pixel editing tools, \nCustom color palettes, Layer support for complex artwork, \nAnimation timeline for creating GIFs, \nExport in various formats, \nCommunity sharing and inspiration'**
  String get features;

  /// No description provided for @featuresTitle.
  ///
  /// In en, this message translates to:
  /// **'Key Features:'**
  String get featuresTitle;

  /// No description provided for @visitWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit my website for more information:'**
  String get visitWebsite;

  /// No description provided for @pickAColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get pickAColor;

  /// No description provided for @colorPicker.
  ///
  /// In en, this message translates to:
  /// **'Color Picker'**
  String get colorPicker;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveAs.
  ///
  /// In en, this message translates to:
  /// **'Save As'**
  String get saveAs;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @lineTool.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get lineTool;

  /// No description provided for @rectangleTool.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get rectangleTool;

  /// No description provided for @circleTool.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get circleTool;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @invalidFileContent.
  ///
  /// In en, this message translates to:
  /// **'Invalid file content'**
  String get invalidFileContent;

  /// No description provided for @anErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get anErrorOccurred;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @creatingProject.
  ///
  /// In en, this message translates to:
  /// **'Creating project...'**
  String get creatingProject;

  /// No description provided for @openingProject.
  ///
  /// In en, this message translates to:
  /// **'Opening project...'**
  String get openingProject;

  /// No description provided for @noProjectsFound.
  ///
  /// In en, this message translates to:
  /// **'No projects found'**
  String get noProjectsFound;

  /// No description provided for @createNewProject.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get createNewProject;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete Project'**
  String get deleteProject;

  /// No description provided for @areYouSureWantToDeleteProject.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this project?'**
  String get areYouSureWantToDeleteProject;

  /// No description provided for @renameProject.
  ///
  /// In en, this message translates to:
  /// **'Rename Project'**
  String get renameProject;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectName;

  /// No description provided for @timeAgo.
  ///
  /// In en, this message translates to:
  /// **'{time} ago'**
  String timeAgo(String time);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @frameCount.
  ///
  /// In en, this message translates to:
  /// **'Frame {current}/{total}'**
  String frameCount(int current, int total);

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed:'**
  String get playbackSpeed;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {ms}ms'**
  String duration(int ms);

  /// No description provided for @animationPreview.
  ///
  /// In en, this message translates to:
  /// **'Animation Preview'**
  String get animationPreview;

  /// No description provided for @colorPalette.
  ///
  /// In en, this message translates to:
  /// **'Color Palette'**
  String get colorPalette;

  /// No description provided for @currentColor.
  ///
  /// In en, this message translates to:
  /// **'Current Color'**
  String get currentColor;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @layers.
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get layers;

  /// No description provided for @deleteLayer.
  ///
  /// In en, this message translates to:
  /// **'Delete Layer'**
  String get deleteLayer;

  /// No description provided for @areYouSureWantToDeleteLayer.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this layer?'**
  String get areYouSureWantToDeleteLayer;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get newProject;

  /// No description provided for @template.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get template;

  /// No description provided for @width.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get width;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions;

  /// No description provided for @fileMenu.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get fileMenu;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @signInToSyncProjects.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your projects.'**
  String get signInToSyncProjects;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing In...'**
  String get signingIn;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @feedback_title.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback_title;

  /// No description provided for @feedback_thank_you.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get feedback_thank_you;

  /// No description provided for @feedback_thank_you_message.
  ///
  /// In en, this message translates to:
  /// **'Your opinion is very important to us and will help make the app better.'**
  String get feedback_thank_you_message;

  /// No description provided for @feedback_return.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get feedback_return;

  /// No description provided for @feedback_help_us.
  ///
  /// In en, this message translates to:
  /// **'Help us become better'**
  String get feedback_help_us;

  /// No description provided for @feedback_intro.
  ///
  /// In en, this message translates to:
  /// **'Your opinion is very important for the project development. Please answer a few questions.'**
  String get feedback_intro;

  /// No description provided for @feedback_answered.
  ///
  /// In en, this message translates to:
  /// **'Answered: {count} of {total}'**
  String feedback_answered(int count, int total);

  /// No description provided for @feedback_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get feedback_required;

  /// No description provided for @feedback_sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get feedback_sending;

  /// No description provided for @feedback_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get feedback_send;

  /// No description provided for @feedback_validation_error.
  ///
  /// In en, this message translates to:
  /// **'Please answer all required questions'**
  String get feedback_validation_error;

  /// No description provided for @feedback_very_poor.
  ///
  /// In en, this message translates to:
  /// **'Very poor'**
  String get feedback_very_poor;

  /// No description provided for @feedback_excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get feedback_excellent;

  /// No description provided for @feedback_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get feedback_yes;

  /// No description provided for @feedback_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get feedback_no;

  /// No description provided for @feedback_text_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your answer...'**
  String get feedback_text_placeholder;

  /// No description provided for @feedback_q_satisfaction.
  ///
  /// In en, this message translates to:
  /// **'How satisfied are you with the app?'**
  String get feedback_q_satisfaction;

  /// No description provided for @feedback_q_missing_features.
  ///
  /// In en, this message translates to:
  /// **'What features are you missing?'**
  String get feedback_q_missing_features;

  /// No description provided for @feedback_q_missing_features_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Describe the features you would like to see...'**
  String get feedback_q_missing_features_placeholder;

  /// No description provided for @feedback_q_bug_reports.
  ///
  /// In en, this message translates to:
  /// **'Have you encountered any errors or crashes?'**
  String get feedback_q_bug_reports;

  /// No description provided for @feedback_q_bug_reports_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Describe the problems you encountered...'**
  String get feedback_q_bug_reports_placeholder;

  /// No description provided for @feedback_q_price_satisfaction.
  ///
  /// In en, this message translates to:
  /// **'Are you satisfied with the current app price?'**
  String get feedback_q_price_satisfaction;

  /// No description provided for @feedback_q_price_feedback.
  ///
  /// In en, this message translates to:
  /// **'If not, what price do you consider fair?'**
  String get feedback_q_price_feedback;

  /// No description provided for @feedback_q_price_free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get feedback_q_price_free;

  /// No description provided for @feedback_q_price_up_to_5.
  ///
  /// In en, this message translates to:
  /// **'Up to \$5'**
  String get feedback_q_price_up_to_5;

  /// No description provided for @feedback_q_price_5_to_10.
  ///
  /// In en, this message translates to:
  /// **'\$5 - \$10'**
  String get feedback_q_price_5_to_10;

  /// No description provided for @feedback_q_price_10_to_20.
  ///
  /// In en, this message translates to:
  /// **'\$10 - \$20'**
  String get feedback_q_price_10_to_20;

  /// No description provided for @feedback_q_price_more_20.
  ///
  /// In en, this message translates to:
  /// **'More than \$20'**
  String get feedback_q_price_more_20;

  /// No description provided for @feedback_q_patreon_support.
  ///
  /// In en, this message translates to:
  /// **'Will you support the project on Patreon?'**
  String get feedback_q_patreon_support;

  /// No description provided for @feedback_q_patreon_definitely.
  ///
  /// In en, this message translates to:
  /// **'Yes, definitely'**
  String get feedback_q_patreon_definitely;

  /// No description provided for @feedback_q_patreon_if_exclusive.
  ///
  /// In en, this message translates to:
  /// **'Maybe, if there are exclusive features'**
  String get feedback_q_patreon_if_exclusive;

  /// No description provided for @feedback_q_patreon_if_reasonable.
  ///
  /// In en, this message translates to:
  /// **'Maybe, if the price is reasonable'**
  String get feedback_q_patreon_if_reasonable;

  /// No description provided for @feedback_q_patreon_probably_not.
  ///
  /// In en, this message translates to:
  /// **'Probably not'**
  String get feedback_q_patreon_probably_not;

  /// No description provided for @feedback_q_patreon_no.
  ///
  /// In en, this message translates to:
  /// **'No, not planning to'**
  String get feedback_q_patreon_no;

  /// No description provided for @feedback_q_patreon_tier.
  ///
  /// In en, this message translates to:
  /// **'Which Patreon support tier interests you?'**
  String get feedback_q_patreon_tier;

  /// No description provided for @feedback_q_patreon_tier_3.
  ///
  /// In en, this message translates to:
  /// **'\$3/month - Early access to features'**
  String get feedback_q_patreon_tier_3;

  /// No description provided for @feedback_q_patreon_tier_5.
  ///
  /// In en, this message translates to:
  /// **'\$5/month - + Exclusive themes'**
  String get feedback_q_patreon_tier_5;

  /// No description provided for @feedback_q_patreon_tier_10.
  ///
  /// In en, this message translates to:
  /// **'\$10/month - + Influence on development'**
  String get feedback_q_patreon_tier_10;

  /// No description provided for @feedback_q_usage_frequency.
  ///
  /// In en, this message translates to:
  /// **'How often do you use the app?'**
  String get feedback_q_usage_frequency;

  /// No description provided for @feedback_q_usage_daily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get feedback_q_usage_daily;

  /// No description provided for @feedback_q_usage_several_week.
  ///
  /// In en, this message translates to:
  /// **'Several times a week'**
  String get feedback_q_usage_several_week;

  /// No description provided for @feedback_q_usage_once_week.
  ///
  /// In en, this message translates to:
  /// **'Once a week'**
  String get feedback_q_usage_once_week;

  /// No description provided for @feedback_q_usage_several_month.
  ///
  /// In en, this message translates to:
  /// **'Several times a month'**
  String get feedback_q_usage_several_month;

  /// No description provided for @feedback_q_usage_rarely.
  ///
  /// In en, this message translates to:
  /// **'Rarely'**
  String get feedback_q_usage_rarely;

  /// No description provided for @feedback_q_main_use_case.
  ///
  /// In en, this message translates to:
  /// **'What do you mainly use the app for?'**
  String get feedback_q_main_use_case;

  /// No description provided for @feedback_q_use_pixel_art.
  ///
  /// In en, this message translates to:
  /// **'Creating pixel art'**
  String get feedback_q_use_pixel_art;

  /// No description provided for @feedback_q_use_game_design.
  ///
  /// In en, this message translates to:
  /// **'Game design'**
  String get feedback_q_use_game_design;

  /// No description provided for @feedback_q_use_animation.
  ///
  /// In en, this message translates to:
  /// **'Animation'**
  String get feedback_q_use_animation;

  /// No description provided for @feedback_q_use_hobby.
  ///
  /// In en, this message translates to:
  /// **'Hobby/entertainment'**
  String get feedback_q_use_hobby;

  /// No description provided for @feedback_q_use_professional.
  ///
  /// In en, this message translates to:
  /// **'Professional work'**
  String get feedback_q_use_professional;

  /// No description provided for @feedback_q_use_learning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get feedback_q_use_learning;

  /// No description provided for @feedback_q_additional_feedback.
  ///
  /// In en, this message translates to:
  /// **'Additional comments and suggestions'**
  String get feedback_q_additional_feedback;

  /// No description provided for @feedback_q_additional_feedback_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts about the app...'**
  String get feedback_q_additional_feedback_placeholder;

  /// No description provided for @feedback_q_recommend.
  ///
  /// In en, this message translates to:
  /// **'Would you recommend this app to friends?'**
  String get feedback_q_recommend;

  /// No description provided for @firstFrame.
  ///
  /// In en, this message translates to:
  /// **'First Frame'**
  String get firstFrame;

  /// No description provided for @previousFrame.
  ///
  /// In en, this message translates to:
  /// **'Previous Frame'**
  String get previousFrame;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @nextFrame.
  ///
  /// In en, this message translates to:
  /// **'Next Frame'**
  String get nextFrame;

  /// No description provided for @lastFrame.
  ///
  /// In en, this message translates to:
  /// **'Last Frame'**
  String get lastFrame;

  /// No description provided for @feedback_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'We\'d Love Your Feedback!'**
  String get feedback_dialog_title;

  /// No description provided for @feedback_dialog_description.
  ///
  /// In en, this message translates to:
  /// **'Your opinion matters! Help us make the app better by sharing your thoughts.'**
  String get feedback_dialog_description;

  /// No description provided for @feedback_dialog_benefit_1.
  ///
  /// In en, this message translates to:
  /// **'Share ideas for new features'**
  String get feedback_dialog_benefit_1;

  /// No description provided for @feedback_dialog_benefit_2.
  ///
  /// In en, this message translates to:
  /// **'Report bugs and issues'**
  String get feedback_dialog_benefit_2;

  /// No description provided for @feedback_dialog_benefit_3.
  ///
  /// In en, this message translates to:
  /// **'Help shape the app\'s future'**
  String get feedback_dialog_benefit_3;

  /// No description provided for @feedback_dialog_leave_feedback.
  ///
  /// In en, this message translates to:
  /// **'Leave Feedback'**
  String get feedback_dialog_leave_feedback;

  /// No description provided for @feedback_dialog_maybe_later.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get feedback_dialog_maybe_later;

  /// No description provided for @feedback_dialog_dont_ask.
  ///
  /// In en, this message translates to:
  /// **'Don\'t ask again'**
  String get feedback_dialog_dont_ask;

  /// No description provided for @paletteBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get paletteBasic;

  /// No description provided for @paletteShades.
  ///
  /// In en, this message translates to:
  /// **'Shades'**
  String get paletteShades;

  /// No description provided for @paletteComplementary.
  ///
  /// In en, this message translates to:
  /// **'Complementary'**
  String get paletteComplementary;

  /// No description provided for @paletteAnalogous.
  ///
  /// In en, this message translates to:
  /// **'Analogous'**
  String get paletteAnalogous;

  /// No description provided for @paletteTriadic.
  ///
  /// In en, this message translates to:
  /// **'Triadic'**
  String get paletteTriadic;

  /// No description provided for @paletteMonochromatic.
  ///
  /// In en, this message translates to:
  /// **'Monochromatic'**
  String get paletteMonochromatic;

  /// No description provided for @paletteCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get paletteCustom;

  /// No description provided for @addToCustomPalette.
  ///
  /// In en, this message translates to:
  /// **'Add to custom palette'**
  String get addToCustomPalette;

  /// No description provided for @noCustomColors.
  ///
  /// In en, this message translates to:
  /// **'No custom colors added yet.\nAdd colors using the + button above.'**
  String get noCustomColors;

  /// No description provided for @effects.
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get effects;

  /// No description provided for @editorSettings.
  ///
  /// In en, this message translates to:
  /// **'Editor Settings'**
  String get editorSettings;

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get resetToDefaults;

  /// No description provided for @input.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get input;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @showGrid.
  ///
  /// In en, this message translates to:
  /// **'Show Grid'**
  String get showGrid;

  /// No description provided for @showGridSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display grid lines on canvas'**
  String get showGridSubtitle;

  /// No description provided for @pixelGridOverlay.
  ///
  /// In en, this message translates to:
  /// **'Pixel Grid Overlay'**
  String get pixelGridOverlay;

  /// No description provided for @pixelGridSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show pixel boundaries when zoomed in'**
  String get pixelGridSubtitle;

  /// No description provided for @gridOpacity.
  ///
  /// In en, this message translates to:
  /// **'Grid Opacity'**
  String get gridOpacity;

  /// No description provided for @zoomNavigation.
  ///
  /// In en, this message translates to:
  /// **'Zoom & Navigation'**
  String get zoomNavigation;

  /// No description provided for @zoomSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Zoom Sensitivity'**
  String get zoomSensitivity;

  /// No description provided for @zoomSensitivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How fast pinch-to-zoom responds'**
  String get zoomSensitivitySubtitle;

  /// No description provided for @minZoom.
  ///
  /// In en, this message translates to:
  /// **'Min Zoom'**
  String get minZoom;

  /// No description provided for @maxZoom.
  ///
  /// In en, this message translates to:
  /// **'Max Zoom'**
  String get maxZoom;

  /// No description provided for @gestures.
  ///
  /// In en, this message translates to:
  /// **'Gestures'**
  String get gestures;

  /// No description provided for @twoFingerUndo.
  ///
  /// In en, this message translates to:
  /// **'Two-Finger Tap Undo'**
  String get twoFingerUndo;

  /// No description provided for @twoFingerUndoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick tap with two fingers to undo'**
  String get twoFingerUndoSubtitle;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @stylusMode.
  ///
  /// In en, this message translates to:
  /// **'Stylus Mode'**
  String get stylusMode;

  /// No description provided for @stylusModeSubtitleOn.
  ///
  /// In en, this message translates to:
  /// **'Draw with stylus only • Touch for navigation'**
  String get stylusModeSubtitleOn;

  /// No description provided for @stylusModeSubtitleOff.
  ///
  /// In en, this message translates to:
  /// **'Draw with both touch and stylus'**
  String get stylusModeSubtitleOff;

  /// No description provided for @importImage.
  ///
  /// In en, this message translates to:
  /// **'Import Image'**
  String get importImage;

  /// No description provided for @selectImportOption.
  ///
  /// In en, this message translates to:
  /// **'Select how you want to import your image:'**
  String get selectImportOption;

  /// No description provided for @convertToPixelArt.
  ///
  /// In en, this message translates to:
  /// **'Convert to Pixel Art'**
  String get convertToPixelArt;

  /// No description provided for @convertToPixelArtDescription.
  ///
  /// In en, this message translates to:
  /// **'Import and automatically convert the image to pixel art style on a new layer.'**
  String get convertToPixelArtDescription;

  /// No description provided for @importAsBackground.
  ///
  /// In en, this message translates to:
  /// **'Import as Background'**
  String get importAsBackground;

  /// No description provided for @importAsBackgroundDescription.
  ///
  /// In en, this message translates to:
  /// **'Import the image as-is and use it as a reference background layer.'**
  String get importAsBackgroundDescription;

  /// No description provided for @tinyIcon.
  ///
  /// In en, this message translates to:
  /// **'Tiny Icon'**
  String get tinyIcon;

  /// No description provided for @smallSprite.
  ///
  /// In en, this message translates to:
  /// **'Small Sprite'**
  String get smallSprite;

  /// No description provided for @mediumCharacter.
  ///
  /// In en, this message translates to:
  /// **'Medium Character'**
  String get mediumCharacter;

  /// No description provided for @largeScene.
  ///
  /// In en, this message translates to:
  /// **'Large Scene'**
  String get largeScene;

  /// No description provided for @projectNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a project name'**
  String get projectNameRequired;

  /// No description provided for @templateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a template'**
  String get templateRequired;

  /// No description provided for @planLimitError.
  ///
  /// In en, this message translates to:
  /// **'Your plan is limited to {limit} pixels'**
  String planLimitError(int limit);

  /// No description provided for @widthRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter width'**
  String get widthRequired;

  /// No description provided for @heightRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter height'**
  String get heightRequired;

  /// No description provided for @widthRangeError.
  ///
  /// In en, this message translates to:
  /// **'Width: 1-{max}'**
  String widthRangeError(int max);

  /// No description provided for @heightRangeError.
  ///
  /// In en, this message translates to:
  /// **'Height: 1-{max}'**
  String heightRangeError(int max);

  /// No description provided for @saveImage.
  ///
  /// In en, this message translates to:
  /// **'Save Image'**
  String get saveImage;

  /// No description provided for @png.
  ///
  /// In en, this message translates to:
  /// **'PNG'**
  String get png;

  /// No description provided for @animatedGif.
  ///
  /// In en, this message translates to:
  /// **'Animated GIF'**
  String get animatedGif;

  /// No description provided for @proPlanRequired.
  ///
  /// In en, this message translates to:
  /// **'Pro Plan Required'**
  String get proPlanRequired;

  /// No description provided for @spriteSheet.
  ///
  /// In en, this message translates to:
  /// **'Sprite Sheet'**
  String get spriteSheet;

  /// No description provided for @transparentBackground.
  ///
  /// In en, this message translates to:
  /// **'Transparent Background'**
  String get transparentBackground;

  /// No description provided for @transparent.
  ///
  /// In en, this message translates to:
  /// **'Transparent'**
  String get transparent;

  /// No description provided for @spriteSheetOptions.
  ///
  /// In en, this message translates to:
  /// **'Sprite Sheet Options'**
  String get spriteSheetOptions;

  /// No description provided for @columnsLabel.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get columnsLabel;

  /// No description provided for @spacingPx.
  ///
  /// In en, this message translates to:
  /// **'Spacing (px)'**
  String get spacingPx;

  /// No description provided for @exportSize.
  ///
  /// In en, this message translates to:
  /// **'Export Size'**
  String get exportSize;

  /// No description provided for @scaleWithValues.
  ///
  /// In en, this message translates to:
  /// **'Scale: {scale}x'**
  String scaleWithValues(String scale);

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @editEffect.
  ///
  /// In en, this message translates to:
  /// **'Edit {name} Effect'**
  String editEffect(String name);

  /// No description provided for @applyChanges.
  ///
  /// In en, this message translates to:
  /// **'Apply Changes'**
  String get applyChanges;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @quickPresets.
  ///
  /// In en, this message translates to:
  /// **'Quick Presets'**
  String get quickPresets;

  /// No description provided for @parameters.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get parameters;

  /// No description provided for @previewNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Preview not available'**
  String get previewNotAvailable;

  /// No description provided for @tapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get tapToChange;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @uiFieldTap.
  ///
  /// In en, this message translates to:
  /// **'Tap'**
  String get uiFieldTap;

  /// No description provided for @uiFieldEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get uiFieldEnabled;

  /// No description provided for @uiFieldDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get uiFieldDisabled;

  /// No description provided for @presetDarker.
  ///
  /// In en, this message translates to:
  /// **'Darker'**
  String get presetDarker;

  /// No description provided for @presetNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get presetNormal;

  /// No description provided for @presetBrighter.
  ///
  /// In en, this message translates to:
  /// **'Brighter'**
  String get presetBrighter;

  /// No description provided for @presetVeryBright.
  ///
  /// In en, this message translates to:
  /// **'Very Bright'**
  String get presetVeryBright;

  /// No description provided for @presetLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get presetLow;

  /// No description provided for @presetHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get presetHigh;

  /// No description provided for @presetVeryHigh.
  ///
  /// In en, this message translates to:
  /// **'Very High'**
  String get presetVeryHigh;

  /// No description provided for @presetSubtle.
  ///
  /// In en, this message translates to:
  /// **'Subtle'**
  String get presetSubtle;

  /// No description provided for @presetSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get presetSoft;

  /// No description provided for @presetMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get presetMedium;

  /// No description provided for @presetStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get presetStrong;

  /// No description provided for @effectBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get effectBrightness;

  /// No description provided for @effectContrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get effectContrast;

  /// No description provided for @effectBlur.
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get effectBlur;

  /// No description provided for @effectVignette.
  ///
  /// In en, this message translates to:
  /// **'Vignette'**
  String get effectVignette;

  /// No description provided for @effectInvert.
  ///
  /// In en, this message translates to:
  /// **'Invert'**
  String get effectInvert;

  /// No description provided for @effectGrayscale.
  ///
  /// In en, this message translates to:
  /// **'Grayscale'**
  String get effectGrayscale;

  /// No description provided for @effectSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get effectSepia;

  /// No description provided for @effectThreshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get effectThreshold;

  /// No description provided for @effectPixelate.
  ///
  /// In en, this message translates to:
  /// **'Pixelate'**
  String get effectPixelate;

  /// No description provided for @effectSharpen.
  ///
  /// In en, this message translates to:
  /// **'Sharpen'**
  String get effectSharpen;

  /// No description provided for @effectNoise.
  ///
  /// In en, this message translates to:
  /// **'Noise'**
  String get effectNoise;

  /// No description provided for @effectGlow.
  ///
  /// In en, this message translates to:
  /// **'Glow'**
  String get effectGlow;

  /// No description provided for @effectGlitch.
  ///
  /// In en, this message translates to:
  /// **'Glitch'**
  String get effectGlitch;

  /// No description provided for @effectSparkle.
  ///
  /// In en, this message translates to:
  /// **'Sparkle'**
  String get effectSparkle;

  /// No description provided for @effectFire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get effectFire;

  /// No description provided for @effectRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get effectRain;

  /// No description provided for @selectEffect.
  ///
  /// In en, this message translates to:
  /// **'Select Effect'**
  String get selectEffect;

  /// No description provided for @searchEffects.
  ///
  /// In en, this message translates to:
  /// **'Search effects...'**
  String get searchEffects;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryColorTone.
  ///
  /// In en, this message translates to:
  /// **'Color & Tone'**
  String get categoryColorTone;

  /// No description provided for @categoryBlurSharpen.
  ///
  /// In en, this message translates to:
  /// **'Blur & Sharpen'**
  String get categoryBlurSharpen;

  /// No description provided for @categoryArtistic.
  ///
  /// In en, this message translates to:
  /// **'Artistic'**
  String get categoryArtistic;

  /// No description provided for @categoryAnimation.
  ///
  /// In en, this message translates to:
  /// **'Animation'**
  String get categoryAnimation;

  /// No description provided for @categoryNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get categoryNature;

  /// No description provided for @categoryParticles.
  ///
  /// In en, this message translates to:
  /// **'Particles'**
  String get categoryParticles;

  /// No description provided for @categoryDistortion.
  ///
  /// In en, this message translates to:
  /// **'Distortion'**
  String get categoryDistortion;

  /// No description provided for @categoryTextures.
  ///
  /// In en, this message translates to:
  /// **'Textures'**
  String get categoryTextures;

  /// No description provided for @categorySpecialFx.
  ///
  /// In en, this message translates to:
  /// **'Special FX'**
  String get categorySpecialFx;

  /// No description provided for @noEffectsMatch.
  ///
  /// In en, this message translates to:
  /// **'No effects match your search'**
  String get noEffectsMatch;

  /// No description provided for @premiumEffect.
  ///
  /// In en, this message translates to:
  /// **'Premium Effect'**
  String get premiumEffect;

  /// No description provided for @proVersionStatus.
  ///
  /// In en, this message translates to:
  /// **'This effect is available in the Pro version.'**
  String get proVersionStatus;

  /// No description provided for @proFeaturesInclude.
  ///
  /// In en, this message translates to:
  /// **'Pro features include:'**
  String get proFeaturesInclude;

  /// No description provided for @featureAdvancedEffects.
  ///
  /// In en, this message translates to:
  /// **'Advanced effects and tools'**
  String get featureAdvancedEffects;

  /// No description provided for @featureUnlimitedProjects.
  ///
  /// In en, this message translates to:
  /// **'Unlimited projects'**
  String get featureUnlimitedProjects;

  /// No description provided for @featureCloudBackup.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup'**
  String get featureCloudBackup;

  /// No description provided for @featurePrioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get featurePrioritySupport;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @effectsPanelRemoveEffectTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Effect'**
  String get effectsPanelRemoveEffectTitle;

  /// No description provided for @effectsPanelRemoveEffectMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the {effectName} effect?'**
  String effectsPanelRemoveEffectMessage(String effectName);

  /// No description provided for @effectsPanelClearAllEffectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Effects'**
  String get effectsPanelClearAllEffectsTitle;

  /// No description provided for @effectsPanelClearAllEffectsMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all effects from this layer?'**
  String get effectsPanelClearAllEffectsMessage;

  /// No description provided for @effectsPanelClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get effectsPanelClearAll;

  /// No description provided for @effectsPanelAppliedToLayerMessage.
  ///
  /// In en, this message translates to:
  /// **'Effect {effectName} applied to layer'**
  String effectsPanelAppliedToLayerMessage(String effectName);

  /// No description provided for @effectsPanelActionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get effectsPanelActionApply;

  /// No description provided for @effectsPanelActionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get effectsPanelActionRemove;

  /// No description provided for @effectsPanelActionMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get effectsPanelActionMore;

  /// No description provided for @effectsPanelMoreActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'More Actions'**
  String get effectsPanelMoreActionsTitle;

  /// No description provided for @effectsPanelApplyAll.
  ///
  /// In en, this message translates to:
  /// **'Apply All'**
  String get effectsPanelApplyAll;
}

class _StringsDelegate extends LocalizationsDelegate<Strings> {
  const _StringsDelegate();

  @override
  Future<Strings> load(Locale locale) {
    return SynchronousFuture<Strings>(lookupStrings(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ky', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_StringsDelegate old) => false;
}

Strings lookupStrings(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return StringsEn();
    case 'ja':
      return StringsJa();
    case 'ky':
      return StringsKy();
    case 'ru':
      return StringsRu();
    case 'zh':
      return StringsZh();
  }

  throw FlutterError(
      'Strings.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
