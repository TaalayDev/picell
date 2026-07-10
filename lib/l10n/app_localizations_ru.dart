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
  String get category => 'Категория';

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
  String get selectionTransforms => 'Трансформации выделения';

  @override
  String get transformInterpolation => 'Интерполяция';

  @override
  String get transformInterpolationSubtitle =>
      'Используется при изменении размера и вращении выделения';

  @override
  String get nearestNeighbor => 'Ближайший сосед';

  @override
  String get bilinear => 'Билинейная';

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
  String get proPlanRequired => 'Требуется план Pro';

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
  String get proFeaturesInclude => 'Функции Pro включают:';

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

  @override
  String get feedback => 'Обратная связь';

  @override
  String get createNewProjectTooltip => 'Создать новый проект';

  @override
  String failedToProcessFile(String fileName) {
    return 'Не удалось обработать $fileName';
  }

  @override
  String importingFile(String fileName) {
    return 'Импорт $fileName...';
  }

  @override
  String importedProjectSuccessfully(String projectName) {
    return '«$projectName» успешно импортирован';
  }

  @override
  String failedToImport(String error) {
    return 'Не удалось импортировать: $error';
  }

  @override
  String unsupportedFileType(String fileName) {
    return 'Неподдерживаемый тип файла: $fileName';
  }

  @override
  String get pleaseSignInToUploadProjects => 'Войдите, чтобы загружать проекты';

  @override
  String get pleaseSignInToUpdateProjects => 'Войдите, чтобы обновлять проекты';

  @override
  String get projectNotSyncedToCloud => 'Проект не синхронизирован с облаком';

  @override
  String get pleaseSignInToRemoveCloudProjects =>
      'Войдите, чтобы удалять проекты из облака';

  @override
  String get removingFromCloud => 'Удаление из облака...';

  @override
  String get projectRemovedFromCloudSuccessfully =>
      'Проект успешно удалён из облака';

  @override
  String failedToRemoveFromCloud(String error) {
    return 'Не удалось удалить из облака: $error';
  }

  @override
  String get search => 'Поиск...';

  @override
  String get myProjects => 'Мои проекты';

  @override
  String get noProjectsYet => 'Пока нет проектов';

  @override
  String get createOne => 'Создать';

  @override
  String get searchProjects => 'Искать проекты...';

  @override
  String get discoverAmazingPixelArt => 'Откройте для себя пиксель-арт';

  @override
  String get sortBy => 'Сортировать';

  @override
  String get mostRecent => 'Сначала новые';

  @override
  String get mostPopular => 'Популярные';

  @override
  String get mostViewed => 'Самые просматриваемые';

  @override
  String get mostLiked => 'Больше лайков';

  @override
  String get titleAZ => 'Название А-Я';

  @override
  String get all => 'Все';

  @override
  String get featuredProjects => 'Избранные проекты';

  @override
  String get errorLoadingProjects => 'Ошибка загрузки проектов';

  @override
  String get deletingProject => 'Удаление проекта...';

  @override
  String get projectDeletedSuccessfully => 'Проект успешно удалён';

  @override
  String get failedToDeleteProject => 'Не удалось удалить проект';

  @override
  String failedToDeleteProjectWithError(String error) {
    return 'Не удалось удалить проект: $error';
  }

  @override
  String get unlike => 'Убрать лайк';

  @override
  String get like => 'Лайк';

  @override
  String get editProject => 'Редактировать проект';

  @override
  String get public => 'Публичный';

  @override
  String get private => 'Приватный';

  @override
  String get analytics => 'Аналитика';

  @override
  String get stats => 'Статистика';

  @override
  String likeCountLabel(String count) {
    return '$count лайков';
  }

  @override
  String commentCountLabel(String count) {
    return '$count комментариев';
  }

  @override
  String get download => 'Скачать';

  @override
  String get openProject => 'Открыть проект';

  @override
  String get downloadProject => 'Скачать проект';

  @override
  String get localProjectNotFound => 'Локальный проект не найден';

  @override
  String get comments => 'Комментарии';

  @override
  String get addComment => 'Добавить комментарий';

  @override
  String get noCommentsYet => 'Комментариев пока нет';

  @override
  String get beFirstToComment => 'Оставьте первый комментарий!';

  @override
  String get failedToLoadComments => 'Не удалось загрузить комментарии';

  @override
  String get edited => 'Изменено';

  @override
  String get makeProjectPublic => 'Сделать проект публичным';

  @override
  String get makeProjectPrivate => 'Сделать проект приватным';

  @override
  String get makeProjectPublicMessage =>
      'Проект станет видимым для всего сообщества. Все смогут просматривать, лайкать и комментировать его.';

  @override
  String get makeProjectPrivateMessage =>
      'Проект будет скрыт от сообщества. Видеть его сможете только вы.';

  @override
  String get projectWillBePublic => 'Проект будет виден публично';

  @override
  String get projectWillBePrivate => 'Проект будет приватным';

  @override
  String get projectIsNowPublic => 'Проект теперь публичный';

  @override
  String get projectIsNowPrivate => 'Проект теперь приватный';

  @override
  String failedToUpdateVisibility(String error) {
    return 'Не удалось изменить видимость: $error';
  }

  @override
  String get makePublic => 'Сделать публичным';

  @override
  String get makePrivate => 'Сделать приватным';

  @override
  String get deleteProjectCannotBeUndone =>
      'Вы уверены, что хотите удалить этот проект? Это действие нельзя отменить.';

  @override
  String get thisWillPermanentlyDelete => 'Будет удалено навсегда:';

  @override
  String get deleteProjectConsequences =>
      '• Данные и арт проекта\n• Все комментарии и лайки\n• Статистика скачиваний';

  @override
  String typeProjectTitleToConfirmDeletion(String title) {
    return 'Введите «$title» для подтверждения удаления:';
  }

  @override
  String get enterProjectTitle => 'Введите название проекта...';

  @override
  String get deleteForever => 'Удалить навсегда';

  @override
  String get openingProjectEditor => 'Открытие редактора проекта...';

  @override
  String get projectLinkCopied => 'Ссылка на проект скопирована!';

  @override
  String get addedToFavorites => 'Добавлено в избранное!';

  @override
  String nowFollowingUser(String username) {
    return 'Вы подписались на $username!';
  }

  @override
  String get reportProject => 'Пожаловаться на проект';

  @override
  String get reportProjectMessage =>
      'Вы уверены, что хотите пожаловаться на этот проект? Пожалуйста, сообщайте только о контенте, нарушающем правила сообщества.';

  @override
  String get reportThanks => 'Спасибо за жалобу. Мы скоро её рассмотрим.';

  @override
  String get report => 'Пожаловаться';

  @override
  String get premiumRequiredToDownloadProjects =>
      'Для скачивания проектов нужна Premium-подписка';

  @override
  String get upgrade => 'Улучшить';

  @override
  String get downloadProjectRewardSubtitle =>
      'Чтобы скачать проект, вы можете:';

  @override
  String get thankYouWatchingDownloadStarting =>
      'Спасибо за просмотр! Скачивание начинается...';

  @override
  String get pleaseSignInToAddComments =>
      'Войдите, чтобы добавлять комментарии';

  @override
  String get writeYourComment => 'Напишите комментарий...';

  @override
  String get commentAddedSuccessfully => 'Комментарий добавлен!';

  @override
  String failedToAddComment(String error) {
    return 'Не удалось добавить комментарий: $error';
  }

  @override
  String get post => 'Опубликовать';

  @override
  String get chooseTheme => 'Выберите тему';

  @override
  String get importFile => 'Импорт файла';

  @override
  String get theme => 'Тема';

  @override
  String get getPro => 'Получить Pro';

  @override
  String get supportOnKofi => 'Поддержать на Ko-fi';

  @override
  String get copyLink => 'Копировать ссылку';

  @override
  String get size => 'Размер';

  @override
  String get views => 'Просмотры';

  @override
  String get downloads => 'Скачивания';

  @override
  String get published => 'Опубликовано!';

  @override
  String get forkedFrom => 'Форк от ';

  @override
  String byUser(String username) {
    return ' от $username';
  }

  @override
  String get projectAnalytics => 'Аналитика проекта';

  @override
  String get totalViews => 'Всего просмотров';

  @override
  String get totalLikes => 'Всего лайков';

  @override
  String get detailedAnalytics => 'Подробная аналитика';

  @override
  String get advancedAnalyticsSoon =>
      'Расширенная аналитика скоро будет доступна.';

  @override
  String get details => 'Детали';

  @override
  String get title => 'Название';

  @override
  String get projectTitleHint => 'Дайте проекту название';

  @override
  String get description => 'Описание';

  @override
  String get projectDescriptionHint =>
      'Расскажите сообществу об этом проекте (необязательно)';

  @override
  String get visibility => 'Видимость';

  @override
  String get tags => 'Теги';

  @override
  String get searchTags => 'Искать теги…';

  @override
  String get failedToLoadTags => 'Не удалось загрузить теги';

  @override
  String get pleaseEnterTitle => 'Введите название';

  @override
  String get removeFromCloudQuestion => 'Удалить из облака?';

  @override
  String get removeFromCommunityMessage =>
      'Проект будет удалён из сообщества. Локальная копия останется.';

  @override
  String get remove => 'Удалить';

  @override
  String get updateProject => 'Обновить проект';

  @override
  String get publishToCommunity => 'Опубликовать в сообществе';

  @override
  String get synced => 'Синхронизировано';

  @override
  String get visibleToEveryone => 'Видно всем';

  @override
  String get onlyVisibleToYou => 'Видно только вам';

  @override
  String get maximumTagsAllowed => 'Можно выбрать не более 5 тегов';

  @override
  String frameCountSimple(int count) {
    return '$count кадр.';
  }

  @override
  String layerCountSimple(int count) {
    return '$count слоёв';
  }

  @override
  String get cloudManagement => 'Управление облаком';

  @override
  String cloudId(String id) {
    return 'Cloud ID: $id';
  }

  @override
  String get preparingUpdate => 'Подготовка обновления…';

  @override
  String get preparingProject => 'Подготовка проекта…';

  @override
  String get generatingThumbnail => 'Создание миниатюры…';

  @override
  String get updatingOnCloud => 'Обновление в облаке…';

  @override
  String get uploadingToCloud => 'Загрузка в облако…';

  @override
  String get finalizing => 'Завершение…';

  @override
  String get updated => 'Обновлено!';

  @override
  String get updating => 'Обновление…';

  @override
  String get publishing => 'Публикация…';

  @override
  String get update => 'Обновить';

  @override
  String get publish => 'Опубликовать';

  @override
  String get downloadingProject => 'Скачивание проекта';

  @override
  String get downloadingProjectData => 'Скачивание данных проекта...';

  @override
  String get downloadComplete => 'Скачивание завершено!';

  @override
  String get projectSavedLocal => 'Проект сохранён в локальные проекты';

  @override
  String get downloadFailed => 'Скачивание не удалось';

  @override
  String get resyncWithCloud => 'Синхронизировать заново';

  @override
  String get syncToCloud => 'Синхронизировать с облаком';

  @override
  String get removeFromCloud => 'Удалить из облака';

  @override
  String get removeFromCloudMessage =>
      'Проект будет удалён из облака и станет только локальным. Локальная копия останется без изменений. Вы уверены?';

  @override
  String get syncedCloudDeleteWarning =>
      'Этот проект синхронизирован с облаком. Локальное удаление не повлияет на облачную версию.';

  @override
  String get openLocalProject => 'Открыть локальный проект';

  @override
  String get premiumRequired => 'Нужен Premium';

  @override
  String byUserInline(String username) {
    return 'от $username';
  }

  @override
  String get createTemplate => 'Создать шаблон';

  @override
  String layerNameLabel(String name) {
    return 'Имя: $name';
  }

  @override
  String layerSizeLabel(int width, int height) {
    return 'Размер: $width×$height';
  }

  @override
  String nonTransparentPixels(int count) {
    return 'Пикселей: $count непрозрачных';
  }

  @override
  String get templateName => 'Название шаблона';

  @override
  String get descriptionOptional => 'Описание (необязательно)';

  @override
  String get saveOptions => 'Параметры сохранения';

  @override
  String get saveLocally => 'Сохранить локально';

  @override
  String get storeOnDeviceOnly => 'Только на этом устройстве';

  @override
  String get uploadToCloud => 'Загрузить в облако';

  @override
  String get shareWithCommunity => 'Поделиться с сообществом';

  @override
  String get privateCloudStorage => 'Приватное облачное хранилище';

  @override
  String get otherUsersCanDiscoverTemplate =>
      'Другие пользователи смогут найти и использовать этот шаблон';

  @override
  String get onlyYouCanAccessTemplate =>
      'Только вы сможете открыть этот шаблон';

  @override
  String get saveLocallyAndUpload => 'Сохранить локально и загрузить';

  @override
  String get bestOfBothWorlds => 'Лучшее из двух вариантов';

  @override
  String get signInToUploadTemplates => 'Войдите, чтобы загружать шаблоны';

  @override
  String get shareTemplatesWithCommunity => 'Делитесь шаблонами с сообществом';

  @override
  String get failedToConvertLayerToTemplate =>
      'Не удалось преобразовать слой в шаблон';

  @override
  String get failedToSaveTemplateLocally =>
      'Не удалось сохранить шаблон локально';

  @override
  String get failedToUploadTemplateToServer =>
      'Не удалось загрузить шаблон на сервер';

  @override
  String errorCreatingTemplate(String error) {
    return 'Ошибка создания шаблона: $error';
  }

  @override
  String get templateSavedLocally => 'Шаблон сохранён локально!';

  @override
  String get templateUploadedSuccessfully => 'Шаблон успешно загружен!';

  @override
  String get templateSavedAndUploaded => 'Шаблон сохранён локально и загружен!';

  @override
  String get templateSavedUploadFailed =>
      'Шаблон сохранён локально (загрузка не удалась)';

  @override
  String get templateUploadedLocalSaveFailed =>
      'Шаблон загружен (локальное сохранение не удалось)';

  @override
  String get templateCreationFailed => 'Не удалось создать шаблон';

  @override
  String get templateGallery => 'Галерея шаблонов';

  @override
  String get allTemplates => 'Все шаблоны';

  @override
  String get local => 'Локальные';

  @override
  String get community => 'Сообщество';

  @override
  String get failedTemplateDetailsCached =>
      'Не удалось загрузить детали шаблона. Используются кэшированные данные.';

  @override
  String errorLoadingTemplate(String error) {
    return 'Ошибка загрузки шаблона: $error';
  }

  @override
  String get loadingTemplate => 'Загрузка шаблона...';

  @override
  String get deleteTemplate => 'Удалить шаблон';

  @override
  String deleteTemplateQuestion(String name) {
    return 'Удалить шаблон «$name»?';
  }

  @override
  String get deleteLocalTemplateWarning =>
      'Этот шаблон будет навсегда удалён из локального хранилища.';

  @override
  String get deleteCloudTemplateWarning =>
      'Этот шаблон будет удалён из облака без возможности восстановления.';

  @override
  String templateDeletedSuccessfully(String name) {
    return 'Шаблон «$name» удалён';
  }

  @override
  String failedToDeleteTemplate(String name) {
    return 'Не удалось удалить шаблон «$name»';
  }

  @override
  String get searchTemplates => 'Искать шаблоны...';

  @override
  String get loadingTemplates => 'Загрузка шаблонов...';

  @override
  String get premiumTemplate => 'Premium-шаблон';

  @override
  String get templateAvailableInPro => 'Этот шаблон доступен в версии Pro.';

  @override
  String get premiumTemplatesFeature => '• Premium-шаблоны';

  @override
  String get advancedEffectsToolsFeature =>
      '• Продвинутые эффекты и инструменты';

  @override
  String get unlimitedProjectsFeature => '• Неограниченные проекты';

  @override
  String get cloudBackupFeature => '• Облачное резервное копирование';

  @override
  String get prioritySupportFeature => '• Приоритетная поддержка';

  @override
  String get noLocalTemplates =>
      'Локальные шаблоны не найдены.\nСоздайте первый шаблон из слоя!';

  @override
  String get noCommunityTemplates =>
      'Шаблоны сообщества не найдены.\nПопробуйте изменить поиск или фильтры.';

  @override
  String get noUploadedTemplates =>
      'Вы ещё не загрузили шаблоны.\nПоделитесь своими работами с сообществом!';

  @override
  String get noTemplatesFoundAdjust =>
      'Шаблоны не найдены.\nПопробуйте изменить поиск или фильтры.';

  @override
  String showingTemplates(int displayed, String total) {
    String _temp0 = intl.Intl.selectLogic(
      total,
      {
        'none': '',
        'other': ' из $total',
      },
    );
    return 'Показано $displayed$_temp0 шаблонов';
  }

  @override
  String get clickTemplateToApply => 'Нажмите шаблон, чтобы применить';

  @override
  String get pro => 'PRO';

  @override
  String get pleaseEnterTemplateName => 'Введите название шаблона';

  @override
  String get signInToUploadTemplatesTitle => 'Войдите, чтобы загружать шаблоны';

  @override
  String get signInToUploadTemplatesSubtitle =>
      'Создайте аккаунт, чтобы делиться шаблонами с сообществом.';

  @override
  String get myTemplates => 'Мои шаблоны';

  @override
  String get cloud => 'Облако';

  @override
  String get tapToUnlock => 'Нажмите, чтобы открыть';

  @override
  String get layerTemplateDefaultName => 'Шаблон слоя';

  @override
  String get undoHistoryTitle => 'История';

  @override
  String undoHistoryStepCount(int total) {
    return '($total шагов)';
  }

  @override
  String get undoHistoryRevertAll => 'Откатить всё';

  @override
  String get undoHistoryCurrentState => 'Текущее состояние';

  @override
  String undoHistoryFrameLayer(int frame, int layer) {
    return 'Кадр $frame, слой $layer';
  }

  @override
  String get keyboardShortcuts => 'Горячие клавиши';

  @override
  String get copySelection => 'Копировать выделение';

  @override
  String get cutSelection => 'Вырезать выделение';

  @override
  String get paste => 'Вставить';

  @override
  String get duplicateLayer => 'Дублировать слой';

  @override
  String get selection => 'Выделение';

  @override
  String get selectAll => 'Выделить всё';

  @override
  String get deselect => 'Снять выделение';

  @override
  String get closePenPath => 'Закрыть контур пера';

  @override
  String get tools => 'Инструменты';

  @override
  String get pencil => 'Карандаш';

  @override
  String get eraser => 'Ластик';

  @override
  String get eyedropper => 'Пипетка';

  @override
  String get fill => 'Заливка';

  @override
  String get selectMarquee => 'Выделение / рамка';

  @override
  String get moveDrag => 'Перемещение / перетаскивание';

  @override
  String get pen => 'Перо';

  @override
  String get sprayPaint => 'Аэрозоль';

  @override
  String get panHold => 'Панорама (удерживать)';

  @override
  String get eyedropperHold => 'Пипетка (удерживать)';

  @override
  String get brush => 'Кисть';

  @override
  String get increaseSize => 'Увеличить размер';

  @override
  String get decreaseSize => 'Уменьшить размер';

  @override
  String get colors => 'Цвета';

  @override
  String get swapColors => 'Поменять цвета';

  @override
  String get defaultColors => 'Цвета по умолчанию';

  @override
  String get view => 'Вид';

  @override
  String get zoomIn => 'Приблизить';

  @override
  String get zoomOut => 'Отдалить';

  @override
  String get zoomToFit => 'По размеру окна';

  @override
  String get zoomOneToOne => 'Масштаб 1:1';

  @override
  String get toggleUi => 'Показать/скрыть UI';

  @override
  String get selectLayerOneToNine => 'Выбрать слой 1-9';

  @override
  String get newLayer => 'Новый слой';

  @override
  String get deleteAccountCannotBeUndone => 'Это действие нельзя отменить';

  @override
  String get deleteAccountPermanentDataWarning =>
      'Удаление аккаунта навсегда удалит все ваши данные.';

  @override
  String get deleteAccountItemsIntro => 'Будет навсегда удалено:';

  @override
  String get deleteAccountPreferencesTitle => 'Настройки приложения';

  @override
  String get deleteAccountPreferencesSubtitle => 'Параметры и персонализация';

  @override
  String get deleteAccountInfoTitle => 'Информация аккаунта';

  @override
  String get deleteAccountInfoSubtitle => 'Профиль и данные входа';

  @override
  String get deleteAccountTypeConfirm =>
      'Введите \"DELETE\" для подтверждения:';

  @override
  String get deleteAccountTypeHint => 'Введите DELETE здесь...';

  @override
  String get deleteAccountIrreversibleImmediate =>
      'Это действие необратимо и вступит в силу сразу.';

  @override
  String get deleteAccountQuickConfirm =>
      'Вы уверены, что хотите навсегда удалить аккаунт?';

  @override
  String get deleteAccountQuickWarningList =>
      '• Все ваши проекты будут потеряны\n• Облачные резервные копии будут удалены\n• Это действие нельзя отменить';

  @override
  String failedToDeleteAccount(String error) {
    return 'Не удалось удалить аккаунт: $error';
  }

  @override
  String get proAccessActive => 'Pro-доступ активен';

  @override
  String proAccessRemaining(String time) {
    return 'У вас осталось $time Pro-доступа.';
  }

  @override
  String get buyPro => 'Купить Pro';

  @override
  String get rewardUpgradeBullets =>
      '• Неограниченный доступ ко всем функциям\n• Разовая покупка\n• Без рекламы\n• Приоритетная поддержка';

  @override
  String get tryPro45Minutes => 'Попробовать Pro на 45 минут';

  @override
  String get rewardAdReadyBullets =>
      '• Посмотрите короткую видеорекламу\n• Получите 45 минут Pro-доступа\n• Поддержите развитие приложения';

  @override
  String get rewardAdLoadingBullets =>
      '• Видеореклама загружается...\n• Попробуйте ещё раз через минуту';

  @override
  String get watchAd => 'Смотреть рекламу';

  @override
  String get loadingEllipsis => 'Загрузка...';

  @override
  String get loadingVideoAd => 'Загрузка видеорекламы...';

  @override
  String get proAccessGranted45 => 'Pro-доступ выдан на 45 минут!';

  @override
  String get videoAdNotCompleted =>
      'Видеореклама не была досмотрена. Попробуйте ещё раз или перейдите на Pro.';

  @override
  String failedToLoadVideoAd(String error) {
    return 'Не удалось загрузить видеорекламу: $error';
  }

  @override
  String get rewardTimeZeroMinutes => '0 минут';

  @override
  String rewardTimeMinutesSeconds(int minutes, int seconds) {
    return '$minutes мин $seconds с';
  }

  @override
  String rewardTimeSeconds(int seconds) {
    return '$seconds с';
  }

  @override
  String get selectionOptions => 'Параметры выделения';

  @override
  String get clearSelection => 'Очистить выделение';

  @override
  String get invertSelection => 'Инвертировать выделение';

  @override
  String get growSelectionOnePixel => 'Расширить (+1 px)';

  @override
  String get shrinkSelectionOnePixel => 'Сжать (-1 px)';

  @override
  String get rotate90 => 'Повернуть на 90°';

  @override
  String get rotate180 => 'Повернуть на 180°';

  @override
  String get flipHorizontal => 'Отразить по горизонтали';

  @override
  String get flipVertical => 'Отразить по вертикали';

  @override
  String get cutToNewLayer => 'Вырезать на новый слой';

  @override
  String get copyToNewLayer => 'Копировать на новый слой';

  @override
  String get cut => 'Вырезать';

  @override
  String get copy => 'Копировать';

  @override
  String get clearArea => 'Очистить область';

  @override
  String get replaceSelection => 'Заменить выделение';

  @override
  String get addToSelectionShift => 'Добавить к выделению (Shift)';

  @override
  String get subtractFromSelectionAlt => 'Вычесть из выделения (Alt)';

  @override
  String get textureBrush => 'Текстурная кисть';

  @override
  String get triangle => 'Треугольник';

  @override
  String get diamond => 'Ромб';

  @override
  String get hexagon => 'Шестиугольник';

  @override
  String get heart => 'Сердце';

  @override
  String get arrow => 'Стрелка';

  @override
  String get lightning => 'Молния';

  @override
  String get cross => 'Крест';

  @override
  String get spiral => 'Спираль';

  @override
  String get cloudShape => 'Облако';

  @override
  String get rectangleSelect => 'Прямоугольное выделение';

  @override
  String get lasso => 'Лассо';

  @override
  String get magicWand => 'Волшебная палочка';

  @override
  String get effectsPanelAllAppliedMessage =>
      'Все эффекты применены к слою и удалены из списка эффектов';

  @override
  String effectsForLayer(String layerName) {
    return 'Эффекты для $layerName';
  }

  @override
  String get effectsPanelAddEffect => 'Добавить эффект';

  @override
  String get appliedEffects => 'Применённые эффекты';

  @override
  String effectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count эффекта',
      many: '$count эффектов',
      few: '$count эффекта',
      one: '1 эффект',
      zero: '0 эффектов',
    );
    return '$_temp0';
  }

  @override
  String get effectsPreview => 'Предпросмотр эффектов';

  @override
  String get effectPreview => 'Предпросмотр эффекта';

  @override
  String get noEffectsApplied => 'Эффекты не применены';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get finalResult => 'Итоговый результат';

  @override
  String get original => 'Оригинал';

  @override
  String get withEffect => 'С эффектом';

  @override
  String get withEffects => 'С эффектами';

  @override
  String effectsAppliedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count эффекта применено',
      many: '$count эффектов применено',
      few: '$count эффекта применено',
      one: '1 эффект применён',
      zero: '0 эффектов применено',
    );
    return '$_temp0';
  }

  @override
  String get effectsAppliedInOrder => 'Эффекты применяются по порядку';

  @override
  String get effectsReorderHint =>
      'Эффекты применяются сверху вниз. Перетащите, чтобы изменить порядок.';

  @override
  String get addYourFirstEffect => 'Добавьте первый эффект';

  @override
  String get layerEffects => 'Эффекты слоя';

  @override
  String get effectWatercolor => 'Акварель';

  @override
  String get effectHalftone => 'Полутон';

  @override
  String get effectOilPaint => 'Масляная краска';

  @override
  String get effectEmboss => 'Тиснение';

  @override
  String get ok => 'OK';

  @override
  String get staticEffect => 'Статический эффект';

  @override
  String effectNotAnimatedMessage(String effectName) {
    return 'Эффект $effectName не является анимированным. Генерация кадров доступна только для эффектов с поддержкой анимации.';
  }

  @override
  String get generateAnimation => 'Создать анимацию';

  @override
  String generateAnimationForEffect(String effectName) {
    return 'Создать кадры анимации для эффекта $effectName?';
  }

  @override
  String get animationDetails => 'Детали анимации';

  @override
  String animationDetailEffect(String effectName) {
    return '• Эффект: $effectName';
  }

  @override
  String animationDetailEstimatedFrames(int count) {
    return '• Примерно кадров: ~$count';
  }

  @override
  String animationDetailProcessingTime(int seconds) {
    return '• Время обработки: ~$seconds сек.';
  }

  @override
  String get generateAnimationTimelineNote =>
      'Будет создано несколько кадров анимации, которые можно добавить на таймлайн.';

  @override
  String get generateAnimationFrames => 'Создать кадры анимации';

  @override
  String effectNameLabel(String effectName) {
    return 'Эффект $effectName';
  }

  @override
  String framesGeneratedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count кадра создано',
      many: '$count кадров создано',
      few: '$count кадра создано',
      one: '1 кадр создан',
      zero: '0 кадров создано',
    );
    return '$_temp0';
  }

  @override
  String get generateFrames => 'Создать кадры';

  @override
  String get stop => 'Стоп';

  @override
  String get frameLabel => 'Кадр:';

  @override
  String get generatingFrames => 'Создание кадров...';

  @override
  String get noFramesGenerated => 'Кадры не созданы';

  @override
  String get animationSettings => 'Настройки анимации';

  @override
  String get durationSeconds => 'Длительность (секунды)';

  @override
  String get fps => 'FPS';

  @override
  String get totalFrames => 'Всего кадров:';

  @override
  String get pingPongAnimation => 'Пинг-понг анимация';

  @override
  String get playForwardThenBackward => 'Проигрывать вперёд, затем назад';

  @override
  String get frameGeneration => 'Генерация кадров';

  @override
  String get generateNewFrames => 'Создать новые кадры';

  @override
  String get createNewFramesForAnimation =>
      'Создать новые кадры для этой анимации';

  @override
  String get insertIntoTimeline => 'Вставить в таймлайн';

  @override
  String get addFramesToExistingTimeline =>
      'Добавить кадры в существующий таймлайн';

  @override
  String get insertPosition => 'Позиция вставки:';

  @override
  String afterFrame(int frame) {
    return 'После кадра $frame';
  }

  @override
  String get effectParameters => 'Параметры эффекта';

  @override
  String get editParameters => 'Редактировать параметры';

  @override
  String get effectParametersBaseNote =>
      'Текущие настройки эффекта будут использованы как основа анимации';

  @override
  String get editBaseParameters => 'Редактировать базовые параметры';

  @override
  String get applyAndRegenerate => 'Применить и пересоздать';

  @override
  String get animationFrameGenerator => 'Генератор кадров анимации';

  @override
  String get animationGeneratorHelpIntro =>
      'Этот инструмент создаёт несколько кадров анимации, применяя выбранный эффект с разными временными параметрами.\n';

  @override
  String get animationHelpDuration =>
      '• Длительность: общая длина анимации в секундах';

  @override
  String get animationHelpFps =>
      '• FPS: кадров в секунду (выше = плавнее, но больше кадров)';

  @override
  String get animationHelpPingPong =>
      '• Пинг-понг: воспроизводит вперёд, затем назад';

  @override
  String get animationHelpInterpolation =>
      '• Параметры эффекта интерполируются во времени для плавной анимации';

  @override
  String get tips => 'Советы:';

  @override
  String get animationTipLowerFps => '• Для тестов начинайте с меньшего FPS';

  @override
  String get animationTipUsePreview =>
      '• Используйте предпросмотр перед генерацией';

  @override
  String get animationTipLongerDurations =>
      '• Большая длительность лучше подходит для медленных эффектов';

  @override
  String effectFrameName(int index) {
    return 'Кадр эффекта $index';
  }

  @override
  String effectAnimationName(int index) {
    return 'Анимация эффекта $index';
  }

  @override
  String effectAnimationReturnName(int index) {
    return 'Анимация эффекта $index (возврат)';
  }

  @override
  String generatedAnimationFrames(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Создано $count кадра анимации',
      many: 'Создано $count кадров анимации',
      few: 'Создано $count кадра анимации',
      one: 'Создан 1 кадр анимации',
      zero: 'Создано 0 кадров анимации',
    );
    return '$_temp0!';
  }

  @override
  String get viewTimeline => 'Открыть таймлайн';

  @override
  String featureBullet(String feature) {
    return '• $feature';
  }

  @override
  String defaultLayerName(int index) {
    return 'Слой $index';
  }

  @override
  String get select => 'Выбрать';

  @override
  String get menu => 'Меню';

  @override
  String get adjustOpacity => 'Настроить прозрачность';

  @override
  String get adjustLayerOpacity => 'Настроить прозрачность слоя';

  @override
  String get addToTemplate => 'Добавить в шаблон';

  @override
  String get editLayer => 'Редактировать слой';

  @override
  String get layerName => 'Название слоя';

  @override
  String get backgroundShort => 'ФОН';

  @override
  String get reference => 'Референс';

  @override
  String get reset => 'Сброс';

  @override
  String get fit => 'Вписать';

  @override
  String get removeBackgroundImage => 'Удалить фоновое изображение';

  @override
  String get removeBackgroundImageMessage =>
      'Вы уверены, что хотите удалить фоновое изображение?';

  @override
  String get themeSelector => 'Выбор темы';

  @override
  String unlockThemeTitle(String themeName) {
    return 'Разблокировать тему $themeName';
  }

  @override
  String get watchAdToUnlockTheme =>
      'Посмотрите видеорекламу, чтобы разблокировать эту тему.';

  @override
  String themeUnlocked(String themeName) {
    return 'Тема $themeName разблокирована!';
  }

  @override
  String themeShowcaseTitle(String themeName) {
    return 'Тема: $themeName';
  }

  @override
  String get primaryColors => 'Основные цвета';

  @override
  String get primary => 'Основной';

  @override
  String get primaryVariant => 'Вариант основного';

  @override
  String get onPrimary => 'На основном';

  @override
  String get accent => 'Акцент';

  @override
  String get onAccent => 'На акценте';

  @override
  String get backgroundColors => 'Цвета фона';

  @override
  String get background => 'Фон';

  @override
  String get surface => 'Поверхность';

  @override
  String get surfaceVariant => 'Вариант поверхности';

  @override
  String get textColors => 'Цвета текста';

  @override
  String get textPrimary => 'Основной текст';

  @override
  String get textSecondary => 'Вторичный текст';

  @override
  String get textDisabled => 'Отключённый текст';

  @override
  String get utilityColors => 'Служебные цвета';

  @override
  String get error => 'Ошибка';

  @override
  String get success => 'Успех';

  @override
  String get warning => 'Предупреждение';

  @override
  String get uiElements => 'Элементы UI';

  @override
  String get elevated => 'Elevated';

  @override
  String get filled => 'Filled';

  @override
  String get outlined => 'Outlined';

  @override
  String get text => 'Text';

  @override
  String get inputField => 'Поле ввода';

  @override
  String get enterText => 'Введите текст';

  @override
  String previewingTheme(String themeName) {
    return 'Предпросмотр: $themeName';
  }

  @override
  String currentTheme(String themeName) {
    return 'Текущая: $themeName';
  }

  @override
  String get unlockPremiumThemes => 'Разблокируйте премиум-темы';

  @override
  String get getAccessToAllThemesWithPro =>
      'Получите доступ ко всем темам с Pro';

  @override
  String get flagship => 'Флагманские';

  @override
  String get free => 'Бесплатно';

  @override
  String get freeThemes => 'Бесплатные темы';

  @override
  String get premiumThemes => 'Премиум-темы';

  @override
  String get apply => 'Применить';

  @override
  String importedFileAsNewLayer(String fileName) {
    return 'Файл \"$fileName\" импортирован как новый слой';
  }

  @override
  String get importAsepriteFile => 'Импорт файла Aseprite';

  @override
  String howImportAsepriteFile(String fileName) {
    return 'Как импортировать \"$fileName\"?';
  }

  @override
  String importedFirstLayerFromFile(String fileName) {
    return 'Первый слой из \"$fileName\" импортирован';
  }

  @override
  String get importAsLayer => 'Импортировать как слой';

  @override
  String get openAsProject => 'Открыть как проект';

  @override
  String get copyFrame => 'Копировать кадр';

  @override
  String get addFrame => 'Добавить кадр';

  @override
  String get deleteFrame => 'Удалить кадр';

  @override
  String get collapse => 'Свернуть';

  @override
  String get expand => 'Развернуть';

  @override
  String get addState => 'Добавить состояние';

  @override
  String get copyState => 'Копировать состояние';

  @override
  String get addAnimationState => 'Добавить состояние анимации';

  @override
  String get stateName => 'Название состояния';

  @override
  String get columns => 'Столбцы';

  @override
  String get tileModeTooltip =>
      'Режим плитки - предпросмотр бесшовного повтора';

  @override
  String get settingsStylusMode => 'Настройки (режим стилуса)';

  @override
  String get onionSkinTooltip => 'Onion Skin (долгое нажатие для прозрачности)';

  @override
  String get sprayPaintToolDescription => 'Создаёт эффект аэрозоля с частицами';

  @override
  String get lineToolDescription => 'Рисует прямые линии между двумя точками';

  @override
  String get circleToolDescription => 'Рисует идеальные круги и эллипсы';

  @override
  String get rectangleToolDescription => 'Рисует прямоугольники и квадраты';

  @override
  String get triangleToolDescription => 'Рисует треугольники';

  @override
  String get diamondToolDescription => 'Рисует ромбы';

  @override
  String get hexagonToolDescription => 'Рисует шестиугольники';

  @override
  String get heartToolDescription => 'Рисует сердца';

  @override
  String get arrowToolDescription => 'Рисует стрелки';

  @override
  String get lightningToolDescription => 'Рисует молнии';

  @override
  String get crossToolDescription => 'Рисует кресты или плюсы';

  @override
  String get spiralToolDescription => 'Рисует спирали';

  @override
  String get cloudToolDescription => 'Рисует облака';

  @override
  String get penToolDescription =>
      'Продвинутый инструмент свободного рисования';

  @override
  String get rectangleSelectToolDescription => 'Выделяет прямоугольную область';

  @override
  String get ellipseSelectToolDescription => 'Выделяет эллиптическую область';

  @override
  String get lassoToolDescription => 'Свободное выделение';

  @override
  String get magicWandToolDescription => 'Выделяет смежные пиксели по цвету';

  @override
  String get curve => 'Кривая';

  @override
  String get curveToolDescription => 'Рисует плавные кривые линии';

  @override
  String get move => 'Перемещение';

  @override
  String get moveToolDescription => 'Перемещает и перетаскивает элементы';
}
