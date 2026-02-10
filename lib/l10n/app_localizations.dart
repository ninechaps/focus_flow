import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus Hut'**
  String get appTitle;

  /// No description provided for @navNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navNavigation;

  /// No description provided for @navTaskList.
  ///
  /// In en, this message translates to:
  /// **'Task List'**
  String get navTaskList;

  /// No description provided for @navSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get navSchedule;

  /// No description provided for @navStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get navStatistics;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @scheduleFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleFilterTitle;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// No description provided for @filterThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get filterThisWeek;

  /// No description provided for @filterThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get filterThisMonth;

  /// No description provided for @filterEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get filterEarlier;

  /// No description provided for @filterAllTasks.
  ///
  /// In en, this message translates to:
  /// **'All Tasks'**
  String get filterAllTasks;

  /// No description provided for @sidebarGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get sidebarGoals;

  /// No description provided for @sidebarTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get sidebarTags;

  /// No description provided for @sidebarNewGoal.
  ///
  /// In en, this message translates to:
  /// **'+ New Goal'**
  String get sidebarNewGoal;

  /// No description provided for @sidebarNewTag.
  ///
  /// In en, this message translates to:
  /// **'+ New Tag'**
  String get sidebarNewTag;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get statusDeleted;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High Priority'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium Priority'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low Priority'**
  String get priorityLow;

  /// No description provided for @priorityHighShort.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHighShort;

  /// No description provided for @priorityMediumShort.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMediumShort;

  /// No description provided for @priorityLowShort.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLowShort;

  /// No description provided for @taskCreated.
  ///
  /// In en, this message translates to:
  /// **'Task created'**
  String get taskCreated;

  /// No description provided for @taskUpdated.
  ///
  /// In en, this message translates to:
  /// **'Task updated'**
  String get taskUpdated;

  /// No description provided for @taskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get taskDeleted;

  /// No description provided for @subtaskCreated.
  ///
  /// In en, this message translates to:
  /// **'Subtask created'**
  String get subtaskCreated;

  /// No description provided for @createTaskFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create task: {error}'**
  String createTaskFailed(String error);

  /// No description provided for @createSubtaskFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create subtask: {error}'**
  String createSubtaskFailed(String error);

  /// No description provided for @updateTaskFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update task: {error}'**
  String updateTaskFailed(String error);

  /// No description provided for @deleteTaskFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete task: {error}'**
  String deleteTaskFailed(String error);

  /// No description provided for @setPriorityFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to set priority: {error}'**
  String setPriorityFailed(String error);

  /// No description provided for @setStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to set status: {error}'**
  String setStatusFailed(String error);

  /// No description provided for @reorderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reorder: {error}'**
  String reorderFailed(String error);

  /// No description provided for @deleteTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTaskTitle;

  /// No description provided for @deleteTaskConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{taskName}\"? This action cannot be undone.'**
  String deleteTaskConfirm(String taskName);

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get newTask;

  /// No description provided for @searchTasks.
  ///
  /// In en, this message translates to:
  /// **'Search tasks...'**
  String get searchTasks;

  /// No description provided for @noPendingTasks.
  ///
  /// In en, this message translates to:
  /// **'No pending tasks'**
  String get noPendingTasks;

  /// No description provided for @noPendingTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Create your first task to get started'**
  String get noPendingTasksHint;

  /// No description provided for @noInProgressTasks.
  ///
  /// In en, this message translates to:
  /// **'No in-progress tasks'**
  String get noInProgressTasks;

  /// No description provided for @noInProgressTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Start a task to see it here'**
  String get noInProgressTasksHint;

  /// No description provided for @noCompletedTasks.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks'**
  String get noCompletedTasks;

  /// No description provided for @noCompletedTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Complete a task to see it here'**
  String get noCompletedTasksHint;

  /// No description provided for @noTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasksYet;

  /// No description provided for @noTasksYetHint.
  ///
  /// In en, this message translates to:
  /// **'Create your first task to get started'**
  String get noTasksYetHint;

  /// No description provided for @editSubtask.
  ///
  /// In en, this message translates to:
  /// **'Edit Subtask'**
  String get editSubtask;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @newSubtask.
  ///
  /// In en, this message translates to:
  /// **'New Subtask'**
  String get newSubtask;

  /// No description provided for @createSubtask.
  ///
  /// In en, this message translates to:
  /// **'Create Subtask'**
  String get createSubtask;

  /// No description provided for @createTask.
  ///
  /// In en, this message translates to:
  /// **'Create Task'**
  String get createTask;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Title'**
  String get taskTitle;

  /// No description provided for @taskTitlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter task name...'**
  String get taskTitlePlaceholder;

  /// No description provided for @taskTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a task title'**
  String get taskTitleRequired;

  /// No description provided for @taskTitleTooLong.
  ///
  /// In en, this message translates to:
  /// **'Title must be less than 200 characters'**
  String get taskTitleTooLong;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @descriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add more details...'**
  String get descriptionPlaceholder;

  /// No description provided for @descriptionTooLong.
  ///
  /// In en, this message translates to:
  /// **'Description must be less than 1000 characters'**
  String get descriptionTooLong;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @dueDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Due Date (optional)'**
  String get dueDateOptional;

  /// No description provided for @relatedGoalOptional.
  ///
  /// In en, this message translates to:
  /// **'Related Goal (optional)'**
  String get relatedGoalOptional;

  /// No description provided for @noRelatedGoal.
  ///
  /// In en, this message translates to:
  /// **'No related goal'**
  String get noRelatedGoal;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @editTaskContextMenu.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTaskContextMenu;

  /// No description provided for @deleteTaskContextMenu.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTaskContextMenu;

  /// No description provided for @addSubtask.
  ///
  /// In en, this message translates to:
  /// **'Add Subtask'**
  String get addSubtask;

  /// No description provided for @focusOnTask.
  ///
  /// In en, this message translates to:
  /// **'Focus on this task'**
  String get focusOnTask;

  /// No description provided for @dueDateToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueDateToday;

  /// No description provided for @dueDateTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dueDateTomorrow;

  /// No description provided for @dueDateOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get dueDateOverdue;

  /// No description provided for @groupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get groupToday;

  /// No description provided for @groupTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get groupTomorrow;

  /// No description provided for @groupThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get groupThisWeek;

  /// No description provided for @groupOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get groupOverdue;

  /// No description provided for @groupYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get groupYesterday;

  /// No description provided for @groupLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get groupLater;

  /// No description provided for @taskCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks'**
  String taskCount(int count);

  /// No description provided for @detailsSection.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsSection;

  /// No description provided for @detailGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get detailGoal;

  /// No description provided for @detailDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get detailDueDate;

  /// No description provided for @detailFocusTime.
  ///
  /// In en, this message translates to:
  /// **'Focus Time'**
  String get detailFocusTime;

  /// No description provided for @detailCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get detailCreatedAt;

  /// No description provided for @subtaskProgress.
  ///
  /// In en, this message translates to:
  /// **'Subtask Progress'**
  String get subtaskProgress;

  /// No description provided for @subtasks.
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get subtasks;

  /// No description provided for @startFocusButton.
  ///
  /// In en, this message translates to:
  /// **'Start Focus'**
  String get startFocusButton;

  /// No description provided for @editButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editButton;

  /// No description provided for @detailTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get detailTasks;

  /// No description provided for @detailTotalFocus.
  ///
  /// In en, this message translates to:
  /// **'Total Focus'**
  String get detailTotalFocus;

  /// No description provided for @detailProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get detailProgress;

  /// No description provided for @completedOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} completed'**
  String completedOfTotal(int completed, int total);

  /// No description provided for @tasksWithCount.
  ///
  /// In en, this message translates to:
  /// **'Tasks ({count})'**
  String tasksWithCount(int count);

  /// No description provided for @subtasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed {completed} / {total} subtasks'**
  String subtasksCompleted(int completed, int total);

  /// No description provided for @createNewGoal.
  ///
  /// In en, this message translates to:
  /// **'Create New Goal'**
  String get createNewGoal;

  /// No description provided for @editGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit Goal'**
  String get editGoal;

  /// No description provided for @goalName.
  ///
  /// In en, this message translates to:
  /// **'Goal Name'**
  String get goalName;

  /// No description provided for @goalNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g., Learn Flutter'**
  String get goalNamePlaceholder;

  /// No description provided for @goalNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Goal name is required'**
  String get goalNameRequired;

  /// No description provided for @goalNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Goal name must be less than 100 characters'**
  String get goalNameTooLong;

  /// No description provided for @targetDueDate.
  ///
  /// In en, this message translates to:
  /// **'Target Due Date'**
  String get targetDueDate;

  /// No description provided for @targetDueDateHint.
  ///
  /// In en, this message translates to:
  /// **'When do you want to achieve this goal?'**
  String get targetDueDateHint;

  /// No description provided for @pleaseSelectDueDate.
  ///
  /// In en, this message translates to:
  /// **'Please select a due date'**
  String get pleaseSelectDueDate;

  /// No description provided for @createGoal.
  ///
  /// In en, this message translates to:
  /// **'Create Goal'**
  String get createGoal;

  /// No description provided for @saveGoal.
  ///
  /// In en, this message translates to:
  /// **'Save Goal'**
  String get saveGoal;

  /// No description provided for @createNewTag.
  ///
  /// In en, this message translates to:
  /// **'Create New Tag'**
  String get createNewTag;

  /// No description provided for @editTag.
  ///
  /// In en, this message translates to:
  /// **'Edit Tag'**
  String get editTag;

  /// No description provided for @tagName.
  ///
  /// In en, this message translates to:
  /// **'Tag Name'**
  String get tagName;

  /// No description provided for @tagNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g., Design, Development'**
  String get tagNamePlaceholder;

  /// No description provided for @tagNameHint.
  ///
  /// In en, this message translates to:
  /// **'Give your tag a descriptive name'**
  String get tagNameHint;

  /// No description provided for @tagNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Tag name is required'**
  String get tagNameRequired;

  /// No description provided for @tagNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Tag name must be less than 50 characters'**
  String get tagNameTooLong;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColor;

  /// No description provided for @createTag.
  ///
  /// In en, this message translates to:
  /// **'Create Tag'**
  String get createTag;

  /// No description provided for @saveTag.
  ///
  /// In en, this message translates to:
  /// **'Save Tag'**
  String get saveTag;

  /// No description provided for @deleteGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Goal'**
  String get deleteGoalTitle;

  /// No description provided for @deleteGoalConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this goal?'**
  String get deleteGoalConfirm;

  /// No description provided for @deleteTagTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Tag'**
  String get deleteTagTitle;

  /// No description provided for @deleteTagConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this tag?'**
  String get deleteTagConfirm;

  /// No description provided for @failedToAddGoal.
  ///
  /// In en, this message translates to:
  /// **'Failed to add goal: {error}'**
  String failedToAddGoal(String error);

  /// No description provided for @failedToUpdateGoal.
  ///
  /// In en, this message translates to:
  /// **'Failed to update goal: {error}'**
  String failedToUpdateGoal(String error);

  /// No description provided for @failedToDeleteGoal.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete goal: {error}'**
  String failedToDeleteGoal(String error);

  /// No description provided for @failedToAddTag.
  ///
  /// In en, this message translates to:
  /// **'Failed to add tag: {error}'**
  String failedToAddTag(String error);

  /// No description provided for @failedToUpdateTag.
  ///
  /// In en, this message translates to:
  /// **'Failed to update tag: {error}'**
  String failedToUpdateTag(String error);

  /// No description provided for @failedToDeleteTag.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete tag: {error}'**
  String failedToDeleteTag(String error);

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueDate(String date);

  /// No description provided for @stopFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop focus session?'**
  String get stopFocusTitle;

  /// No description provided for @stopFocusContent.
  ///
  /// In en, this message translates to:
  /// **'Your progress will be saved, but the timer will stop.'**
  String get stopFocusContent;

  /// No description provided for @stopAndLeave.
  ///
  /// In en, this message translates to:
  /// **'Stop & Leave'**
  String get stopAndLeave;

  /// No description provided for @backToList.
  ///
  /// In en, this message translates to:
  /// **'Back to list'**
  String get backToList;

  /// No description provided for @focusModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode'**
  String get focusModeTitle;

  /// No description provided for @sessionHistory.
  ///
  /// In en, this message translates to:
  /// **'Session history'**
  String get sessionHistory;

  /// No description provided for @taskDetail.
  ///
  /// In en, this message translates to:
  /// **'Task detail'**
  String get taskDetail;

  /// No description provided for @timerCountdown.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get timerCountdown;

  /// No description provided for @timerStopwatch.
  ///
  /// In en, this message translates to:
  /// **'Stopwatch'**
  String get timerStopwatch;

  /// No description provided for @statusBreakTime.
  ///
  /// In en, this message translates to:
  /// **'Break Time'**
  String get statusBreakTime;

  /// No description provided for @statusTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get statusTracking;

  /// No description provided for @statusFocusing.
  ///
  /// In en, this message translates to:
  /// **'Focusing'**
  String get statusFocusing;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// No description provided for @statusTapStart.
  ///
  /// In en, this message translates to:
  /// **'Tap Start to Begin'**
  String get statusTapStart;

  /// No description provided for @statusComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete!'**
  String get statusComplete;

  /// No description provided for @controlStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get controlStart;

  /// No description provided for @controlPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get controlPause;

  /// No description provided for @controlFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get controlFinish;

  /// No description provided for @controlStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get controlStop;

  /// No description provided for @controlResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get controlResume;

  /// No description provided for @controlBreak.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get controlBreak;

  /// No description provided for @controlSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get controlSkip;

  /// No description provided for @controlDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get controlDone;

  /// No description provided for @controlAgain.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get controlAgain;

  /// No description provided for @infoThisSession.
  ///
  /// In en, this message translates to:
  /// **'This Session'**
  String get infoThisSession;

  /// No description provided for @infoTotalFocus.
  ///
  /// In en, this message translates to:
  /// **'Total Focus'**
  String get infoTotalFocus;

  /// No description provided for @infoSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get infoSessions;

  /// No description provided for @sessionHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Session History'**
  String get sessionHistoryTitle;

  /// No description provided for @noSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get noSessionsYet;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your app preferences'**
  String get settingsSubtitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get settingsThemeMode;

  /// No description provided for @settingsThemeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the app\'s theme'**
  String get settingsThemeHint;

  /// No description provided for @settingsFollowSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsFollowSystem;

  /// No description provided for @settingsLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsLight;

  /// No description provided for @settingsDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Display Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the app\'s display language'**
  String get settingsLanguageHint;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get settingsLanguageChinese;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsMoreComing.
  ///
  /// In en, this message translates to:
  /// **'More settings coming soon'**
  String get settingsMoreComing;

  /// No description provided for @settingsDebugTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer Options'**
  String get settingsDebugTitle;

  /// No description provided for @settingsDebugWarning.
  ///
  /// In en, this message translates to:
  /// **'These options are for testing only and will be removed before release.'**
  String get settingsDebugWarning;

  /// No description provided for @settingsClearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get settingsClearAllData;

  /// No description provided for @settingsClearAllDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Delete all tasks, tags, and goals from the database'**
  String get settingsClearAllDataDesc;

  /// No description provided for @settingsClearConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get settingsClearConfirmTitle;

  /// No description provided for @settingsClearConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all tasks, tags, and goals.\nThis action cannot be undone.\n\nAre you sure you want to continue?'**
  String get settingsClearConfirmContent;

  /// No description provided for @settingsClearConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get settingsClearConfirmButton;

  /// No description provided for @settingsDataCleared.
  ///
  /// In en, this message translates to:
  /// **'All data has been cleared'**
  String get settingsDataCleared;

  /// No description provided for @settingsClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear data: {error}'**
  String settingsClearFailed(String error);

  /// No description provided for @settingsClearing.
  ///
  /// In en, this message translates to:
  /// **'Clearing...'**
  String get settingsClearing;

  /// No description provided for @settingsClearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsClearButton;

  /// No description provided for @statisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsTitle;

  /// No description provided for @statisticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your productivity and progress'**
  String get statisticsSubtitle;

  /// No description provided for @todayFocus.
  ///
  /// In en, this message translates to:
  /// **'Today Focus'**
  String get todayFocus;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @dailyFocusLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Daily Focus (Last 7 Days)'**
  String get dailyFocusLast7Days;

  /// No description provided for @taskStatus.
  ///
  /// In en, this message translates to:
  /// **'Task Status'**
  String get taskStatus;

  /// No description provided for @goalProgress.
  ///
  /// In en, this message translates to:
  /// **'Goal Progress'**
  String get goalProgress;

  /// No description provided for @noGoalsYet.
  ///
  /// In en, this message translates to:
  /// **'No goals yet'**
  String get noGoalsYet;

  /// No description provided for @noTasksForDay.
  ///
  /// In en, this message translates to:
  /// **'No tasks for this day'**
  String get noTasksForDay;

  /// No description provided for @trayStartFocus.
  ///
  /// In en, this message translates to:
  /// **'Start Focus'**
  String get trayStartFocus;

  /// No description provided for @trayStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get trayStart;

  /// No description provided for @trayPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get trayPause;

  /// No description provided for @trayResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get trayResume;

  /// No description provided for @traySkipBreak.
  ///
  /// In en, this message translates to:
  /// **'Skip Break'**
  String get traySkipBreak;

  /// No description provided for @trayStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get trayStop;

  /// No description provided for @trayOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Open Focus Hut'**
  String get trayOpenApp;

  /// No description provided for @trayQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get trayQuit;

  /// No description provided for @popoverFocusSession.
  ///
  /// In en, this message translates to:
  /// **'Focus Session'**
  String get popoverFocusSession;

  /// No description provided for @popoverPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get popoverPause;

  /// No description provided for @popoverStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get popoverStop;

  /// No description provided for @popoverResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get popoverResume;

  /// No description provided for @popoverStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get popoverStart;

  /// No description provided for @popoverThisSession.
  ///
  /// In en, this message translates to:
  /// **'This Session'**
  String get popoverThisSession;

  /// No description provided for @popoverTotalFocus.
  ///
  /// In en, this message translates to:
  /// **'Total Focus'**
  String get popoverTotalFocus;

  /// No description provided for @popoverSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get popoverSessions;

  /// No description provided for @popoverNoActiveFocus.
  ///
  /// In en, this message translates to:
  /// **'No active focus session'**
  String get popoverNoActiveFocus;

  /// No description provided for @popoverOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Open Focus Hut'**
  String get popoverOpenApp;

  /// No description provided for @popoverFocusing.
  ///
  /// In en, this message translates to:
  /// **'Focusing'**
  String get popoverFocusing;

  /// No description provided for @popoverPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get popoverPaused;

  /// No description provided for @popoverReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get popoverReady;

  /// No description provided for @popoverCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get popoverCompleted;

  /// No description provided for @notificationFocusComplete.
  ///
  /// In en, this message translates to:
  /// **'Focus Complete!'**
  String get notificationFocusComplete;

  /// No description provided for @notificationFocusBody.
  ///
  /// In en, this message translates to:
  /// **'{taskName} — This session: {duration}'**
  String notificationFocusBody(String taskName, String duration);

  /// No description provided for @notificationBreakComplete.
  ///
  /// In en, this message translates to:
  /// **'Break Over'**
  String get notificationBreakComplete;

  /// No description provided for @notificationBreakBody.
  ///
  /// In en, this message translates to:
  /// **'Ready to start the next focus session'**
  String get notificationBreakBody;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(String error);

  /// No description provided for @loginSlideTitle1.
  ///
  /// In en, this message translates to:
  /// **'Focus Timer'**
  String get loginSlideTitle1;

  /// No description provided for @loginSlideDesc1.
  ///
  /// In en, this message translates to:
  /// **'Stay productive with Pomodoro technique and customizable focus sessions.'**
  String get loginSlideDesc1;

  /// No description provided for @loginSlideTitle2.
  ///
  /// In en, this message translates to:
  /// **'Task Management'**
  String get loginSlideTitle2;

  /// No description provided for @loginSlideDesc2.
  ///
  /// In en, this message translates to:
  /// **'Organize your tasks efficiently with intuitive drag-and-drop interface.'**
  String get loginSlideDesc2;

  /// No description provided for @loginSlideTitle3.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get loginSlideTitle3;

  /// No description provided for @loginSlideDesc3.
  ///
  /// In en, this message translates to:
  /// **'Track your productivity patterns and improve over time.'**
  String get loginSlideDesc3;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to Focus Hut'**
  String get loginSubtitle;

  /// No description provided for @loginUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginUsername;

  /// No description provided for @loginUsernamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get loginUsernamePlaceholder;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordPlaceholder;

  /// No description provided for @loginUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your username'**
  String get loginUsernameRequired;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get loginPasswordRequired;

  /// No description provided for @loginPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 4 characters'**
  String get loginPasswordTooShort;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginSignIn;

  /// No description provided for @loginDemoHint.
  ///
  /// In en, this message translates to:
  /// **'Demo: admin / admin123'**
  String get loginDemoHint;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your personal information'**
  String get profileSubtitle;

  /// No description provided for @profileUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get profileUnknownUser;

  /// No description provided for @profileNoEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get profileNoEmail;

  /// No description provided for @profileLastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last login: {time}'**
  String profileLastLogin(String time);

  /// No description provided for @datePickerSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get datePickerSelectDate;

  /// No description provided for @datePickerSelectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time: {time}'**
  String datePickerSelectTime(String time);

  /// No description provided for @datePickerClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get datePickerClear;

  /// No description provided for @datePickerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get datePickerConfirm;

  /// No description provided for @authEmptyCredentials.
  ///
  /// In en, this message translates to:
  /// **'Username and password cannot be empty'**
  String get authEmptyCredentials;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password\nCorrect username: admin, password: admin123'**
  String get authInvalidCredentials;

  /// No description provided for @scheduleTabPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get scheduleTabPlan;

  /// No description provided for @scheduleTabReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get scheduleTabReview;

  /// No description provided for @scheduleQuickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick Add Task'**
  String get scheduleQuickAdd;

  /// No description provided for @scheduleNoSessions.
  ///
  /// In en, this message translates to:
  /// **'No focus sessions this day'**
  String get scheduleNoSessions;

  /// No description provided for @scheduleTotalFocus.
  ///
  /// In en, this message translates to:
  /// **'Total Focus'**
  String get scheduleTotalFocus;

  /// No description provided for @scheduleFocusCount.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get scheduleFocusCount;

  /// No description provided for @scheduleTaskRescheduled.
  ///
  /// In en, this message translates to:
  /// **'Task rescheduled'**
  String get scheduleTaskRescheduled;

  /// No description provided for @scheduleRescheduleDate.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get scheduleRescheduleDate;

  /// No description provided for @scheduleSetPriority.
  ///
  /// In en, this message translates to:
  /// **'Set Priority'**
  String get scheduleSetPriority;

  /// No description provided for @scheduleSetStatus.
  ///
  /// In en, this message translates to:
  /// **'Set Status'**
  String get scheduleSetStatus;

  /// No description provided for @scheduleStartFocus.
  ///
  /// In en, this message translates to:
  /// **'Start Focus'**
  String get scheduleStartFocus;

  /// No description provided for @scheduleUnplanned.
  ///
  /// In en, this message translates to:
  /// **'Unplanned'**
  String get scheduleUnplanned;

  /// No description provided for @scheduleFocusDuration.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String scheduleFocusDuration(int minutes);

  /// No description provided for @scheduleFocusDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h{minutes}m'**
  String scheduleFocusDurationHours(int hours, int minutes);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
