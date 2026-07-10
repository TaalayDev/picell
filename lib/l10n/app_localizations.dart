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

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

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

  /// No description provided for @paletteImported.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get paletteImported;

  /// No description provided for @paletteImportedCount.
  ///
  /// In en, this message translates to:
  /// **'colors'**
  String get paletteImportedCount;

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

  /// No description provided for @selectionTransforms.
  ///
  /// In en, this message translates to:
  /// **'Selection Transforms'**
  String get selectionTransforms;

  /// No description provided for @transformInterpolation.
  ///
  /// In en, this message translates to:
  /// **'Interpolation'**
  String get transformInterpolation;

  /// No description provided for @transformInterpolationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sampling used when resizing and rotating selections'**
  String get transformInterpolationSubtitle;

  /// No description provided for @nearestNeighbor.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get nearestNeighbor;

  /// No description provided for @bilinear.
  ///
  /// In en, this message translates to:
  /// **'Bilinear'**
  String get bilinear;

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

  /// No description provided for @conversionSettings.
  ///
  /// In en, this message translates to:
  /// **'Conversion Settings'**
  String get conversionSettings;

  /// No description provided for @paletteColors.
  ///
  /// In en, this message translates to:
  /// **'Palette Colors'**
  String get paletteColors;

  /// No description provided for @fullColor.
  ///
  /// In en, this message translates to:
  /// **'Full Color'**
  String get fullColor;

  /// No description provided for @dithering.
  ///
  /// In en, this message translates to:
  /// **'Dithering'**
  String get dithering;

  /// No description provided for @noDithering.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noDithering;

  /// No description provided for @alphaThreshold.
  ///
  /// In en, this message translates to:
  /// **'Alpha Threshold'**
  String get alphaThreshold;

  /// No description provided for @chooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose Image'**
  String get chooseImage;

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

  /// No description provided for @ellipseSelection.
  ///
  /// In en, this message translates to:
  /// **'Ellipse Selection'**
  String get ellipseSelection;

  /// No description provided for @ellipseSelectionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select an elliptical area'**
  String get ellipseSelectionTooltip;

  /// No description provided for @autoSelectLayer.
  ///
  /// In en, this message translates to:
  /// **'Auto-Select'**
  String get autoSelectLayer;

  /// No description provided for @autoSelectLayerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select all non-empty pixels in the current layer'**
  String get autoSelectLayerTooltip;

  /// No description provided for @selectionAnchor.
  ///
  /// In en, this message translates to:
  /// **'Selection Anchor'**
  String get selectionAnchor;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @createNewProjectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create New Project'**
  String get createNewProjectTooltip;

  /// No description provided for @failedToProcessFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to process {fileName}'**
  String failedToProcessFile(String fileName);

  /// No description provided for @importingFile.
  ///
  /// In en, this message translates to:
  /// **'Importing {fileName}...'**
  String importingFile(String fileName);

  /// No description provided for @importedProjectSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Imported \"{projectName}\" successfully'**
  String importedProjectSuccessfully(String projectName);

  /// No description provided for @failedToImport.
  ///
  /// In en, this message translates to:
  /// **'Failed to import: {error}'**
  String failedToImport(String error);

  /// No description provided for @unsupportedFileType.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type: {fileName}'**
  String unsupportedFileType(String fileName);

  /// No description provided for @pleaseSignInToUploadProjects.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to upload projects'**
  String get pleaseSignInToUploadProjects;

  /// No description provided for @pleaseSignInToUpdateProjects.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to update projects'**
  String get pleaseSignInToUpdateProjects;

  /// No description provided for @projectNotSyncedToCloud.
  ///
  /// In en, this message translates to:
  /// **'Project is not synced to cloud'**
  String get projectNotSyncedToCloud;

  /// No description provided for @pleaseSignInToRemoveCloudProjects.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to remove cloud projects'**
  String get pleaseSignInToRemoveCloudProjects;

  /// No description provided for @removingFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Removing from cloud...'**
  String get removingFromCloud;

  /// No description provided for @projectRemovedFromCloudSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Project removed from cloud successfully'**
  String get projectRemovedFromCloudSuccessfully;

  /// No description provided for @failedToRemoveFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove from cloud: {error}'**
  String failedToRemoveFromCloud(String error);

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @myProjects.
  ///
  /// In en, this message translates to:
  /// **'My Projects'**
  String get myProjects;

  /// No description provided for @noProjectsYet.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get noProjectsYet;

  /// No description provided for @createOne.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get createOne;

  /// No description provided for @searchProjects.
  ///
  /// In en, this message translates to:
  /// **'Search projects...'**
  String get searchProjects;

  /// No description provided for @discoverAmazingPixelArt.
  ///
  /// In en, this message translates to:
  /// **'Discover amazing pixel art'**
  String get discoverAmazingPixelArt;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @mostRecent.
  ///
  /// In en, this message translates to:
  /// **'Most Recent'**
  String get mostRecent;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get mostPopular;

  /// No description provided for @mostViewed.
  ///
  /// In en, this message translates to:
  /// **'Most Viewed'**
  String get mostViewed;

  /// No description provided for @mostLiked.
  ///
  /// In en, this message translates to:
  /// **'Most Liked'**
  String get mostLiked;

  /// No description provided for @titleAZ.
  ///
  /// In en, this message translates to:
  /// **'Title A-Z'**
  String get titleAZ;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @featuredProjects.
  ///
  /// In en, this message translates to:
  /// **'Featured Projects'**
  String get featuredProjects;

  /// No description provided for @errorLoadingProjects.
  ///
  /// In en, this message translates to:
  /// **'Error loading projects'**
  String get errorLoadingProjects;

  /// No description provided for @deletingProject.
  ///
  /// In en, this message translates to:
  /// **'Deleting project...'**
  String get deletingProject;

  /// No description provided for @projectDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Project deleted successfully'**
  String get projectDeletedSuccessfully;

  /// No description provided for @failedToDeleteProject.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete project'**
  String get failedToDeleteProject;

  /// No description provided for @failedToDeleteProjectWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete project: {error}'**
  String failedToDeleteProjectWithError(String error);

  /// No description provided for @unlike.
  ///
  /// In en, this message translates to:
  /// **'Unlike'**
  String get unlike;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @editProject.
  ///
  /// In en, this message translates to:
  /// **'Edit Project'**
  String get editProject;

  /// No description provided for @public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @likeCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} Likes'**
  String likeCountLabel(String count);

  /// No description provided for @commentCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} Comments'**
  String commentCountLabel(String count);

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @openProject.
  ///
  /// In en, this message translates to:
  /// **'Open Project'**
  String get openProject;

  /// No description provided for @downloadProject.
  ///
  /// In en, this message translates to:
  /// **'Download Project'**
  String get downloadProject;

  /// No description provided for @localProjectNotFound.
  ///
  /// In en, this message translates to:
  /// **'Local project not found'**
  String get localProjectNotFound;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add Comment'**
  String get addComment;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsYet;

  /// No description provided for @beFirstToComment.
  ///
  /// In en, this message translates to:
  /// **'Be the first to leave a comment!'**
  String get beFirstToComment;

  /// No description provided for @failedToLoadComments.
  ///
  /// In en, this message translates to:
  /// **'Failed to load comments'**
  String get failedToLoadComments;

  /// No description provided for @edited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get edited;

  /// No description provided for @makeProjectPublic.
  ///
  /// In en, this message translates to:
  /// **'Make Project Public'**
  String get makeProjectPublic;

  /// No description provided for @makeProjectPrivate.
  ///
  /// In en, this message translates to:
  /// **'Make Project Private'**
  String get makeProjectPrivate;

  /// No description provided for @makeProjectPublicMessage.
  ///
  /// In en, this message translates to:
  /// **'This will make your project visible to everyone in the community. Anyone will be able to view, like, and comment on it.'**
  String get makeProjectPublicMessage;

  /// No description provided for @makeProjectPrivateMessage.
  ///
  /// In en, this message translates to:
  /// **'This will hide your project from the public community. Only you will be able to see it.'**
  String get makeProjectPrivateMessage;

  /// No description provided for @projectWillBePublic.
  ///
  /// In en, this message translates to:
  /// **'Project will be publicly visible'**
  String get projectWillBePublic;

  /// No description provided for @projectWillBePrivate.
  ///
  /// In en, this message translates to:
  /// **'Project will be private'**
  String get projectWillBePrivate;

  /// No description provided for @projectIsNowPublic.
  ///
  /// In en, this message translates to:
  /// **'Project is now public'**
  String get projectIsNowPublic;

  /// No description provided for @projectIsNowPrivate.
  ///
  /// In en, this message translates to:
  /// **'Project is now private'**
  String get projectIsNowPrivate;

  /// No description provided for @failedToUpdateVisibility.
  ///
  /// In en, this message translates to:
  /// **'Failed to update visibility: {error}'**
  String failedToUpdateVisibility(String error);

  /// No description provided for @makePublic.
  ///
  /// In en, this message translates to:
  /// **'Make Public'**
  String get makePublic;

  /// No description provided for @makePrivate.
  ///
  /// In en, this message translates to:
  /// **'Make Private'**
  String get makePrivate;

  /// No description provided for @deleteProjectCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this project? This action cannot be undone.'**
  String get deleteProjectCannotBeUndone;

  /// No description provided for @thisWillPermanentlyDelete.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete:'**
  String get thisWillPermanentlyDelete;

  /// No description provided for @deleteProjectConsequences.
  ///
  /// In en, this message translates to:
  /// **'• Project data and artwork\n• All comments and likes\n• Download statistics'**
  String get deleteProjectConsequences;

  /// No description provided for @typeProjectTitleToConfirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Type \"{title}\" to confirm deletion:'**
  String typeProjectTitleToConfirmDeletion(String title);

  /// No description provided for @enterProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter project title...'**
  String get enterProjectTitle;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete Forever'**
  String get deleteForever;

  /// No description provided for @openingProjectEditor.
  ///
  /// In en, this message translates to:
  /// **'Opening project editor...'**
  String get openingProjectEditor;

  /// No description provided for @projectLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Project link copied to clipboard!'**
  String get projectLinkCopied;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites!'**
  String get addedToFavorites;

  /// No description provided for @nowFollowingUser.
  ///
  /// In en, this message translates to:
  /// **'Now following {username}!'**
  String nowFollowingUser(String username);

  /// No description provided for @reportProject.
  ///
  /// In en, this message translates to:
  /// **'Report Project'**
  String get reportProject;

  /// No description provided for @reportProjectMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to report this project? Please only report content that violates our community guidelines.'**
  String get reportProjectMessage;

  /// No description provided for @reportThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your report. We will review it shortly.'**
  String get reportThanks;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @premiumRequiredToDownloadProjects.
  ///
  /// In en, this message translates to:
  /// **'Premium subscription required to download projects'**
  String get premiumRequiredToDownloadProjects;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @downloadProjectRewardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To download this project, you can either:'**
  String get downloadProjectRewardSubtitle;

  /// No description provided for @thankYouWatchingDownloadStarting.
  ///
  /// In en, this message translates to:
  /// **'Thank you for watching! Your download is starting...'**
  String get thankYouWatchingDownloadStarting;

  /// No description provided for @pleaseSignInToAddComments.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to add comments'**
  String get pleaseSignInToAddComments;

  /// No description provided for @writeYourComment.
  ///
  /// In en, this message translates to:
  /// **'Write your comment...'**
  String get writeYourComment;

  /// No description provided for @commentAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Comment added successfully!'**
  String get commentAddedSuccessfully;

  /// No description provided for @failedToAddComment.
  ///
  /// In en, this message translates to:
  /// **'Failed to add comment: {error}'**
  String failedToAddComment(String error);

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @importFile.
  ///
  /// In en, this message translates to:
  /// **'Import File'**
  String get importFile;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @getPro.
  ///
  /// In en, this message translates to:
  /// **'Get Pro'**
  String get getPro;

  /// No description provided for @supportOnKofi.
  ///
  /// In en, this message translates to:
  /// **'Support on Ko-fi'**
  String get supportOnKofi;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @views.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get views;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published!'**
  String get published;

  /// No description provided for @forkedFrom.
  ///
  /// In en, this message translates to:
  /// **'Forked from '**
  String get forkedFrom;

  /// No description provided for @byUser.
  ///
  /// In en, this message translates to:
  /// **' by {username}'**
  String byUser(String username);

  /// No description provided for @projectAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Project Analytics'**
  String get projectAnalytics;

  /// No description provided for @totalViews.
  ///
  /// In en, this message translates to:
  /// **'Total Views'**
  String get totalViews;

  /// No description provided for @totalLikes.
  ///
  /// In en, this message translates to:
  /// **'Total Likes'**
  String get totalLikes;

  /// No description provided for @detailedAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Detailed Analytics'**
  String get detailedAnalytics;

  /// No description provided for @advancedAnalyticsSoon.
  ///
  /// In en, this message translates to:
  /// **'Advanced analytics features will be available soon.'**
  String get advancedAnalyticsSoon;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @projectTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Give your project a name'**
  String get projectTitleHint;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @projectDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Tell the community about this project (optional)'**
  String get projectDescriptionHint;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @searchTags.
  ///
  /// In en, this message translates to:
  /// **'Search tags…'**
  String get searchTags;

  /// No description provided for @failedToLoadTags.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tags'**
  String get failedToLoadTags;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @removeFromCloudQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove from Cloud?'**
  String get removeFromCloudQuestion;

  /// No description provided for @removeFromCommunityMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove the project from the community. Your local copy will remain.'**
  String get removeFromCommunityMessage;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @updateProject.
  ///
  /// In en, this message translates to:
  /// **'Update Project'**
  String get updateProject;

  /// No description provided for @publishToCommunity.
  ///
  /// In en, this message translates to:
  /// **'Publish to Community'**
  String get publishToCommunity;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @visibleToEveryone.
  ///
  /// In en, this message translates to:
  /// **'Visible to everyone'**
  String get visibleToEveryone;

  /// No description provided for @onlyVisibleToYou.
  ///
  /// In en, this message translates to:
  /// **'Only visible to you'**
  String get onlyVisibleToYou;

  /// No description provided for @maximumTagsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 tags allowed'**
  String get maximumTagsAllowed;

  /// No description provided for @frameCountSimple.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, one {frame} other {frames}}'**
  String frameCountSimple(int count);

  /// No description provided for @layerCountSimple.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, one {layer} other {layers}}'**
  String layerCountSimple(int count);

  /// No description provided for @cloudManagement.
  ///
  /// In en, this message translates to:
  /// **'Cloud Management'**
  String get cloudManagement;

  /// No description provided for @cloudId.
  ///
  /// In en, this message translates to:
  /// **'Cloud ID: {id}'**
  String cloudId(String id);

  /// No description provided for @preparingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Preparing update…'**
  String get preparingUpdate;

  /// No description provided for @preparingProject.
  ///
  /// In en, this message translates to:
  /// **'Preparing project…'**
  String get preparingProject;

  /// No description provided for @generatingThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Generating thumbnail…'**
  String get generatingThumbnail;

  /// No description provided for @updatingOnCloud.
  ///
  /// In en, this message translates to:
  /// **'Updating on cloud…'**
  String get updatingOnCloud;

  /// No description provided for @uploadingToCloud.
  ///
  /// In en, this message translates to:
  /// **'Uploading to cloud…'**
  String get uploadingToCloud;

  /// No description provided for @finalizing.
  ///
  /// In en, this message translates to:
  /// **'Finalizing…'**
  String get finalizing;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated!'**
  String get updated;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updating;

  /// No description provided for @publishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing…'**
  String get publishing;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @downloadingProject.
  ///
  /// In en, this message translates to:
  /// **'Downloading Project'**
  String get downloadingProject;

  /// No description provided for @downloadingProjectData.
  ///
  /// In en, this message translates to:
  /// **'Downloading project data...'**
  String get downloadingProjectData;

  /// No description provided for @downloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download Complete!'**
  String get downloadComplete;

  /// No description provided for @projectSavedLocal.
  ///
  /// In en, this message translates to:
  /// **'Project saved to your local projects'**
  String get projectSavedLocal;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download Failed'**
  String get downloadFailed;

  /// No description provided for @resyncWithCloud.
  ///
  /// In en, this message translates to:
  /// **'Resync with cloud'**
  String get resyncWithCloud;

  /// No description provided for @syncToCloud.
  ///
  /// In en, this message translates to:
  /// **'Sync to cloud'**
  String get syncToCloud;

  /// No description provided for @removeFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Remove from Cloud'**
  String get removeFromCloud;

  /// No description provided for @removeFromCloudMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove the project from the cloud and make it local-only. Your local copy will remain unchanged. Are you sure?'**
  String get removeFromCloudMessage;

  /// No description provided for @syncedCloudDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This project is synced to the cloud. Deleting locally will not affect the cloud version.'**
  String get syncedCloudDeleteWarning;

  /// No description provided for @openLocalProject.
  ///
  /// In en, this message translates to:
  /// **'Open Local Project'**
  String get openLocalProject;

  /// No description provided for @premiumRequired.
  ///
  /// In en, this message translates to:
  /// **'Premium Required'**
  String get premiumRequired;

  /// No description provided for @byUserInline.
  ///
  /// In en, this message translates to:
  /// **'by {username}'**
  String byUserInline(String username);

  /// No description provided for @createTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create Template'**
  String get createTemplate;

  /// No description provided for @layerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name: {name}'**
  String layerNameLabel(String name);

  /// No description provided for @layerSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size: {width}×{height}'**
  String layerSizeLabel(int width, int height);

  /// No description provided for @nonTransparentPixels.
  ///
  /// In en, this message translates to:
  /// **'Pixels: {count} non-transparent'**
  String nonTransparentPixels(int count);

  /// No description provided for @templateName.
  ///
  /// In en, this message translates to:
  /// **'Template Name'**
  String get templateName;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @saveOptions.
  ///
  /// In en, this message translates to:
  /// **'Save Options'**
  String get saveOptions;

  /// No description provided for @saveLocally.
  ///
  /// In en, this message translates to:
  /// **'Save Locally'**
  String get saveLocally;

  /// No description provided for @storeOnDeviceOnly.
  ///
  /// In en, this message translates to:
  /// **'Store on this device only'**
  String get storeOnDeviceOnly;

  /// No description provided for @uploadToCloud.
  ///
  /// In en, this message translates to:
  /// **'Upload to Cloud'**
  String get uploadToCloud;

  /// No description provided for @shareWithCommunity.
  ///
  /// In en, this message translates to:
  /// **'Share with the community'**
  String get shareWithCommunity;

  /// No description provided for @privateCloudStorage.
  ///
  /// In en, this message translates to:
  /// **'Private cloud storage'**
  String get privateCloudStorage;

  /// No description provided for @otherUsersCanDiscoverTemplate.
  ///
  /// In en, this message translates to:
  /// **'Other users can discover and use this template'**
  String get otherUsersCanDiscoverTemplate;

  /// No description provided for @onlyYouCanAccessTemplate.
  ///
  /// In en, this message translates to:
  /// **'Only you can access this template'**
  String get onlyYouCanAccessTemplate;

  /// No description provided for @saveLocallyAndUpload.
  ///
  /// In en, this message translates to:
  /// **'Save Locally & Upload'**
  String get saveLocallyAndUpload;

  /// No description provided for @bestOfBothWorlds.
  ///
  /// In en, this message translates to:
  /// **'Best of both worlds'**
  String get bestOfBothWorlds;

  /// No description provided for @signInToUploadTemplates.
  ///
  /// In en, this message translates to:
  /// **'Sign in to upload templates'**
  String get signInToUploadTemplates;

  /// No description provided for @shareTemplatesWithCommunity.
  ///
  /// In en, this message translates to:
  /// **'Share your templates with the community'**
  String get shareTemplatesWithCommunity;

  /// No description provided for @failedToConvertLayerToTemplate.
  ///
  /// In en, this message translates to:
  /// **'Failed to convert layer to template'**
  String get failedToConvertLayerToTemplate;

  /// No description provided for @failedToSaveTemplateLocally.
  ///
  /// In en, this message translates to:
  /// **'Failed to save template locally'**
  String get failedToSaveTemplateLocally;

  /// No description provided for @failedToUploadTemplateToServer.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload template to server'**
  String get failedToUploadTemplateToServer;

  /// No description provided for @errorCreatingTemplate.
  ///
  /// In en, this message translates to:
  /// **'Error creating template: {error}'**
  String errorCreatingTemplate(String error);

  /// No description provided for @templateSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Template saved locally!'**
  String get templateSavedLocally;

  /// No description provided for @templateUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Template uploaded successfully!'**
  String get templateUploadedSuccessfully;

  /// No description provided for @templateSavedAndUploaded.
  ///
  /// In en, this message translates to:
  /// **'Template saved locally and uploaded!'**
  String get templateSavedAndUploaded;

  /// No description provided for @templateSavedUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Template saved locally (upload failed)'**
  String get templateSavedUploadFailed;

  /// No description provided for @templateUploadedLocalSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Template uploaded (local save failed)'**
  String get templateUploadedLocalSaveFailed;

  /// No description provided for @templateCreationFailed.
  ///
  /// In en, this message translates to:
  /// **'Template creation failed'**
  String get templateCreationFailed;

  /// No description provided for @templateGallery.
  ///
  /// In en, this message translates to:
  /// **'Template Gallery'**
  String get templateGallery;

  /// No description provided for @allTemplates.
  ///
  /// In en, this message translates to:
  /// **'All Templates'**
  String get allTemplates;

  /// No description provided for @local.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get local;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @failedTemplateDetailsCached.
  ///
  /// In en, this message translates to:
  /// **'Failed to load template details. Using cached data.'**
  String get failedTemplateDetailsCached;

  /// No description provided for @errorLoadingTemplate.
  ///
  /// In en, this message translates to:
  /// **'Error loading template: {error}'**
  String errorLoadingTemplate(String error);

  /// No description provided for @loadingTemplate.
  ///
  /// In en, this message translates to:
  /// **'Loading template...'**
  String get loadingTemplate;

  /// No description provided for @deleteTemplate.
  ///
  /// In en, this message translates to:
  /// **'Delete Template'**
  String get deleteTemplate;

  /// No description provided for @deleteTemplateQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteTemplateQuestion(String name);

  /// No description provided for @deleteLocalTemplateWarning.
  ///
  /// In en, this message translates to:
  /// **'This template will be permanently removed from your local storage.'**
  String get deleteLocalTemplateWarning;

  /// No description provided for @deleteCloudTemplateWarning.
  ///
  /// In en, this message translates to:
  /// **'This template will be removed from the cloud and can\'t be recovered.'**
  String get deleteCloudTemplateWarning;

  /// No description provided for @templateDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Template \"{name}\" deleted successfully'**
  String templateDeletedSuccessfully(String name);

  /// No description provided for @failedToDeleteTemplate.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete template \"{name}\"'**
  String failedToDeleteTemplate(String name);

  /// No description provided for @searchTemplates.
  ///
  /// In en, this message translates to:
  /// **'Search templates...'**
  String get searchTemplates;

  /// No description provided for @loadingTemplates.
  ///
  /// In en, this message translates to:
  /// **'Loading templates...'**
  String get loadingTemplates;

  /// No description provided for @premiumTemplate.
  ///
  /// In en, this message translates to:
  /// **'Premium Template'**
  String get premiumTemplate;

  /// No description provided for @templateAvailableInPro.
  ///
  /// In en, this message translates to:
  /// **'This template is available in the Pro version.'**
  String get templateAvailableInPro;

  /// No description provided for @premiumTemplatesFeature.
  ///
  /// In en, this message translates to:
  /// **'• Premium templates'**
  String get premiumTemplatesFeature;

  /// No description provided for @advancedEffectsToolsFeature.
  ///
  /// In en, this message translates to:
  /// **'• Advanced effects and tools'**
  String get advancedEffectsToolsFeature;

  /// No description provided for @unlimitedProjectsFeature.
  ///
  /// In en, this message translates to:
  /// **'• Unlimited projects'**
  String get unlimitedProjectsFeature;

  /// No description provided for @cloudBackupFeature.
  ///
  /// In en, this message translates to:
  /// **'• Cloud backup'**
  String get cloudBackupFeature;

  /// No description provided for @prioritySupportFeature.
  ///
  /// In en, this message translates to:
  /// **'• Priority support'**
  String get prioritySupportFeature;

  /// No description provided for @noLocalTemplates.
  ///
  /// In en, this message translates to:
  /// **'No local templates found.\nCreate your first template from a layer!'**
  String get noLocalTemplates;

  /// No description provided for @noCommunityTemplates.
  ///
  /// In en, this message translates to:
  /// **'No community templates found.\nTry adjusting your search or filters.'**
  String get noCommunityTemplates;

  /// No description provided for @noUploadedTemplates.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t uploaded any templates yet.\nShare your creations with the community!'**
  String get noUploadedTemplates;

  /// No description provided for @noTemplatesFoundAdjust.
  ///
  /// In en, this message translates to:
  /// **'No templates found.\nTry adjusting your search or filters.'**
  String get noTemplatesFoundAdjust;

  /// No description provided for @showingTemplates.
  ///
  /// In en, this message translates to:
  /// **'Showing {displayed}{total, select, none {} other { of {total}}} templates'**
  String showingTemplates(int displayed, String total);

  /// No description provided for @clickTemplateToApply.
  ///
  /// In en, this message translates to:
  /// **'Click a template to apply it'**
  String get clickTemplateToApply;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get pro;

  /// No description provided for @pleaseEnterTemplateName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a template name'**
  String get pleaseEnterTemplateName;

  /// No description provided for @signInToUploadTemplatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Upload Templates'**
  String get signInToUploadTemplatesTitle;

  /// No description provided for @signInToUploadTemplatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to share your templates with the community.'**
  String get signInToUploadTemplatesSubtitle;

  /// No description provided for @myTemplates.
  ///
  /// In en, this message translates to:
  /// **'My Templates'**
  String get myTemplates;

  /// No description provided for @cloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get cloud;

  /// No description provided for @tapToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Tap to Unlock'**
  String get tapToUnlock;

  /// No description provided for @layerTemplateDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Layer Template'**
  String get layerTemplateDefaultName;

  /// No description provided for @undoHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get undoHistoryTitle;

  /// No description provided for @undoHistoryStepCount.
  ///
  /// In en, this message translates to:
  /// **'({total} steps)'**
  String undoHistoryStepCount(int total);

  /// No description provided for @undoHistoryRevertAll.
  ///
  /// In en, this message translates to:
  /// **'Revert all'**
  String get undoHistoryRevertAll;

  /// No description provided for @undoHistoryCurrentState.
  ///
  /// In en, this message translates to:
  /// **'Current state'**
  String get undoHistoryCurrentState;

  /// No description provided for @undoHistoryFrameLayer.
  ///
  /// In en, this message translates to:
  /// **'Frame {frame}, Layer {layer}'**
  String undoHistoryFrameLayer(int frame, int layer);

  /// No description provided for @keyboardShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get keyboardShortcuts;

  /// No description provided for @copySelection.
  ///
  /// In en, this message translates to:
  /// **'Copy selection'**
  String get copySelection;

  /// No description provided for @cutSelection.
  ///
  /// In en, this message translates to:
  /// **'Cut selection'**
  String get cutSelection;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @duplicateLayer.
  ///
  /// In en, this message translates to:
  /// **'Duplicate layer'**
  String get duplicateLayer;

  /// No description provided for @selection.
  ///
  /// In en, this message translates to:
  /// **'Selection'**
  String get selection;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @deselect.
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get deselect;

  /// No description provided for @closePenPath.
  ///
  /// In en, this message translates to:
  /// **'Close pen path'**
  String get closePenPath;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @pencil.
  ///
  /// In en, this message translates to:
  /// **'Pencil'**
  String get pencil;

  /// No description provided for @eraser.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get eraser;

  /// No description provided for @eyedropper.
  ///
  /// In en, this message translates to:
  /// **'Eyedropper'**
  String get eyedropper;

  /// No description provided for @fill.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get fill;

  /// No description provided for @selectMarquee.
  ///
  /// In en, this message translates to:
  /// **'Select / Marquee'**
  String get selectMarquee;

  /// No description provided for @moveDrag.
  ///
  /// In en, this message translates to:
  /// **'Move / Drag'**
  String get moveDrag;

  /// No description provided for @pen.
  ///
  /// In en, this message translates to:
  /// **'Pen'**
  String get pen;

  /// No description provided for @sprayPaint.
  ///
  /// In en, this message translates to:
  /// **'Spray paint'**
  String get sprayPaint;

  /// No description provided for @panHold.
  ///
  /// In en, this message translates to:
  /// **'Pan (hold)'**
  String get panHold;

  /// No description provided for @eyedropperHold.
  ///
  /// In en, this message translates to:
  /// **'Eyedropper (hold)'**
  String get eyedropperHold;

  /// No description provided for @brush.
  ///
  /// In en, this message translates to:
  /// **'Brush'**
  String get brush;

  /// No description provided for @increaseSize.
  ///
  /// In en, this message translates to:
  /// **'Increase size'**
  String get increaseSize;

  /// No description provided for @decreaseSize.
  ///
  /// In en, this message translates to:
  /// **'Decrease size'**
  String get decreaseSize;

  /// No description provided for @colors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get colors;

  /// No description provided for @swapColors.
  ///
  /// In en, this message translates to:
  /// **'Swap colors'**
  String get swapColors;

  /// No description provided for @defaultColors.
  ///
  /// In en, this message translates to:
  /// **'Default colors'**
  String get defaultColors;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @zoomToFit.
  ///
  /// In en, this message translates to:
  /// **'Zoom to fit'**
  String get zoomToFit;

  /// No description provided for @zoomOneToOne.
  ///
  /// In en, this message translates to:
  /// **'Zoom 1:1'**
  String get zoomOneToOne;

  /// No description provided for @toggleUi.
  ///
  /// In en, this message translates to:
  /// **'Toggle UI'**
  String get toggleUi;

  /// No description provided for @selectLayerOneToNine.
  ///
  /// In en, this message translates to:
  /// **'Select layer 1-9'**
  String get selectLayerOneToNine;

  /// No description provided for @newLayer.
  ///
  /// In en, this message translates to:
  /// **'New layer'**
  String get newLayer;

  /// No description provided for @deleteAccountCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get deleteAccountCannotBeUndone;

  /// No description provided for @deleteAccountPermanentDataWarning.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account will permanently remove all your data.'**
  String get deleteAccountPermanentDataWarning;

  /// No description provided for @deleteAccountItemsIntro.
  ///
  /// In en, this message translates to:
  /// **'The following will be permanently deleted:'**
  String get deleteAccountItemsIntro;

  /// No description provided for @deleteAccountPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'App Preferences'**
  String get deleteAccountPreferencesTitle;

  /// No description provided for @deleteAccountPreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Settings and customizations'**
  String get deleteAccountPreferencesSubtitle;

  /// No description provided for @deleteAccountInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get deleteAccountInfoTitle;

  /// No description provided for @deleteAccountInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile and authentication data'**
  String get deleteAccountInfoSubtitle;

  /// No description provided for @deleteAccountTypeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type \"DELETE\" to confirm:'**
  String get deleteAccountTypeConfirm;

  /// No description provided for @deleteAccountTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE here...'**
  String get deleteAccountTypeHint;

  /// No description provided for @deleteAccountIrreversibleImmediate.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible and will take effect immediately.'**
  String get deleteAccountIrreversibleImmediate;

  /// No description provided for @deleteAccountQuickConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete your account?'**
  String get deleteAccountQuickConfirm;

  /// No description provided for @deleteAccountQuickWarningList.
  ///
  /// In en, this message translates to:
  /// **'• All your projects will be lost\n• Cloud backups will be deleted\n• This action cannot be undone'**
  String get deleteAccountQuickWarningList;

  /// No description provided for @failedToDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account: {error}'**
  String failedToDeleteAccount(String error);

  /// No description provided for @proAccessActive.
  ///
  /// In en, this message translates to:
  /// **'Pro Access Active'**
  String get proAccessActive;

  /// No description provided for @proAccessRemaining.
  ///
  /// In en, this message translates to:
  /// **'You have {time} of Pro access remaining.'**
  String proAccessRemaining(String time);

  /// No description provided for @buyPro.
  ///
  /// In en, this message translates to:
  /// **'Buy Pro'**
  String get buyPro;

  /// No description provided for @rewardUpgradeBullets.
  ///
  /// In en, this message translates to:
  /// **'• Unlimited access to all features\n• One-time purchase\n• No ads\n• Priority support'**
  String get rewardUpgradeBullets;

  /// No description provided for @tryPro45Minutes.
  ///
  /// In en, this message translates to:
  /// **'Try Pro for 45 Minutes'**
  String get tryPro45Minutes;

  /// No description provided for @rewardAdReadyBullets.
  ///
  /// In en, this message translates to:
  /// **'• Watch a short video ad\n• Get 45 minutes of Pro access\n• Support the app development'**
  String get rewardAdReadyBullets;

  /// No description provided for @rewardAdLoadingBullets.
  ///
  /// In en, this message translates to:
  /// **'• Video ad is loading...\n• Please try again in a moment'**
  String get rewardAdLoadingBullets;

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get watchAd;

  /// No description provided for @loadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingEllipsis;

  /// No description provided for @loadingVideoAd.
  ///
  /// In en, this message translates to:
  /// **'Loading video ad...'**
  String get loadingVideoAd;

  /// No description provided for @proAccessGranted45.
  ///
  /// In en, this message translates to:
  /// **'Pro access granted for 45 minutes!'**
  String get proAccessGranted45;

  /// No description provided for @videoAdNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Video ad was not completed. Please try again or upgrade to Pro.'**
  String get videoAdNotCompleted;

  /// No description provided for @failedToLoadVideoAd.
  ///
  /// In en, this message translates to:
  /// **'Failed to load video ad: {error}'**
  String failedToLoadVideoAd(String error);

  /// No description provided for @rewardTimeZeroMinutes.
  ///
  /// In en, this message translates to:
  /// **'0 minutes'**
  String get rewardTimeZeroMinutes;

  /// No description provided for @rewardTimeMinutesSeconds.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {seconds}s'**
  String rewardTimeMinutesSeconds(int minutes, int seconds);

  /// No description provided for @rewardTimeSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String rewardTimeSeconds(int seconds);

  /// No description provided for @selectionOptions.
  ///
  /// In en, this message translates to:
  /// **'Selection Options'**
  String get selectionOptions;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear Selection'**
  String get clearSelection;

  /// No description provided for @invertSelection.
  ///
  /// In en, this message translates to:
  /// **'Invert Selection'**
  String get invertSelection;

  /// No description provided for @growSelectionOnePixel.
  ///
  /// In en, this message translates to:
  /// **'Grow (+1px)'**
  String get growSelectionOnePixel;

  /// No description provided for @shrinkSelectionOnePixel.
  ///
  /// In en, this message translates to:
  /// **'Shrink (-1px)'**
  String get shrinkSelectionOnePixel;

  /// No description provided for @rotate90.
  ///
  /// In en, this message translates to:
  /// **'Rotate 90°'**
  String get rotate90;

  /// No description provided for @rotate180.
  ///
  /// In en, this message translates to:
  /// **'Rotate 180°'**
  String get rotate180;

  /// No description provided for @flipHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Flip Horizontal'**
  String get flipHorizontal;

  /// No description provided for @flipVertical.
  ///
  /// In en, this message translates to:
  /// **'Flip Vertical'**
  String get flipVertical;

  /// No description provided for @cutToNewLayer.
  ///
  /// In en, this message translates to:
  /// **'Cut to New Layer'**
  String get cutToNewLayer;

  /// No description provided for @copyToNewLayer.
  ///
  /// In en, this message translates to:
  /// **'Copy to New Layer'**
  String get copyToNewLayer;

  /// No description provided for @cut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @clearArea.
  ///
  /// In en, this message translates to:
  /// **'Clear Area'**
  String get clearArea;

  /// No description provided for @replaceSelection.
  ///
  /// In en, this message translates to:
  /// **'Replace selection'**
  String get replaceSelection;

  /// No description provided for @addToSelectionShift.
  ///
  /// In en, this message translates to:
  /// **'Add to selection (Shift)'**
  String get addToSelectionShift;

  /// No description provided for @subtractFromSelectionAlt.
  ///
  /// In en, this message translates to:
  /// **'Subtract from selection (Alt)'**
  String get subtractFromSelectionAlt;

  /// No description provided for @textureBrush.
  ///
  /// In en, this message translates to:
  /// **'Texture Brush'**
  String get textureBrush;

  /// No description provided for @triangle.
  ///
  /// In en, this message translates to:
  /// **'Triangle'**
  String get triangle;

  /// No description provided for @diamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get diamond;

  /// No description provided for @hexagon.
  ///
  /// In en, this message translates to:
  /// **'Hexagon'**
  String get hexagon;

  /// No description provided for @heart.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get heart;

  /// No description provided for @arrow.
  ///
  /// In en, this message translates to:
  /// **'Arrow'**
  String get arrow;

  /// No description provided for @lightning.
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get lightning;

  /// No description provided for @cross.
  ///
  /// In en, this message translates to:
  /// **'Cross'**
  String get cross;

  /// No description provided for @spiral.
  ///
  /// In en, this message translates to:
  /// **'Spiral'**
  String get spiral;

  /// No description provided for @cloudShape.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get cloudShape;

  /// No description provided for @rectangleSelect.
  ///
  /// In en, this message translates to:
  /// **'Rectangle Select'**
  String get rectangleSelect;

  /// No description provided for @lasso.
  ///
  /// In en, this message translates to:
  /// **'Lasso'**
  String get lasso;

  /// No description provided for @magicWand.
  ///
  /// In en, this message translates to:
  /// **'Magic Wand'**
  String get magicWand;

  /// No description provided for @effectsPanelAllAppliedMessage.
  ///
  /// In en, this message translates to:
  /// **'All effects applied to layer and removed from effects list'**
  String get effectsPanelAllAppliedMessage;

  /// No description provided for @effectsForLayer.
  ///
  /// In en, this message translates to:
  /// **'Effects for {layerName}'**
  String effectsForLayer(String layerName);

  /// No description provided for @effectsPanelAddEffect.
  ///
  /// In en, this message translates to:
  /// **'Add Effect'**
  String get effectsPanelAddEffect;

  /// No description provided for @appliedEffects.
  ///
  /// In en, this message translates to:
  /// **'Applied Effects'**
  String get appliedEffects;

  /// No description provided for @effectCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 effects} =1{1 effect} other{{count} effects}}'**
  String effectCount(int count);

  /// No description provided for @effectsPreview.
  ///
  /// In en, this message translates to:
  /// **'Effects Preview'**
  String get effectsPreview;

  /// No description provided for @effectPreview.
  ///
  /// In en, this message translates to:
  /// **'Effect Preview'**
  String get effectPreview;

  /// No description provided for @noEffectsApplied.
  ///
  /// In en, this message translates to:
  /// **'No effects applied'**
  String get noEffectsApplied;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @finalResult.
  ///
  /// In en, this message translates to:
  /// **'Final Result'**
  String get finalResult;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @withEffect.
  ///
  /// In en, this message translates to:
  /// **'With Effect'**
  String get withEffect;

  /// No description provided for @withEffects.
  ///
  /// In en, this message translates to:
  /// **'With Effects'**
  String get withEffects;

  /// No description provided for @effectsAppliedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 effects applied} =1{1 effect applied} other{{count} effects applied}}'**
  String effectsAppliedCount(int count);

  /// No description provided for @effectsAppliedInOrder.
  ///
  /// In en, this message translates to:
  /// **'Effects are applied in order'**
  String get effectsAppliedInOrder;

  /// No description provided for @effectsReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Effects are applied from top to bottom. Drag to reorder.'**
  String get effectsReorderHint;

  /// No description provided for @addYourFirstEffect.
  ///
  /// In en, this message translates to:
  /// **'Add your first effect'**
  String get addYourFirstEffect;

  /// No description provided for @layerEffects.
  ///
  /// In en, this message translates to:
  /// **'Layer Effects'**
  String get layerEffects;

  /// No description provided for @effectWatercolor.
  ///
  /// In en, this message translates to:
  /// **'Watercolor'**
  String get effectWatercolor;

  /// No description provided for @effectHalftone.
  ///
  /// In en, this message translates to:
  /// **'Halftone'**
  String get effectHalftone;

  /// No description provided for @effectOilPaint.
  ///
  /// In en, this message translates to:
  /// **'Oil Paint'**
  String get effectOilPaint;

  /// No description provided for @effectEmboss.
  ///
  /// In en, this message translates to:
  /// **'Emboss'**
  String get effectEmboss;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @staticEffect.
  ///
  /// In en, this message translates to:
  /// **'Static Effect'**
  String get staticEffect;

  /// No description provided for @effectNotAnimatedMessage.
  ///
  /// In en, this message translates to:
  /// **'The {effectName} effect is not an animated effect. Animation frame generation is only available for effects that support animation.'**
  String effectNotAnimatedMessage(String effectName);

  /// No description provided for @generateAnimation.
  ///
  /// In en, this message translates to:
  /// **'Generate Animation'**
  String get generateAnimation;

  /// No description provided for @generateAnimationForEffect.
  ///
  /// In en, this message translates to:
  /// **'Generate animation frames for {effectName} effect?'**
  String generateAnimationForEffect(String effectName);

  /// No description provided for @animationDetails.
  ///
  /// In en, this message translates to:
  /// **'Animation Details'**
  String get animationDetails;

  /// No description provided for @animationDetailEffect.
  ///
  /// In en, this message translates to:
  /// **'• Effect: {effectName}'**
  String animationDetailEffect(String effectName);

  /// No description provided for @animationDetailEstimatedFrames.
  ///
  /// In en, this message translates to:
  /// **'• Estimated frames: ~{count}'**
  String animationDetailEstimatedFrames(int count);

  /// No description provided for @animationDetailProcessingTime.
  ///
  /// In en, this message translates to:
  /// **'• Processing time: ~{seconds} seconds'**
  String animationDetailProcessingTime(int seconds);

  /// No description provided for @generateAnimationTimelineNote.
  ///
  /// In en, this message translates to:
  /// **'This will create multiple animation frames that you can add to your timeline.'**
  String get generateAnimationTimelineNote;

  /// No description provided for @generateAnimationFrames.
  ///
  /// In en, this message translates to:
  /// **'Generate Animation Frames'**
  String get generateAnimationFrames;

  /// No description provided for @effectNameLabel.
  ///
  /// In en, this message translates to:
  /// **'{effectName} Effect'**
  String effectNameLabel(String effectName);

  /// No description provided for @framesGeneratedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 frames generated} =1{1 frame generated} other{{count} frames generated}}'**
  String framesGeneratedCount(int count);

  /// No description provided for @generateFrames.
  ///
  /// In en, this message translates to:
  /// **'Generate Frames'**
  String get generateFrames;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @frameLabel.
  ///
  /// In en, this message translates to:
  /// **'Frame:'**
  String get frameLabel;

  /// No description provided for @generatingFrames.
  ///
  /// In en, this message translates to:
  /// **'Generating frames...'**
  String get generatingFrames;

  /// No description provided for @noFramesGenerated.
  ///
  /// In en, this message translates to:
  /// **'No frames generated'**
  String get noFramesGenerated;

  /// No description provided for @animationSettings.
  ///
  /// In en, this message translates to:
  /// **'Animation Settings'**
  String get animationSettings;

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'Duration (seconds)'**
  String get durationSeconds;

  /// No description provided for @fps.
  ///
  /// In en, this message translates to:
  /// **'FPS'**
  String get fps;

  /// No description provided for @totalFrames.
  ///
  /// In en, this message translates to:
  /// **'Total Frames:'**
  String get totalFrames;

  /// No description provided for @pingPongAnimation.
  ///
  /// In en, this message translates to:
  /// **'Ping-Pong Animation'**
  String get pingPongAnimation;

  /// No description provided for @playForwardThenBackward.
  ///
  /// In en, this message translates to:
  /// **'Play forward then backward'**
  String get playForwardThenBackward;

  /// No description provided for @frameGeneration.
  ///
  /// In en, this message translates to:
  /// **'Frame Generation'**
  String get frameGeneration;

  /// No description provided for @generateNewFrames.
  ///
  /// In en, this message translates to:
  /// **'Generate New Frames'**
  String get generateNewFrames;

  /// No description provided for @createNewFramesForAnimation.
  ///
  /// In en, this message translates to:
  /// **'Create new frames for this animation'**
  String get createNewFramesForAnimation;

  /// No description provided for @insertIntoTimeline.
  ///
  /// In en, this message translates to:
  /// **'Insert Into Timeline'**
  String get insertIntoTimeline;

  /// No description provided for @addFramesToExistingTimeline.
  ///
  /// In en, this message translates to:
  /// **'Add frames to existing timeline'**
  String get addFramesToExistingTimeline;

  /// No description provided for @insertPosition.
  ///
  /// In en, this message translates to:
  /// **'Insert Position:'**
  String get insertPosition;

  /// No description provided for @afterFrame.
  ///
  /// In en, this message translates to:
  /// **'After frame {frame}'**
  String afterFrame(int frame);

  /// No description provided for @effectParameters.
  ///
  /// In en, this message translates to:
  /// **'Effect Parameters'**
  String get effectParameters;

  /// No description provided for @editParameters.
  ///
  /// In en, this message translates to:
  /// **'Edit Parameters'**
  String get editParameters;

  /// No description provided for @effectParametersBaseNote.
  ///
  /// In en, this message translates to:
  /// **'Current effect settings will be used as the base for animation'**
  String get effectParametersBaseNote;

  /// No description provided for @editBaseParameters.
  ///
  /// In en, this message translates to:
  /// **'Edit Base Parameters'**
  String get editBaseParameters;

  /// No description provided for @applyAndRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Apply & Regenerate'**
  String get applyAndRegenerate;

  /// No description provided for @animationFrameGenerator.
  ///
  /// In en, this message translates to:
  /// **'Animation Frame Generator'**
  String get animationFrameGenerator;

  /// No description provided for @animationGeneratorHelpIntro.
  ///
  /// In en, this message translates to:
  /// **'This tool generates multiple animation frames by applying the selected effect with different time parameters.\n'**
  String get animationGeneratorHelpIntro;

  /// No description provided for @animationHelpDuration.
  ///
  /// In en, this message translates to:
  /// **'• Duration: Total length of the animation in seconds'**
  String get animationHelpDuration;

  /// No description provided for @animationHelpFps.
  ///
  /// In en, this message translates to:
  /// **'• FPS: Frames per second (higher = smoother but more frames)'**
  String get animationHelpFps;

  /// No description provided for @animationHelpPingPong.
  ///
  /// In en, this message translates to:
  /// **'• Ping-Pong: Makes animation play forward then backward'**
  String get animationHelpPingPong;

  /// No description provided for @animationHelpInterpolation.
  ///
  /// In en, this message translates to:
  /// **'• The effect parameters are interpolated over time to create smooth animations'**
  String get animationHelpInterpolation;

  /// No description provided for @tips.
  ///
  /// In en, this message translates to:
  /// **'Tips:'**
  String get tips;

  /// No description provided for @animationTipLowerFps.
  ///
  /// In en, this message translates to:
  /// **'• Start with lower FPS for testing'**
  String get animationTipLowerFps;

  /// No description provided for @animationTipUsePreview.
  ///
  /// In en, this message translates to:
  /// **'• Use Preview to see the animation before generating'**
  String get animationTipUsePreview;

  /// No description provided for @animationTipLongerDurations.
  ///
  /// In en, this message translates to:
  /// **'• Longer durations work better for slower effects'**
  String get animationTipLongerDurations;

  /// No description provided for @effectFrameName.
  ///
  /// In en, this message translates to:
  /// **'Effect Frame {index}'**
  String effectFrameName(int index);

  /// No description provided for @effectAnimationName.
  ///
  /// In en, this message translates to:
  /// **'Effect Animation {index}'**
  String effectAnimationName(int index);

  /// No description provided for @effectAnimationReturnName.
  ///
  /// In en, this message translates to:
  /// **'Effect Animation {index} (Return)'**
  String effectAnimationReturnName(int index);

  /// No description provided for @generatedAnimationFrames.
  ///
  /// In en, this message translates to:
  /// **'Generated {count, plural, =0{0 animation frames} =1{1 animation frame} other{{count} animation frames}}!'**
  String generatedAnimationFrames(int count);

  /// No description provided for @viewTimeline.
  ///
  /// In en, this message translates to:
  /// **'View Timeline'**
  String get viewTimeline;

  /// No description provided for @featureBullet.
  ///
  /// In en, this message translates to:
  /// **'• {feature}'**
  String featureBullet(String feature);

  /// No description provided for @defaultLayerName.
  ///
  /// In en, this message translates to:
  /// **'Layer {index}'**
  String defaultLayerName(int index);

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @adjustOpacity.
  ///
  /// In en, this message translates to:
  /// **'Adjust Opacity'**
  String get adjustOpacity;

  /// No description provided for @adjustLayerOpacity.
  ///
  /// In en, this message translates to:
  /// **'Adjust Layer Opacity'**
  String get adjustLayerOpacity;

  /// No description provided for @addToTemplate.
  ///
  /// In en, this message translates to:
  /// **'Add to Template'**
  String get addToTemplate;

  /// No description provided for @editLayer.
  ///
  /// In en, this message translates to:
  /// **'Edit Layer'**
  String get editLayer;

  /// No description provided for @layerName.
  ///
  /// In en, this message translates to:
  /// **'Layer Name'**
  String get layerName;

  /// No description provided for @backgroundShort.
  ///
  /// In en, this message translates to:
  /// **'BG'**
  String get backgroundShort;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @fit.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get fit;

  /// No description provided for @removeBackgroundImage.
  ///
  /// In en, this message translates to:
  /// **'Remove background image'**
  String get removeBackgroundImage;

  /// No description provided for @removeBackgroundImageMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the background image?'**
  String get removeBackgroundImageMessage;

  /// No description provided for @themeSelector.
  ///
  /// In en, this message translates to:
  /// **'Theme Selector'**
  String get themeSelector;

  /// No description provided for @unlockThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock {themeName} Theme'**
  String unlockThemeTitle(String themeName);

  /// No description provided for @watchAdToUnlockTheme.
  ///
  /// In en, this message translates to:
  /// **'Watch a video ad to unlock this theme.'**
  String get watchAdToUnlockTheme;

  /// No description provided for @themeUnlocked.
  ///
  /// In en, this message translates to:
  /// **'{themeName} theme unlocked!'**
  String themeUnlocked(String themeName);

  /// No description provided for @themeShowcaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme: {themeName}'**
  String themeShowcaseTitle(String themeName);

  /// No description provided for @primaryColors.
  ///
  /// In en, this message translates to:
  /// **'Primary Colors'**
  String get primaryColors;

  /// No description provided for @primary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primary;

  /// No description provided for @primaryVariant.
  ///
  /// In en, this message translates to:
  /// **'Primary Variant'**
  String get primaryVariant;

  /// No description provided for @onPrimary.
  ///
  /// In en, this message translates to:
  /// **'On Primary'**
  String get onPrimary;

  /// No description provided for @accent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get accent;

  /// No description provided for @onAccent.
  ///
  /// In en, this message translates to:
  /// **'On Accent'**
  String get onAccent;

  /// No description provided for @backgroundColors.
  ///
  /// In en, this message translates to:
  /// **'Background Colors'**
  String get backgroundColors;

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// No description provided for @surface.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get surface;

  /// No description provided for @surfaceVariant.
  ///
  /// In en, this message translates to:
  /// **'Surface Variant'**
  String get surfaceVariant;

  /// No description provided for @textColors.
  ///
  /// In en, this message translates to:
  /// **'Text Colors'**
  String get textColors;

  /// No description provided for @textPrimary.
  ///
  /// In en, this message translates to:
  /// **'Text Primary'**
  String get textPrimary;

  /// No description provided for @textSecondary.
  ///
  /// In en, this message translates to:
  /// **'Text Secondary'**
  String get textSecondary;

  /// No description provided for @textDisabled.
  ///
  /// In en, this message translates to:
  /// **'Text Disabled'**
  String get textDisabled;

  /// No description provided for @utilityColors.
  ///
  /// In en, this message translates to:
  /// **'Utility Colors'**
  String get utilityColors;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @uiElements.
  ///
  /// In en, this message translates to:
  /// **'UI Elements'**
  String get uiElements;

  /// No description provided for @elevated.
  ///
  /// In en, this message translates to:
  /// **'Elevated'**
  String get elevated;

  /// No description provided for @filled.
  ///
  /// In en, this message translates to:
  /// **'Filled'**
  String get filled;

  /// No description provided for @outlined.
  ///
  /// In en, this message translates to:
  /// **'Outlined'**
  String get outlined;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @inputField.
  ///
  /// In en, this message translates to:
  /// **'Input field'**
  String get inputField;

  /// No description provided for @enterText.
  ///
  /// In en, this message translates to:
  /// **'Enter text'**
  String get enterText;

  /// No description provided for @previewingTheme.
  ///
  /// In en, this message translates to:
  /// **'Previewing {themeName}'**
  String previewingTheme(String themeName);

  /// No description provided for @currentTheme.
  ///
  /// In en, this message translates to:
  /// **'Current: {themeName}'**
  String currentTheme(String themeName);

  /// No description provided for @unlockPremiumThemes.
  ///
  /// In en, this message translates to:
  /// **'Unlock Premium Themes'**
  String get unlockPremiumThemes;

  /// No description provided for @getAccessToAllThemesWithPro.
  ///
  /// In en, this message translates to:
  /// **'Get access to all themes with Pro'**
  String get getAccessToAllThemesWithPro;

  /// No description provided for @flagship.
  ///
  /// In en, this message translates to:
  /// **'Flagship'**
  String get flagship;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @freeThemes.
  ///
  /// In en, this message translates to:
  /// **'Free Themes'**
  String get freeThemes;

  /// No description provided for @premiumThemes.
  ///
  /// In en, this message translates to:
  /// **'Premium Themes'**
  String get premiumThemes;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @importedFileAsNewLayer.
  ///
  /// In en, this message translates to:
  /// **'Imported \"{fileName}\" as new layer'**
  String importedFileAsNewLayer(String fileName);

  /// No description provided for @importAsepriteFile.
  ///
  /// In en, this message translates to:
  /// **'Import Aseprite File'**
  String get importAsepriteFile;

  /// No description provided for @howImportAsepriteFile.
  ///
  /// In en, this message translates to:
  /// **'How would you like to import \"{fileName}\"?'**
  String howImportAsepriteFile(String fileName);

  /// No description provided for @importedFirstLayerFromFile.
  ///
  /// In en, this message translates to:
  /// **'Imported first layer from \"{fileName}\"'**
  String importedFirstLayerFromFile(String fileName);

  /// No description provided for @importAsLayer.
  ///
  /// In en, this message translates to:
  /// **'Import as Layer'**
  String get importAsLayer;

  /// No description provided for @openAsProject.
  ///
  /// In en, this message translates to:
  /// **'Open as Project'**
  String get openAsProject;

  /// No description provided for @copyFrame.
  ///
  /// In en, this message translates to:
  /// **'Copy Frame'**
  String get copyFrame;

  /// No description provided for @addFrame.
  ///
  /// In en, this message translates to:
  /// **'Add Frame'**
  String get addFrame;

  /// No description provided for @deleteFrame.
  ///
  /// In en, this message translates to:
  /// **'Delete Frame'**
  String get deleteFrame;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @addState.
  ///
  /// In en, this message translates to:
  /// **'Add State'**
  String get addState;

  /// No description provided for @copyState.
  ///
  /// In en, this message translates to:
  /// **'Copy State'**
  String get copyState;

  /// No description provided for @addAnimationState.
  ///
  /// In en, this message translates to:
  /// **'Add Animation State'**
  String get addAnimationState;

  /// No description provided for @stateName.
  ///
  /// In en, this message translates to:
  /// **'State Name'**
  String get stateName;

  /// No description provided for @columns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get columns;

  /// No description provided for @tileModeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Tile Mode - preview seamless tiling'**
  String get tileModeTooltip;

  /// No description provided for @settingsStylusMode.
  ///
  /// In en, this message translates to:
  /// **'Settings (Stylus Mode)'**
  String get settingsStylusMode;

  /// No description provided for @onionSkinTooltip.
  ///
  /// In en, this message translates to:
  /// **'Onion Skin (long-press to set opacity)'**
  String get onionSkinTooltip;

  /// No description provided for @sprayPaintToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Creates a spray effect with particles'**
  String get sprayPaintToolDescription;

  /// No description provided for @lineToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Draw straight lines between two points'**
  String get lineToolDescription;

  /// No description provided for @circleToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Draw perfect circles and ellipses'**
  String get circleToolDescription;

  /// No description provided for @rectangleToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Draw rectangles and squares'**
  String get rectangleToolDescription;

  /// No description provided for @triangleToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Draw triangular shapes'**
  String get triangleToolDescription;

  /// No description provided for @diamondToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Draw diamond shapes'**
  String get diamondToolDescription;

  /// No description provided for @hexagonToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Draw hexagonal shapes'**
  String get hexagonToolDescription;

  /// No description provided for @heartToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Draw heart shapes'**
  String get heartToolDescription;

  /// No description provided for @arrowToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Draw arrow shapes'**
  String get arrowToolDescription;

  /// No description provided for @lightningToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Draw lightning bolt shapes'**
  String get lightningToolDescription;

  /// No description provided for @crossToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Draw cross or plus shapes'**
  String get crossToolDescription;

  /// No description provided for @spiralToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Draw spiral shapes'**
  String get spiralToolDescription;

  /// No description provided for @cloudToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Draw cloud shapes'**
  String get cloudToolDescription;

  /// No description provided for @penToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Advanced freehand drawing tool'**
  String get penToolDescription;

  /// No description provided for @rectangleSelectToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Select a rectangular area'**
  String get rectangleSelectToolDescription;

  /// No description provided for @ellipseSelectToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Select an elliptical area'**
  String get ellipseSelectToolDescription;

  /// No description provided for @lassoToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Freehand selection tool'**
  String get lassoToolDescription;

  /// No description provided for @magicWandToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Select contiguous pixels by color'**
  String get magicWandToolDescription;

  /// No description provided for @curve.
  ///
  /// In en, this message translates to:
  /// **'Curve'**
  String get curve;

  /// No description provided for @curveToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Draw smooth curved lines'**
  String get curveToolDescription;

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @moveToolDescription.
  ///
  /// In en, this message translates to:
  /// **'Move and drag elements'**
  String get moveToolDescription;
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
