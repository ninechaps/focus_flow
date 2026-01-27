import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// ============================================================================
/// Professional Dialog Design System
///
/// 采用项目标准的紧凑桌面布局，确保与整个应用的美感一致
/// ============================================================================

// ===== 颜色系统 =====
class _DialogColors {
  static const Color background = AppTheme.backgroundColor;
  static const Color surface = AppTheme.surfaceColor;
  static const Color primary = Color(0xFF6366F1); // Indigo-500
  static const Color textPrimary = AppTheme.textPrimary;
  static const Color textSecondary = AppTheme.textSecondary;
  static const Color border = AppTheme.dividerColor;
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color error = AppTheme.errorColor;
}

// ===== 间距系统（遵循项目标准）=====
class _DialogSpacing {
  static const double md = AppTheme.spacingMd; // 10.0
  static const double lg = AppTheme.spacingLg; // 14.0
}

// ===== 圆角系统 =====
class _DialogRadius {
  static const double md = AppTheme.radiusMd; // 6.0
  static const double lg = AppTheme.radiusLg; // 8.0
}

// ===== 排版系统 =====
class _DialogTypography {
  static const TextStyle titleStyle = TextStyle(
    fontSize: 16, // 16px - 对话框标题（适中）
    fontWeight: FontWeight.w600,
    color: _DialogColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 12, // 12px - 副标题
    fontWeight: FontWeight.normal,
    color: _DialogColors.textSecondary,
    height: 1.3,
  );
}

/// ============================================================================
/// DialogBox - 对话框容器
/// ============================================================================

class DialogBox extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final String? subtitle;
  final VoidCallback? onClose;
  final double? width;

  const DialogBox({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.subtitle,
    this.onClose,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: width ?? 460,
        decoration: BoxDecoration(
          color: _DialogColors.surface,
          borderRadius: BorderRadius.circular(_DialogRadius.lg),
          boxShadow: [
            BoxShadow(
              color: const Color(0x1A000000),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0x0A000000),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _DialogSpacing.lg,
                vertical: _DialogSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: _DialogTypography.titleStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: _DialogTypography.subtitleStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onClose != null) ...[
                    const SizedBox(width: _DialogSpacing.md),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _DialogColors.borderLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: _DialogColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: _DialogSpacing.lg),
              color: _DialogColors.border,
            ),

            // Content
            SingleChildScrollView(
              padding: const EdgeInsets.all(_DialogSpacing.lg),
              child: content,
            ),

            // Actions
            Container(
              height: 1,
              color: _DialogColors.border,
            ),
            Padding(
              padding: const EdgeInsets.all(_DialogSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: _DialogSpacing.md),
                    actions[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// DialogButton - 对话框按钮
/// ============================================================================

class DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const DialogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDestructive
        ? _DialogColors.error
        : isPrimary
            ? _DialogColors.primary
            : _DialogColors.background;
    final foregroundColor =
        isDestructive || isPrimary ? Colors.white : _DialogColors.textPrimary;
    final borderColor = isPrimary || isDestructive
        ? Colors.transparent
        : _DialogColors.border;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_DialogRadius.md),
          side: BorderSide(color: borderColor),
        ),
        elevation: 0,
        minimumSize: const Size(0, 38), // 统一高度标准
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: AppTheme.fontSizeSm,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

