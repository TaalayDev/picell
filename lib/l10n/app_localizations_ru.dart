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
  String frameCount(int current, int total) {
    return 'Кадр $current/$total';
  }

  @override
  String get playbackSpeed => 'Скорость:';

  @override
  String duration(int ms) {
    return 'Длительность: $msмс';
  }

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
  String get subscriptions => 'Подписки';

  @override
  String get fileMenu => 'Файл';

  @override
  String get profile => 'Профиль';

  @override
  String get logout => 'Выйти';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get signInToContinue => 'Войдите, чтобы продолжить';

  @override
  String get signInToSyncProjects =>
      'Войдите, чтобы синхронизировать ваши проекты.';

  @override
  String get signingIn => 'Вход...';

  @override
  String get continueWithApple => 'Продолжить через Apple';

  @override
  String get signInWithGoogle => 'Войти через Google';

  @override
  String get skipForNow => 'Пропустить';

  @override
  String get noEmail => 'Нет почты';

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
  String get firstFrame => 'Первый кадр';

  @override
  String get previousFrame => 'Предыдущий кадр';

  @override
  String get pause => 'Пауза';

  @override
  String get play => 'Воспроизвести';

  @override
  String get nextFrame => 'Следующий кадр';

  @override
  String get lastFrame => 'Последний кадр';

  @override
  String get feedback_dialog_title => 'Нам важен ваш отзыв!';

  @override
  String get feedback_dialog_description =>
      'Ваше мнение важно! Поделитесь им, чтобы помочь нам сделать приложение лучше.';

  @override
  String get feedback_dialog_benefit_1 => 'Делитесь идеями новых функций';

  @override
  String get feedback_dialog_benefit_2 => 'Сообщайте о багах и проблемах';

  @override
  String get feedback_dialog_benefit_3 =>
      'Помогайте формировать будущее приложения';

  @override
  String get feedback_dialog_leave_feedback => 'Оставить отзыв';

  @override
  String get feedback_dialog_maybe_later => 'Позже';

  @override
  String get feedback_dialog_dont_ask => 'Больше не спрашивать';

  @override
  String get paletteBasic => 'Базовая';

  @override
  String get paletteShades => 'Оттенки';

  @override
  String get paletteComplementary => 'Комплиментарная';

  @override
  String get paletteAnalogous => 'Аналогичная';

  @override
  String get paletteTriadic => 'Триадная';

  @override
  String get paletteMonochromatic => 'Монохроматическая';

  @override
  String get paletteCustom => 'Пользовательская';

  @override
  String get paletteImported => 'Импортированная';

  @override
  String get paletteImportedCount => 'цветов';

  @override
  String get addToCustomPalette => 'Добавить в пользовательскую палитру';

  @override
  String get noCustomColors =>
      'Пользовательские цвета еще не добавлены.\nДобавьте цвета с помощью кнопки + выше.';

  @override
  String get effects => 'Эффекты';

  @override
  String get editorSettings => 'Настройки редактора';

  @override
  String get resetToDefaults => 'Сбросить по умолчанию';

  @override
  String get input => 'Ввод';

  @override
  String get display => 'Отображение';

  @override
  String get showGrid => 'Показать сетку';

  @override
  String get showGridSubtitle => 'Отображать линии сетки на холсте';

  @override
  String get pixelGridOverlay => 'Пиксельная сетка';

  @override
  String get pixelGridSubtitle => 'Показывать границы пикселей при увеличении';

  @override
  String get gridOpacity => 'Прозрачность сетки';

  @override
  String get zoomNavigation => 'Масштаб и навигация';

  @override
  String get zoomSensitivity => 'Чувствительность масштаба';

  @override
  String get zoomSensitivitySubtitle =>
      'Как быстро реагирует щипок для масштабирования';

  @override
  String get minZoom => 'Мин. масштаб';

  @override
  String get maxZoom => 'Макс. масштаб';

  @override
  String get gestures => 'Жесты';

  @override
  String get twoFingerUndo => 'Отмена касанием двумя пальцами';

  @override
  String get twoFingerUndoSubtitle =>
      'Быстрое касание двумя пальцами для отмены';

  @override
  String get done => 'Готово';

  @override
  String get stylusMode => 'Режим стилуса';

  @override
  String get stylusModeSubtitleOn =>
      'Рисование только стилусом • Касание для навигации';

  @override
  String get stylusModeSubtitleOff => 'Рисование и пальцем, и стилусом';

  @override
  String get importImage => 'Импортировать изображение';

  @override
  String get selectImportOption => 'Выберите способ импорта изображения:';

  @override
  String get convertToPixelArt => 'Преобразовать в Pixel Art';

  @override
  String get convertToPixelArtDescription =>
      'Импорт и автоматическое преобразование в пиксельный стиль на новом слое.';

  @override
  String get importAsBackground => 'Импортировать как фон';

  @override
  String get importAsBackgroundDescription =>
      'Импорт как есть для использования в качестве фонового слоя.';

  @override
  String get conversionSettings => 'Настройки конвертации';

  @override
  String get paletteColors => 'Цвета палитры';

  @override
  String get fullColor => 'Полный цвет';

  @override
  String get dithering => 'Дизеринг';

  @override
  String get noDithering => 'Нет';

  @override
  String get alphaThreshold => 'Порог прозрачности';

  @override
  String get chooseImage => 'Выбрать изображение';

  @override
  String get tinyIcon => 'Маленькая иконка';

  @override
  String get smallSprite => 'Небольшой спрайт';

  @override
  String get mediumCharacter => 'Средний персонаж';

  @override
  String get largeScene => 'Большая сцена';

  @override
  String get projectNameRequired => 'Введите название проекта';

  @override
  String get templateRequired => 'Выберите шаблон';

  @override
  String planLimitError(int limit) {
    return 'Ваш план ограничен $limit пикселями';
  }

  @override
  String get widthRequired => 'Введите ширину';

  @override
  String get heightRequired => 'Введите высоту';

  @override
  String widthRangeError(int max) {
    return 'Ширина: 1-$max';
  }

  @override
  String heightRangeError(int max) {
    return 'Высота: 1-$max';
  }

  @override
  String get saveImage => 'Сохранить изображение';

  @override
  String get png => 'PNG';

  @override
  String get animatedGif => 'Анимированный GIF';

  @override
  String get proPlanRequired => 'Требуется тариф Pro';

  @override
  String get spriteSheet => 'Спрайтовый лист';

  @override
  String get transparentBackground => 'Прозрачный фон';

  @override
  String get transparent => 'Прозрачный';

  @override
  String get spriteSheetOptions => 'Настройки спрайтового листа';

  @override
  String get columnsLabel => 'Колонки';

  @override
  String get spacingPx => 'Отступ (px)';

  @override
  String get exportSize => 'Размер экспорта';

  @override
  String scaleWithValues(String scale) {
    return 'Масштаб: ${scale}x';
  }

  @override
  String get format => 'Формат';

  @override
  String get options => 'Опции';

  @override
  String editEffect(String name) {
    return 'Редактировать эффект $name';
  }

  @override
  String get applyChanges => 'Применить изменения';

  @override
  String get preview => 'Предпросмотр';

  @override
  String get quickPresets => 'Быстрые пресеты';

  @override
  String get parameters => 'Параметры';

  @override
  String get previewNotAvailable => 'Предпросмотр недоступен';

  @override
  String get tapToChange => 'Нажмите, чтобы изменить';

  @override
  String get enable => 'Включить';

  @override
  String get uiFieldTap => 'Нажмите';

  @override
  String get uiFieldEnabled => 'Включено';

  @override
  String get uiFieldDisabled => 'Выключено';

  @override
  String get presetDarker => 'Темнее';

  @override
  String get presetNormal => 'Нормально';

  @override
  String get presetBrighter => 'Ярче';

  @override
  String get presetVeryBright => 'Очень ярко';

  @override
  String get presetLow => 'Низкий';

  @override
  String get presetHigh => 'Высокий';

  @override
  String get presetVeryHigh => 'Очень высокий';

  @override
  String get presetSubtle => 'Слабо';

  @override
  String get presetSoft => 'Мягко';

  @override
  String get presetMedium => 'Средне';

  @override
  String get presetStrong => 'Сильно';

  @override
  String get effectBrightness => 'Яркость';

  @override
  String get effectContrast => 'Контраст';

  @override
  String get effectBlur => 'Размытие';

  @override
  String get effectVignette => 'Виньетка';

  @override
  String get effectInvert => 'Инверсия';

  @override
  String get effectGrayscale => 'Оттенки серого';

  @override
  String get effectSepia => 'Сепия';

  @override
  String get effectThreshold => 'Порог';

  @override
  String get effectPixelate => 'Пикселизация';

  @override
  String get effectSharpen => 'Резкость';

  @override
  String get effectNoise => 'Шум';

  @override
  String get effectGlow => 'Свечение';

  @override
  String get effectGlitch => 'Глитч';

  @override
  String get effectSparkle => 'Искры';

  @override
  String get effectFire => 'Огонь';

  @override
  String get effectRain => 'Дождь';

  @override
  String get selectEffect => 'Выбор эффекта';

  @override
  String get searchEffects => 'Поиск эффектов...';

  @override
  String get categoryAll => 'Все';

  @override
  String get categoryColorTone => 'Цвет и Тон';

  @override
  String get categoryBlurSharpen => 'Размытие и Резкость';

  @override
  String get categoryArtistic => 'Художественные';

  @override
  String get categoryAnimation => 'Анимация';

  @override
  String get categoryNature => 'Природа';

  @override
  String get categoryParticles => 'Частицы';

  @override
  String get categoryDistortion => 'Искажение';

  @override
  String get categoryTextures => 'Текстуры';

  @override
  String get categorySpecialFx => 'Спецэффекты';

  @override
  String get noEffectsMatch => 'Нет эффектов, соответствующих поиску';

  @override
  String get premiumEffect => 'Премиум эффект';

  @override
  String get proVersionStatus => 'Этот эффект доступен в Pro версии.';

  @override
  String get proFeaturesInclude => 'Возможности Pro версии:';

  @override
  String get featureAdvancedEffects => 'Продвинутые эффекты и инструменты';

  @override
  String get featureUnlimitedProjects => 'Неограниченное количество проектов';

  @override
  String get featureCloudBackup => 'Облачное резервное копирование';

  @override
  String get featurePrioritySupport => 'Приоритетная поддержка';

  @override
  String get maybeLater => 'Возможно позже';

  @override
  String get upgradeToPro => 'Обновить до Pro';

  @override
  String get effectsPanelRemoveEffectTitle => 'Удалить эффект';

  @override
  String effectsPanelRemoveEffectMessage(String effectName) {
    return 'Вы уверены, что хотите удалить эффект $effectName?';
  }

  @override
  String get effectsPanelClearAllEffectsTitle => 'Очистить все эффекты';

  @override
  String get effectsPanelClearAllEffectsMessage =>
      'Вы уверены, что хотите удалить все эффекты с этого слоя?';

  @override
  String get effectsPanelClearAll => 'Очистить все';

  @override
  String effectsPanelAppliedToLayerMessage(String effectName) {
    return 'Эффект $effectName применен к слою';
  }

  @override
  String get effectsPanelActionApply => 'Применить';

  @override
  String get effectsPanelActionRemove => 'Удалить';

  @override
  String get effectsPanelActionMore => 'Еще';

  @override
  String get effectsPanelMoreActionsTitle => 'Другие действия';

  @override
  String get effectsPanelApplyAll => 'Применить все';

  @override
  String get ellipseSelection => 'Овальное выделение';

  @override
  String get ellipseSelectionTooltip => 'Выделить овальную область';

  @override
  String get autoSelectLayer => 'Авто-выделение';

  @override
  String get autoSelectLayerTooltip =>
      'Выделить все непустые пиксели текущего слоя';

  @override
  String get selectionAnchor => 'Якорь выделения';
}
