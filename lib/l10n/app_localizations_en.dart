// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class StringsEn extends Strings {
  StringsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Picell';

  @override
  String get aboutTitle => 'About Picell';

  @override
  String get welcome => 'Welcome to Picell!';

  @override
  String get aboutAppDescription =>
      'Picell is your gateway to creating amazing pixel art. Whether you\'re a seasoned artist or just starting out, our app provides the tools you need to bring your pixelated visions to life.';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get features =>
      'Intuitive pixel editing tools, \nCustom color palettes, Layer support for complex artwork, \nAnimation timeline for creating GIFs, \nExport in various formats, \nCommunity sharing and inspiration';

  @override
  String get featuresTitle => 'Key Features:';

  @override
  String get visitWebsite => 'Visit my website for more information:';

  @override
  String get pickAColor => 'Pick a color';

  @override
  String get colorPicker => 'Color Picker';

  @override
  String get gotIt => 'Got it';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get clear => 'Clear';

  @override
  String get save => 'Save';

  @override
  String get saveAs => 'Save As';

  @override
  String get open => 'Open';

  @override
  String get export => 'Export';

  @override
  String get import => 'Import';

  @override
  String get share => 'Share';

  @override
  String get close => 'Close';

  @override
  String get projects => 'Projects';

  @override
  String get lineTool => 'Line';

  @override
  String get rectangleTool => 'Rectangle';

  @override
  String get circleTool => 'Circle';

  @override
  String get about => 'About';

  @override
  String get invalidFileContent => 'Invalid file content';

  @override
  String get anErrorOccurred => 'An error occurred';

  @override
  String get tryAgain => 'Try again';

  @override
  String get creatingProject => 'Creating project...';

  @override
  String get openingProject => 'Opening project...';

  @override
  String get noProjectsFound => 'No projects found';

  @override
  String get createNewProject => 'Create New';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteProject => 'Delete Project';

  @override
  String get areYouSureWantToDeleteProject =>
      'Are you sure you want to delete this project?';

  @override
  String get renameProject => 'Rename Project';

  @override
  String get projectName => 'Project Name';

  @override
  String timeAgo(String time) {
    return '$time ago';
  }

  @override
  String get justNow => 'Just now';

  @override
  String frameCount(int current, int total) {
    return 'Frame $current/$total';
  }

  @override
  String get playbackSpeed => 'Speed:';

  @override
  String duration(int ms) {
    return 'Duration: ${ms}ms';
  }

  @override
  String get animationPreview => 'Animation Preview';

  @override
  String get colorPalette => 'Color Palette';

  @override
  String get currentColor => 'Current Color';

  @override
  String get add => 'Add';

  @override
  String get layers => 'Layers';

  @override
  String get deleteLayer => 'Delete Layer';

  @override
  String get areYouSureWantToDeleteLayer =>
      'Are you sure you want to delete this layer?';

  @override
  String get newProject => 'New Project';

  @override
  String get template => 'Template';

  @override
  String get width => 'Width';

  @override
  String get height => 'Height';

  @override
  String get create => 'Create';

  @override
  String get subscriptions => 'Subscriptions';

  @override
  String get fileMenu => 'File';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Logout';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get signInToSyncProjects => 'Sign in to sync your projects.';

  @override
  String get signingIn => 'Signing In...';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get noEmail => 'No email';

  @override
  String get feedback_title => 'Feedback';

  @override
  String get feedback_thank_you => 'Thank you for your feedback!';

  @override
  String get feedback_thank_you_message =>
      'Your opinion is very important to us and will help make the app better.';

  @override
  String get feedback_return => 'Return';

  @override
  String get feedback_help_us => 'Help us become better';

  @override
  String get feedback_intro =>
      'Your opinion is very important for the project development. Please answer a few questions.';

  @override
  String feedback_answered(int count, int total) {
    return 'Answered: $count of $total';
  }

  @override
  String get feedback_required => 'Required';

  @override
  String get feedback_sending => 'Sending...';

  @override
  String get feedback_send => 'Send';

  @override
  String get feedback_validation_error =>
      'Please answer all required questions';

  @override
  String get feedback_very_poor => 'Very poor';

  @override
  String get feedback_excellent => 'Excellent';

  @override
  String get feedback_yes => 'Yes';

  @override
  String get feedback_no => 'No';

  @override
  String get feedback_text_placeholder => 'Enter your answer...';

  @override
  String get feedback_q_satisfaction => 'How satisfied are you with the app?';

  @override
  String get feedback_q_missing_features => 'What features are you missing?';

  @override
  String get feedback_q_missing_features_placeholder =>
      'Describe the features you would like to see...';

  @override
  String get feedback_q_bug_reports =>
      'Have you encountered any errors or crashes?';

  @override
  String get feedback_q_bug_reports_placeholder =>
      'Describe the problems you encountered...';

  @override
  String get feedback_q_price_satisfaction =>
      'Are you satisfied with the current app price?';

  @override
  String get feedback_q_price_feedback =>
      'If not, what price do you consider fair?';

  @override
  String get feedback_q_price_free => 'Free';

  @override
  String get feedback_q_price_up_to_5 => 'Up to \$5';

  @override
  String get feedback_q_price_5_to_10 => '\$5 - \$10';

  @override
  String get feedback_q_price_10_to_20 => '\$10 - \$20';

  @override
  String get feedback_q_price_more_20 => 'More than \$20';

  @override
  String get feedback_q_patreon_support =>
      'Will you support the project on Patreon?';

  @override
  String get feedback_q_patreon_definitely => 'Yes, definitely';

  @override
  String get feedback_q_patreon_if_exclusive =>
      'Maybe, if there are exclusive features';

  @override
  String get feedback_q_patreon_if_reasonable =>
      'Maybe, if the price is reasonable';

  @override
  String get feedback_q_patreon_probably_not => 'Probably not';

  @override
  String get feedback_q_patreon_no => 'No, not planning to';

  @override
  String get feedback_q_patreon_tier =>
      'Which Patreon support tier interests you?';

  @override
  String get feedback_q_patreon_tier_3 =>
      '\$3/month - Early access to features';

  @override
  String get feedback_q_patreon_tier_5 => '\$5/month - + Exclusive themes';

  @override
  String get feedback_q_patreon_tier_10 =>
      '\$10/month - + Influence on development';

  @override
  String get feedback_q_usage_frequency => 'How often do you use the app?';

  @override
  String get feedback_q_usage_daily => 'Every day';

  @override
  String get feedback_q_usage_several_week => 'Several times a week';

  @override
  String get feedback_q_usage_once_week => 'Once a week';

  @override
  String get feedback_q_usage_several_month => 'Several times a month';

  @override
  String get feedback_q_usage_rarely => 'Rarely';

  @override
  String get feedback_q_main_use_case => 'What do you mainly use the app for?';

  @override
  String get feedback_q_use_pixel_art => 'Creating pixel art';

  @override
  String get feedback_q_use_game_design => 'Game design';

  @override
  String get feedback_q_use_animation => 'Animation';

  @override
  String get feedback_q_use_hobby => 'Hobby/entertainment';

  @override
  String get feedback_q_use_professional => 'Professional work';

  @override
  String get feedback_q_use_learning => 'Learning';

  @override
  String get feedback_q_additional_feedback =>
      'Additional comments and suggestions';

  @override
  String get feedback_q_additional_feedback_placeholder =>
      'Share your thoughts about the app...';

  @override
  String get feedback_q_recommend => 'Would you recommend this app to friends?';

  @override
  String get firstFrame => 'First Frame';

  @override
  String get previousFrame => 'Previous Frame';

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Play';

  @override
  String get nextFrame => 'Next Frame';

  @override
  String get lastFrame => 'Last Frame';

  @override
  String get feedback_dialog_title => 'We\'d Love Your Feedback!';

  @override
  String get feedback_dialog_description =>
      'Your opinion matters! Help us make the app better by sharing your thoughts.';

  @override
  String get feedback_dialog_benefit_1 => 'Share ideas for new features';

  @override
  String get feedback_dialog_benefit_2 => 'Report bugs and issues';

  @override
  String get feedback_dialog_benefit_3 => 'Help shape the app\'s future';

  @override
  String get feedback_dialog_leave_feedback => 'Leave Feedback';

  @override
  String get feedback_dialog_maybe_later => 'Maybe Later';

  @override
  String get feedback_dialog_dont_ask => 'Don\'t ask again';

  @override
  String get paletteBasic => 'Basic';

  @override
  String get paletteShades => 'Shades';

  @override
  String get paletteComplementary => 'Complementary';

  @override
  String get paletteAnalogous => 'Analogous';

  @override
  String get paletteTriadic => 'Triadic';

  @override
  String get paletteMonochromatic => 'Monochromatic';

  @override
  String get paletteCustom => 'Custom';

  @override
  String get paletteImported => 'Imported';

  @override
  String get paletteImportedCount => 'colors';

  @override
  String get addToCustomPalette => 'Add to custom palette';

  @override
  String get noCustomColors =>
      'No custom colors added yet.\nAdd colors using the + button above.';

  @override
  String get effects => 'Effects';

  @override
  String get editorSettings => 'Editor Settings';

  @override
  String get resetToDefaults => 'Reset to defaults';

  @override
  String get input => 'Input';

  @override
  String get display => 'Display';

  @override
  String get showGrid => 'Show Grid';

  @override
  String get showGridSubtitle => 'Display grid lines on canvas';

  @override
  String get pixelGridOverlay => 'Pixel Grid Overlay';

  @override
  String get pixelGridSubtitle => 'Show pixel boundaries when zoomed in';

  @override
  String get gridOpacity => 'Grid Opacity';

  @override
  String get selectionTransforms => 'Selection Transforms';

  @override
  String get transformInterpolation => 'Interpolation';

  @override
  String get transformInterpolationSubtitle =>
      'Sampling used when resizing and rotating selections';

  @override
  String get nearestNeighbor => 'Nearest';

  @override
  String get bilinear => 'Bilinear';

  @override
  String get zoomNavigation => 'Zoom & Navigation';

  @override
  String get zoomSensitivity => 'Zoom Sensitivity';

  @override
  String get zoomSensitivitySubtitle => 'How fast pinch-to-zoom responds';

  @override
  String get minZoom => 'Min Zoom';

  @override
  String get maxZoom => 'Max Zoom';

  @override
  String get gestures => 'Gestures';

  @override
  String get twoFingerUndo => 'Two-Finger Tap Undo';

  @override
  String get twoFingerUndoSubtitle => 'Quick tap with two fingers to undo';

  @override
  String get done => 'Done';

  @override
  String get stylusMode => 'Stylus Mode';

  @override
  String get stylusModeSubtitleOn =>
      'Draw with stylus only • Touch for navigation';

  @override
  String get stylusModeSubtitleOff => 'Draw with both touch and stylus';

  @override
  String get importImage => 'Import Image';

  @override
  String get selectImportOption => 'Select how you want to import your image:';

  @override
  String get convertToPixelArt => 'Convert to Pixel Art';

  @override
  String get convertToPixelArtDescription =>
      'Import and automatically convert the image to pixel art style on a new layer.';

  @override
  String get importAsBackground => 'Import as Background';

  @override
  String get importAsBackgroundDescription =>
      'Import the image as-is and use it as a reference background layer.';

  @override
  String get conversionSettings => 'Conversion Settings';

  @override
  String get paletteColors => 'Palette Colors';

  @override
  String get fullColor => 'Full Color';

  @override
  String get dithering => 'Dithering';

  @override
  String get noDithering => 'None';

  @override
  String get alphaThreshold => 'Alpha Threshold';

  @override
  String get chooseImage => 'Choose Image';

  @override
  String get tinyIcon => 'Tiny Icon';

  @override
  String get smallSprite => 'Small Sprite';

  @override
  String get mediumCharacter => 'Medium Character';

  @override
  String get largeScene => 'Large Scene';

  @override
  String get projectNameRequired => 'Please enter a project name';

  @override
  String get templateRequired => 'Please select a template';

  @override
  String planLimitError(int limit) {
    return 'Your plan is limited to $limit pixels';
  }

  @override
  String get widthRequired => 'Enter width';

  @override
  String get heightRequired => 'Enter height';

  @override
  String widthRangeError(int max) {
    return 'Width: 1-$max';
  }

  @override
  String heightRangeError(int max) {
    return 'Height: 1-$max';
  }

  @override
  String get saveImage => 'Save Image';

  @override
  String get png => 'PNG';

  @override
  String get animatedGif => 'Animated GIF';

  @override
  String get proPlanRequired => 'Pro Plan Required';

  @override
  String get spriteSheet => 'Sprite Sheet';

  @override
  String get transparentBackground => 'Transparent Background';

  @override
  String get transparent => 'Transparent';

  @override
  String get spriteSheetOptions => 'Sprite Sheet Options';

  @override
  String get columnsLabel => 'Columns';

  @override
  String get spacingPx => 'Spacing (px)';

  @override
  String get exportSize => 'Export Size';

  @override
  String scaleWithValues(String scale) {
    return 'Scale: ${scale}x';
  }

  @override
  String get format => 'Format';

  @override
  String get options => 'Options';

  @override
  String editEffect(String name) {
    return 'Edit $name Effect';
  }

  @override
  String get applyChanges => 'Apply Changes';

  @override
  String get preview => 'Preview';

  @override
  String get quickPresets => 'Quick Presets';

  @override
  String get parameters => 'Parameters';

  @override
  String get previewNotAvailable => 'Preview not available';

  @override
  String get tapToChange => 'Tap to change';

  @override
  String get enable => 'Enable';

  @override
  String get uiFieldTap => 'Tap';

  @override
  String get uiFieldEnabled => 'Enabled';

  @override
  String get uiFieldDisabled => 'Disabled';

  @override
  String get presetDarker => 'Darker';

  @override
  String get presetNormal => 'Normal';

  @override
  String get presetBrighter => 'Brighter';

  @override
  String get presetVeryBright => 'Very Bright';

  @override
  String get presetLow => 'Low';

  @override
  String get presetHigh => 'High';

  @override
  String get presetVeryHigh => 'Very High';

  @override
  String get presetSubtle => 'Subtle';

  @override
  String get presetSoft => 'Soft';

  @override
  String get presetMedium => 'Medium';

  @override
  String get presetStrong => 'Strong';

  @override
  String get effectBrightness => 'Brightness';

  @override
  String get effectContrast => 'Contrast';

  @override
  String get effectBlur => 'Blur';

  @override
  String get effectVignette => 'Vignette';

  @override
  String get effectInvert => 'Invert';

  @override
  String get effectGrayscale => 'Grayscale';

  @override
  String get effectSepia => 'Sepia';

  @override
  String get effectThreshold => 'Threshold';

  @override
  String get effectPixelate => 'Pixelate';

  @override
  String get effectSharpen => 'Sharpen';

  @override
  String get effectNoise => 'Noise';

  @override
  String get effectGlow => 'Glow';

  @override
  String get effectGlitch => 'Glitch';

  @override
  String get effectSparkle => 'Sparkle';

  @override
  String get effectFire => 'Fire';

  @override
  String get effectRain => 'Rain';

  @override
  String get selectEffect => 'Select Effect';

  @override
  String get searchEffects => 'Search effects...';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryColorTone => 'Color & Tone';

  @override
  String get categoryBlurSharpen => 'Blur & Sharpen';

  @override
  String get categoryArtistic => 'Artistic';

  @override
  String get categoryAnimation => 'Animation';

  @override
  String get categoryNature => 'Nature';

  @override
  String get categoryParticles => 'Particles';

  @override
  String get categoryDistortion => 'Distortion';

  @override
  String get categoryTextures => 'Textures';

  @override
  String get categorySpecialFx => 'Special FX';

  @override
  String get noEffectsMatch => 'No effects match your search';

  @override
  String get premiumEffect => 'Premium Effect';

  @override
  String get proVersionStatus => 'This effect is available in the Pro version.';

  @override
  String get proFeaturesInclude => 'Pro features include:';

  @override
  String get featureAdvancedEffects => 'Advanced effects and tools';

  @override
  String get featureUnlimitedProjects => 'Unlimited projects';

  @override
  String get featureCloudBackup => 'Cloud backup';

  @override
  String get featurePrioritySupport => 'Priority support';

  @override
  String get maybeLater => 'Maybe Later';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String get effectsPanelRemoveEffectTitle => 'Remove Effect';

  @override
  String effectsPanelRemoveEffectMessage(String effectName) {
    return 'Are you sure you want to remove the $effectName effect?';
  }

  @override
  String get effectsPanelClearAllEffectsTitle => 'Clear All Effects';

  @override
  String get effectsPanelClearAllEffectsMessage =>
      'Are you sure you want to remove all effects from this layer?';

  @override
  String get effectsPanelClearAll => 'Clear All';

  @override
  String effectsPanelAppliedToLayerMessage(String effectName) {
    return 'Effect $effectName applied to layer';
  }

  @override
  String get effectsPanelActionApply => 'Apply';

  @override
  String get effectsPanelActionRemove => 'Remove';

  @override
  String get effectsPanelActionMore => 'More';

  @override
  String get effectsPanelMoreActionsTitle => 'More Actions';

  @override
  String get effectsPanelApplyAll => 'Apply All';

  @override
  String get ellipseSelection => 'Ellipse Selection';

  @override
  String get ellipseSelectionTooltip => 'Select an elliptical area';

  @override
  String get autoSelectLayer => 'Auto-Select';

  @override
  String get autoSelectLayerTooltip =>
      'Select all non-empty pixels in the current layer';

  @override
  String get selectionAnchor => 'Selection Anchor';
}
