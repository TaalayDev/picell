// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class StringsRu extends Strings {
  StringsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Picell';

  @override
  String get aboutTitle => 'О программе Picell';

  @override
  String get welcome => 'Добро пожаловать в Picell!';

  @override
  String get aboutAppDescription =>
      'Picell - это ваш путь к созданию потрясающего пиксельного искусства. Независимо от того, являетесь ли вы опытным художником или только начинаете, наше приложение предоставляет все необходимые инструменты для воплощения ваших пиксельных идей в жизнь.';

  @override
  String version(String version) {
    return 'Версия $version';
  }

  @override
  String get features =>
      'Интуитивные инструменты для редактирования пикселей, \nПользовательские цветовые палитры, \nПоддержка слоев для сложных работ, \nВременная шкала анимации для создания GIF, \nЭкспорт в различных форматах, \nОбмен работами в сообществе';

  @override
  String get featuresTitle => 'Основные возможности:';

  @override
  String get visitWebsite =>
      'Посетите мой сайт для получения дополнительной информации:';

  @override
  String get pickAColor => 'Выберите цвет';

  @override
  String get colorPicker => 'Выбор цвета';

  @override
  String get gotIt => 'Понятно';

  @override
  String get undo => 'Отменить';

  @override
  String get redo => 'Повторить';

  @override
  String get clear => 'Очистить';

  @override
  String get save => 'Сохранить';

  @override
  String get saveAs => 'Сохранить как';

  @override
  String get open => 'Открыть';

  @override
  String get export => 'Экспорт';

  @override
  String get import => 'Импорт';

  @override
  String get share => 'Поделиться';

  @override
  String get close => 'Закрыть';

  @override
  String get projects => 'Проекты';

  @override
  String get lineTool => 'Линия';

  @override
  String get rectangleTool => 'Прямоугольник';

  @override
  String get circleTool => 'Круг';

  @override
  String get about => 'О программе';

  @override
  String get invalidFileContent => 'Неверное содержимое файла';

  @override
  String get anErrorOccurred => 'Произошла ошибка';

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String get creatingProject => 'Создание проекта...';

  @override
  String get openingProject => 'Открытие проекта...';

  @override
  String get noProjectsFound => 'Проекты не найдены';

  @override
  String get createNewProject => 'Создать новый';

  @override
  String get rename => 'Переименовать';

  @override
  String get delete => 'Удалить';

  @override
  String get edit => 'Редактировать';

  @override
  String get cancel => 'Отмена';

  @override
  String get deleteProject => 'Удалить проект';

  @override
  String get areYouSureWantToDeleteProject =>
      'Вы уверены, что хотите удалить этот проект?';

  @override
  String get renameProject => 'Переименовать проект';

  @override
  String get projectName => 'Название проекта';

  @override
  String timeAgo(String time) {
    return '$time назад';
  }

  @override
  String get justNow => 'Только что';

  @override
  String get animationPreview => 'Предпросмотр анимации';

  @override
  String get colorPalette => 'Цветовая палитра';

  @override
  String get currentColor => 'Текущий цвет';

  @override
  String get add => 'Добавить';

  @override
  String get layers => 'Слои';

  @override
  String get deleteLayer => 'Удалить слой';

  @override
  String get areYouSureWantToDeleteLayer =>
      'Вы уверены, что хотите удалить этот слой?';

  @override
  String get newProject => 'Новый проект';

  @override
  String get template => 'Шаблон';

  @override
  String get width => 'Ширина';

  @override
  String get height => 'Высота';

  @override
  String get create => 'Создать';

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
  String get feedback_title => 'Обратная связь';

  @override
  String get feedback_thank_you => 'Спасибо за ваш отзыв!';

  @override
  String get feedback_thank_you_message =>
      'Ваше мнение очень важно для нас и поможет сделать приложение лучше.';

  @override
  String get feedback_return => 'Вернуться';

  @override
  String get feedback_help_us => 'Помогите нам стать лучше';

  @override
  String get feedback_intro =>
      'Ваше мнение очень важно для развития проекта. Пожалуйста, ответьте на несколько вопросов.';

  @override
  String feedback_answered(int count, int total) {
    return 'Отвечено: $count из $total';
  }

  @override
  String get feedback_required => 'Обязательно';

  @override
  String get feedback_sending => 'Отправка...';

  @override
  String get feedback_send => 'Отправить';

  @override
  String get feedback_validation_error =>
      'Пожалуйста, ответьте на все обязательные вопросы';

  @override
  String get feedback_very_poor => 'Очень плохо';

  @override
  String get feedback_excellent => 'Отлично';

  @override
  String get feedback_yes => 'Да';

  @override
  String get feedback_no => 'Нет';

  @override
  String get feedback_text_placeholder => 'Введите ваш ответ...';

  @override
  String get feedback_q_satisfaction => 'Насколько вы довольны приложением?';

  @override
  String get feedback_q_missing_features =>
      'Какие функциональности вам не хватают?';

  @override
  String get feedback_q_missing_features_placeholder =>
      'Опишите функции, которые вы хотели бы видеть...';

  @override
  String get feedback_q_bug_reports =>
      'Столкнулись ли вы с какими-либо ошибками или сбоями?';

  @override
  String get feedback_q_bug_reports_placeholder =>
      'Опишите проблемы, с которыми вы столкнулись...';

  @override
  String get feedback_q_price_satisfaction =>
      'Устраивает ли вас текущая цена приложения?';

  @override
  String get feedback_q_price_feedback =>
      'Если нет, какую цену вы считаете справедливой?';

  @override
  String get feedback_q_price_free => 'Бесплатно';

  @override
  String get feedback_q_price_up_to_5 => 'До \$5';

  @override
  String get feedback_q_price_5_to_10 => '\$5 - \$10';

  @override
  String get feedback_q_price_10_to_20 => '\$10 - \$20';

  @override
  String get feedback_q_price_more_20 => 'Больше \$20';

  @override
  String get feedback_q_patreon_support =>
      'Будете ли вы поддерживать проект на Patreon?';

  @override
  String get feedback_q_patreon_definitely => 'Да, обязательно';

  @override
  String get feedback_q_patreon_if_exclusive =>
      'Возможно, если будут эксклюзивные функции';

  @override
  String get feedback_q_patreon_if_reasonable =>
      'Возможно, если цена будет разумной';

  @override
  String get feedback_q_patreon_probably_not => 'Скорее нет';

  @override
  String get feedback_q_patreon_no => 'Нет, не планирую';

  @override
  String get feedback_q_patreon_tier =>
      'Какой уровень поддержки на Patreon вам интересен?';

  @override
  String get feedback_q_patreon_tier_3 =>
      '\$3/месяц - Ранний доступ к функциям';

  @override
  String get feedback_q_patreon_tier_5 => '\$5/месяц - + Эксклюзивные темы';

  @override
  String get feedback_q_patreon_tier_10 =>
      '\$10/месяц - + Влияние на разработку';

  @override
  String get feedback_q_usage_frequency =>
      'Как часто вы используете приложение?';

  @override
  String get feedback_q_usage_daily => 'Каждый день';

  @override
  String get feedback_q_usage_several_week => 'Несколько раз в неделю';

  @override
  String get feedback_q_usage_once_week => 'Раз в неделю';

  @override
  String get feedback_q_usage_several_month => 'Несколько раз в месяц';

  @override
  String get feedback_q_usage_rarely => 'Реже';

  @override
  String get feedback_q_main_use_case =>
      'Для чего вы в основном используете приложение?';

  @override
  String get feedback_q_use_pixel_art => 'Создание pixel art';

  @override
  String get feedback_q_use_game_design => 'Дизайн игр';

  @override
  String get feedback_q_use_animation => 'Анимация';

  @override
  String get feedback_q_use_hobby => 'Хобби/развлечение';

  @override
  String get feedback_q_use_professional => 'Профессиональная работа';

  @override
  String get feedback_q_use_learning => 'Обучение';

  @override
  String get feedback_q_additional_feedback =>
      'Дополнительные комментарии и пожелания';

  @override
  String get feedback_q_additional_feedback_placeholder =>
      'Поделитесь своими мыслями о приложении...';

  @override
  String get feedback_q_recommend =>
      'Порекомендуете ли вы это приложение друзьям?';

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
