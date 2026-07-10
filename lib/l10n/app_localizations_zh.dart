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
  String get category => '类别';

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
  String get proFeaturesInclude => 'Pro 功能包括：';

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

  @override
  String get feedback => '反馈';

  @override
  String get createNewProjectTooltip => '创建新项目';

  @override
  String failedToProcessFile(String fileName) {
    return '无法处理 $fileName';
  }

  @override
  String importingFile(String fileName) {
    return '正在导入 $fileName...';
  }

  @override
  String importedProjectSuccessfully(String projectName) {
    return '已成功导入“$projectName”';
  }

  @override
  String failedToImport(String error) {
    return '导入失败：$error';
  }

  @override
  String unsupportedFileType(String fileName) {
    return '不支持的文件类型：$fileName';
  }

  @override
  String get pleaseSignInToUploadProjects => '请登录以上传项目';

  @override
  String get pleaseSignInToUpdateProjects => '请登录以更新项目';

  @override
  String get projectNotSyncedToCloud => '项目尚未同步到云端';

  @override
  String get pleaseSignInToRemoveCloudProjects => '请登录以移除云端项目';

  @override
  String get removingFromCloud => '正在从云端移除...';

  @override
  String get projectRemovedFromCloudSuccessfully => '项目已成功从云端移除';

  @override
  String failedToRemoveFromCloud(String error) {
    return '从云端移除失败：$error';
  }

  @override
  String get search => '搜索...';

  @override
  String get myProjects => '我的项目';

  @override
  String get noProjectsYet => '还没有项目';

  @override
  String get createOne => '创建一个';

  @override
  String get searchProjects => '搜索项目...';

  @override
  String get discoverAmazingPixelArt => '发现精彩像素艺术';

  @override
  String get sortBy => '排序方式';

  @override
  String get mostRecent => '最新';

  @override
  String get mostPopular => '最受欢迎';

  @override
  String get mostViewed => '浏览最多';

  @override
  String get mostLiked => '点赞最多';

  @override
  String get titleAZ => '标题 A-Z';

  @override
  String get all => '全部';

  @override
  String get featuredProjects => '精选项目';

  @override
  String get errorLoadingProjects => '加载项目出错';

  @override
  String get deletingProject => '正在删除项目...';

  @override
  String get projectDeletedSuccessfully => '项目已删除';

  @override
  String get failedToDeleteProject => '删除项目失败';

  @override
  String failedToDeleteProjectWithError(String error) {
    return '删除项目失败：$error';
  }

  @override
  String get unlike => '取消点赞';

  @override
  String get like => '点赞';

  @override
  String get editProject => '编辑项目';

  @override
  String get public => '公开';

  @override
  String get private => '私密';

  @override
  String get analytics => '分析';

  @override
  String get stats => '统计';

  @override
  String likeCountLabel(String count) {
    return '$count 个赞';
  }

  @override
  String commentCountLabel(String count) {
    return '$count 条评论';
  }

  @override
  String get download => '下载';

  @override
  String get openProject => '打开项目';

  @override
  String get downloadProject => '下载项目';

  @override
  String get localProjectNotFound => '未找到本地项目';

  @override
  String get comments => '评论';

  @override
  String get addComment => '添加评论';

  @override
  String get noCommentsYet => '还没有评论';

  @override
  String get beFirstToComment => '来发表第一条评论吧！';

  @override
  String get failedToLoadComments => '加载评论失败';

  @override
  String get edited => '已编辑';

  @override
  String get makeProjectPublic => '设为公开项目';

  @override
  String get makeProjectPrivate => '设为私密项目';

  @override
  String get makeProjectPublicMessage => '你的项目将对社区所有人可见。其他人可以查看、点赞和评论。';

  @override
  String get makeProjectPrivateMessage => '你的项目将从公开社区隐藏。只有你可以看到它。';

  @override
  String get projectWillBePublic => '项目将公开可见';

  @override
  String get projectWillBePrivate => '项目将设为私密';

  @override
  String get projectIsNowPublic => '项目现在是公开的';

  @override
  String get projectIsNowPrivate => '项目现在是私密的';

  @override
  String failedToUpdateVisibility(String error) {
    return '更新可见性失败：$error';
  }

  @override
  String get makePublic => '设为公开';

  @override
  String get makePrivate => '设为私密';

  @override
  String get deleteProjectCannotBeUndone => '确定要删除此项目吗？此操作无法撤销。';

  @override
  String get thisWillPermanentlyDelete => '这将永久删除：';

  @override
  String get deleteProjectConsequences => '• 项目数据和作品\n• 所有评论和点赞\n• 下载统计';

  @override
  String typeProjectTitleToConfirmDeletion(String title) {
    return '输入“$title”以确认删除：';
  }

  @override
  String get enterProjectTitle => '输入项目标题...';

  @override
  String get deleteForever => '永久删除';

  @override
  String get openingProjectEditor => '正在打开项目编辑器...';

  @override
  String get projectLinkCopied => '项目链接已复制！';

  @override
  String get addedToFavorites => '已加入收藏！';

  @override
  String nowFollowingUser(String username) {
    return '已关注 $username！';
  }

  @override
  String get reportProject => '举报项目';

  @override
  String get reportProjectMessage => '确定要举报此项目吗？请只举报违反社区准则的内容。';

  @override
  String get reportThanks => '感谢你的举报。我们会尽快审核。';

  @override
  String get report => '举报';

  @override
  String get premiumRequiredToDownloadProjects => '下载项目需要 Premium 订阅';

  @override
  String get upgrade => '升级';

  @override
  String get downloadProjectRewardSubtitle => '要下载此项目，你可以：';

  @override
  String get thankYouWatchingDownloadStarting => '感谢观看！下载即将开始...';

  @override
  String get pleaseSignInToAddComments => '请登录以添加评论';

  @override
  String get writeYourComment => '写下你的评论...';

  @override
  String get commentAddedSuccessfully => '评论已添加！';

  @override
  String failedToAddComment(String error) {
    return '添加评论失败：$error';
  }

  @override
  String get post => '发布';

  @override
  String get chooseTheme => '选择主题';

  @override
  String get importFile => '导入文件';

  @override
  String get theme => '主题';

  @override
  String get getPro => '获取 Pro';

  @override
  String get supportOnKofi => '在 Ko-fi 支持';

  @override
  String get copyLink => '复制链接';

  @override
  String get size => '尺寸';

  @override
  String get views => '浏览';

  @override
  String get downloads => '下载';

  @override
  String get published => '已发布！';

  @override
  String get forkedFrom => '派生自 ';

  @override
  String byUser(String username) {
    return ' 作者 $username';
  }

  @override
  String get projectAnalytics => '项目分析';

  @override
  String get totalViews => '总浏览量';

  @override
  String get totalLikes => '总点赞数';

  @override
  String get detailedAnalytics => '详细分析';

  @override
  String get advancedAnalyticsSoon => '高级分析功能即将推出。';

  @override
  String get details => '详情';

  @override
  String get title => '标题';

  @override
  String get projectTitleHint => '给你的项目起个名字';

  @override
  String get description => '描述';

  @override
  String get projectDescriptionHint => '向社区介绍这个项目（可选）';

  @override
  String get visibility => '可见性';

  @override
  String get tags => '标签';

  @override
  String get searchTags => '搜索标签…';

  @override
  String get failedToLoadTags => '加载标签失败';

  @override
  String get pleaseEnterTitle => '请输入标题';

  @override
  String get removeFromCloudQuestion => '从云端移除？';

  @override
  String get removeFromCommunityMessage => '这会将项目从社区移除。你的本地副本会保留。';

  @override
  String get remove => '移除';

  @override
  String get updateProject => '更新项目';

  @override
  String get publishToCommunity => '发布到社区';

  @override
  String get synced => '已同步';

  @override
  String get visibleToEveryone => '所有人可见';

  @override
  String get onlyVisibleToYou => '仅你可见';

  @override
  String get maximumTagsAllowed => '最多允许 5 个标签';

  @override
  String frameCountSimple(int count) {
    return '$count 帧';
  }

  @override
  String layerCountSimple(int count) {
    return '$count 图层';
  }

  @override
  String get cloudManagement => '云端管理';

  @override
  String cloudId(String id) {
    return 'Cloud ID: $id';
  }

  @override
  String get preparingUpdate => '正在准备更新…';

  @override
  String get preparingProject => '正在准备项目…';

  @override
  String get generatingThumbnail => '正在生成缩略图…';

  @override
  String get updatingOnCloud => '正在更新云端…';

  @override
  String get uploadingToCloud => '正在上传到云端…';

  @override
  String get finalizing => '正在完成…';

  @override
  String get updated => '已更新！';

  @override
  String get updating => '正在更新…';

  @override
  String get publishing => '正在发布…';

  @override
  String get update => '更新';

  @override
  String get publish => '发布';

  @override
  String get downloadingProject => '正在下载项目';

  @override
  String get downloadingProjectData => '正在下载项目数据...';

  @override
  String get downloadComplete => '下载完成！';

  @override
  String get projectSavedLocal => '项目已保存到本地项目';

  @override
  String get downloadFailed => '下载失败';

  @override
  String get resyncWithCloud => '重新同步云端';

  @override
  String get syncToCloud => '同步到云端';

  @override
  String get removeFromCloud => '从云端移除';

  @override
  String get removeFromCloudMessage => '这会将项目从云端移除并变为仅本地项目。本地副本不会更改。确定吗？';

  @override
  String get syncedCloudDeleteWarning => '此项目已同步到云端。仅删除本地副本不会影响云端版本。';

  @override
  String get openLocalProject => '打开本地项目';

  @override
  String get premiumRequired => '需要 Premium';

  @override
  String byUserInline(String username) {
    return '作者 $username';
  }

  @override
  String get createTemplate => '创建模板';

  @override
  String layerNameLabel(String name) {
    return '名称：$name';
  }

  @override
  String layerSizeLabel(int width, int height) {
    return '尺寸：$width×$height';
  }

  @override
  String nonTransparentPixels(int count) {
    return '像素：$count 个非透明';
  }

  @override
  String get templateName => '模板名称';

  @override
  String get descriptionOptional => '描述（可选）';

  @override
  String get saveOptions => '保存选项';

  @override
  String get saveLocally => '保存到本地';

  @override
  String get storeOnDeviceOnly => '仅存储在此设备';

  @override
  String get uploadToCloud => '上传到云端';

  @override
  String get shareWithCommunity => '与社区分享';

  @override
  String get privateCloudStorage => '私密云端存储';

  @override
  String get otherUsersCanDiscoverTemplate => '其他用户可以发现并使用此模板';

  @override
  String get onlyYouCanAccessTemplate => '只有你可以访问此模板';

  @override
  String get saveLocallyAndUpload => '保存到本地并上传';

  @override
  String get bestOfBothWorlds => '两全其美';

  @override
  String get signInToUploadTemplates => '登录以上传模板';

  @override
  String get shareTemplatesWithCommunity => '与社区分享你的模板';

  @override
  String get failedToConvertLayerToTemplate => '无法将图层转换为模板';

  @override
  String get failedToSaveTemplateLocally => '本地保存模板失败';

  @override
  String get failedToUploadTemplateToServer => '上传模板到服务器失败';

  @override
  String errorCreatingTemplate(String error) {
    return '创建模板出错：$error';
  }

  @override
  String get templateSavedLocally => '模板已保存到本地！';

  @override
  String get templateUploadedSuccessfully => '模板上传成功！';

  @override
  String get templateSavedAndUploaded => '模板已保存到本地并上传！';

  @override
  String get templateSavedUploadFailed => '模板已保存到本地（上传失败）';

  @override
  String get templateUploadedLocalSaveFailed => '模板已上传（本地保存失败）';

  @override
  String get templateCreationFailed => '模板创建失败';

  @override
  String get templateGallery => '模板库';

  @override
  String get allTemplates => '全部模板';

  @override
  String get local => '本地';

  @override
  String get community => '社区';

  @override
  String get failedTemplateDetailsCached => '加载模板详情失败。正在使用缓存数据。';

  @override
  String errorLoadingTemplate(String error) {
    return '加载模板出错：$error';
  }

  @override
  String get loadingTemplate => '正在加载模板...';

  @override
  String get deleteTemplate => '删除模板';

  @override
  String deleteTemplateQuestion(String name) {
    return '确定要删除“$name”吗？';
  }

  @override
  String get deleteLocalTemplateWarning => '此模板将从本地存储中永久移除。';

  @override
  String get deleteCloudTemplateWarning => '此模板将从云端移除且无法恢复。';

  @override
  String templateDeletedSuccessfully(String name) {
    return '模板“$name”已删除';
  }

  @override
  String failedToDeleteTemplate(String name) {
    return '删除模板“$name”失败';
  }

  @override
  String get searchTemplates => '搜索模板...';

  @override
  String get loadingTemplates => '正在加载模板...';

  @override
  String get premiumTemplate => 'Premium 模板';

  @override
  String get templateAvailableInPro => '此模板在 Pro 版本中可用。';

  @override
  String get premiumTemplatesFeature => '• Premium 模板';

  @override
  String get advancedEffectsToolsFeature => '• 高级效果和工具';

  @override
  String get unlimitedProjectsFeature => '• 无限项目';

  @override
  String get cloudBackupFeature => '• 云端备份';

  @override
  String get prioritySupportFeature => '• 优先支持';

  @override
  String get noLocalTemplates => '未找到本地模板。\n从图层创建你的第一个模板吧！';

  @override
  String get noCommunityTemplates => '未找到社区模板。\n请尝试调整搜索或筛选条件。';

  @override
  String get noUploadedTemplates => '你还没有上传任何模板。\n与社区分享你的创作吧！';

  @override
  String get noTemplatesFoundAdjust => '未找到模板。\n请尝试调整搜索或筛选条件。';

  @override
  String showingTemplates(int displayed, String total) {
    String _temp0 = intl.Intl.selectLogic(
      total,
      {
        'none': '',
        'other': ' / $total',
      },
    );
    return '显示 $displayed$_temp0 个模板';
  }

  @override
  String get clickTemplateToApply => '点击模板以应用';

  @override
  String get pro => 'PRO';

  @override
  String get pleaseEnterTemplateName => '请输入模板名称';

  @override
  String get signInToUploadTemplatesTitle => '登录以上传模板';

  @override
  String get signInToUploadTemplatesSubtitle => '创建账号，与社区分享你的模板。';

  @override
  String get myTemplates => '我的模板';

  @override
  String get cloud => '云端';

  @override
  String get tapToUnlock => '点击解锁';

  @override
  String get layerTemplateDefaultName => '图层模板';

  @override
  String get undoHistoryTitle => '历史记录';

  @override
  String undoHistoryStepCount(int total) {
    return '（$total步）';
  }

  @override
  String get undoHistoryRevertAll => '全部还原';

  @override
  String get undoHistoryCurrentState => '当前状态';

  @override
  String undoHistoryFrameLayer(int frame, int layer) {
    return '帧 $frame，图层 $layer';
  }

  @override
  String get keyboardShortcuts => '键盘快捷键';

  @override
  String get copySelection => '复制选区';

  @override
  String get cutSelection => '剪切选区';

  @override
  String get paste => '粘贴';

  @override
  String get duplicateLayer => '复制图层';

  @override
  String get selection => '选择';

  @override
  String get selectAll => '全选';

  @override
  String get deselect => '取消选择';

  @override
  String get closePenPath => '闭合钢笔路径';

  @override
  String get tools => '工具';

  @override
  String get pencil => '铅笔';

  @override
  String get eraser => '橡皮擦';

  @override
  String get eyedropper => '吸管';

  @override
  String get fill => '填充';

  @override
  String get selectMarquee => '选择 / 选框';

  @override
  String get moveDrag => '移动 / 拖拽';

  @override
  String get pen => '钢笔';

  @override
  String get sprayPaint => '喷漆';

  @override
  String get panHold => '平移（按住）';

  @override
  String get eyedropperHold => '吸管（按住）';

  @override
  String get brush => '画笔';

  @override
  String get increaseSize => '增大尺寸';

  @override
  String get decreaseSize => '减小尺寸';

  @override
  String get colors => '颜色';

  @override
  String get swapColors => '交换颜色';

  @override
  String get defaultColors => '默认颜色';

  @override
  String get view => '视图';

  @override
  String get zoomIn => '放大';

  @override
  String get zoomOut => '缩小';

  @override
  String get zoomToFit => '适应窗口';

  @override
  String get zoomOneToOne => '1:1 缩放';

  @override
  String get toggleUi => '切换界面';

  @override
  String get selectLayerOneToNine => '选择图层 1-9';

  @override
  String get newLayer => '新建图层';

  @override
  String get deleteAccountCannotBeUndone => '此操作无法撤销';

  @override
  String get deleteAccountPermanentDataWarning => '删除账号会永久移除你的所有数据。';

  @override
  String get deleteAccountItemsIntro => '以下内容将被永久删除：';

  @override
  String get deleteAccountPreferencesTitle => '应用偏好设置';

  @override
  String get deleteAccountPreferencesSubtitle => '设置和自定义内容';

  @override
  String get deleteAccountInfoTitle => '账号信息';

  @override
  String get deleteAccountInfoSubtitle => '个人资料和认证数据';

  @override
  String get deleteAccountTypeConfirm => '输入“DELETE”以确认：';

  @override
  String get deleteAccountTypeHint => '在此输入 DELETE...';

  @override
  String get deleteAccountIrreversibleImmediate => '此操作不可逆，并会立即生效。';

  @override
  String get deleteAccountQuickConfirm => '确定要永久删除你的账号吗？';

  @override
  String get deleteAccountQuickWarningList =>
      '• 你的所有项目都会丢失\n• 云备份将被删除\n• 此操作无法撤销';

  @override
  String failedToDeleteAccount(String error) {
    return '删除账号失败：$error';
  }

  @override
  String get proAccessActive => 'Pro 权限已启用';

  @override
  String proAccessRemaining(String time) {
    return '你的 Pro 权限还剩 $time。';
  }

  @override
  String get buyPro => '购买 Pro';

  @override
  String get rewardUpgradeBullets => '• 无限使用所有功能\n• 一次性购买\n• 无广告\n• 优先支持';

  @override
  String get tryPro45Minutes => '试用 Pro 45 分钟';

  @override
  String get rewardAdReadyBullets => '• 观看一段短视频广告\n• 获得 45 分钟 Pro 权限\n• 支持应用开发';

  @override
  String get rewardAdLoadingBullets => '• 视频广告正在加载...\n• 请稍后再试';

  @override
  String get watchAd => '观看广告';

  @override
  String get loadingEllipsis => '加载中...';

  @override
  String get loadingVideoAd => '正在加载视频广告...';

  @override
  String get proAccessGranted45 => '已授予 45 分钟 Pro 权限！';

  @override
  String get videoAdNotCompleted => '视频广告未播放完成。请重试或升级到 Pro。';

  @override
  String failedToLoadVideoAd(String error) {
    return '加载视频广告失败：$error';
  }

  @override
  String get rewardTimeZeroMinutes => '0 分钟';

  @override
  String rewardTimeMinutesSeconds(int minutes, int seconds) {
    return '$minutes 分 $seconds 秒';
  }

  @override
  String rewardTimeSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get selectionOptions => '选择选项';

  @override
  String get clearSelection => '清除选择';

  @override
  String get invertSelection => '反选';

  @override
  String get growSelectionOnePixel => '扩大（+1px）';

  @override
  String get shrinkSelectionOnePixel => '缩小（-1px）';

  @override
  String get rotate90 => '旋转 90°';

  @override
  String get rotate180 => '旋转 180°';

  @override
  String get flipHorizontal => '水平翻转';

  @override
  String get flipVertical => '垂直翻转';

  @override
  String get cutToNewLayer => '剪切到新图层';

  @override
  String get copyToNewLayer => '复制到新图层';

  @override
  String get cut => '剪切';

  @override
  String get copy => '复制';

  @override
  String get clearArea => '清除区域';

  @override
  String get replaceSelection => '替换选择';

  @override
  String get addToSelectionShift => '添加到选择（Shift）';

  @override
  String get subtractFromSelectionAlt => '从选择中减去（Alt）';

  @override
  String get textureBrush => '纹理画笔';

  @override
  String get triangle => '三角形';

  @override
  String get diamond => '菱形';

  @override
  String get hexagon => '六边形';

  @override
  String get heart => '心形';

  @override
  String get arrow => '箭头';

  @override
  String get lightning => '闪电';

  @override
  String get cross => '十字';

  @override
  String get spiral => '螺旋';

  @override
  String get cloudShape => '云朵';

  @override
  String get rectangleSelect => '矩形选择';

  @override
  String get lasso => '套索';

  @override
  String get magicWand => '魔棒';

  @override
  String get effectsPanelAllAppliedMessage => '所有效果已应用到图层，并从效果列表中移除';

  @override
  String effectsForLayer(String layerName) {
    return '$layerName 的效果';
  }

  @override
  String get effectsPanelAddEffect => '添加效果';

  @override
  String get appliedEffects => '已应用效果';

  @override
  String effectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个效果',
      one: '1 个效果',
      zero: '0 个效果',
    );
    return '$_temp0';
  }

  @override
  String get effectsPreview => '效果预览';

  @override
  String get effectPreview => '效果预览';

  @override
  String get noEffectsApplied => '未应用效果';

  @override
  String get saveChanges => '保存更改';

  @override
  String get finalResult => '最终结果';

  @override
  String get original => '原始';

  @override
  String get withEffect => '带效果';

  @override
  String get withEffects => '带效果';

  @override
  String effectsAppliedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已应用 $count 个效果',
      one: '已应用 1 个效果',
      zero: '已应用 0 个效果',
    );
    return '$_temp0';
  }

  @override
  String get effectsAppliedInOrder => '效果按顺序应用';

  @override
  String get effectsReorderHint => '效果会从上到下应用。拖动可重新排序。';

  @override
  String get addYourFirstEffect => '添加第一个效果';

  @override
  String get layerEffects => '图层效果';

  @override
  String get effectWatercolor => '水彩';

  @override
  String get effectHalftone => '半色调';

  @override
  String get effectOilPaint => '油画';

  @override
  String get effectEmboss => '浮雕';

  @override
  String get ok => 'OK';

  @override
  String get staticEffect => '静态效果';

  @override
  String effectNotAnimatedMessage(String effectName) {
    return '$effectName 效果不是动画效果。动画帧生成仅适用于支持动画的效果。';
  }

  @override
  String get generateAnimation => '生成动画';

  @override
  String generateAnimationForEffect(String effectName) {
    return '为 $effectName 效果生成动画帧？';
  }

  @override
  String get animationDetails => '动画详情';

  @override
  String animationDetailEffect(String effectName) {
    return '• 效果：$effectName';
  }

  @override
  String animationDetailEstimatedFrames(int count) {
    return '• 预计帧数：~$count';
  }

  @override
  String animationDetailProcessingTime(int seconds) {
    return '• 处理时间：约 $seconds 秒';
  }

  @override
  String get generateAnimationTimelineNote => '这会创建多个动画帧，你可以将它们添加到时间线。';

  @override
  String get generateAnimationFrames => '生成动画帧';

  @override
  String effectNameLabel(String effectName) {
    return '$effectName 效果';
  }

  @override
  String framesGeneratedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已生成 $count 帧',
      one: '已生成 1 帧',
      zero: '已生成 0 帧',
    );
    return '$_temp0';
  }

  @override
  String get generateFrames => '生成帧';

  @override
  String get stop => '停止';

  @override
  String get frameLabel => '帧：';

  @override
  String get generatingFrames => '正在生成帧...';

  @override
  String get noFramesGenerated => '未生成帧';

  @override
  String get animationSettings => '动画设置';

  @override
  String get durationSeconds => '时长（秒）';

  @override
  String get fps => 'FPS';

  @override
  String get totalFrames => '总帧数：';

  @override
  String get pingPongAnimation => '往返动画';

  @override
  String get playForwardThenBackward => '先正向播放再反向播放';

  @override
  String get frameGeneration => '帧生成';

  @override
  String get generateNewFrames => '生成新帧';

  @override
  String get createNewFramesForAnimation => '为此动画创建新帧';

  @override
  String get insertIntoTimeline => '插入到时间线';

  @override
  String get addFramesToExistingTimeline => '将帧添加到现有时间线';

  @override
  String get insertPosition => '插入位置：';

  @override
  String afterFrame(int frame) {
    return '第 $frame 帧之后';
  }

  @override
  String get effectParameters => '效果参数';

  @override
  String get editParameters => '编辑参数';

  @override
  String get effectParametersBaseNote => '当前效果设置将作为动画的基础';

  @override
  String get editBaseParameters => '编辑基础参数';

  @override
  String get applyAndRegenerate => '应用并重新生成';

  @override
  String get animationFrameGenerator => '动画帧生成器';

  @override
  String get animationGeneratorHelpIntro => '此工具会使用不同时间参数应用所选效果，从而生成多个动画帧。\n';

  @override
  String get animationHelpDuration => '• 时长：动画总长度（秒）';

  @override
  String get animationHelpFps => '• FPS：每秒帧数（越高越流畅，但帧数更多）';

  @override
  String get animationHelpPingPong => '• 往返：先向前播放，再向后播放';

  @override
  String get animationHelpInterpolation => '• 效果参数会随时间插值，以创建平滑动画';

  @override
  String get tips => '提示：';

  @override
  String get animationTipLowerFps => '• 测试时先使用较低 FPS';

  @override
  String get animationTipUsePreview => '• 生成前使用预览查看动画';

  @override
  String get animationTipLongerDurations => '• 较长时长更适合慢速效果';

  @override
  String effectFrameName(int index) {
    return '效果帧 $index';
  }

  @override
  String effectAnimationName(int index) {
    return '效果动画 $index';
  }

  @override
  String effectAnimationReturnName(int index) {
    return '效果动画 $index（返回）';
  }

  @override
  String generatedAnimationFrames(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已生成 $count 个动画帧',
      one: '已生成 1 个动画帧',
      zero: '已生成 0 个动画帧',
    );
    return '$_temp0！';
  }

  @override
  String get viewTimeline => '查看时间线';

  @override
  String featureBullet(String feature) {
    return '• $feature';
  }

  @override
  String defaultLayerName(int index) {
    return '图层 $index';
  }

  @override
  String get select => '选择';

  @override
  String get menu => '菜单';

  @override
  String get adjustOpacity => '调整不透明度';

  @override
  String get adjustLayerOpacity => '调整图层不透明度';

  @override
  String get addToTemplate => '添加到模板';

  @override
  String get editLayer => '编辑图层';

  @override
  String get layerName => '图层名称';

  @override
  String get backgroundShort => '背景';

  @override
  String get reference => '参考';

  @override
  String get reset => '重置';

  @override
  String get fit => '适应';

  @override
  String get removeBackgroundImage => '移除背景图像';

  @override
  String get removeBackgroundImageMessage => '确定要移除背景图像吗？';

  @override
  String get themeSelector => '主题选择器';

  @override
  String unlockThemeTitle(String themeName) {
    return '解锁 $themeName 主题';
  }

  @override
  String get watchAdToUnlockTheme => '观看视频广告即可解锁此主题。';

  @override
  String themeUnlocked(String themeName) {
    return '$themeName 主题已解锁！';
  }

  @override
  String themeShowcaseTitle(String themeName) {
    return '主题：$themeName';
  }

  @override
  String get primaryColors => '主色';

  @override
  String get primary => '主色';

  @override
  String get primaryVariant => '主色变体';

  @override
  String get onPrimary => '主色上的颜色';

  @override
  String get accent => '强调色';

  @override
  String get onAccent => '强调色上的颜色';

  @override
  String get backgroundColors => '背景颜色';

  @override
  String get background => '背景';

  @override
  String get surface => '表面';

  @override
  String get surfaceVariant => '表面变体';

  @override
  String get textColors => '文本颜色';

  @override
  String get textPrimary => '主文本';

  @override
  String get textSecondary => '次级文本';

  @override
  String get textDisabled => '禁用文本';

  @override
  String get utilityColors => '辅助颜色';

  @override
  String get error => '错误';

  @override
  String get success => '成功';

  @override
  String get warning => '警告';

  @override
  String get uiElements => '界面元素';

  @override
  String get elevated => '凸起';

  @override
  String get filled => '填充';

  @override
  String get outlined => '描边';

  @override
  String get text => '文本';

  @override
  String get inputField => '输入字段';

  @override
  String get enterText => '输入文本';

  @override
  String previewingTheme(String themeName) {
    return '正在预览 $themeName';
  }

  @override
  String currentTheme(String themeName) {
    return '当前：$themeName';
  }

  @override
  String get unlockPremiumThemes => '解锁高级主题';

  @override
  String get getAccessToAllThemesWithPro => '使用 Pro 获取所有主题';

  @override
  String get flagship => '旗舰';

  @override
  String get free => '免费';

  @override
  String get freeThemes => '免费主题';

  @override
  String get premiumThemes => '高级主题';

  @override
  String get apply => '应用';

  @override
  String importedFileAsNewLayer(String fileName) {
    return '已将“$fileName”导入为新图层';
  }

  @override
  String get importAsepriteFile => '导入 Aseprite 文件';

  @override
  String howImportAsepriteFile(String fileName) {
    return '你想如何导入“$fileName”？';
  }

  @override
  String importedFirstLayerFromFile(String fileName) {
    return '已从“$fileName”导入第一层';
  }

  @override
  String get importAsLayer => '作为图层导入';

  @override
  String get openAsProject => '作为项目打开';

  @override
  String get copyFrame => '复制帧';

  @override
  String get addFrame => '添加帧';

  @override
  String get deleteFrame => '删除帧';

  @override
  String get collapse => '收起';

  @override
  String get expand => '展开';

  @override
  String get addState => '添加状态';

  @override
  String get copyState => '复制状态';

  @override
  String get addAnimationState => '添加动画状态';

  @override
  String get stateName => '状态名称';

  @override
  String get columns => '列';

  @override
  String get tileModeTooltip => '平铺模式 - 预览无缝平铺';

  @override
  String get settingsStylusMode => '设置（触控笔模式）';

  @override
  String get onionSkinTooltip => '洋葱皮（长按设置不透明度）';

  @override
  String get sprayPaintToolDescription => '使用粒子创建喷涂效果';

  @override
  String get lineToolDescription => '在两点之间绘制直线';

  @override
  String get circleToolDescription => '绘制完美圆形和椭圆';

  @override
  String get rectangleToolDescription => '绘制矩形和正方形';

  @override
  String get triangleToolDescription => '绘制三角形';

  @override
  String get diamondToolDescription => '绘制菱形';

  @override
  String get hexagonToolDescription => '绘制六边形';

  @override
  String get heartToolDescription => '绘制心形';

  @override
  String get arrowToolDescription => '绘制箭头';

  @override
  String get lightningToolDescription => '绘制闪电形状';

  @override
  String get crossToolDescription => '绘制十字或加号形状';

  @override
  String get spiralToolDescription => '绘制螺旋形状';

  @override
  String get cloudToolDescription => '绘制云朵形状';

  @override
  String get penToolDescription => '高级手绘工具';

  @override
  String get rectangleSelectToolDescription => '选择矩形区域';

  @override
  String get ellipseSelectToolDescription => '选择椭圆区域';

  @override
  String get lassoToolDescription => '手绘选择工具';

  @override
  String get magicWandToolDescription => '按颜色选择连续像素';

  @override
  String get curve => '曲线';

  @override
  String get curveToolDescription => '绘制平滑曲线';

  @override
  String get move => '移动';

  @override
  String get moveToolDescription => '移动和拖拽元素';
}
