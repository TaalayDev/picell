// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class StringsJa extends Strings {
  StringsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Picell';

  @override
  String get aboutTitle => 'Picellについて';

  @override
  String get welcome => 'Picellへようこそ！';

  @override
  String get aboutAppDescription =>
      'Picellは、素晴らしいピクセルアートを作成するためのツールです。経験豊富なアーティストも、初心者も、このアプリケーションを使って、あなたのピクセルアートのビジョンを実現できます。';

  @override
  String version(String version) {
    return 'バージョン $version';
  }

  @override
  String get features =>
      '直感的なピクセル編集ツール\nカスタムカラーパレット\n複雑なアートワークのためのレイヤーサポート\nGIF作成用のアニメーションタイムライン\n様々なフォーマットでのエクスポート\nコミュニティでの共有機能';

  @override
  String get featuresTitle => '主な機能：';

  @override
  String get visitWebsite => '詳細はウェブサイトをご覧ください：';

  @override
  String get pickAColor => '色を選択';

  @override
  String get colorPicker => 'カラーピッカー';

  @override
  String get gotIt => '了解';

  @override
  String get undo => '元に戻す';

  @override
  String get redo => 'やり直し';

  @override
  String get clear => 'クリア';

  @override
  String get save => '保存';

  @override
  String get saveAs => '名前を付けて保存';

  @override
  String get open => '開く';

  @override
  String get export => 'エクスポート';

  @override
  String get import => 'インポート';

  @override
  String get share => '共有';

  @override
  String get close => '閉じる';

  @override
  String get projects => 'プロジェクト';

  @override
  String get lineTool => '直線';

  @override
  String get rectangleTool => '四角形';

  @override
  String get circleTool => '円';

  @override
  String get about => '概要';

  @override
  String get invalidFileContent => '無効なファイル内容';

  @override
  String get anErrorOccurred => 'エラーが発生しました';

  @override
  String get tryAgain => '再試行';

  @override
  String get creatingProject => 'プロジェクトを作成中...';

  @override
  String get openingProject => 'プロジェクトを開いています...';

  @override
  String get noProjectsFound => 'プロジェクトが見つかりません';

  @override
  String get createNewProject => '新規作成';

  @override
  String get rename => '名前の変更';

  @override
  String get delete => '削除';

  @override
  String get edit => '編集';

  @override
  String get cancel => 'キャンセル';

  @override
  String get deleteProject => 'プロジェクトの削除';

  @override
  String get areYouSureWantToDeleteProject => 'このプロジェクトを削除してもよろしいですか？';

  @override
  String get renameProject => 'プロジェクト名の変更';

  @override
  String get projectName => 'プロジェクト名';

  @override
  String timeAgo(String time) {
    return '$time前';
  }

  @override
  String get justNow => 'たった今';

  @override
  String frameCount(int current, int total) {
    return 'フレーム $current/$total';
  }

  @override
  String get playbackSpeed => '再生速度：';

  @override
  String duration(int ms) {
    return '再生時間: ${ms}ms';
  }

  @override
  String get animationPreview => 'アニメーションプレビュー';

  @override
  String get colorPalette => 'カラーパレット';

  @override
  String get currentColor => '現在の色';

  @override
  String get add => '追加';

  @override
  String get layers => 'レイヤー';

  @override
  String get deleteLayer => 'レイヤーを削除';

  @override
  String get areYouSureWantToDeleteLayer => 'このレイヤーを削除してもよろしいですか？';

  @override
  String get newProject => '新規プロジェクト';

  @override
  String get template => 'テンプレート';

  @override
  String get category => 'カテゴリ';

  @override
  String get width => '幅';

  @override
  String get height => '高さ';

  @override
  String get create => '作成';

  @override
  String get subscriptions => 'サブスクリプション';

  @override
  String get fileMenu => 'ファイル';

  @override
  String get profile => 'プロフィール';

  @override
  String get logout => 'ログアウト';

  @override
  String get deleteAccount => 'アカウント削除';

  @override
  String get signInToContinue => '続行するにはサインインしてください';

  @override
  String get signInToSyncProjects => 'プロジェクトを同期するにはサインインしてください。';

  @override
  String get signingIn => 'サインイン中...';

  @override
  String get continueWithApple => 'Appleでサインイン';

  @override
  String get signInWithGoogle => 'Googleでサインイン';

  @override
  String get skipForNow => '今はスキップする';

  @override
  String get noEmail => 'メールアドレスなし';

  @override
  String get feedback_title => 'フィードバック';

  @override
  String get feedback_thank_you => 'フィードバックありがとうございます！';

  @override
  String get feedback_thank_you_message =>
      'あなたのご意見は私たちにとって非常に重要であり、アプリの改善に役立ちます。';

  @override
  String get feedback_return => '戻る';

  @override
  String get feedback_help_us => 'より良いアプリにするためにご協力ください';

  @override
  String get feedback_intro => 'あなたのご意見はプロジェクトの発展にとって非常に重要です。いくつかの質問にお答えください。';

  @override
  String feedback_answered(int count, int total) {
    return '回答済み：$total中$count';
  }

  @override
  String get feedback_required => '必須';

  @override
  String get feedback_sending => '送信中...';

  @override
  String get feedback_send => '送信';

  @override
  String get feedback_validation_error => '必須項目にすべて回答してください';

  @override
  String get feedback_very_poor => '非常に悪い';

  @override
  String get feedback_excellent => '優秀';

  @override
  String get feedback_yes => 'はい';

  @override
  String get feedback_no => 'いいえ';

  @override
  String get feedback_text_placeholder => '回答を入力してください...';

  @override
  String get feedback_q_satisfaction => 'アプリに満足していますか？';

  @override
  String get feedback_q_missing_features => 'どのような機能が不足していますか？';

  @override
  String get feedback_q_missing_features_placeholder => '見たい機能を説明してください...';

  @override
  String get feedback_q_bug_reports => 'エラーやクラッシュに遭遇しましたか？';

  @override
  String get feedback_q_bug_reports_placeholder => '遭遇した問題を説明してください...';

  @override
  String get feedback_q_price_satisfaction => '現在のアプリ価格に満足していますか？';

  @override
  String get feedback_q_price_feedback => '満足していない場合、適正と考える価格は？';

  @override
  String get feedback_q_price_free => '無料';

  @override
  String get feedback_q_price_up_to_5 => '\$5まで';

  @override
  String get feedback_q_price_5_to_10 => '\$5 - \$10';

  @override
  String get feedback_q_price_10_to_20 => '\$10 - \$20';

  @override
  String get feedback_q_price_more_20 => '\$20以上';

  @override
  String get feedback_q_patreon_support => 'Patreonでプロジェクトをサポートしますか？';

  @override
  String get feedback_q_patreon_definitely => 'はい、必ず';

  @override
  String get feedback_q_patreon_if_exclusive => '限定機能があれば';

  @override
  String get feedback_q_patreon_if_reasonable => '価格が妥当であれば';

  @override
  String get feedback_q_patreon_probably_not => 'おそらくしない';

  @override
  String get feedback_q_patreon_no => 'いいえ、予定なし';

  @override
  String get feedback_q_patreon_tier => 'どのPatreonサポート層に興味がありますか？';

  @override
  String get feedback_q_patreon_tier_3 => '\$3/月 - 機能への早期アクセス';

  @override
  String get feedback_q_patreon_tier_5 => '\$5/月 - + 限定テーマ';

  @override
  String get feedback_q_patreon_tier_10 => '\$10/月 - + 開発への影響力';

  @override
  String get feedback_q_usage_frequency => 'アプリをどのくらいの頻度で使用しますか？';

  @override
  String get feedback_q_usage_daily => '毎日';

  @override
  String get feedback_q_usage_several_week => '週に数回';

  @override
  String get feedback_q_usage_once_week => '週に1回';

  @override
  String get feedback_q_usage_several_month => '月に数回';

  @override
  String get feedback_q_usage_rarely => 'まれに';

  @override
  String get feedback_q_main_use_case => 'アプリを主に何に使用していますか？';

  @override
  String get feedback_q_use_pixel_art => 'ピクセルアート制作';

  @override
  String get feedback_q_use_game_design => 'ゲームデザイン';

  @override
  String get feedback_q_use_animation => 'アニメーション';

  @override
  String get feedback_q_use_hobby => '趣味/娯楽';

  @override
  String get feedback_q_use_professional => 'プロの仕事';

  @override
  String get feedback_q_use_learning => '学習';

  @override
  String get feedback_q_additional_feedback => '追加のコメントと提案';

  @override
  String get feedback_q_additional_feedback_placeholder =>
      'アプリについてのご意見をお聞かせください...';

  @override
  String get feedback_q_recommend => 'このアプリを友達に勧めますか？';

  @override
  String get firstFrame => '最初のフレーム';

  @override
  String get previousFrame => '前のフレーム';

  @override
  String get pause => '一時停止';

  @override
  String get play => '再生';

  @override
  String get nextFrame => '次のフレーム';

  @override
  String get lastFrame => '最後のフレーム';

  @override
  String get feedback_dialog_title => 'ご意見をお聞かせください！';

  @override
  String get feedback_dialog_description =>
      'あなたのご意見は大切です。感想を共有してアプリの改善にご協力ください。';

  @override
  String get feedback_dialog_benefit_1 => '新機能のアイデアを共有';

  @override
  String get feedback_dialog_benefit_2 => 'バグや問題を報告';

  @override
  String get feedback_dialog_benefit_3 => 'アプリの未来づくりに参加';

  @override
  String get feedback_dialog_leave_feedback => 'フィードバックを送る';

  @override
  String get feedback_dialog_maybe_later => '後で';

  @override
  String get feedback_dialog_dont_ask => '今後は表示しない';

  @override
  String get paletteBasic => '基本';

  @override
  String get paletteShades => 'シェード';

  @override
  String get paletteComplementary => '補色';

  @override
  String get paletteAnalogous => '類似色';

  @override
  String get paletteTriadic => 'トライアディック';

  @override
  String get paletteMonochromatic => 'モノクロマチック';

  @override
  String get paletteCustom => 'カスタム';

  @override
  String get paletteImported => 'インポート済み';

  @override
  String get paletteImportedCount => '色';

  @override
  String get addToCustomPalette => 'カスタムパレットに追加';

  @override
  String get noCustomColors => 'カスタムカラーはまだ追加されていません。\n上の+ボタンを使用して色を追加してください。';

  @override
  String get effects => 'エフェクト';

  @override
  String get editorSettings => 'エディター設定';

  @override
  String get resetToDefaults => 'デフォルトにリセット';

  @override
  String get input => '入力';

  @override
  String get display => '表示';

  @override
  String get showGrid => 'グリッドを表示';

  @override
  String get showGridSubtitle => 'キャンバスにグリッド線を表示します';

  @override
  String get pixelGridOverlay => 'ピクセルグリッドオーバーレイ';

  @override
  String get pixelGridSubtitle => 'ズーム時にピクセルの境界を表示します';

  @override
  String get gridOpacity => 'グリッドの不透明度';

  @override
  String get selectionTransforms => '選択変形';

  @override
  String get transformInterpolation => '補間';

  @override
  String get transformInterpolationSubtitle => '選択範囲のサイズ変更と回転に使用します';

  @override
  String get nearestNeighbor => 'ニアレスト';

  @override
  String get bilinear => 'バイリニア';

  @override
  String get zoomNavigation => 'ズームとナビゲーション';

  @override
  String get zoomSensitivity => 'ズーム感度';

  @override
  String get zoomSensitivitySubtitle => 'ピンチズームの反応速度';

  @override
  String get minZoom => '最小ズーム';

  @override
  String get maxZoom => '最大ズーム';

  @override
  String get gestures => 'ジェスチャー';

  @override
  String get twoFingerUndo => '2本指タップで元に戻す';

  @override
  String get twoFingerUndoSubtitle => '2本指でクイックタップして操作を元に戻します';

  @override
  String get done => '完了';

  @override
  String get stylusMode => 'スタイラスモード';

  @override
  String get stylusModeSubtitleOn => 'スタイラスのみで描画 ・ タッチで移動';

  @override
  String get stylusModeSubtitleOff => 'タッチとスタイラスの両方で描画';

  @override
  String get importImage => '画像をインポート';

  @override
  String get selectImportOption => '画像のインポート方法を選択してください：';

  @override
  String get convertToPixelArt => 'ピクセルアートに変換';

  @override
  String get convertToPixelArtDescription =>
      '画像をインポートし、新しいレイヤーで自動的にピクセルアートスタイルに変換します。';

  @override
  String get importAsBackground => '背景としてインポート';

  @override
  String get importAsBackgroundDescription =>
      '画像をそのままインポートし、参照用の背景レイヤーとして使用します。';

  @override
  String get conversionSettings => '変換設定';

  @override
  String get paletteColors => 'パレット色数';

  @override
  String get fullColor => 'フルカラー';

  @override
  String get dithering => 'ディザリング';

  @override
  String get noDithering => 'なし';

  @override
  String get alphaThreshold => 'アルファ閾値';

  @override
  String get chooseImage => '画像を選択';

  @override
  String get tinyIcon => '小さいアイコン';

  @override
  String get smallSprite => '小さいスプライト';

  @override
  String get mediumCharacter => '中サイズキャラクター';

  @override
  String get largeScene => '大きいシーン';

  @override
  String get projectNameRequired => 'プロジェクト名を入力してください';

  @override
  String get templateRequired => 'テンプレートを選択してください';

  @override
  String planLimitError(int limit) {
    return 'あなたのプランは$limitピクセルに制限されています';
  }

  @override
  String get widthRequired => '幅を入力してください';

  @override
  String get heightRequired => '高さを入力してください';

  @override
  String widthRangeError(int max) {
    return '幅: 1-$max';
  }

  @override
  String heightRangeError(int max) {
    return '高さ: 1-$max';
  }

  @override
  String get saveImage => '画像を保存';

  @override
  String get png => 'PNG';

  @override
  String get animatedGif => 'アニメーションGIF';

  @override
  String get proPlanRequired => 'Proプランが必要です';

  @override
  String get spriteSheet => 'スプライトシート';

  @override
  String get transparentBackground => '背景を透明にする';

  @override
  String get transparent => '透明';

  @override
  String get spriteSheetOptions => 'スプライトシート設定';

  @override
  String get columnsLabel => '列数';

  @override
  String get spacingPx => '間隔 (px)';

  @override
  String get exportSize => 'エクスポートサイズ';

  @override
  String scaleWithValues(String scale) {
    return '倍率: ${scale}x';
  }

  @override
  String get format => '形式';

  @override
  String get options => 'オプション';

  @override
  String editEffect(String name) {
    return '効果を編集: $name';
  }

  @override
  String get applyChanges => '変更を適用';

  @override
  String get preview => 'プレビュー';

  @override
  String get quickPresets => 'クイックプリセット';

  @override
  String get parameters => 'パラメータ';

  @override
  String get previewNotAvailable => 'プレビューを利用できません';

  @override
  String get tapToChange => 'タップして変更';

  @override
  String get enable => '有効';

  @override
  String get uiFieldTap => 'タップ';

  @override
  String get uiFieldEnabled => '有効';

  @override
  String get uiFieldDisabled => '無効';

  @override
  String get presetDarker => 'より暗く';

  @override
  String get presetNormal => '通常';

  @override
  String get presetBrighter => 'より明るく';

  @override
  String get presetVeryBright => '非常に明るく';

  @override
  String get presetLow => '低い';

  @override
  String get presetHigh => '高い';

  @override
  String get presetVeryHigh => '非常に高い';

  @override
  String get presetSubtle => 'かすかに';

  @override
  String get presetSoft => 'ソフト';

  @override
  String get presetMedium => '中間';

  @override
  String get presetStrong => '強く';

  @override
  String get effectBrightness => '明るさ';

  @override
  String get effectContrast => 'コントラスト';

  @override
  String get effectBlur => 'ぼかし';

  @override
  String get effectVignette => 'ビネット';

  @override
  String get effectInvert => '反転';

  @override
  String get effectGrayscale => 'グレースケール';

  @override
  String get effectSepia => 'セピア';

  @override
  String get effectThreshold => 'しきい値';

  @override
  String get effectPixelate => 'ピクセル化';

  @override
  String get effectSharpen => 'シャープ';

  @override
  String get effectNoise => 'ノイズ';

  @override
  String get effectGlow => 'グロー';

  @override
  String get effectGlitch => 'グリッチ';

  @override
  String get effectSparkle => 'スパークル';

  @override
  String get effectFire => '炎';

  @override
  String get effectRain => '雨';

  @override
  String get selectEffect => '効果を選択';

  @override
  String get searchEffects => '効果を検索...';

  @override
  String get categoryAll => 'すべて';

  @override
  String get categoryColorTone => '色と調子';

  @override
  String get categoryBlurSharpen => 'ぼかしとシャープ';

  @override
  String get categoryArtistic => '芸術的';

  @override
  String get categoryAnimation => 'アニメーション';

  @override
  String get categoryNature => '自然';

  @override
  String get categoryParticles => 'パーティクル';

  @override
  String get categoryDistortion => '歪み';

  @override
  String get categoryTextures => 'テクスチャ';

  @override
  String get categorySpecialFx => '特殊効果';

  @override
  String get noEffectsMatch => '検索に一致する効果はありません';

  @override
  String get premiumEffect => 'プレミアム効果';

  @override
  String get proVersionStatus => 'この効果はProバージョンで利用可能です。';

  @override
  String get proFeaturesInclude => 'Pro機能:';

  @override
  String get featureAdvancedEffects => '高度な効果とツール';

  @override
  String get featureUnlimitedProjects => '無制限のプロジェクト';

  @override
  String get featureCloudBackup => 'クラウドバックアップ';

  @override
  String get featurePrioritySupport => '優先サポート';

  @override
  String get maybeLater => 'あとで';

  @override
  String get upgradeToPro => 'Proにアップグレード';

  @override
  String get effectsPanelRemoveEffectTitle => '効果を削除';

  @override
  String effectsPanelRemoveEffectMessage(String effectName) {
    return '$effectName効果を削除してもよろしいですか？';
  }

  @override
  String get effectsPanelClearAllEffectsTitle => 'すべての効果をクリア';

  @override
  String get effectsPanelClearAllEffectsMessage =>
      'このレイヤーからすべての効果を削除してもよろしいですか？';

  @override
  String get effectsPanelClearAll => 'すべてクリア';

  @override
  String effectsPanelAppliedToLayerMessage(String effectName) {
    return '$effectName効果をレイヤーに適用しました';
  }

  @override
  String get effectsPanelActionApply => '適用';

  @override
  String get effectsPanelActionRemove => '削除';

  @override
  String get effectsPanelActionMore => 'その他';

  @override
  String get effectsPanelMoreActionsTitle => 'その他の操作';

  @override
  String get effectsPanelApplyAll => 'すべて適用';

  @override
  String get ellipseSelection => '楕円選択';

  @override
  String get ellipseSelectionTooltip => '楕円形の領域を選択';

  @override
  String get autoSelectLayer => '自動選択';

  @override
  String get autoSelectLayerTooltip => '現在のレイヤーの空でないピクセルをすべて選択';

  @override
  String get selectionAnchor => '選択アンカー';

  @override
  String get feedback => 'フィードバック';

  @override
  String get createNewProjectTooltip => '新規プロジェクトを作成';

  @override
  String failedToProcessFile(String fileName) {
    return '$fileName を処理できませんでした';
  }

  @override
  String importingFile(String fileName) {
    return '$fileName をインポート中...';
  }

  @override
  String importedProjectSuccessfully(String projectName) {
    return '「$projectName」をインポートしました';
  }

  @override
  String failedToImport(String error) {
    return 'インポートに失敗しました: $error';
  }

  @override
  String unsupportedFileType(String fileName) {
    return '未対応のファイル形式: $fileName';
  }

  @override
  String get pleaseSignInToUploadProjects => 'プロジェクトをアップロードするにはサインインしてください';

  @override
  String get pleaseSignInToUpdateProjects => 'プロジェクトを更新するにはサインインしてください';

  @override
  String get projectNotSyncedToCloud => 'プロジェクトはクラウドと同期されていません';

  @override
  String get pleaseSignInToRemoveCloudProjects =>
      'クラウドプロジェクトを削除するにはサインインしてください';

  @override
  String get removingFromCloud => 'クラウドから削除中...';

  @override
  String get projectRemovedFromCloudSuccessfully => 'プロジェクトをクラウドから削除しました';

  @override
  String failedToRemoveFromCloud(String error) {
    return 'クラウドから削除できませんでした: $error';
  }

  @override
  String get search => '検索...';

  @override
  String get myProjects => 'マイプロジェクト';

  @override
  String get noProjectsYet => 'まだプロジェクトがありません';

  @override
  String get createOne => '作成する';

  @override
  String get searchProjects => 'プロジェクトを検索...';

  @override
  String get discoverAmazingPixelArt => '素敵なピクセルアートを見つけよう';

  @override
  String get sortBy => '並べ替え';

  @override
  String get mostRecent => '新しい順';

  @override
  String get mostPopular => '人気順';

  @override
  String get mostViewed => '閲覧数順';

  @override
  String get mostLiked => 'いいね順';

  @override
  String get titleAZ => 'タイトル A-Z';

  @override
  String get all => 'すべて';

  @override
  String get featuredProjects => '注目プロジェクト';

  @override
  String get errorLoadingProjects => 'プロジェクトの読み込みエラー';

  @override
  String get deletingProject => 'プロジェクトを削除中...';

  @override
  String get projectDeletedSuccessfully => 'プロジェクトを削除しました';

  @override
  String get failedToDeleteProject => 'プロジェクトを削除できませんでした';

  @override
  String failedToDeleteProjectWithError(String error) {
    return 'プロジェクトを削除できませんでした: $error';
  }

  @override
  String get unlike => 'いいねを解除';

  @override
  String get like => 'いいね';

  @override
  String get editProject => 'プロジェクトを編集';

  @override
  String get public => '公開';

  @override
  String get private => '非公開';

  @override
  String get analytics => '分析';

  @override
  String get stats => '統計';

  @override
  String likeCountLabel(String count) {
    return '$count 件のいいね';
  }

  @override
  String commentCountLabel(String count) {
    return '$count 件のコメント';
  }

  @override
  String get download => 'ダウンロード';

  @override
  String get openProject => 'プロジェクトを開く';

  @override
  String get downloadProject => 'プロジェクトをダウンロード';

  @override
  String get localProjectNotFound => 'ローカルプロジェクトが見つかりません';

  @override
  String get comments => 'コメント';

  @override
  String get addComment => 'コメントを追加';

  @override
  String get noCommentsYet => 'まだコメントはありません';

  @override
  String get beFirstToComment => '最初のコメントを投稿しましょう！';

  @override
  String get failedToLoadComments => 'コメントを読み込めませんでした';

  @override
  String get edited => '編集済み';

  @override
  String get makeProjectPublic => 'プロジェクトを公開';

  @override
  String get makeProjectPrivate => 'プロジェクトを非公開';

  @override
  String get makeProjectPublicMessage =>
      'プロジェクトがコミュニティ全体に表示されます。誰でも閲覧、いいね、コメントができます。';

  @override
  String get makeProjectPrivateMessage =>
      'プロジェクトは公開コミュニティから非表示になります。表示できるのはあなただけです。';

  @override
  String get projectWillBePublic => 'プロジェクトは公開されます';

  @override
  String get projectWillBePrivate => 'プロジェクトは非公開になります';

  @override
  String get projectIsNowPublic => 'プロジェクトを公開しました';

  @override
  String get projectIsNowPrivate => 'プロジェクトを非公開にしました';

  @override
  String failedToUpdateVisibility(String error) {
    return '公開設定を更新できませんでした: $error';
  }

  @override
  String get makePublic => '公開する';

  @override
  String get makePrivate => '非公開にする';

  @override
  String get deleteProjectCannotBeUndone => 'このプロジェクトを削除しますか？この操作は元に戻せません。';

  @override
  String get thisWillPermanentlyDelete => '完全に削除されるもの:';

  @override
  String get deleteProjectConsequences =>
      '• プロジェクトデータとアートワーク\n• すべてのコメントといいね\n• ダウンロード統計';

  @override
  String typeProjectTitleToConfirmDeletion(String title) {
    return '削除を確認するには「$title」と入力してください:';
  }

  @override
  String get enterProjectTitle => 'プロジェクトタイトルを入力...';

  @override
  String get deleteForever => '完全に削除';

  @override
  String get openingProjectEditor => 'プロジェクトエディタを開いています...';

  @override
  String get projectLinkCopied => 'プロジェクトリンクをコピーしました！';

  @override
  String get addedToFavorites => 'お気に入りに追加しました！';

  @override
  String nowFollowingUser(String username) {
    return '$username をフォローしました！';
  }

  @override
  String get reportProject => 'プロジェクトを報告';

  @override
  String get reportProjectMessage =>
      'このプロジェクトを報告しますか？コミュニティガイドラインに違反する内容のみ報告してください。';

  @override
  String get reportThanks => '報告ありがとうございます。確認します。';

  @override
  String get report => '報告';

  @override
  String get premiumRequiredToDownloadProjects =>
      'プロジェクトのダウンロードにはPremium登録が必要です';

  @override
  String get upgrade => 'アップグレード';

  @override
  String get downloadProjectRewardSubtitle => 'このプロジェクトをダウンロードするには:';

  @override
  String get thankYouWatchingDownloadStarting => '視聴ありがとうございます！ダウンロードを開始します...';

  @override
  String get pleaseSignInToAddComments => 'コメントするにはサインインしてください';

  @override
  String get writeYourComment => 'コメントを書く...';

  @override
  String get commentAddedSuccessfully => 'コメントを追加しました！';

  @override
  String failedToAddComment(String error) {
    return 'コメントを追加できませんでした: $error';
  }

  @override
  String get post => '投稿';

  @override
  String get chooseTheme => 'テーマを選択';

  @override
  String get importFile => 'ファイルをインポート';

  @override
  String get theme => 'テーマ';

  @override
  String get getPro => 'Proを入手';

  @override
  String get supportOnKofi => 'Ko-fiで支援';

  @override
  String get copyLink => 'リンクをコピー';

  @override
  String get size => 'サイズ';

  @override
  String get views => '閲覧数';

  @override
  String get downloads => 'ダウンロード';

  @override
  String get published => '公開しました！';

  @override
  String get forkedFrom => 'フォーク元: ';

  @override
  String byUser(String username) {
    return ' 作成者: $username';
  }

  @override
  String get projectAnalytics => 'プロジェクト分析';

  @override
  String get totalViews => '総閲覧数';

  @override
  String get totalLikes => '総いいね数';

  @override
  String get detailedAnalytics => '詳細分析';

  @override
  String get advancedAnalyticsSoon => '高度な分析機能は近日公開予定です。';

  @override
  String get details => '詳細';

  @override
  String get title => 'タイトル';

  @override
  String get projectTitleHint => 'プロジェクト名を入力';

  @override
  String get description => '説明';

  @override
  String get projectDescriptionHint => 'このプロジェクトについてコミュニティに伝えましょう（任意）';

  @override
  String get visibility => '公開設定';

  @override
  String get tags => 'タグ';

  @override
  String get searchTags => 'タグを検索…';

  @override
  String get failedToLoadTags => 'タグを読み込めませんでした';

  @override
  String get pleaseEnterTitle => 'タイトルを入力してください';

  @override
  String get removeFromCloudQuestion => 'クラウドから削除しますか？';

  @override
  String get removeFromCommunityMessage =>
      'プロジェクトはコミュニティから削除されます。ローカルコピーは残ります。';

  @override
  String get remove => '削除';

  @override
  String get updateProject => 'プロジェクトを更新';

  @override
  String get publishToCommunity => 'コミュニティに公開';

  @override
  String get synced => '同期済み';

  @override
  String get visibleToEveryone => '全員に表示';

  @override
  String get onlyVisibleToYou => '自分だけに表示';

  @override
  String get maximumTagsAllowed => 'タグは最大5個までです';

  @override
  String frameCountSimple(int count) {
    return '$count フレーム';
  }

  @override
  String layerCountSimple(int count) {
    return '$count レイヤー';
  }

  @override
  String get cloudManagement => 'クラウド管理';

  @override
  String cloudId(String id) {
    return 'Cloud ID: $id';
  }

  @override
  String get preparingUpdate => '更新を準備中…';

  @override
  String get preparingProject => 'プロジェクトを準備中…';

  @override
  String get generatingThumbnail => 'サムネイルを生成中…';

  @override
  String get updatingOnCloud => 'クラウドで更新中…';

  @override
  String get uploadingToCloud => 'クラウドへアップロード中…';

  @override
  String get finalizing => '最終処理中…';

  @override
  String get updated => '更新しました！';

  @override
  String get updating => '更新中…';

  @override
  String get publishing => '公開中…';

  @override
  String get update => '更新';

  @override
  String get publish => '公開';

  @override
  String get downloadingProject => 'プロジェクトをダウンロード中';

  @override
  String get downloadingProjectData => 'プロジェクトデータをダウンロード中...';

  @override
  String get downloadComplete => 'ダウンロード完了！';

  @override
  String get projectSavedLocal => 'プロジェクトをローカルプロジェクトに保存しました';

  @override
  String get downloadFailed => 'ダウンロード失敗';

  @override
  String get resyncWithCloud => 'クラウドと再同期';

  @override
  String get syncToCloud => 'クラウドに同期';

  @override
  String get removeFromCloud => 'クラウドから削除';

  @override
  String get removeFromCloudMessage =>
      'プロジェクトはクラウドから削除され、ローカルのみになります。ローカルコピーは変更されません。よろしいですか？';

  @override
  String get syncedCloudDeleteWarning =>
      'このプロジェクトはクラウドと同期されています。ローカルで削除してもクラウド版には影響しません。';

  @override
  String get openLocalProject => 'ローカルプロジェクトを開く';

  @override
  String get premiumRequired => 'Premium が必要';

  @override
  String byUserInline(String username) {
    return '$username 作';
  }

  @override
  String get createTemplate => 'テンプレートを作成';

  @override
  String layerNameLabel(String name) {
    return '名前: $name';
  }

  @override
  String layerSizeLabel(int width, int height) {
    return 'サイズ: $width×$height';
  }

  @override
  String nonTransparentPixels(int count) {
    return 'ピクセル: $count 個の不透明';
  }

  @override
  String get templateName => 'テンプレート名';

  @override
  String get descriptionOptional => '説明（任意）';

  @override
  String get saveOptions => '保存オプション';

  @override
  String get saveLocally => 'ローカルに保存';

  @override
  String get storeOnDeviceOnly => 'このデバイスのみに保存';

  @override
  String get uploadToCloud => 'クラウドにアップロード';

  @override
  String get shareWithCommunity => 'コミュニティに共有';

  @override
  String get privateCloudStorage => '非公開クラウド保存';

  @override
  String get otherUsersCanDiscoverTemplate => '他のユーザーがこのテンプレートを見つけて使用できます';

  @override
  String get onlyYouCanAccessTemplate => 'このテンプレートにアクセスできるのはあなただけです';

  @override
  String get saveLocallyAndUpload => 'ローカル保存とアップロード';

  @override
  String get bestOfBothWorlds => '両方のいいとこ取り';

  @override
  String get signInToUploadTemplates => 'テンプレートをアップロードするにはサインイン';

  @override
  String get shareTemplatesWithCommunity => 'テンプレートをコミュニティと共有';

  @override
  String get failedToConvertLayerToTemplate => 'レイヤーをテンプレートに変換できませんでした';

  @override
  String get failedToSaveTemplateLocally => 'テンプレートをローカルに保存できませんでした';

  @override
  String get failedToUploadTemplateToServer => 'テンプレートをサーバーにアップロードできませんでした';

  @override
  String errorCreatingTemplate(String error) {
    return 'テンプレート作成エラー: $error';
  }

  @override
  String get templateSavedLocally => 'テンプレートをローカルに保存しました！';

  @override
  String get templateUploadedSuccessfully => 'テンプレートをアップロードしました！';

  @override
  String get templateSavedAndUploaded => 'テンプレートをローカル保存してアップロードしました！';

  @override
  String get templateSavedUploadFailed => 'テンプレートをローカル保存しました（アップロード失敗）';

  @override
  String get templateUploadedLocalSaveFailed => 'テンプレートをアップロードしました（ローカル保存失敗）';

  @override
  String get templateCreationFailed => 'テンプレート作成に失敗しました';

  @override
  String get templateGallery => 'テンプレートギャラリー';

  @override
  String get allTemplates => 'すべてのテンプレート';

  @override
  String get local => 'ローカル';

  @override
  String get community => 'コミュニティ';

  @override
  String get failedTemplateDetailsCached =>
      'テンプレート詳細を読み込めませんでした。キャッシュデータを使用します。';

  @override
  String errorLoadingTemplate(String error) {
    return 'テンプレート読み込みエラー: $error';
  }

  @override
  String get loadingTemplate => 'テンプレートを読み込み中...';

  @override
  String get deleteTemplate => 'テンプレートを削除';

  @override
  String deleteTemplateQuestion(String name) {
    return '「$name」を削除しますか？';
  }

  @override
  String get deleteLocalTemplateWarning => 'このテンプレートはローカル保存から完全に削除されます。';

  @override
  String get deleteCloudTemplateWarning => 'このテンプレートはクラウドから削除され、復元できません。';

  @override
  String templateDeletedSuccessfully(String name) {
    return '「$name」を削除しました';
  }

  @override
  String failedToDeleteTemplate(String name) {
    return '「$name」を削除できませんでした';
  }

  @override
  String get searchTemplates => 'テンプレートを検索...';

  @override
  String get loadingTemplates => 'テンプレートを読み込み中...';

  @override
  String get premiumTemplate => 'Premium テンプレート';

  @override
  String get templateAvailableInPro => 'このテンプレートはPro版で利用できます。';

  @override
  String get premiumTemplatesFeature => '• Premiumテンプレート';

  @override
  String get advancedEffectsToolsFeature => '• 高度なエフェクトとツール';

  @override
  String get unlimitedProjectsFeature => '• 無制限のプロジェクト';

  @override
  String get cloudBackupFeature => '• クラウドバックアップ';

  @override
  String get prioritySupportFeature => '• 優先サポート';

  @override
  String get noLocalTemplates => 'ローカルテンプレートがありません。\nレイヤーから最初のテンプレートを作成しましょう！';

  @override
  String get noCommunityTemplates => 'コミュニティテンプレートがありません。\n検索やフィルターを調整してください。';

  @override
  String get noUploadedTemplates =>
      'まだテンプレートをアップロードしていません。\n作品をコミュニティに共有しましょう！';

  @override
  String get noTemplatesFoundAdjust => 'テンプレートが見つかりません。\n検索やフィルターを調整してください。';

  @override
  String showingTemplates(int displayed, String total) {
    String _temp0 = intl.Intl.selectLogic(
      total,
      {
        'none': '',
        'other': ' / $total',
      },
    );
    return '$displayed$_temp0 件のテンプレートを表示';
  }

  @override
  String get clickTemplateToApply => 'テンプレートをクリックして適用';

  @override
  String get pro => 'PRO';

  @override
  String get pleaseEnterTemplateName => 'テンプレート名を入力してください';

  @override
  String get signInToUploadTemplatesTitle => 'テンプレートをアップロードするにはサインイン';

  @override
  String get signInToUploadTemplatesSubtitle =>
      'テンプレートをコミュニティに共有するにはアカウントを作成してください。';

  @override
  String get myTemplates => 'マイテンプレート';

  @override
  String get cloud => 'クラウド';

  @override
  String get tapToUnlock => 'タップして解除';

  @override
  String get layerTemplateDefaultName => 'レイヤーテンプレート';

  @override
  String get undoHistoryTitle => '履歴';

  @override
  String undoHistoryStepCount(int total) {
    return '（$totalステップ）';
  }

  @override
  String get undoHistoryRevertAll => 'すべて戻す';

  @override
  String get undoHistoryCurrentState => '現在の状態';

  @override
  String undoHistoryFrameLayer(int frame, int layer) {
    return 'フレーム$frame、レイヤー$layer';
  }

  @override
  String get keyboardShortcuts => 'キーボードショートカット';

  @override
  String get copySelection => '選択範囲をコピー';

  @override
  String get cutSelection => '選択範囲を切り取り';

  @override
  String get paste => '貼り付け';

  @override
  String get duplicateLayer => 'レイヤーを複製';

  @override
  String get selection => '選択';

  @override
  String get selectAll => 'すべて選択';

  @override
  String get deselect => '選択解除';

  @override
  String get closePenPath => 'ペンパスを閉じる';

  @override
  String get tools => 'ツール';

  @override
  String get pencil => '鉛筆';

  @override
  String get eraser => '消しゴム';

  @override
  String get eyedropper => 'スポイト';

  @override
  String get fill => '塗りつぶし';

  @override
  String get selectMarquee => '選択 / 矩形選択';

  @override
  String get moveDrag => '移動 / ドラッグ';

  @override
  String get pen => 'ペン';

  @override
  String get sprayPaint => 'スプレー';

  @override
  String get panHold => 'パン（長押し）';

  @override
  String get eyedropperHold => 'スポイト（長押し）';

  @override
  String get brush => 'ブラシ';

  @override
  String get increaseSize => 'サイズを大きく';

  @override
  String get decreaseSize => 'サイズを小さく';

  @override
  String get colors => '色';

  @override
  String get swapColors => '色を入れ替え';

  @override
  String get defaultColors => 'デフォルト色';

  @override
  String get view => '表示';

  @override
  String get zoomIn => 'ズームイン';

  @override
  String get zoomOut => 'ズームアウト';

  @override
  String get zoomToFit => '全体表示';

  @override
  String get zoomOneToOne => '1:1表示';

  @override
  String get toggleUi => 'UIを切り替え';

  @override
  String get selectLayerOneToNine => 'レイヤー1-9を選択';

  @override
  String get newLayer => '新規レイヤー';

  @override
  String get deleteAccountCannotBeUndone => 'この操作は元に戻せません';

  @override
  String get deleteAccountPermanentDataWarning =>
      'アカウントを削除すると、すべてのデータが完全に削除されます。';

  @override
  String get deleteAccountItemsIntro => '以下が完全に削除されます:';

  @override
  String get deleteAccountPreferencesTitle => 'アプリ設定';

  @override
  String get deleteAccountPreferencesSubtitle => '設定とカスタマイズ';

  @override
  String get deleteAccountInfoTitle => 'アカウント情報';

  @override
  String get deleteAccountInfoSubtitle => 'プロフィールと認証データ';

  @override
  String get deleteAccountTypeConfirm => '確認するには「DELETE」と入力してください:';

  @override
  String get deleteAccountTypeHint => 'ここにDELETEと入力...';

  @override
  String get deleteAccountIrreversibleImmediate => 'この操作は取り消せず、すぐに反映されます。';

  @override
  String get deleteAccountQuickConfirm => 'アカウントを完全に削除してもよろしいですか？';

  @override
  String get deleteAccountQuickWarningList =>
      '• すべてのプロジェクトが失われます\n• クラウドバックアップが削除されます\n• この操作は元に戻せません';

  @override
  String failedToDeleteAccount(String error) {
    return 'アカウントの削除に失敗しました: $error';
  }

  @override
  String get proAccessActive => 'Proアクセス有効';

  @override
  String proAccessRemaining(String time) {
    return 'Proアクセスの残り時間は$timeです。';
  }

  @override
  String get buyPro => 'Proを購入';

  @override
  String get rewardUpgradeBullets =>
      '• すべての機能に無制限アクセス\n• 一度きりの購入\n• 広告なし\n• 優先サポート';

  @override
  String get tryPro45Minutes => 'Proを45分試す';

  @override
  String get rewardAdReadyBullets =>
      '• 短い動画広告を見る\n• 45分間のProアクセスを取得\n• アプリ開発を応援';

  @override
  String get rewardAdLoadingBullets => '• 動画広告を読み込み中...\n• しばらくしてからもう一度お試しください';

  @override
  String get watchAd => '広告を見る';

  @override
  String get loadingEllipsis => '読み込み中...';

  @override
  String get loadingVideoAd => '動画広告を読み込み中...';

  @override
  String get proAccessGranted45 => 'Proアクセスが45分間付与されました！';

  @override
  String get videoAdNotCompleted => '動画広告が完了しませんでした。もう一度試すか、Proにアップグレードしてください。';

  @override
  String failedToLoadVideoAd(String error) {
    return '動画広告の読み込みに失敗しました: $error';
  }

  @override
  String get rewardTimeZeroMinutes => '0分';

  @override
  String rewardTimeMinutesSeconds(int minutes, int seconds) {
    return '$minutes分$seconds秒';
  }

  @override
  String rewardTimeSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String get selectionOptions => '選択オプション';

  @override
  String get clearSelection => '選択をクリア';

  @override
  String get invertSelection => '選択を反転';

  @override
  String get growSelectionOnePixel => '拡張（+1px）';

  @override
  String get shrinkSelectionOnePixel => '縮小（-1px）';

  @override
  String get rotate90 => '90°回転';

  @override
  String get rotate180 => '180°回転';

  @override
  String get flipHorizontal => '左右反転';

  @override
  String get flipVertical => '上下反転';

  @override
  String get cutToNewLayer => '新規レイヤーへ切り取り';

  @override
  String get copyToNewLayer => '新規レイヤーへコピー';

  @override
  String get cut => '切り取り';

  @override
  String get copy => 'コピー';

  @override
  String get clearArea => '範囲をクリア';

  @override
  String get replaceSelection => '選択を置き換え';

  @override
  String get addToSelectionShift => '選択に追加（Shift）';

  @override
  String get subtractFromSelectionAlt => '選択から減算（Alt）';

  @override
  String get textureBrush => 'テクスチャブラシ';

  @override
  String get triangle => '三角形';

  @override
  String get diamond => 'ひし形';

  @override
  String get hexagon => '六角形';

  @override
  String get heart => 'ハート';

  @override
  String get arrow => '矢印';

  @override
  String get lightning => '稲妻';

  @override
  String get cross => '十字';

  @override
  String get spiral => '渦巻き';

  @override
  String get cloudShape => '雲';

  @override
  String get rectangleSelect => '矩形選択';

  @override
  String get lasso => '投げ縄';

  @override
  String get magicWand => '自動選択';

  @override
  String get effectsPanelAllAppliedMessage =>
      'すべてのエフェクトをレイヤーに適用し、エフェクト一覧から削除しました';

  @override
  String effectsForLayer(String layerName) {
    return '$layerNameのエフェクト';
  }

  @override
  String get effectsPanelAddEffect => 'エフェクトを追加';

  @override
  String get appliedEffects => '適用済みエフェクト';

  @override
  String effectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count個のエフェクト',
      one: '1個のエフェクト',
      zero: '0個のエフェクト',
    );
    return '$_temp0';
  }

  @override
  String get effectsPreview => 'エフェクトプレビュー';

  @override
  String get effectPreview => 'エフェクトプレビュー';

  @override
  String get noEffectsApplied => 'エフェクトは適用されていません';

  @override
  String get saveChanges => '変更を保存';

  @override
  String get finalResult => '最終結果';

  @override
  String get original => '元画像';

  @override
  String get withEffect => 'エフェクトあり';

  @override
  String get withEffects => 'エフェクトあり';

  @override
  String effectsAppliedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count個のエフェクトを適用',
      one: '1個のエフェクトを適用',
      zero: '0個のエフェクトを適用',
    );
    return '$_temp0';
  }

  @override
  String get effectsAppliedInOrder => 'エフェクトは順番に適用されます';

  @override
  String get effectsReorderHint => 'エフェクトは上から下へ適用されます。ドラッグして並べ替えできます。';

  @override
  String get addYourFirstEffect => '最初のエフェクトを追加';

  @override
  String get layerEffects => 'レイヤーエフェクト';

  @override
  String get effectWatercolor => '水彩';

  @override
  String get effectHalftone => 'ハーフトーン';

  @override
  String get effectOilPaint => '油絵';

  @override
  String get effectEmboss => 'エンボス';

  @override
  String get ok => 'OK';

  @override
  String get staticEffect => '静的エフェクト';

  @override
  String effectNotAnimatedMessage(String effectName) {
    return '$effectNameエフェクトはアニメーションエフェクトではありません。アニメーションフレーム生成は、アニメーション対応エフェクトでのみ利用できます。';
  }

  @override
  String get generateAnimation => 'アニメーションを生成';

  @override
  String generateAnimationForEffect(String effectName) {
    return '$effectNameエフェクトのアニメーションフレームを生成しますか？';
  }

  @override
  String get animationDetails => 'アニメーション詳細';

  @override
  String animationDetailEffect(String effectName) {
    return '• エフェクト: $effectName';
  }

  @override
  String animationDetailEstimatedFrames(int count) {
    return '• 推定フレーム数: ~$count';
  }

  @override
  String animationDetailProcessingTime(int seconds) {
    return '• 処理時間: ~$seconds秒';
  }

  @override
  String get generateAnimationTimelineNote =>
      'タイムラインに追加できる複数のアニメーションフレームを作成します。';

  @override
  String get generateAnimationFrames => 'アニメーションフレームを生成';

  @override
  String effectNameLabel(String effectName) {
    return '$effectNameエフェクト';
  }

  @override
  String framesGeneratedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countフレーム生成済み',
      one: '1フレーム生成済み',
      zero: '0フレーム生成済み',
    );
    return '$_temp0';
  }

  @override
  String get generateFrames => 'フレームを生成';

  @override
  String get stop => '停止';

  @override
  String get frameLabel => 'フレーム:';

  @override
  String get generatingFrames => 'フレームを生成中...';

  @override
  String get noFramesGenerated => '生成されたフレームはありません';

  @override
  String get animationSettings => 'アニメーション設定';

  @override
  String get durationSeconds => '長さ（秒）';

  @override
  String get fps => 'FPS';

  @override
  String get totalFrames => '総フレーム数:';

  @override
  String get pingPongAnimation => 'ピンポンアニメーション';

  @override
  String get playForwardThenBackward => '順方向のあと逆方向に再生';

  @override
  String get frameGeneration => 'フレーム生成';

  @override
  String get generateNewFrames => '新規フレームを生成';

  @override
  String get createNewFramesForAnimation => 'このアニメーション用の新規フレームを作成';

  @override
  String get insertIntoTimeline => 'タイムラインに挿入';

  @override
  String get addFramesToExistingTimeline => '既存のタイムラインにフレームを追加';

  @override
  String get insertPosition => '挿入位置:';

  @override
  String afterFrame(int frame) {
    return 'フレーム$frameの後';
  }

  @override
  String get effectParameters => 'エフェクトパラメータ';

  @override
  String get editParameters => 'パラメータを編集';

  @override
  String get effectParametersBaseNote => '現在のエフェクト設定をアニメーションのベースとして使用します';

  @override
  String get editBaseParameters => '基本パラメータを編集';

  @override
  String get applyAndRegenerate => '適用して再生成';

  @override
  String get animationFrameGenerator => 'アニメーションフレーム生成';

  @override
  String get animationGeneratorHelpIntro =>
      'このツールは、選択したエフェクトを異なる時間パラメータで適用して複数のアニメーションフレームを生成します。\n';

  @override
  String get animationHelpDuration => '• 長さ: アニメーション全体の秒数';

  @override
  String get animationHelpFps => '• FPS: 1秒あたりのフレーム数（高いほど滑らかですがフレーム数が増えます）';

  @override
  String get animationHelpPingPong => '• ピンポン: 順方向のあと逆方向に再生します';

  @override
  String get animationHelpInterpolation =>
      '• 滑らかなアニメーションのため、エフェクトパラメータは時間に沿って補間されます';

  @override
  String get tips => 'ヒント:';

  @override
  String get animationTipLowerFps => '• テスト時は低めのFPSから始めましょう';

  @override
  String get animationTipUsePreview => '• 生成前にプレビューで確認しましょう';

  @override
  String get animationTipLongerDurations => '• ゆっくりしたエフェクトには長めの時間が向いています';

  @override
  String effectFrameName(int index) {
    return 'エフェクトフレーム $index';
  }

  @override
  String effectAnimationName(int index) {
    return 'エフェクトアニメーション $index';
  }

  @override
  String effectAnimationReturnName(int index) {
    return 'エフェクトアニメーション $index（戻り）';
  }

  @override
  String generatedAnimationFrames(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count個のアニメーションフレームを生成しました',
      one: '1個のアニメーションフレームを生成しました',
      zero: '0個のアニメーションフレームを生成しました',
    );
    return '$_temp0！';
  }

  @override
  String get viewTimeline => 'タイムラインを表示';

  @override
  String featureBullet(String feature) {
    return '• $feature';
  }

  @override
  String defaultLayerName(int index) {
    return 'レイヤー $index';
  }

  @override
  String get select => '選択';

  @override
  String get menu => 'メニュー';

  @override
  String get adjustOpacity => '不透明度を調整';

  @override
  String get adjustLayerOpacity => 'レイヤーの不透明度を調整';

  @override
  String get addToTemplate => 'テンプレートに追加';

  @override
  String get editLayer => 'レイヤーを編集';

  @override
  String get layerName => 'レイヤー名';

  @override
  String get backgroundShort => 'BG';

  @override
  String get reference => '参照';

  @override
  String get reset => 'リセット';

  @override
  String get fit => '合わせる';

  @override
  String get removeBackgroundImage => '背景画像を削除';

  @override
  String get removeBackgroundImageMessage => '背景画像を削除してもよろしいですか？';

  @override
  String get themeSelector => 'テーマセレクター';

  @override
  String unlockThemeTitle(String themeName) {
    return '$themeNameテーマを解除';
  }

  @override
  String get watchAdToUnlockTheme => '動画広告を見るとこのテーマを解除できます。';

  @override
  String themeUnlocked(String themeName) {
    return '$themeNameテーマを解除しました！';
  }

  @override
  String themeShowcaseTitle(String themeName) {
    return 'テーマ: $themeName';
  }

  @override
  String get primaryColors => 'プライマリカラー';

  @override
  String get primary => 'プライマリ';

  @override
  String get primaryVariant => 'プライマリバリアント';

  @override
  String get onPrimary => 'オンプライマリ';

  @override
  String get accent => 'アクセント';

  @override
  String get onAccent => 'オンアクセント';

  @override
  String get backgroundColors => '背景色';

  @override
  String get background => '背景';

  @override
  String get surface => 'サーフェス';

  @override
  String get surfaceVariant => 'サーフェスバリアント';

  @override
  String get textColors => 'テキスト色';

  @override
  String get textPrimary => 'プライマリテキスト';

  @override
  String get textSecondary => 'セカンダリテキスト';

  @override
  String get textDisabled => '無効テキスト';

  @override
  String get utilityColors => 'ユーティリティ色';

  @override
  String get error => 'エラー';

  @override
  String get success => '成功';

  @override
  String get warning => '警告';

  @override
  String get uiElements => 'UI要素';

  @override
  String get elevated => 'Elevated';

  @override
  String get filled => 'Filled';

  @override
  String get outlined => 'Outlined';

  @override
  String get text => 'Text';

  @override
  String get inputField => '入力欄';

  @override
  String get enterText => 'テキストを入力';

  @override
  String previewingTheme(String themeName) {
    return '$themeNameをプレビュー中';
  }

  @override
  String currentTheme(String themeName) {
    return '現在: $themeName';
  }

  @override
  String get unlockPremiumThemes => 'プレミアムテーマを解除';

  @override
  String get getAccessToAllThemesWithPro => 'Proですべてのテーマにアクセス';

  @override
  String get flagship => 'フラッグシップ';

  @override
  String get free => '無料';

  @override
  String get freeThemes => '無料テーマ';

  @override
  String get premiumThemes => 'プレミアムテーマ';

  @override
  String get apply => '適用';

  @override
  String importedFileAsNewLayer(String fileName) {
    return '\"$fileName\"を新規レイヤーとしてインポートしました';
  }

  @override
  String get importAsepriteFile => 'Asepriteファイルをインポート';

  @override
  String howImportAsepriteFile(String fileName) {
    return '\"$fileName\"をどのようにインポートしますか？';
  }

  @override
  String importedFirstLayerFromFile(String fileName) {
    return '\"$fileName\"から最初のレイヤーをインポートしました';
  }

  @override
  String get importAsLayer => 'レイヤーとしてインポート';

  @override
  String get openAsProject => 'プロジェクトとして開く';

  @override
  String get copyFrame => 'フレームをコピー';

  @override
  String get addFrame => 'フレームを追加';

  @override
  String get deleteFrame => 'フレームを削除';

  @override
  String get collapse => '折りたたむ';

  @override
  String get expand => '展開';

  @override
  String get addState => '状態を追加';

  @override
  String get copyState => '状態をコピー';

  @override
  String get addAnimationState => 'アニメーション状態を追加';

  @override
  String get stateName => '状態名';

  @override
  String get columns => '列';

  @override
  String get tileModeTooltip => 'タイルモード - シームレスな並びをプレビュー';

  @override
  String get settingsStylusMode => '設定（スタイラスモード）';

  @override
  String get onionSkinTooltip => 'オニオンスキン（長押しで不透明度を設定）';

  @override
  String get sprayPaintToolDescription => '粒子でスプレー効果を作成します';

  @override
  String get lineToolDescription => '2点間に直線を描きます';

  @override
  String get circleToolDescription => '正円と楕円を描きます';

  @override
  String get rectangleToolDescription => '長方形と正方形を描きます';

  @override
  String get triangleToolDescription => '三角形を描きます';

  @override
  String get diamondToolDescription => 'ひし形を描きます';

  @override
  String get hexagonToolDescription => '六角形を描きます';

  @override
  String get heartToolDescription => 'ハート形を描きます';

  @override
  String get arrowToolDescription => '矢印形を描きます';

  @override
  String get lightningToolDescription => '稲妻形を描きます';

  @override
  String get crossToolDescription => '十字またはプラス形を描きます';

  @override
  String get spiralToolDescription => '渦巻き形を描きます';

  @override
  String get cloudToolDescription => '雲形を描きます';

  @override
  String get penToolDescription => '高度なフリーハンド描画ツール';

  @override
  String get rectangleSelectToolDescription => '矩形範囲を選択します';

  @override
  String get ellipseSelectToolDescription => '楕円範囲を選択します';

  @override
  String get lassoToolDescription => 'フリーハンド選択ツール';

  @override
  String get magicWandToolDescription => '色でつながったピクセルを選択します';

  @override
  String get curve => '曲線';

  @override
  String get curveToolDescription => '滑らかな曲線を描きます';

  @override
  String get move => '移動';

  @override
  String get moveToolDescription => '要素を移動・ドラッグします';
}
