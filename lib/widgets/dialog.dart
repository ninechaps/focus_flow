import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// ============================================================================
/// Professional Dialog Design System
///
/// 采用项目标准的紧凑桌面布局，确保与整个应用的美感一致
/// ============================================================================

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
    final colors = context.appColors;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: width ?? 460,
        decoration: BoxDecoration(
          color: colors.dialogSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: colors.dialogBorder,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
                vertical: AppTheme.spacingMd,
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: colors.textSecondary,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onClose != null) ...[
                    const SizedBox(width: AppTheme.spacingMd),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: colors.hoverBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 12,
                            color: colors.textSecondary,
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
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
              color: colors.divider,
            ),

            // Content
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: content,
            ),

            // Actions
            Container(
              height: 1,
              color: colors.divider,
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppTheme.spacingMd),
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
    final colors = context.appColors;

    final bgColor = isDestructive
        ? colors.error
        : isPrimary
            ? colors.primary
            : colors.background;
    final fgColor =
        isDestructive || isPrimary ? Colors.white : colors.textPrimary;
    final borderColor = isPrimary || isDestructive
        ? Colors.transparent
        : colors.divider;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(color: borderColor),
        ),
        elevation: 0,
        minimumSize: const Size(0, 38),
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
