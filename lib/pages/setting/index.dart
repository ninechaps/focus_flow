import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/database_config.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有数据'),
        content: const Text(
          '这将永久删除所有任务、标签和目标。\n'
          '此操作不可撤销。\n\n'
          '确定要继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清除全部'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据已全部清除'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清除数据失败: $e'), backgroundColor: Colors.red),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacingLg, 36, AppTheme.spacingLg, AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '设置',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '管理应用偏好设置',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // ===== 外观设置 =====
          _buildAppearanceSection(context),

          const SizedBox(height: AppTheme.spacingXl),

          // Debug section
          if (DatabaseConfig.debugMode) ...[
            _buildSectionHeader(context, '开发者选项', Colors.orange, 'DEBUG'),
            const SizedBox(height: AppTheme.spacingMd),
            _buildDebugSection(context),
            const SizedBox(height: AppTheme.spacingXl),
          ],

          // Placeholder
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings_outlined, size: 64, color: colors.textHint),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    '更多设置即将上线',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
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
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '外观', colors.primary, null),
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
                '主题模式',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMd,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '选择应用的外观主题',
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
                    label: '跟随系统',
                    isSelected: themeProvider.themeMode == ThemeMode.system,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                  ),
                  const SizedBox(width: 8),
                  _ThemeOption(
                    icon: Icons.light_mode_outlined,
                    label: '浅色',
                    isSelected: themeProvider.themeMode == ThemeMode.light,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  _ThemeOption(
                    icon: Icons.dark_mode_outlined,
                    label: '深色',
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
                  '以下选项仅用于测试，发布前将移除。',
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
                      '清除所有数据',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '删除数据库中的所有任务、标签和目标',
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
                label: Text(_isClearing ? '清除中...' : '清除'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// macOS 风格主题选项按钮
class _ThemeOption extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ThemeOption> createState() => _ThemeOptionState();
}

class _ThemeOptionState extends State<_ThemeOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
                  ? colors.primaryLight
                  : _isHovered
                      ? colors.hoverBg
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: widget.isSelected
                    ? colors.primary
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
                  color: widget.isSelected ? colors.primary : colors.textSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: widget.isSelected ? colors.primary : colors.textSecondary,
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
