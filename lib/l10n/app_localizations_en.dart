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
  String get category => 'Category';

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

  @override
  String get feedback => 'Feedback';

  @override
  String get createNewProjectTooltip => 'Create New Project';

  @override
  String failedToProcessFile(String fileName) {
    return 'Failed to process $fileName';
  }

  @override
  String importingFile(String fileName) {
    return 'Importing $fileName...';
  }

  @override
  String importedProjectSuccessfully(String projectName) {
    return 'Imported \"$projectName\" successfully';
  }

  @override
  String failedToImport(String error) {
    return 'Failed to import: $error';
  }

  @override
  String unsupportedFileType(String fileName) {
    return 'Unsupported file type: $fileName';
  }

  @override
  String get pleaseSignInToUploadProjects =>
      'Please sign in to upload projects';

  @override
  String get pleaseSignInToUpdateProjects =>
      'Please sign in to update projects';

  @override
  String get projectNotSyncedToCloud => 'Project is not synced to cloud';

  @override
  String get pleaseSignInToRemoveCloudProjects =>
      'Please sign in to remove cloud projects';

  @override
  String get removingFromCloud => 'Removing from cloud...';

  @override
  String get projectRemovedFromCloudSuccessfully =>
      'Project removed from cloud successfully';

  @override
  String failedToRemoveFromCloud(String error) {
    return 'Failed to remove from cloud: $error';
  }

  @override
  String get search => 'Search...';

  @override
  String get myProjects => 'My Projects';

  @override
  String get noProjectsYet => 'No projects yet';

  @override
  String get createOne => 'Create one';

  @override
  String get searchProjects => 'Search projects...';

  @override
  String get discoverAmazingPixelArt => 'Discover amazing pixel art';

  @override
  String get sortBy => 'Sort by';

  @override
  String get mostRecent => 'Most Recent';

  @override
  String get mostPopular => 'Most Popular';

  @override
  String get mostViewed => 'Most Viewed';

  @override
  String get mostLiked => 'Most Liked';

  @override
  String get titleAZ => 'Title A-Z';

  @override
  String get all => 'All';

  @override
  String get featuredProjects => 'Featured Projects';

  @override
  String get errorLoadingProjects => 'Error loading projects';

  @override
  String get deletingProject => 'Deleting project...';

  @override
  String get projectDeletedSuccessfully => 'Project deleted successfully';

  @override
  String get failedToDeleteProject => 'Failed to delete project';

  @override
  String failedToDeleteProjectWithError(String error) {
    return 'Failed to delete project: $error';
  }

  @override
  String get unlike => 'Unlike';

  @override
  String get like => 'Like';

  @override
  String get editProject => 'Edit Project';

  @override
  String get public => 'Public';

  @override
  String get private => 'Private';

  @override
  String get analytics => 'Analytics';

  @override
  String get stats => 'Stats';

  @override
  String likeCountLabel(String count) {
    return '$count Likes';
  }

  @override
  String commentCountLabel(String count) {
    return '$count Comments';
  }

  @override
  String get download => 'Download';

  @override
  String get openProject => 'Open Project';

  @override
  String get downloadProject => 'Download Project';

  @override
  String get localProjectNotFound => 'Local project not found';

  @override
  String get comments => 'Comments';

  @override
  String get addComment => 'Add Comment';

  @override
  String get noCommentsYet => 'No comments yet';

  @override
  String get beFirstToComment => 'Be the first to leave a comment!';

  @override
  String get failedToLoadComments => 'Failed to load comments';

  @override
  String get edited => 'Edited';

  @override
  String get makeProjectPublic => 'Make Project Public';

  @override
  String get makeProjectPrivate => 'Make Project Private';

  @override
  String get makeProjectPublicMessage =>
      'This will make your project visible to everyone in the community. Anyone will be able to view, like, and comment on it.';

  @override
  String get makeProjectPrivateMessage =>
      'This will hide your project from the public community. Only you will be able to see it.';

  @override
  String get projectWillBePublic => 'Project will be publicly visible';

  @override
  String get projectWillBePrivate => 'Project will be private';

  @override
  String get projectIsNowPublic => 'Project is now public';

  @override
  String get projectIsNowPrivate => 'Project is now private';

  @override
  String failedToUpdateVisibility(String error) {
    return 'Failed to update visibility: $error';
  }

  @override
  String get makePublic => 'Make Public';

  @override
  String get makePrivate => 'Make Private';

  @override
  String get deleteProjectCannotBeUndone =>
      'Are you sure you want to delete this project? This action cannot be undone.';

  @override
  String get thisWillPermanentlyDelete => 'This will permanently delete:';

  @override
  String get deleteProjectConsequences =>
      '• Project data and artwork\n• All comments and likes\n• Download statistics';

  @override
  String typeProjectTitleToConfirmDeletion(String title) {
    return 'Type \"$title\" to confirm deletion:';
  }

  @override
  String get enterProjectTitle => 'Enter project title...';

  @override
  String get deleteForever => 'Delete Forever';

  @override
  String get openingProjectEditor => 'Opening project editor...';

  @override
  String get projectLinkCopied => 'Project link copied to clipboard!';

  @override
  String get addedToFavorites => 'Added to favorites!';

  @override
  String nowFollowingUser(String username) {
    return 'Now following $username!';
  }

  @override
  String get reportProject => 'Report Project';

  @override
  String get reportProjectMessage =>
      'Are you sure you want to report this project? Please only report content that violates our community guidelines.';

  @override
  String get reportThanks =>
      'Thank you for your report. We will review it shortly.';

  @override
  String get report => 'Report';

  @override
  String get premiumRequiredToDownloadProjects =>
      'Premium subscription required to download projects';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get downloadProjectRewardSubtitle =>
      'To download this project, you can either:';

  @override
  String get thankYouWatchingDownloadStarting =>
      'Thank you for watching! Your download is starting...';

  @override
  String get pleaseSignInToAddComments => 'Please sign in to add comments';

  @override
  String get writeYourComment => 'Write your comment...';

  @override
  String get commentAddedSuccessfully => 'Comment added successfully!';

  @override
  String failedToAddComment(String error) {
    return 'Failed to add comment: $error';
  }

  @override
  String get post => 'Post';

  @override
  String get chooseTheme => 'Choose Theme';

  @override
  String get importFile => 'Import File';

  @override
  String get theme => 'Theme';

  @override
  String get getPro => 'Get Pro';

  @override
  String get supportOnKofi => 'Support on Ko-fi';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get size => 'Size';

  @override
  String get views => 'Views';

  @override
  String get downloads => 'Downloads';

  @override
  String get published => 'Published!';

  @override
  String get forkedFrom => 'Forked from ';

  @override
  String byUser(String username) {
    return ' by $username';
  }

  @override
  String get projectAnalytics => 'Project Analytics';

  @override
  String get totalViews => 'Total Views';

  @override
  String get totalLikes => 'Total Likes';

  @override
  String get detailedAnalytics => 'Detailed Analytics';

  @override
  String get advancedAnalyticsSoon =>
      'Advanced analytics features will be available soon.';

  @override
  String get details => 'Details';

  @override
  String get title => 'Title';

  @override
  String get projectTitleHint => 'Give your project a name';

  @override
  String get description => 'Description';

  @override
  String get projectDescriptionHint =>
      'Tell the community about this project (optional)';

  @override
  String get visibility => 'Visibility';

  @override
  String get tags => 'Tags';

  @override
  String get searchTags => 'Search tags…';

  @override
  String get failedToLoadTags => 'Failed to load tags';

  @override
  String get pleaseEnterTitle => 'Please enter a title';

  @override
  String get removeFromCloudQuestion => 'Remove from Cloud?';

  @override
  String get removeFromCommunityMessage =>
      'This will remove the project from the community. Your local copy will remain.';

  @override
  String get remove => 'Remove';

  @override
  String get updateProject => 'Update Project';

  @override
  String get publishToCommunity => 'Publish to Community';

  @override
  String get synced => 'Synced';

  @override
  String get visibleToEveryone => 'Visible to everyone';

  @override
  String get onlyVisibleToYou => 'Only visible to you';

  @override
  String get maximumTagsAllowed => 'Maximum 5 tags allowed';

  @override
  String frameCountSimple(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'frames',
      one: 'frame',
    );
    return '$count $_temp0';
  }

  @override
  String layerCountSimple(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'layers',
      one: 'layer',
    );
    return '$count $_temp0';
  }

  @override
  String get cloudManagement => 'Cloud Management';

  @override
  String cloudId(String id) {
    return 'Cloud ID: $id';
  }

  @override
  String get preparingUpdate => 'Preparing update…';

  @override
  String get preparingProject => 'Preparing project…';

  @override
  String get generatingThumbnail => 'Generating thumbnail…';

  @override
  String get updatingOnCloud => 'Updating on cloud…';

  @override
  String get uploadingToCloud => 'Uploading to cloud…';

  @override
  String get finalizing => 'Finalizing…';

  @override
  String get updated => 'Updated!';

  @override
  String get updating => 'Updating…';

  @override
  String get publishing => 'Publishing…';

  @override
  String get update => 'Update';

  @override
  String get publish => 'Publish';

  @override
  String get downloadingProject => 'Downloading Project';

  @override
  String get downloadingProjectData => 'Downloading project data...';

  @override
  String get downloadComplete => 'Download Complete!';

  @override
  String get projectSavedLocal => 'Project saved to your local projects';

  @override
  String get downloadFailed => 'Download Failed';

  @override
  String get resyncWithCloud => 'Resync with cloud';

  @override
  String get syncToCloud => 'Sync to cloud';

  @override
  String get removeFromCloud => 'Remove from Cloud';

  @override
  String get removeFromCloudMessage =>
      'This will remove the project from the cloud and make it local-only. Your local copy will remain unchanged. Are you sure?';

  @override
  String get syncedCloudDeleteWarning =>
      'This project is synced to the cloud. Deleting locally will not affect the cloud version.';

  @override
  String get openLocalProject => 'Open Local Project';

  @override
  String get premiumRequired => 'Premium Required';

  @override
  String byUserInline(String username) {
    return 'by $username';
  }

  @override
  String get createTemplate => 'Create Template';

  @override
  String layerNameLabel(String name) {
    return 'Name: $name';
  }

  @override
  String layerSizeLabel(int width, int height) {
    return 'Size: $width×$height';
  }

  @override
  String nonTransparentPixels(int count) {
    return 'Pixels: $count non-transparent';
  }

  @override
  String get templateName => 'Template Name';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get saveOptions => 'Save Options';

  @override
  String get saveLocally => 'Save Locally';

  @override
  String get storeOnDeviceOnly => 'Store on this device only';

  @override
  String get uploadToCloud => 'Upload to Cloud';

  @override
  String get shareWithCommunity => 'Share with the community';

  @override
  String get privateCloudStorage => 'Private cloud storage';

  @override
  String get otherUsersCanDiscoverTemplate =>
      'Other users can discover and use this template';

  @override
  String get onlyYouCanAccessTemplate => 'Only you can access this template';

  @override
  String get saveLocallyAndUpload => 'Save Locally & Upload';

  @override
  String get bestOfBothWorlds => 'Best of both worlds';

  @override
  String get signInToUploadTemplates => 'Sign in to upload templates';

  @override
  String get shareTemplatesWithCommunity =>
      'Share your templates with the community';

  @override
  String get failedToConvertLayerToTemplate =>
      'Failed to convert layer to template';

  @override
  String get failedToSaveTemplateLocally => 'Failed to save template locally';

  @override
  String get failedToUploadTemplateToServer =>
      'Failed to upload template to server';

  @override
  String errorCreatingTemplate(String error) {
    return 'Error creating template: $error';
  }

  @override
  String get templateSavedLocally => 'Template saved locally!';

  @override
  String get templateUploadedSuccessfully => 'Template uploaded successfully!';

  @override
  String get templateSavedAndUploaded => 'Template saved locally and uploaded!';

  @override
  String get templateSavedUploadFailed =>
      'Template saved locally (upload failed)';

  @override
  String get templateUploadedLocalSaveFailed =>
      'Template uploaded (local save failed)';

  @override
  String get templateCreationFailed => 'Template creation failed';

  @override
  String get templateGallery => 'Template Gallery';

  @override
  String get allTemplates => 'All Templates';

  @override
  String get local => 'Local';

  @override
  String get community => 'Community';

  @override
  String get failedTemplateDetailsCached =>
      'Failed to load template details. Using cached data.';

  @override
  String errorLoadingTemplate(String error) {
    return 'Error loading template: $error';
  }

  @override
  String get loadingTemplate => 'Loading template...';

  @override
  String get deleteTemplate => 'Delete Template';

  @override
  String deleteTemplateQuestion(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get deleteLocalTemplateWarning =>
      'This template will be permanently removed from your local storage.';

  @override
  String get deleteCloudTemplateWarning =>
      'This template will be removed from the cloud and can\'t be recovered.';

  @override
  String templateDeletedSuccessfully(String name) {
    return 'Template \"$name\" deleted successfully';
  }

  @override
  String failedToDeleteTemplate(String name) {
    return 'Failed to delete template \"$name\"';
  }

  @override
  String get searchTemplates => 'Search templates...';

  @override
  String get loadingTemplates => 'Loading templates...';

  @override
  String get premiumTemplate => 'Premium Template';

  @override
  String get templateAvailableInPro =>
      'This template is available in the Pro version.';

  @override
  String get premiumTemplatesFeature => '• Premium templates';

  @override
  String get advancedEffectsToolsFeature => '• Advanced effects and tools';

  @override
  String get unlimitedProjectsFeature => '• Unlimited projects';

  @override
  String get cloudBackupFeature => '• Cloud backup';

  @override
  String get prioritySupportFeature => '• Priority support';

  @override
  String get noLocalTemplates =>
      'No local templates found.\nCreate your first template from a layer!';

  @override
  String get noCommunityTemplates =>
      'No community templates found.\nTry adjusting your search or filters.';

  @override
  String get noUploadedTemplates =>
      'You haven\'t uploaded any templates yet.\nShare your creations with the community!';

  @override
  String get noTemplatesFoundAdjust =>
      'No templates found.\nTry adjusting your search or filters.';

  @override
  String showingTemplates(int displayed, String total) {
    String _temp0 = intl.Intl.selectLogic(
      total,
      {
        'none': '',
        'other': ' of $total',
      },
    );
    return 'Showing $displayed$_temp0 templates';
  }

  @override
  String get clickTemplateToApply => 'Click a template to apply it';

  @override
  String get pro => 'PRO';

  @override
  String get pleaseEnterTemplateName => 'Please enter a template name';

  @override
  String get signInToUploadTemplatesTitle => 'Sign in to Upload Templates';

  @override
  String get signInToUploadTemplatesSubtitle =>
      'Create an account to share your templates with the community.';

  @override
  String get myTemplates => 'My Templates';

  @override
  String get cloud => 'Cloud';

  @override
  String get tapToUnlock => 'Tap to Unlock';

  @override
  String get layerTemplateDefaultName => 'Layer Template';

  @override
  String get undoHistoryTitle => 'History';

  @override
  String undoHistoryStepCount(int total) {
    return '($total steps)';
  }

  @override
  String get undoHistoryRevertAll => 'Revert all';

  @override
  String get undoHistoryCurrentState => 'Current state';

  @override
  String undoHistoryFrameLayer(int frame, int layer) {
    return 'Frame $frame, Layer $layer';
  }

  @override
  String get keyboardShortcuts => 'Keyboard Shortcuts';

  @override
  String get copySelection => 'Copy selection';

  @override
  String get cutSelection => 'Cut selection';

  @override
  String get paste => 'Paste';

  @override
  String get duplicateLayer => 'Duplicate layer';

  @override
  String get selection => 'Selection';

  @override
  String get selectAll => 'Select all';

  @override
  String get deselect => 'Deselect';

  @override
  String get closePenPath => 'Close pen path';

  @override
  String get tools => 'Tools';

  @override
  String get pencil => 'Pencil';

  @override
  String get eraser => 'Eraser';

  @override
  String get eyedropper => 'Eyedropper';

  @override
  String get fill => 'Fill';

  @override
  String get selectMarquee => 'Select / Marquee';

  @override
  String get moveDrag => 'Move / Drag';

  @override
  String get pen => 'Pen';

  @override
  String get sprayPaint => 'Spray paint';

  @override
  String get panHold => 'Pan (hold)';

  @override
  String get eyedropperHold => 'Eyedropper (hold)';

  @override
  String get brush => 'Brush';

  @override
  String get increaseSize => 'Increase size';

  @override
  String get decreaseSize => 'Decrease size';

  @override
  String get colors => 'Colors';

  @override
  String get swapColors => 'Swap colors';

  @override
  String get defaultColors => 'Default colors';

  @override
  String get view => 'View';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get zoomToFit => 'Zoom to fit';

  @override
  String get zoomOneToOne => 'Zoom 1:1';

  @override
  String get toggleUi => 'Toggle UI';

  @override
  String get selectLayerOneToNine => 'Select layer 1-9';

  @override
  String get newLayer => 'New layer';

  @override
  String get deleteAccountCannotBeUndone => 'This action cannot be undone';

  @override
  String get deleteAccountPermanentDataWarning =>
      'Deleting your account will permanently remove all your data.';

  @override
  String get deleteAccountItemsIntro =>
      'The following will be permanently deleted:';

  @override
  String get deleteAccountPreferencesTitle => 'App Preferences';

  @override
  String get deleteAccountPreferencesSubtitle => 'Settings and customizations';

  @override
  String get deleteAccountInfoTitle => 'Account Information';

  @override
  String get deleteAccountInfoSubtitle => 'Profile and authentication data';

  @override
  String get deleteAccountTypeConfirm => 'Type \"DELETE\" to confirm:';

  @override
  String get deleteAccountTypeHint => 'Type DELETE here...';

  @override
  String get deleteAccountIrreversibleImmediate =>
      'This action is irreversible and will take effect immediately.';

  @override
  String get deleteAccountQuickConfirm =>
      'Are you sure you want to permanently delete your account?';

  @override
  String get deleteAccountQuickWarningList =>
      '• All your projects will be lost\n• Cloud backups will be deleted\n• This action cannot be undone';

  @override
  String failedToDeleteAccount(String error) {
    return 'Failed to delete account: $error';
  }

  @override
  String get proAccessActive => 'Pro Access Active';

  @override
  String proAccessRemaining(String time) {
    return 'You have $time of Pro access remaining.';
  }

  @override
  String get buyPro => 'Buy Pro';

  @override
  String get rewardUpgradeBullets =>
      '• Unlimited access to all features\n• One-time purchase\n• No ads\n• Priority support';

  @override
  String get tryPro45Minutes => 'Try Pro for 45 Minutes';

  @override
  String get rewardAdReadyBullets =>
      '• Watch a short video ad\n• Get 45 minutes of Pro access\n• Support the app development';

  @override
  String get rewardAdLoadingBullets =>
      '• Video ad is loading...\n• Please try again in a moment';

  @override
  String get watchAd => 'Watch Ad';

  @override
  String get loadingEllipsis => 'Loading...';

  @override
  String get loadingVideoAd => 'Loading video ad...';

  @override
  String get proAccessGranted45 => 'Pro access granted for 45 minutes!';

  @override
  String get videoAdNotCompleted =>
      'Video ad was not completed. Please try again or upgrade to Pro.';

  @override
  String failedToLoadVideoAd(String error) {
    return 'Failed to load video ad: $error';
  }

  @override
  String get rewardTimeZeroMinutes => '0 minutes';

  @override
  String rewardTimeMinutesSeconds(int minutes, int seconds) {
    return '$minutes min ${seconds}s';
  }

  @override
  String rewardTimeSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get selectionOptions => 'Selection Options';

  @override
  String get clearSelection => 'Clear Selection';

  @override
  String get invertSelection => 'Invert Selection';

  @override
  String get growSelectionOnePixel => 'Grow (+1px)';

  @override
  String get shrinkSelectionOnePixel => 'Shrink (-1px)';

  @override
  String get rotate90 => 'Rotate 90°';

  @override
  String get rotate180 => 'Rotate 180°';

  @override
  String get flipHorizontal => 'Flip Horizontal';

  @override
  String get flipVertical => 'Flip Vertical';

  @override
  String get cutToNewLayer => 'Cut to New Layer';

  @override
  String get copyToNewLayer => 'Copy to New Layer';

  @override
  String get cut => 'Cut';

  @override
  String get copy => 'Copy';

  @override
  String get clearArea => 'Clear Area';

  @override
  String get replaceSelection => 'Replace selection';

  @override
  String get addToSelectionShift => 'Add to selection (Shift)';

  @override
  String get subtractFromSelectionAlt => 'Subtract from selection (Alt)';

  @override
  String get textureBrush => 'Texture Brush';

  @override
  String get triangle => 'Triangle';

  @override
  String get diamond => 'Diamond';

  @override
  String get hexagon => 'Hexagon';

  @override
  String get heart => 'Heart';

  @override
  String get arrow => 'Arrow';

  @override
  String get lightning => 'Lightning';

  @override
  String get cross => 'Cross';

  @override
  String get spiral => 'Spiral';

  @override
  String get cloudShape => 'Cloud';

  @override
  String get rectangleSelect => 'Rectangle Select';

  @override
  String get lasso => 'Lasso';

  @override
  String get magicWand => 'Magic Wand';

  @override
  String get effectsPanelAllAppliedMessage =>
      'All effects applied to layer and removed from effects list';

  @override
  String effectsForLayer(String layerName) {
    return 'Effects for $layerName';
  }

  @override
  String get effectsPanelAddEffect => 'Add Effect';

  @override
  String get appliedEffects => 'Applied Effects';

  @override
  String effectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count effects',
      one: '1 effect',
      zero: '0 effects',
    );
    return '$_temp0';
  }

  @override
  String get effectsPreview => 'Effects Preview';

  @override
  String get effectPreview => 'Effect Preview';

  @override
  String get noEffectsApplied => 'No effects applied';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get finalResult => 'Final Result';

  @override
  String get original => 'Original';

  @override
  String get withEffect => 'With Effect';

  @override
  String get withEffects => 'With Effects';

  @override
  String effectsAppliedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count effects applied',
      one: '1 effect applied',
      zero: '0 effects applied',
    );
    return '$_temp0';
  }

  @override
  String get effectsAppliedInOrder => 'Effects are applied in order';

  @override
  String get effectsReorderHint =>
      'Effects are applied from top to bottom. Drag to reorder.';

  @override
  String get addYourFirstEffect => 'Add your first effect';

  @override
  String get layerEffects => 'Layer Effects';

  @override
  String get effectWatercolor => 'Watercolor';

  @override
  String get effectHalftone => 'Halftone';

  @override
  String get effectOilPaint => 'Oil Paint';

  @override
  String get effectEmboss => 'Emboss';

  @override
  String get ok => 'OK';

  @override
  String get staticEffect => 'Static Effect';

  @override
  String effectNotAnimatedMessage(String effectName) {
    return 'The $effectName effect is not an animated effect. Animation frame generation is only available for effects that support animation.';
  }

  @override
  String get generateAnimation => 'Generate Animation';

  @override
  String generateAnimationForEffect(String effectName) {
    return 'Generate animation frames for $effectName effect?';
  }

  @override
  String get animationDetails => 'Animation Details';

  @override
  String animationDetailEffect(String effectName) {
    return '• Effect: $effectName';
  }

  @override
  String animationDetailEstimatedFrames(int count) {
    return '• Estimated frames: ~$count';
  }

  @override
  String animationDetailProcessingTime(int seconds) {
    return '• Processing time: ~$seconds seconds';
  }

  @override
  String get generateAnimationTimelineNote =>
      'This will create multiple animation frames that you can add to your timeline.';

  @override
  String get generateAnimationFrames => 'Generate Animation Frames';

  @override
  String effectNameLabel(String effectName) {
    return '$effectName Effect';
  }

  @override
  String framesGeneratedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count frames generated',
      one: '1 frame generated',
      zero: '0 frames generated',
    );
    return '$_temp0';
  }

  @override
  String get generateFrames => 'Generate Frames';

  @override
  String get stop => 'Stop';

  @override
  String get frameLabel => 'Frame:';

  @override
  String get generatingFrames => 'Generating frames...';

  @override
  String get noFramesGenerated => 'No frames generated';

  @override
  String get animationSettings => 'Animation Settings';

  @override
  String get durationSeconds => 'Duration (seconds)';

  @override
  String get fps => 'FPS';

  @override
  String get totalFrames => 'Total Frames:';

  @override
  String get pingPongAnimation => 'Ping-Pong Animation';

  @override
  String get playForwardThenBackward => 'Play forward then backward';

  @override
  String get frameGeneration => 'Frame Generation';

  @override
  String get generateNewFrames => 'Generate New Frames';

  @override
  String get createNewFramesForAnimation =>
      'Create new frames for this animation';

  @override
  String get insertIntoTimeline => 'Insert Into Timeline';

  @override
  String get addFramesToExistingTimeline => 'Add frames to existing timeline';

  @override
  String get insertPosition => 'Insert Position:';

  @override
  String afterFrame(int frame) {
    return 'After frame $frame';
  }

  @override
  String get effectParameters => 'Effect Parameters';

  @override
  String get editParameters => 'Edit Parameters';

  @override
  String get effectParametersBaseNote =>
      'Current effect settings will be used as the base for animation';

  @override
  String get editBaseParameters => 'Edit Base Parameters';

  @override
  String get applyAndRegenerate => 'Apply & Regenerate';

  @override
  String get animationFrameGenerator => 'Animation Frame Generator';

  @override
  String get animationGeneratorHelpIntro =>
      'This tool generates multiple animation frames by applying the selected effect with different time parameters.\n';

  @override
  String get animationHelpDuration =>
      '• Duration: Total length of the animation in seconds';

  @override
  String get animationHelpFps =>
      '• FPS: Frames per second (higher = smoother but more frames)';

  @override
  String get animationHelpPingPong =>
      '• Ping-Pong: Makes animation play forward then backward';

  @override
  String get animationHelpInterpolation =>
      '• The effect parameters are interpolated over time to create smooth animations';

  @override
  String get tips => 'Tips:';

  @override
  String get animationTipLowerFps => '• Start with lower FPS for testing';

  @override
  String get animationTipUsePreview =>
      '• Use Preview to see the animation before generating';

  @override
  String get animationTipLongerDurations =>
      '• Longer durations work better for slower effects';

  @override
  String effectFrameName(int index) {
    return 'Effect Frame $index';
  }

  @override
  String effectAnimationName(int index) {
    return 'Effect Animation $index';
  }

  @override
  String effectAnimationReturnName(int index) {
    return 'Effect Animation $index (Return)';
  }

  @override
  String generatedAnimationFrames(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count animation frames',
      one: '1 animation frame',
      zero: '0 animation frames',
    );
    return 'Generated $_temp0!';
  }

  @override
  String get viewTimeline => 'View Timeline';

  @override
  String featureBullet(String feature) {
    return '• $feature';
  }

  @override
  String defaultLayerName(int index) {
    return 'Layer $index';
  }

  @override
  String get select => 'Select';

  @override
  String get menu => 'Menu';

  @override
  String get adjustOpacity => 'Adjust Opacity';

  @override
  String get adjustLayerOpacity => 'Adjust Layer Opacity';

  @override
  String get addToTemplate => 'Add to Template';

  @override
  String get editLayer => 'Edit Layer';

  @override
  String get layerName => 'Layer Name';

  @override
  String get backgroundShort => 'BG';

  @override
  String get reference => 'Reference';

  @override
  String get reset => 'Reset';

  @override
  String get fit => 'Fit';

  @override
  String get removeBackgroundImage => 'Remove background image';

  @override
  String get removeBackgroundImageMessage =>
      'Are you sure you want to remove the background image?';

  @override
  String get themeSelector => 'Theme Selector';

  @override
  String unlockThemeTitle(String themeName) {
    return 'Unlock $themeName Theme';
  }

  @override
  String get watchAdToUnlockTheme => 'Watch a video ad to unlock this theme.';

  @override
  String themeUnlocked(String themeName) {
    return '$themeName theme unlocked!';
  }

  @override
  String themeShowcaseTitle(String themeName) {
    return 'Theme: $themeName';
  }

  @override
  String get primaryColors => 'Primary Colors';

  @override
  String get primary => 'Primary';

  @override
  String get primaryVariant => 'Primary Variant';

  @override
  String get onPrimary => 'On Primary';

  @override
  String get accent => 'Accent';

  @override
  String get onAccent => 'On Accent';

  @override
  String get backgroundColors => 'Background Colors';

  @override
  String get background => 'Background';

  @override
  String get surface => 'Surface';

  @override
  String get surfaceVariant => 'Surface Variant';

  @override
  String get textColors => 'Text Colors';

  @override
  String get textPrimary => 'Text Primary';

  @override
  String get textSecondary => 'Text Secondary';

  @override
  String get textDisabled => 'Text Disabled';

  @override
  String get utilityColors => 'Utility Colors';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get uiElements => 'UI Elements';

  @override
  String get elevated => 'Elevated';

  @override
  String get filled => 'Filled';

  @override
  String get outlined => 'Outlined';

  @override
  String get text => 'Text';

  @override
  String get inputField => 'Input field';

  @override
  String get enterText => 'Enter text';

  @override
  String previewingTheme(String themeName) {
    return 'Previewing $themeName';
  }

  @override
  String currentTheme(String themeName) {
    return 'Current: $themeName';
  }

  @override
  String get unlockPremiumThemes => 'Unlock Premium Themes';

  @override
  String get getAccessToAllThemesWithPro => 'Get access to all themes with Pro';

  @override
  String get flagship => 'Flagship';

  @override
  String get free => 'Free';

  @override
  String get freeThemes => 'Free Themes';

  @override
  String get premiumThemes => 'Premium Themes';

  @override
  String get apply => 'Apply';

  @override
  String importedFileAsNewLayer(String fileName) {
    return 'Imported \"$fileName\" as new layer';
  }

  @override
  String get importAsepriteFile => 'Import Aseprite File';

  @override
  String howImportAsepriteFile(String fileName) {
    return 'How would you like to import \"$fileName\"?';
  }

  @override
  String importedFirstLayerFromFile(String fileName) {
    return 'Imported first layer from \"$fileName\"';
  }

  @override
  String get importAsLayer => 'Import as Layer';

  @override
  String get openAsProject => 'Open as Project';

  @override
  String get copyFrame => 'Copy Frame';

  @override
  String get addFrame => 'Add Frame';

  @override
  String get deleteFrame => 'Delete Frame';

  @override
  String get collapse => 'Collapse';

  @override
  String get expand => 'Expand';

  @override
  String get addState => 'Add State';

  @override
  String get copyState => 'Copy State';

  @override
  String get addAnimationState => 'Add Animation State';

  @override
  String get stateName => 'State Name';

  @override
  String get columns => 'Columns';

  @override
  String get tileModeTooltip => 'Tile Mode - preview seamless tiling';

  @override
  String get settingsStylusMode => 'Settings (Stylus Mode)';

  @override
  String get onionSkinTooltip => 'Onion Skin (long-press to set opacity)';

  @override
  String get sprayPaintToolDescription =>
      'Creates a spray effect with particles';

  @override
  String get lineToolDescription => 'Draw straight lines between two points';

  @override
  String get circleToolDescription => 'Draw perfect circles and ellipses';

  @override
  String get rectangleToolDescription => 'Draw rectangles and squares';

  @override
  String get triangleToolDescription => 'Draw triangular shapes';

  @override
  String get diamondToolDescription => 'Draw diamond shapes';

  @override
  String get hexagonToolDescription => 'Draw hexagonal shapes';

  @override
  String get heartToolDescription => 'Draw heart shapes';

  @override
  String get arrowToolDescription => 'Draw arrow shapes';

  @override
  String get lightningToolDescription => 'Draw lightning bolt shapes';

  @override
  String get crossToolDescription => 'Draw cross or plus shapes';

  @override
  String get spiralToolDescription => 'Draw spiral shapes';

  @override
  String get cloudToolDescription => 'Draw cloud shapes';

  @override
  String get penToolDescription => 'Advanced freehand drawing tool';

  @override
  String get rectangleSelectToolDescription => 'Select a rectangular area';

  @override
  String get ellipseSelectToolDescription => 'Select an elliptical area';

  @override
  String get lassoToolDescription => 'Freehand selection tool';

  @override
  String get magicWandToolDescription => 'Select contiguous pixels by color';

  @override
  String get curve => 'Curve';

  @override
  String get curveToolDescription => 'Draw smooth curved lines';

  @override
  String get move => 'Move';

  @override
  String get moveToolDescription => 'Move and drag elements';
}
