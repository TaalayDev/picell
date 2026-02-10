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
}
