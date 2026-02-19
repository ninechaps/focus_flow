import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/database_config.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';
import '../../providers/locale_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_preferences_provider.dart';
import '../../theme/app_theme.dart';

/// Settings page - Application settings and preferences
class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _isClearing = false;

  Future<void> _showClearConfirmDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsClearConfirmTitle),
        content: Text(l10n.settingsClearConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.settingsClearConfirmButton),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _clearAllData();
    }
  }

  Future<void> _clearAllData() async {
    setState(() => _isClearing = true);

    try {
      final taskProvider = context.read<TaskProvider>();
      await taskProvider.clearAllData();

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsDataCleared), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsClearFailed('$e')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacingLg, 36, AppTheme.spacingLg, AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            l10n.settingsSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // Scrollable settings content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Appearance =====
                  _buildAppearanceSection(context),
                  const SizedBox(height: AppTheme.spacingXl),

                  // ===== Language =====
                  _buildLanguageSection(context),
                  const SizedBox(height: AppTheme.spacingXl),

                  // ===== General (startup page) =====
                  _buildGeneralSection(context),
                  const SizedBox(height: AppTheme.spacingXl),

                  // ===== Task defaults =====
                  _buildTaskDefaultsSection(context),
                  const SizedBox(height: AppTheme.spacingXl),

                  // ===== Notifications =====
                  _buildNotificationsSection(context),

                  // ===== Debug =====
                  if (DatabaseConfig.debugMode) ...[
                    const SizedBox(height: AppTheme.spacingXl),
                    _buildSectionHeader(context, l10n.settingsDebugTitle, Colors.orange, 'DEBUG'),
                    const SizedBox(height: AppTheme.spacingMd),
                    _buildDebugSection(context),
                  ],

                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, l10n.settingsAppearance, colors.primary, null),
        const SizedBox(height: AppTheme.spacingMd),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsThemeMode,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMd,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.settingsThemeHint,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeXs,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ThemeOption(
                    icon: Icons.brightness_auto,
                    label: l10n.settingsFollowSystem,
                    isSelected: themeProvider.themeMode == ThemeMode.system,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                  ),
                  const SizedBox(width: 8),
                  _ThemeOption(
                    icon: Icons.light_mode_outlined,
                    label: l10n.settingsLight,
                    isSelected: themeProvider.themeMode == ThemeMode.light,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  _ThemeOption(
                    icon: Icons.dark_mode_outlined,
                    label: l10n.settingsDark,
                    isSelected: themeProvider.themeMode == ThemeMode.dark,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSection(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, l10n.settingsLanguage, colors.primary, null),
        const SizedBox(height: AppTheme.spacingMd),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsLanguageTitle,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMd,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.settingsLanguageHint,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeXs,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ThemeOption(
                    icon: Icons.brightness_auto,
                    label: l10n.settingsLanguageSystem,
                    isSelected: localeProvider.locale == null,
                    onTap: () => localeProvider.setLocale(null),
                  ),
                  const SizedBox(width: 8),
                  _ThemeOption(
                    icon: Icons.translate,
                    label: l10n.settingsLanguageChinese,
                    isSelected: localeProvider.locale?.languageCode == 'zh',
                    onTap: () => localeProvider.setLocale(const Locale('zh')),
                  ),
                  const SizedBox(width: 8),
                  _ThemeOption(
                    icon: Icons.language,
                    label: l10n.settingsLanguageEnglish,
                    isSelected: localeProvider.locale?.languageCode == 'en',
                    onTap: () => localeProvider.setLocale(const Locale('en')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralSection(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final prefs = context.watch<UserPreferencesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, l10n.settingsGeneral, colors.primary, null),
        const SizedBox(height: AppTheme.spacingMd),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsStartupPage,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMd,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.settingsStartupPageHint,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeXs,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ThemeOption(
                    icon: Icons.list_alt_rounded,
                    label: l10n.settingsStartupList,
                    isSelected: prefs.startupPage == 'list',
                    onTap: () => prefs.setStartupPage('list'),
                  ),
                  const SizedBox(width: 8),
                  _ThemeOption(
                    icon: Icons.calendar_month_rounded,
                    label: l10n.settingsStartupSchedule,
                    isSelected: prefs.startupPage == 'schedule',
                    onTap: () => prefs.setStartupPage('schedule'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskDefaultsSection(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final prefs = context.watch<UserPreferencesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, l10n.settingsTaskDefaults, colors.primary, null),
        const SizedBox(height: AppTheme.spacingMd),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsDefaultPriority,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMd,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.settingsDefaultPriorityHint,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeXs,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ThemeOption(
                    icon: Icons.remove_circle_outline,
                    label: l10n.settingsPriorityNone,
                    isSelected: prefs.defaultPriority == null,
                    onTap: () => prefs.setDefaultPriority(null),
                  ),
                  const SizedBox(width: 8),
                  _ThemeOption(
                    icon: Icons.circle,
                    label: l10n.priorityLowShort,
                    isSelected: prefs.defaultPriority == TaskPriority.low,
                    onTap: () => prefs.setDefaultPriority(TaskPriority.low),
                    selectedColor: AppTheme.successColor,
                  ),
                  const SizedBox(width: 8),
                  _ThemeOption(
                    icon: Icons.circle,
                    label: l10n.priorityMediumShort,
                    isSelected: prefs.defaultPriority == TaskPriority.medium,
                    onTap: () => prefs.setDefaultPriority(TaskPriority.medium),
                    selectedColor: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  _ThemeOption(
                    icon: Icons.circle,
                    label: l10n.priorityHighShort,
                    isSelected: prefs.defaultPriority == TaskPriority.high,
                    onTap: () => prefs.setDefaultPriority(TaskPriority.high),
                    selectedColor: AppTheme.errorColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final prefs = context.watch<UserPreferencesProvider>();
    final reminderTime = prefs.reminderTime;

    final timeLabel =
        '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, l10n.settingsNotifications, colors.primary, null),
        const SizedBox(height: AppTheme.spacingMd),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.settingsDailyReminder,
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeMd,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.settingsDailyReminderHint,
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeXs,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: prefs.reminderEnabled,
                    onChanged: (value) => context.read<UserPreferencesProvider>().setReminderEnabled(value),
                  ),
                ],
              ),

              // Time picker row (only when enabled)
              if (prefs.reminderEnabled) ...[
                const SizedBox(height: AppTheme.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.settingsDailyReminderTime,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSm,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSm,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    TextButton(
                      onPressed: () => _pickReminderTime(context, prefs.reminderTime),
                      child: Text(l10n.settingsChangeTime),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickReminderTime(BuildContext context, TimeOfDay current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked != null && context.mounted) {
      context.read<UserPreferencesProvider>().setReminderTime(picked);
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color, String? badge) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
        if (badge != null) ...[
          const SizedBox(width: AppTheme.spacingSm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDebugSection(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  l10n.settingsDebugWarning,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsClearAllData,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.settingsClearAllDataDesc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              FilledButton.icon(
                onPressed: _isClearing ? null : _showClearConfirmDialog,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.red.withValues(alpha: 0.5),
                ),
                icon: _isClearing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.delete_forever, size: 18),
                label: Text(_isClearing ? l10n.settingsClearing : l10n.settingsClearButton),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// macOS style option button (reused for theme, language, and other settings)
class _ThemeOption extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  State<_ThemeOption> createState() => _ThemeOptionState();
}

class _ThemeOptionState extends State<_ThemeOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final activeColor = widget.selectedColor ?? colors.primary;

    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? activeColor.withValues(alpha: 0.1)
                  : _isHovered
                      ? colors.hoverBg
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: widget.isSelected
                    ? activeColor
                    : _isHovered
                        ? colors.divider
                        : Colors.transparent,
                width: widget.isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: widget.isSelected ? activeColor : colors.textSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: widget.isSelected ? activeColor : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
