// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class StringsZh extends Strings {
  StringsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '像素工房';

  @override
  String get aboutTitle => '关于像素工房';

  @override
  String get welcome => '欢迎使用像素工房！';

  @override
  String get aboutAppDescription =>
      '像素工房是您创作像素艺术的理想工具。无论您是经验丰富的艺术家还是初学者，我们的应用都能为您提供所需的工具，帮助您将像素创意变为现实。';

  @override
  String version(String version) {
    return '版本 $version';
  }

  @override
  String get features =>
      '直观的像素编辑工具\n自定义调色板\n图层支持复杂作品\n动画时间轴创建GIF\n多种格式导出\n社区分享功能';

  @override
  String get featuresTitle => '主要功能：';

  @override
  String get visitWebsite => '访问我们的网站了解更多：';

  @override
  String get pickAColor => '选择颜色';

  @override
  String get colorPicker => '颜色选择器';

  @override
  String get gotIt => '知道了';

  @override
  String get undo => '撤销';

  @override
  String get redo => '重做';

  @override
  String get clear => '清除';

  @override
  String get save => '保存';

  @override
  String get saveAs => '另存为';

  @override
  String get open => '打开';

  @override
  String get export => '导出';

  @override
  String get import => '导入';

  @override
  String get share => '分享';

  @override
  String get close => '关闭';

  @override
  String get projects => '项目';

  @override
  String get lineTool => '直线';

  @override
  String get rectangleTool => '矩形';

  @override
  String get circleTool => '圆形';

  @override
  String get about => '关于';

  @override
  String get invalidFileContent => '文件内容无效';

  @override
  String get anErrorOccurred => '发生错误';

  @override
  String get tryAgain => '重试';

  @override
  String get creatingProject => '正在创建项目...';

  @override
  String get openingProject => '正在打开项目...';

  @override
  String get noProjectsFound => '未找到项目';

  @override
  String get createNewProject => '创建新项目';

  @override
  String get rename => '重命名';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get cancel => '取消';

  @override
  String get deleteProject => '删除项目';

  @override
  String get areYouSureWantToDeleteProject => '确定要删除此项目吗？';

  @override
  String get renameProject => '重命名项目';

  @override
  String get projectName => '项目名称';

  @override
  String timeAgo(String time) {
    return '$time前';
  }

  @override
  String get justNow => '刚刚';

  @override
  String frameCount(int current, int total) {
    return '帧 $current/$total';
  }

  @override
  String get playbackSpeed => '速度：';

  @override
  String duration(int ms) {
    return '时长: ${ms}ms';
  }

  @override
  String get animationPreview => '动画预览';

  @override
  String get colorPalette => '调色板';

  @override
  String get currentColor => '当前颜色';

  @override
  String get add => '添加';

  @override
  String get layers => '图层';

  @override
  String get deleteLayer => '删除图层';

  @override
  String get areYouSureWantToDeleteLayer => '确定要删除此图层吗？';

  @override
  String get newProject => '新建项目';

  @override
  String get template => '模板';

  @override
  String get width => '宽度';

  @override
  String get height => '高度';

  @override
  String get create => '创建';

  @override
  String get subscriptions => '订阅';

  @override
  String get fileMenu => '文件';

  @override
  String get profile => '个人资料';

  @override
  String get logout => '登出';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get signInToContinue => '登录以继续';

  @override
  String get signInToSyncProjects => '登录以同步您的项目。';

  @override
  String get signingIn => '登录中...';

  @override
  String get continueWithApple => '使用 Apple 登录';

  @override
  String get signInWithGoogle => '使用 Google 登录';

  @override
  String get skipForNow => '暂时跳过';

  @override
  String get noEmail => '无电子邮件';

  @override
  String get feedback_title => '反馈';

  @override
  String get feedback_thank_you => '感谢您的反馈！';

  @override
  String get feedback_thank_you_message => '您的意见对我们非常重要，将帮助我们改进应用。';

  @override
  String get feedback_return => '返回';

  @override
  String get feedback_help_us => '帮助我们做得更好';

  @override
  String get feedback_intro => '您的意见对项目发展非常重要。请回答几个问题。';

  @override
  String feedback_answered(int count, int total) {
    return '已回答：$count/$total';
  }

  @override
  String get feedback_required => '必填';

  @override
  String get feedback_sending => '发送中...';

  @override
  String get feedback_send => '发送';

  @override
  String get feedback_validation_error => '请回答所有必填问题';

  @override
  String get feedback_very_poor => '非常差';

  @override
  String get feedback_excellent => '优秀';

  @override
  String get feedback_yes => '是';

  @override
  String get feedback_no => '否';

  @override
  String get feedback_text_placeholder => '输入您的答案...';

  @override
  String get feedback_q_satisfaction => '您对应用的满意度如何？';

  @override
  String get feedback_q_missing_features => '您觉得缺少哪些功能？';

  @override
  String get feedback_q_missing_features_placeholder => '描述您希望看到的功能...';

  @override
  String get feedback_q_bug_reports => '您是否遇到过任何错误或崩溃？';

  @override
  String get feedback_q_bug_reports_placeholder => '描述您遇到的问题...';

  @override
  String get feedback_q_price_satisfaction => '您对目前的应用价格满意吗？';

  @override
  String get feedback_q_price_feedback => '如果不满意，您认为合理的价格是多少？';

  @override
  String get feedback_q_price_free => '免费';

  @override
  String get feedback_q_price_up_to_5 => '最多\$5';

  @override
  String get feedback_q_price_5_to_10 => '\$5 - \$10';

  @override
  String get feedback_q_price_10_to_20 => '\$10 - \$20';

  @override
  String get feedback_q_price_more_20 => '超过\$20';

  @override
  String get feedback_q_patreon_support => '您会在Patreon上支持该项目吗？';

  @override
  String get feedback_q_patreon_definitely => '是的，一定会';

  @override
  String get feedback_q_patreon_if_exclusive => '可能，如果有独家功能';

  @override
  String get feedback_q_patreon_if_reasonable => '可能，如果价格合理';

  @override
  String get feedback_q_patreon_probably_not => '可能不会';

  @override
  String get feedback_q_patreon_no => '不，不打算';

  @override
  String get feedback_q_patreon_tier => '您对Patreon的哪个支持级别感兴趣？';

  @override
  String get feedback_q_patreon_tier_3 => '\$3/月 - 提前使用功能';

  @override
  String get feedback_q_patreon_tier_5 => '\$5/月 - + 独家主题';

  @override
  String get feedback_q_patreon_tier_10 => '\$10/月 - + 影响开发';

  @override
  String get feedback_q_usage_frequency => '您多久使用一次应用？';

  @override
  String get feedback_q_usage_daily => '每天';

  @override
  String get feedback_q_usage_several_week => '每周几次';

  @override
  String get feedback_q_usage_once_week => '每周一次';

  @override
  String get feedback_q_usage_several_month => '每月几次';

  @override
  String get feedback_q_usage_rarely => '很少';

  @override
  String get feedback_q_main_use_case => '您主要用应用做什么？';

  @override
  String get feedback_q_use_pixel_art => '创作像素艺术';

  @override
  String get feedback_q_use_game_design => '游戏设计';

  @override
  String get feedback_q_use_animation => '动画';

  @override
  String get feedback_q_use_hobby => '爱好/娱乐';

  @override
  String get feedback_q_use_professional => '专业工作';

  @override
  String get feedback_q_use_learning => '学习';

  @override
  String get feedback_q_additional_feedback => '其他评论和建议';

  @override
  String get feedback_q_additional_feedback_placeholder => '分享您对应用的看法...';

  @override
  String get feedback_q_recommend => '您会向朋友推荐这个应用吗？';

  @override
  String get firstFrame => '第一帧';

  @override
  String get previousFrame => '上一帧';

  @override
  String get pause => '暂停';

  @override
  String get play => '播放';

  @override
  String get nextFrame => '下一帧';

  @override
  String get lastFrame => '最后一帧';

  @override
  String get feedback_dialog_title => '我们期待您的反馈！';

  @override
  String get feedback_dialog_description => '您的意见很重要！分享您的想法，帮助我们把应用做得更好。';

  @override
  String get feedback_dialog_benefit_1 => '分享新功能创意';

  @override
  String get feedback_dialog_benefit_2 => '反馈错误和问题';

  @override
  String get feedback_dialog_benefit_3 => '帮助塑造应用未来';

  @override
  String get feedback_dialog_leave_feedback => '提交反馈';

  @override
  String get feedback_dialog_maybe_later => '稍后再说';

  @override
  String get feedback_dialog_dont_ask => '不再询问';

  @override
  String get paletteBasic => '基本';

  @override
  String get paletteShades => '阴影';

  @override
  String get paletteComplementary => '互补色';

  @override
  String get paletteAnalogous => '邻近色';

  @override
  String get paletteTriadic => '三角色';

  @override
  String get paletteMonochromatic => '单色';

  @override
  String get paletteCustom => '自定义';

  @override
  String get paletteImported => '已导入';

  @override
  String get paletteImportedCount => '种颜色';

  @override
  String get addToCustomPalette => '添加到自定义色板';

  @override
  String get noCustomColors => '尚未添加自定义颜色。\n使用上方的 + 按钮添加颜色。';

  @override
  String get effects => '特效';

  @override
  String get editorSettings => '编辑器设置';

  @override
  String get resetToDefaults => '重置为默认值';

  @override
  String get input => '输入';

  @override
  String get display => '显示';

  @override
  String get showGrid => '显示网格';

  @override
  String get showGridSubtitle => '在画布上显示网格线';

  @override
  String get pixelGridOverlay => '像素网格叠加';

  @override
  String get pixelGridSubtitle => '放大时显示像素边界';

  @override
  String get gridOpacity => '网格不透明度';

  @override
  String get selectionTransforms => '选区变换';

  @override
  String get transformInterpolation => '插值';

  @override
  String get transformInterpolationSubtitle => '用于选区缩放和旋转';

  @override
  String get nearestNeighbor => '最近邻';

  @override
  String get bilinear => '双线性';

  @override
  String get zoomNavigation => '缩放和导航';

  @override
  String get zoomSensitivity => '缩放灵敏度';

  @override
  String get zoomSensitivitySubtitle => '捏合缩放的响应速度';

  @override
  String get minZoom => '最小缩放';

  @override
  String get maxZoom => '最大缩放';

  @override
  String get gestures => '手势';

  @override
  String get twoFingerUndo => '双指点击撤销';

  @override
  String get twoFingerUndoSubtitle => '双指快速点击以撤销';

  @override
  String get done => '完成';

  @override
  String get stylusMode => '手写笔模式';

  @override
  String get stylusModeSubtitleOn => '仅使用手写笔绘图 • 触控用于导航';

  @override
  String get stylusModeSubtitleOff => '同时使用触控和手写笔绘图';

  @override
  String get importImage => '导入图像';

  @override
  String get selectImportOption => '选择您想要导入图像的方式：';

  @override
  String get convertToPixelArt => '转换为像素艺术';

  @override
  String get convertToPixelArtDescription => '导入并在新图层上自动将图像转换为像素艺术风格。';

  @override
  String get importAsBackground => '作为背景导入';

  @override
  String get importAsBackgroundDescription => '原样导入图像并将其用作参考背景图层。';

  @override
  String get conversionSettings => '转换设置';

  @override
  String get paletteColors => '调色板颜色';

  @override
  String get fullColor => '全彩';

  @override
  String get dithering => '抖动';

  @override
  String get noDithering => '无';

  @override
  String get alphaThreshold => '透明度阈值';

  @override
  String get chooseImage => '选择图像';

  @override
  String get tinyIcon => '小图标';

  @override
  String get smallSprite => '小精灵';

  @override
  String get mediumCharacter => '中型角色';

  @override
  String get largeScene => '大型场景';

  @override
  String get projectNameRequired => '请输入项目名称';

  @override
  String get templateRequired => '请选择一个模板';

  @override
  String planLimitError(int limit) {
    return '您的计划仅限于 $limit 像素';
  }

  @override
  String get widthRequired => '请输入宽度';

  @override
  String get heightRequired => '请输入高度';

  @override
  String widthRangeError(int max) {
    return '宽度：1-$max';
  }

  @override
  String heightRangeError(int max) {
    return '高度：1-$max';
  }

  @override
  String get saveImage => '保存图像';

  @override
  String get png => 'PNG';

  @override
  String get animatedGif => '动态 GIF';

  @override
  String get proPlanRequired => '需要 Pro 计划';

  @override
  String get spriteSheet => '精灵表';

  @override
  String get transparentBackground => '透明背景';

  @override
  String get transparent => '透明';

  @override
  String get spriteSheetOptions => '精灵表选项';

  @override
  String get columnsLabel => '列数';

  @override
  String get spacingPx => '间距 (px)';

  @override
  String get exportSize => '导出尺寸';

  @override
  String scaleWithValues(String scale) {
    return '缩放: ${scale}x';
  }

  @override
  String get format => '格式';

  @override
  String get options => '选项';

  @override
  String editEffect(String name) {
    return '编辑效果 $name';
  }

  @override
  String get applyChanges => '应用更改';

  @override
  String get preview => '预览';

  @override
  String get quickPresets => '快速预设';

  @override
  String get parameters => '参数';

  @override
  String get previewNotAvailable => '预览不可用';

  @override
  String get tapToChange => '点击更改';

  @override
  String get enable => '启用';

  @override
  String get uiFieldTap => '点击';

  @override
  String get uiFieldEnabled => '已启用';

  @override
  String get uiFieldDisabled => '已禁用';

  @override
  String get presetDarker => '更暗';

  @override
  String get presetNormal => '正常';

  @override
  String get presetBrighter => '更亮';

  @override
  String get presetVeryBright => '非常亮';

  @override
  String get presetLow => '低';

  @override
  String get presetHigh => '高';

  @override
  String get presetVeryHigh => '非常高';

  @override
  String get presetSubtle => '细微';

  @override
  String get presetSoft => '柔和';

  @override
  String get presetMedium => '中等';

  @override
  String get presetStrong => '强烈';

  @override
  String get effectBrightness => '亮度';

  @override
  String get effectContrast => '对比度';

  @override
  String get effectBlur => '模糊';

  @override
  String get effectVignette => '渐晕';

  @override
  String get effectInvert => '反相';

  @override
  String get effectGrayscale => '灰度';

  @override
  String get effectSepia => '怀旧';

  @override
  String get effectThreshold => '阈值';

  @override
  String get effectPixelate => '像素化';

  @override
  String get effectSharpen => '锐化';

  @override
  String get effectNoise => '噪点';

  @override
  String get effectGlow => '发光';

  @override
  String get effectGlitch => '故障';

  @override
  String get effectSparkle => '闪烁';

  @override
  String get effectFire => '火焰';

  @override
  String get effectRain => '下雨';

  @override
  String get selectEffect => '选择效果';

  @override
  String get searchEffects => '搜索效果...';

  @override
  String get categoryAll => '全部';

  @override
  String get categoryColorTone => '颜色和色调';

  @override
  String get categoryBlurSharpen => '模糊和锐化';

  @override
  String get categoryArtistic => '艺术';

  @override
  String get categoryAnimation => '动画';

  @override
  String get categoryNature => '自然';

  @override
  String get categoryParticles => '粒子';

  @override
  String get categoryDistortion => '失真';

  @override
  String get categoryTextures => '纹理';

  @override
  String get categorySpecialFx => '特殊效果';

  @override
  String get noEffectsMatch => '没有符合搜索条件的效果';

  @override
  String get premiumEffect => '高级效果';

  @override
  String get proVersionStatus => '此效果在Pro版本中可用。';

  @override
  String get proFeaturesInclude => 'Pro版本功能包括:';

  @override
  String get featureAdvancedEffects => '高级效果和工具';

  @override
  String get featureUnlimitedProjects => '无限项目';

  @override
  String get featureCloudBackup => '云备份';

  @override
  String get featurePrioritySupport => '优先支持';

  @override
  String get maybeLater => '稍后再说';

  @override
  String get upgradeToPro => '升级到 Pro';

  @override
  String get effectsPanelRemoveEffectTitle => '移除效果';

  @override
  String effectsPanelRemoveEffectMessage(String effectName) {
    return '确定要移除$effectName效果吗？';
  }

  @override
  String get effectsPanelClearAllEffectsTitle => '清除所有效果';

  @override
  String get effectsPanelClearAllEffectsMessage => '确定要从该图层移除所有效果吗？';

  @override
  String get effectsPanelClearAll => '全部清除';

  @override
  String effectsPanelAppliedToLayerMessage(String effectName) {
    return '效果$effectName已应用到图层';
  }

  @override
  String get effectsPanelActionApply => '应用';

  @override
  String get effectsPanelActionRemove => '移除';

  @override
  String get effectsPanelActionMore => '更多';

  @override
  String get effectsPanelMoreActionsTitle => '更多操作';

  @override
  String get effectsPanelApplyAll => '全部应用';

  @override
  String get ellipseSelection => '椭圆选区';

  @override
  String get ellipseSelectionTooltip => '选择椭圆区域';

  @override
  String get autoSelectLayer => '自动选择';

  @override
  String get autoSelectLayerTooltip => '选择当前图层中所有非空像素';

  @override
  String get selectionAnchor => '选区锚点';
}
