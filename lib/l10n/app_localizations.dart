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
    Locale('en', 'US'),
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
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'US':
            return StringsEnUs();
        }
        break;
      }
  }

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
