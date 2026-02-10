// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '专注小栈';

  @override
  String get navNavigation => '导航';

  @override
  String get navTaskList => '任务列表';

  @override
  String get navSchedule => '日程安排';

  @override
  String get navStatistics => '统计分析';

  @override
  String get navSettings => '设置';

  @override
  String get scheduleFilterTitle => '日程';

  @override
  String get filterToday => '今天';

  @override
  String get filterThisWeek => '本周';

  @override
  String get filterThisMonth => '本月';

  @override
  String get filterEarlier => '更早';

  @override
  String get filterAllTasks => '全部任务';

  @override
  String get sidebarGoals => '目标';

  @override
  String get sidebarTags => '标签';

  @override
  String get sidebarNewGoal => '+ 新建目标';

  @override
  String get sidebarNewTag => '+ 新建标签';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get save => '保存';

  @override
  String get retry => '重试';

  @override
  String get create => '创建';

  @override
  String get custom => '自定义';

  @override
  String get statusPending => '待办';

  @override
  String get statusInProgress => '进行中';

  @override
  String get statusCompleted => '已完成';

  @override
  String get statusDeleted => '已删除';

  @override
  String get priorityHigh => '高优先级';

  @override
  String get priorityMedium => '中优先级';

  @override
  String get priorityLow => '低优先级';

  @override
  String get priorityHighShort => '高';

  @override
  String get priorityMediumShort => '中';

  @override
  String get priorityLowShort => '低';

  @override
  String get taskCreated => '任务已创建';

  @override
  String get taskUpdated => '任务已更新';

  @override
  String get taskDeleted => '任务已删除';

  @override
  String get subtaskCreated => '子任务已创建';

  @override
  String createTaskFailed(String error) {
    return '创建任务失败: $error';
  }

  @override
  String createSubtaskFailed(String error) {
    return '创建子任务失败: $error';
  }

  @override
  String updateTaskFailed(String error) {
    return '更新任务失败: $error';
  }

  @override
  String deleteTaskFailed(String error) {
    return '删除任务失败: $error';
  }

  @override
  String setPriorityFailed(String error) {
    return '设置优先级失败: $error';
  }

  @override
  String setStatusFailed(String error) {
    return '设置状态失败: $error';
  }

  @override
  String reorderFailed(String error) {
    return '排序失败: $error';
  }

  @override
  String get deleteTaskTitle => '删除任务';

  @override
  String deleteTaskConfirm(String taskName) {
    return '确定要删除「$taskName」吗？此操作不可撤销。';
  }

  @override
  String get newTask => '新建任务';

  @override
  String get searchTasks => '搜索任务...';

  @override
  String get noPendingTasks => '没有待办任务';

  @override
  String get noPendingTasksHint => '创建你的第一个任务开始吧';

  @override
  String get noInProgressTasks => '没有进行中的任务';

  @override
  String get noInProgressTasksHint => '开始一个任务后会显示在这里';

  @override
  String get noCompletedTasks => '没有已完成的任务';

  @override
  String get noCompletedTasksHint => '完成一个任务后会显示在这里';

  @override
  String get noTasksYet => '还没有任务';

  @override
  String get noTasksYetHint => '创建你的第一个任务开始吧';

  @override
  String get editSubtask => '编辑子任务';

  @override
  String get editTask => '编辑任务';

  @override
  String get newSubtask => '新建子任务';

  @override
  String get createSubtask => '创建子任务';

  @override
  String get createTask => '创建任务';

  @override
  String get taskTitle => '任务标题';

  @override
  String get taskTitlePlaceholder => '输入任务名称...';

  @override
  String get taskTitleRequired => '请输入任务标题';

  @override
  String get taskTitleTooLong => '标题不能超过200个字符';

  @override
  String get descriptionOptional => '描述（可选）';

  @override
  String get descriptionPlaceholder => '添加更多细节...';

  @override
  String get descriptionTooLong => '描述不能超过1000个字符';

  @override
  String get priority => '优先级';

  @override
  String get dueDateOptional => '截止日期（可选）';

  @override
  String get relatedGoalOptional => '关联目标（可选）';

  @override
  String get noRelatedGoal => '无关联目标';

  @override
  String get tags => '标签';

  @override
  String get editTaskContextMenu => '编辑任务';

  @override
  String get deleteTaskContextMenu => '删除任务';

  @override
  String get addSubtask => '添加子任务';

  @override
  String get focusOnTask => '专注此任务';

  @override
  String get dueDateToday => '今天到期';

  @override
  String get dueDateTomorrow => '明天';

  @override
  String get dueDateOverdue => '已逾期';

  @override
  String get groupToday => '今天';

  @override
  String get groupTomorrow => '明天';

  @override
  String get groupThisWeek => '本周';

  @override
  String get groupOverdue => '已逾期';

  @override
  String get groupYesterday => '昨天';

  @override
  String get groupLater => '以后';

  @override
  String taskCount(int count) {
    return '$count 个任务';
  }

  @override
  String get detailsSection => '详情';

  @override
  String get detailGoal => '目标';

  @override
  String get detailDueDate => '到期日';

  @override
  String get detailFocusTime => '已专注';

  @override
  String get detailCreatedAt => '创建于';

  @override
  String get subtaskProgress => '子任务进度';

  @override
  String get subtasks => '子任务';

  @override
  String get startFocusButton => '开始专注';

  @override
  String get editButton => '编辑';

  @override
  String get detailTasks => '任务';

  @override
  String get detailTotalFocus => '总专注';

  @override
  String get detailProgress => '进度';

  @override
  String completedOfTotal(int completed, int total) {
    return '$completed/$total 已完成';
  }

  @override
  String tasksWithCount(int count) {
    return '任务 ($count)';
  }

  @override
  String subtasksCompleted(int completed, int total) {
    return '已完成 $completed / $total 个子任务';
  }

  @override
  String get createNewGoal => '新建目标';

  @override
  String get editGoal => '编辑目标';

  @override
  String get goalName => '目标名称';

  @override
  String get goalNamePlaceholder => '例如：学习 Flutter';

  @override
  String get goalNameRequired => '请输入目标名称';

  @override
  String get goalNameTooLong => '目标名称不能超过100个字符';

  @override
  String get targetDueDate => '目标截止日期';

  @override
  String get targetDueDateHint => '你希望什么时候达成这个目标？';

  @override
  String get pleaseSelectDueDate => '请选择截止日期';

  @override
  String get createGoal => '创建目标';

  @override
  String get saveGoal => '保存目标';

  @override
  String get createNewTag => '新建标签';

  @override
  String get editTag => '编辑标签';

  @override
  String get tagName => '标签名称';

  @override
  String get tagNamePlaceholder => '例如：设计、开发';

  @override
  String get tagNameHint => '为标签取一个描述性的名称';

  @override
  String get tagNameRequired => '请输入标签名称';

  @override
  String get tagNameTooLong => '标签名称不能超过50个字符';

  @override
  String get selectColor => '选择颜色';

  @override
  String get createTag => '创建标签';

  @override
  String get saveTag => '保存标签';

  @override
  String get deleteGoalTitle => '删除目标';

  @override
  String get deleteGoalConfirm => '确定要删除这个目标吗？';

  @override
  String get deleteTagTitle => '删除标签';

  @override
  String get deleteTagConfirm => '确定要删除这个标签吗？';

  @override
  String failedToAddGoal(String error) {
    return '添加目标失败: $error';
  }

  @override
  String failedToUpdateGoal(String error) {
    return '更新目标失败: $error';
  }

  @override
  String failedToDeleteGoal(String error) {
    return '删除目标失败: $error';
  }

  @override
  String failedToAddTag(String error) {
    return '添加标签失败: $error';
  }

  @override
  String failedToUpdateTag(String error) {
    return '更新标签失败: $error';
  }

  @override
  String failedToDeleteTag(String error) {
    return '删除标签失败: $error';
  }

  @override
  String dueDate(String date) {
    return '截止 $date';
  }

  @override
  String get stopFocusTitle => '停止专注？';

  @override
  String get stopFocusContent => '你的进度将会保存，但计时器会停止。';

  @override
  String get stopAndLeave => '停止并离开';

  @override
  String get backToList => '返回列表';

  @override
  String get focusModeTitle => '专注模式';

  @override
  String get sessionHistory => '专注记录';

  @override
  String get taskDetail => '任务详情';

  @override
  String get timerCountdown => '倒计时';

  @override
  String get timerStopwatch => '正计时';

  @override
  String get statusBreakTime => '休息时间';

  @override
  String get statusTracking => '计时中';

  @override
  String get statusFocusing => '专注中';

  @override
  String get statusPaused => '已暂停';

  @override
  String get statusTapStart => '点击开始';

  @override
  String get statusComplete => '完成！';

  @override
  String get controlStart => '开始';

  @override
  String get controlPause => '暂停';

  @override
  String get controlFinish => '完成';

  @override
  String get controlStop => '停止';

  @override
  String get controlResume => '继续';

  @override
  String get controlBreak => '休息';

  @override
  String get controlSkip => '跳过';

  @override
  String get controlDone => '结束';

  @override
  String get controlAgain => '再来';

  @override
  String get infoThisSession => '本次会话';

  @override
  String get infoTotalFocus => '累计专注';

  @override
  String get infoSessions => '完成次数';

  @override
  String get sessionHistoryTitle => '专注记录';

  @override
  String get noSessionsYet => '暂无记录';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSubtitle => '管理应用偏好设置';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsThemeMode => '主题模式';

  @override
  String get settingsThemeHint => '选择应用的外观主题';

  @override
  String get settingsFollowSystem => '跟随系统';

  @override
  String get settingsLight => '浅色';

  @override
  String get settingsDark => '深色';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageTitle => '显示语言';

  @override
  String get settingsLanguageHint => '选择应用的显示语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsLanguageChinese => '中文';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsMoreComing => '更多设置即将上线';

  @override
  String get settingsDebugTitle => '开发者选项';

  @override
  String get settingsDebugWarning => '以下选项仅用于测试，发布前将移除。';

  @override
  String get settingsClearAllData => '清除所有数据';

  @override
  String get settingsClearAllDataDesc => '删除数据库中的所有任务、标签和目标';

  @override
  String get settingsClearConfirmTitle => '清除所有数据';

  @override
  String get settingsClearConfirmContent =>
      '这将永久删除所有任务、标签和目标。\n此操作不可撤销。\n\n确定要继续吗？';

  @override
  String get settingsClearConfirmButton => '清除全部';

  @override
  String get settingsDataCleared => '数据已全部清除';

  @override
  String settingsClearFailed(String error) {
    return '清除数据失败: $error';
  }

  @override
  String get settingsClearing => '清除中...';

  @override
  String get settingsClearButton => '清除';

  @override
  String get statisticsTitle => '统计分析';

  @override
  String get statisticsSubtitle => '追踪你的生产力与进度';

  @override
  String get todayFocus => '今日专注';

  @override
  String get thisWeek => '本周';

  @override
  String get completed => '已完成';

  @override
  String get dailyFocusLast7Days => '每日专注（近7天）';

  @override
  String get taskStatus => '任务状态';

  @override
  String get goalProgress => '目标进度';

  @override
  String get noGoalsYet => '暂无目标';

  @override
  String get noTasksForDay => '当天没有任务';

  @override
  String get trayStartFocus => '▶ 开始专注';

  @override
  String get trayStart => '▶ 开始';

  @override
  String get trayPause => '⏸ 暂停';

  @override
  String get trayResume => '▶ 继续';

  @override
  String get traySkipBreak => '⏭ 跳过休息';

  @override
  String get trayStop => '⏹ 停止';

  @override
  String get trayOpenApp => '打开 Focus Hut';

  @override
  String get trayQuit => '退出';

  @override
  String get popoverFocusSession => '专注任务';

  @override
  String get popoverPause => '⏸ 暂停';

  @override
  String get popoverStop => '⏹ 停止';

  @override
  String get popoverResume => '▶ 继续';

  @override
  String get popoverStart => '▶ 开始';

  @override
  String get popoverThisSession => '本次会话';

  @override
  String get popoverTotalFocus => '累计专注';

  @override
  String get popoverSessions => '完成次数';

  @override
  String get popoverNoActiveFocus => '暂无进行中的专注';

  @override
  String get popoverOpenApp => '打开 Focus Hut';

  @override
  String get popoverFocusing => '专注中';

  @override
  String get popoverPaused => '已暂停';

  @override
  String get popoverReady => '准备就绪';

  @override
  String get popoverCompleted => '已完成';

  @override
  String get notificationFocusComplete => '专注完成！';

  @override
  String notificationFocusBody(String taskName, String duration) {
    return '$taskName — 本次专注 $duration';
  }

  @override
  String get notificationBreakComplete => '休息结束';

  @override
  String get notificationBreakBody => '准备开始下一个专注时段吧';

  @override
  String errorPrefix(String error) {
    return '错误: $error';
  }

  @override
  String get loginSlideTitle1 => '专注计时';

  @override
  String get loginSlideDesc1 => '使用番茄工作法和可自定义的专注时段，保持高效产出。';

  @override
  String get loginSlideTitle2 => '任务管理';

  @override
  String get loginSlideDesc2 => '用直观的拖放界面高效组织你的任务。';

  @override
  String get loginSlideTitle3 => '统计分析';

  @override
  String get loginSlideDesc3 => '追踪你的生产力模式，持续改进。';

  @override
  String get loginWelcomeBack => '欢迎回来';

  @override
  String get loginSubtitle => '登录以继续使用专注小栈';

  @override
  String get loginUsername => '用户名';

  @override
  String get loginUsernamePlaceholder => '请输入用户名';

  @override
  String get loginPassword => '密码';

  @override
  String get loginPasswordPlaceholder => '请输入密码';

  @override
  String get loginUsernameRequired => '请输入用户名';

  @override
  String get loginPasswordRequired => '请输入密码';

  @override
  String get loginPasswordTooShort => '密码至少4位';

  @override
  String get loginSignIn => '登录';

  @override
  String get loginDemoHint => '演示账号: admin / admin123';

  @override
  String get profileTitle => '个人资料';

  @override
  String get profileSubtitle => '管理你的个人信息';

  @override
  String get profileUnknownUser => '未知用户';

  @override
  String get profileNoEmail => '未设置邮箱';

  @override
  String profileLastLogin(String time) {
    return '上次登录: $time';
  }

  @override
  String get datePickerSelectDate => '选择日期';

  @override
  String datePickerSelectTime(String time) {
    return '选择时间: $time';
  }

  @override
  String get datePickerClear => '清除';

  @override
  String get datePickerConfirm => '确定';

  @override
  String get authEmptyCredentials => '用户名和密码不能为空';

  @override
  String get authInvalidCredentials => '用户名或密码错误\n正确的用户名: admin, 密码: admin123';

  @override
  String get scheduleTabPlan => '计划';

  @override
  String get scheduleTabReview => '回顾';

  @override
  String get scheduleQuickAdd => '快速添加任务';

  @override
  String get scheduleNoSessions => '当天没有专注记录';

  @override
  String get scheduleTotalFocus => '总专注时长';

  @override
  String get scheduleFocusCount => '专注次数';

  @override
  String get scheduleTaskRescheduled => '任务已重新安排';

  @override
  String get scheduleRescheduleDate => '重新安排日期';

  @override
  String get scheduleSetPriority => '设置优先级';

  @override
  String get scheduleSetStatus => '设置状态';

  @override
  String get scheduleStartFocus => '开始专注';

  @override
  String get scheduleUnplanned => '未安排';

  @override
  String scheduleFocusDuration(int minutes) {
    return '$minutes分钟';
  }

  @override
  String scheduleFocusDurationHours(int hours, int minutes) {
    return '$hours小时$minutes分钟';
  }
}
