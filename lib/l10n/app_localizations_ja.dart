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
  String get editorSettings => 'エディタ設定';

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
  String get proPlanRequired => 'Proプランが必要';

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
  String get proFeaturesInclude => 'Proバージョンの機能:';

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
}
