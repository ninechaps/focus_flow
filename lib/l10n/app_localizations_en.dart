// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Focus Hut';

  @override
  String get navNavigation => 'Navigation';

  @override
  String get navTaskList => 'Task List';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navStatistics => 'Statistics';

  @override
  String get navSettings => 'Settings';

  @override
  String get scheduleFilterTitle => 'Schedule';

  @override
  String get filterToday => 'Today';

  @override
  String get filterThisWeek => 'This Week';

  @override
  String get filterThisMonth => 'This Month';

  @override
  String get filterEarlier => 'Earlier';

  @override
  String get filterAllTasks => 'All Tasks';

  @override
  String get sidebarGoals => 'Goals';

  @override
  String get sidebarTags => 'Tags';

  @override
  String get sidebarNewGoal => '+ New Goal';

  @override
  String get sidebarNewTag => '+ New Tag';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Retry';

  @override
  String get create => 'Create';

  @override
  String get custom => 'Custom';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusDeleted => 'Deleted';

  @override
  String get priorityHigh => 'High Priority';

  @override
  String get priorityMedium => 'Medium Priority';

  @override
  String get priorityLow => 'Low Priority';

  @override
  String get priorityHighShort => 'High';

  @override
  String get priorityMediumShort => 'Medium';

  @override
  String get priorityLowShort => 'Low';

  @override
  String get taskCreated => 'Task created';

  @override
  String get taskUpdated => 'Task updated';

  @override
  String get taskDeleted => 'Task deleted';

  @override
  String get subtaskCreated => 'Subtask created';

  @override
  String createTaskFailed(String error) {
    return 'Failed to create task: $error';
  }

  @override
  String createSubtaskFailed(String error) {
    return 'Failed to create subtask: $error';
  }

  @override
  String updateTaskFailed(String error) {
    return 'Failed to update task: $error';
  }

  @override
  String deleteTaskFailed(String error) {
    return 'Failed to delete task: $error';
  }

  @override
  String setPriorityFailed(String error) {
    return 'Failed to set priority: $error';
  }

  @override
  String setStatusFailed(String error) {
    return 'Failed to set status: $error';
  }

  @override
  String reorderFailed(String error) {
    return 'Failed to reorder: $error';
  }

  @override
  String get deleteTaskTitle => 'Delete Task';

  @override
  String deleteTaskConfirm(String taskName) {
    return 'Are you sure you want to delete \"$taskName\"? This action cannot be undone.';
  }

  @override
  String get newTask => 'New Task';

  @override
  String get searchTasks => 'Search tasks...';

  @override
  String get noPendingTasks => 'No pending tasks';

  @override
  String get noPendingTasksHint => 'Create your first task to get started';

  @override
  String get noInProgressTasks => 'No in-progress tasks';

  @override
  String get noInProgressTasksHint => 'Start a task to see it here';

  @override
  String get noCompletedTasks => 'No completed tasks';

  @override
  String get noCompletedTasksHint => 'Complete a task to see it here';

  @override
  String get noTasksYet => 'No tasks yet';

  @override
  String get noTasksYetHint => 'Create your first task to get started';

  @override
  String get editSubtask => 'Edit Subtask';

  @override
  String get editTask => 'Edit Task';

  @override
  String get newSubtask => 'New Subtask';

  @override
  String get createSubtask => 'Create Subtask';

  @override
  String get createTask => 'Create Task';

  @override
  String get taskTitle => 'Task Title';

  @override
  String get taskTitlePlaceholder => 'Enter task name...';

  @override
  String get taskTitleRequired => 'Please enter a task title';

  @override
  String get taskTitleTooLong => 'Title must be less than 200 characters';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get descriptionPlaceholder => 'Add more details...';

  @override
  String get descriptionTooLong =>
      'Description must be less than 1000 characters';

  @override
  String get priority => 'Priority';

  @override
  String get dueDateOptional => 'Due Date (optional)';

  @override
  String get relatedGoalOptional => 'Related Goal (optional)';

  @override
  String get noRelatedGoal => 'No related goal';

  @override
  String get tags => 'Tags';

  @override
  String get editTaskContextMenu => 'Edit Task';

  @override
  String get deleteTaskContextMenu => 'Delete Task';

  @override
  String get addSubtask => 'Add Subtask';

  @override
  String get focusOnTask => 'Focus on this task';

  @override
  String get dueDateToday => 'Due today';

  @override
  String get dueDateTomorrow => 'Tomorrow';

  @override
  String get dueDateOverdue => 'Overdue';

  @override
  String get groupToday => 'Today';

  @override
  String get groupTomorrow => 'Tomorrow';

  @override
  String get groupThisWeek => 'This Week';

  @override
  String get groupOverdue => 'Overdue';

  @override
  String get groupYesterday => 'Yesterday';

  @override
  String get groupLater => 'Later';

  @override
  String taskCount(int count) {
    return '$count tasks';
  }

  @override
  String get detailsSection => 'Details';

  @override
  String get detailGoal => 'Goal';

  @override
  String get detailDueDate => 'Due Date';

  @override
  String get detailFocusTime => 'Focus Time';

  @override
  String get detailCreatedAt => 'Created At';

  @override
  String get subtaskProgress => 'Subtask Progress';

  @override
  String get subtasks => 'Subtasks';

  @override
  String get startFocusButton => 'Start Focus';

  @override
  String get editButton => 'Edit';

  @override
  String get detailTasks => 'Tasks';

  @override
  String get detailTotalFocus => 'Total Focus';

  @override
  String get detailProgress => 'Progress';

  @override
  String completedOfTotal(int completed, int total) {
    return '$completed/$total completed';
  }

  @override
  String tasksWithCount(int count) {
    return 'Tasks ($count)';
  }

  @override
  String subtasksCompleted(int completed, int total) {
    return 'Completed $completed / $total subtasks';
  }

  @override
  String get createNewGoal => 'Create New Goal';

  @override
  String get editGoal => 'Edit Goal';

  @override
  String get goalName => 'Goal Name';

  @override
  String get goalNamePlaceholder => 'e.g., Learn Flutter';

  @override
  String get goalNameRequired => 'Goal name is required';

  @override
  String get goalNameTooLong => 'Goal name must be less than 100 characters';

  @override
  String get targetDueDate => 'Target Due Date';

  @override
  String get targetDueDateHint => 'When do you want to achieve this goal?';

  @override
  String get pleaseSelectDueDate => 'Please select a due date';

  @override
  String get createGoal => 'Create Goal';

  @override
  String get saveGoal => 'Save Goal';

  @override
  String get createNewTag => 'Create New Tag';

  @override
  String get editTag => 'Edit Tag';

  @override
  String get tagName => 'Tag Name';

  @override
  String get tagNamePlaceholder => 'e.g., Design, Development';

  @override
  String get tagNameHint => 'Give your tag a descriptive name';

  @override
  String get tagNameRequired => 'Tag name is required';

  @override
  String get tagNameTooLong => 'Tag name must be less than 50 characters';

  @override
  String get selectColor => 'Select Color';

  @override
  String get createTag => 'Create Tag';

  @override
  String get saveTag => 'Save Tag';

  @override
  String get deleteGoalTitle => 'Delete Goal';

  @override
  String get deleteGoalConfirm => 'Are you sure you want to delete this goal?';

  @override
  String get deleteTagTitle => 'Delete Tag';

  @override
  String get deleteTagConfirm => 'Are you sure you want to delete this tag?';

  @override
  String failedToAddGoal(String error) {
    return 'Failed to add goal: $error';
  }

  @override
  String failedToUpdateGoal(String error) {
    return 'Failed to update goal: $error';
  }

  @override
  String failedToDeleteGoal(String error) {
    return 'Failed to delete goal: $error';
  }

  @override
  String failedToAddTag(String error) {
    return 'Failed to add tag: $error';
  }

  @override
  String failedToUpdateTag(String error) {
    return 'Failed to update tag: $error';
  }

  @override
  String failedToDeleteTag(String error) {
    return 'Failed to delete tag: $error';
  }

  @override
  String dueDate(String date) {
    return 'Due $date';
  }

  @override
  String get stopFocusTitle => 'Stop focus session?';

  @override
  String get stopFocusContent =>
      'Your progress will be saved, but the timer will stop.';

  @override
  String get stopAndLeave => 'Stop & Leave';

  @override
  String get backToList => 'Back to list';

  @override
  String get focusModeTitle => 'Focus Mode';

  @override
  String get sessionHistory => 'Session history';

  @override
  String get taskDetail => 'Task detail';

  @override
  String get timerCountdown => 'Countdown';

  @override
  String get timerStopwatch => 'Stopwatch';

  @override
  String get statusBreakTime => 'Break Time';

  @override
  String get statusTracking => 'Tracking';

  @override
  String get statusFocusing => 'Focusing';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusTapStart => 'Tap Start to Begin';

  @override
  String get statusComplete => 'Complete!';

  @override
  String get controlStart => 'Start';

  @override
  String get controlPause => 'Pause';

  @override
  String get controlFinish => 'Finish';

  @override
  String get controlStop => 'Stop';

  @override
  String get controlResume => 'Resume';

  @override
  String get controlBreak => 'Break';

  @override
  String get controlSkip => 'Skip';

  @override
  String get controlDone => 'Done';

  @override
  String get controlAgain => 'Again';

  @override
  String get infoThisSession => 'This Session';

  @override
  String get infoTotalFocus => 'Total Focus';

  @override
  String get infoSessions => 'Sessions';

  @override
  String get sessionHistoryTitle => 'Session History';

  @override
  String get noSessionsYet => 'No sessions yet';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Manage your app preferences';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeMode => 'Theme Mode';

  @override
  String get settingsThemeHint => 'Choose the app\'s theme';

  @override
  String get settingsFollowSystem => 'System';

  @override
  String get settingsLight => 'Light';

  @override
  String get settingsDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageTitle => 'Display Language';

  @override
  String get settingsLanguageHint => 'Choose the app\'s display language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageChinese => 'Chinese';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsMoreComing => 'More settings coming soon';

  @override
  String get settingsDebugTitle => 'Developer Options';

  @override
  String get settingsDebugWarning =>
      'These options are for testing only and will be removed before release.';

  @override
  String get settingsClearAllData => 'Clear All Data';

  @override
  String get settingsClearAllDataDesc =>
      'Delete all tasks, tags, and goals from the database';

  @override
  String get settingsClearConfirmTitle => 'Clear All Data';

  @override
  String get settingsClearConfirmContent =>
      'This will permanently delete all tasks, tags, and goals.\nThis action cannot be undone.\n\nAre you sure you want to continue?';

  @override
  String get settingsClearConfirmButton => 'Clear All';

  @override
  String get settingsDataCleared => 'All data has been cleared';

  @override
  String settingsClearFailed(String error) {
    return 'Failed to clear data: $error';
  }

  @override
  String get settingsClearing => 'Clearing...';

  @override
  String get settingsClearButton => 'Clear';

  @override
  String get statisticsTitle => 'Statistics';

  @override
  String get statisticsSubtitle => 'Track your productivity and progress';

  @override
  String get todayFocus => 'Today Focus';

  @override
  String get thisWeek => 'This Week';

  @override
  String get completed => 'Completed';

  @override
  String get dailyFocusLast7Days => 'Daily Focus (Last 7 Days)';

  @override
  String get taskStatus => 'Task Status';

  @override
  String get goalProgress => 'Goal Progress';

  @override
  String get noGoalsYet => 'No goals yet';

  @override
  String get noTasksForDay => 'No tasks for this day';

  @override
  String get trayStartFocus => 'Start Focus';

  @override
  String get trayStart => 'Start';

  @override
  String get trayPause => 'Pause';

  @override
  String get trayResume => 'Resume';

  @override
  String get traySkipBreak => 'Skip Break';

  @override
  String get trayStop => 'Stop';

  @override
  String get trayOpenApp => 'Open Focus Hut';

  @override
  String get trayQuit => 'Quit';

  @override
  String get popoverFocusSession => 'Focus Session';

  @override
  String get popoverPause => 'Pause';

  @override
  String get popoverStop => 'Stop';

  @override
  String get popoverResume => 'Resume';

  @override
  String get popoverStart => 'Start';

  @override
  String get popoverThisSession => 'This Session';

  @override
  String get popoverTotalFocus => 'Total Focus';

  @override
  String get popoverSessions => 'Sessions';

  @override
  String get popoverNoActiveFocus => 'No active focus session';

  @override
  String get popoverOpenApp => 'Open Focus Hut';

  @override
  String get popoverFocusing => 'Focusing';

  @override
  String get popoverPaused => 'Paused';

  @override
  String get popoverReady => 'Ready';

  @override
  String get popoverCompleted => 'Completed';

  @override
  String get notificationFocusComplete => 'Focus Complete!';

  @override
  String notificationFocusBody(String taskName, String duration) {
    return '$taskName — This session: $duration';
  }

  @override
  String get notificationBreakComplete => 'Break Over';

  @override
  String get notificationBreakBody => 'Ready to start the next focus session';

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get loginSlideTitle1 => 'Focus Timer';

  @override
  String get loginSlideDesc1 =>
      'Stay productive with Pomodoro technique and customizable focus sessions.';

  @override
  String get loginSlideTitle2 => 'Task Management';

  @override
  String get loginSlideDesc2 =>
      'Organize your tasks efficiently with intuitive drag-and-drop interface.';

  @override
  String get loginSlideTitle3 => 'Analytics';

  @override
  String get loginSlideDesc3 =>
      'Track your productivity patterns and improve over time.';

  @override
  String get loginWelcomeBack => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to continue to Focus Hut';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginEmailPlaceholder => 'Enter your email address';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginPasswordPlaceholder => 'Enter your password';

  @override
  String get loginEmailRequired => 'Please enter your email address';

  @override
  String get loginEmailInvalid => 'Please enter a valid email address';

  @override
  String get loginPasswordRequired => 'Please enter your password';

  @override
  String get loginPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get loginSignIn => 'Sign In';

  @override
  String get loginRegister => 'Don\'t have an account?';

  @override
  String get loginRegisterLink => 'Sign Up';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSubtitle => 'Manage your personal information';

  @override
  String get profileUnknownUser => 'Unknown User';

  @override
  String get profileNoEmail => 'No email';

  @override
  String profileLastLogin(String time) {
    return 'Last login: $time';
  }

  @override
  String get datePickerSelectDate => 'Select date';

  @override
  String datePickerSelectTime(String time) {
    return 'Select time: $time';
  }

  @override
  String get datePickerClear => 'Clear';

  @override
  String get datePickerConfirm => 'Confirm';

  @override
  String get authEmptyCredentials => 'Email and password cannot be empty';

  @override
  String get authInvalidCredentials => 'Invalid email or password';

  @override
  String get authEncryptionError =>
      'Encryption service error, please try again later';

  @override
  String get authNetworkError =>
      'Network connection failed, please check your network';

  @override
  String get authServerError => 'Server error, please try again later';

  @override
  String get authSessionExpired => 'Session expired, please sign in again';

  @override
  String get authEmailNotVerified =>
      'Email not verified, please verify your email first';

  @override
  String get authTooManyRequests => 'Too many requests, please try again later';

  @override
  String get scheduleTabPlan => 'Plan';

  @override
  String get scheduleTabReview => 'Review';

  @override
  String get scheduleQuickAdd => 'Quick Add Task';

  @override
  String get scheduleNoSessions => 'No focus sessions this day';

  @override
  String get scheduleTotalFocus => 'Total Focus';

  @override
  String get scheduleFocusCount => 'Sessions';

  @override
  String get scheduleTaskRescheduled => 'Task rescheduled';

  @override
  String get scheduleRescheduleDate => 'Reschedule';

  @override
  String get scheduleSetPriority => 'Set Priority';

  @override
  String get scheduleSetStatus => 'Set Status';

  @override
  String get scheduleStartFocus => 'Start Focus';

  @override
  String get scheduleUnplanned => 'Unplanned';

  @override
  String scheduleFocusDuration(int minutes) {
    return '${minutes}m';
  }

  @override
  String scheduleFocusDurationHours(int hours, int minutes) {
    return '${hours}h${minutes}m';
  }

  @override
  String get scheduleAddTaskToDate => 'Add task to this date';

  @override
  String get scheduleViewReview => 'View focus review';

  @override
  String get scheduleGoToDate => 'Go to this date';

  @override
  String get scheduleOverdueTask => 'Overdue';
}
