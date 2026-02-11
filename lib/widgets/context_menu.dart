import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// ContextMenu - 右键菜单组件 (优化版)
/// ============================================================================

/// 菜单项数据模型
class ContextMenuItem<T> {
  final String label;
  final IconData? icon;
  final T value;
  final bool isDangerous;
  final bool enabled;
  final String? shortcut;
  final bool showArrow;

  const ContextMenuItem({
    required this.label,
    required this.value,
    this.icon,
    this.isDangerous = false,
    this.enabled = true,
    this.shortcut,
    this.showArrow = false,
  });
}

/// 菜单分组
class ContextMenuGroup<T> {
  final List<ContextMenuItem<T>> items;

  const ContextMenuGroup({required this.items});
}

/// 屏障上右键点击时的返回值，携带点击位置
class ContextMenuSecondaryTap {
  final Offset position;
  const ContextMenuSecondaryTap(this.position);
}

/// 右键菜单组件
class ContextMenu<T> {
  /// 显示右键菜单
  ///
  /// 返回值可能是：
  /// - T: 用户选择了菜单项
  /// - null: 用户点击空白区域关闭菜单
  /// - ContextMenuSecondaryTap: 用户在屏障上右键点击，携带新位置
  static Future<Object?> show<T>({
    required BuildContext context,
    required List<ContextMenuGroup<T>> groups,
    required Offset position,
  }) {
    return showGeneralDialog<Object>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 100),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _MenuContainer<T>(
          position: position,
          groups: groups,
          onSelected: (value) {
            Navigator.of(context).pop(value);
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

/// 菜单容器 Widget - 使用 Stack 和 Positioned 精确控制位置
class _MenuContainer<T> extends StatefulWidget {
  final Offset position;
  final List<ContextMenuGroup<T>> groups;
  final Function(T) onSelected;

  const _MenuContainer({
    required this.position,
    required this.groups,
    required this.onSelected,
  });

  @override
  State<_MenuContainer<T>> createState() => _MenuContainerState<T>();
}

class _MenuContainerState<T> extends State<_MenuContainer<T>> {
  late GlobalKey<State<_MenuItemsPanel<T>>> _menuKey;

  @override
  void initState() {
    super.initState();
    _menuKey = GlobalKey();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 背景点击区域 - 左键关闭菜单，右键带位置返回
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          onSecondaryTapUp: (details) {
            Navigator.of(context).pop(ContextMenuSecondaryTap(details.globalPosition));
          },
          child: Container(color: Colors.transparent),
        ),
        // 菜单面板
        Positioned(
          left: widget.position.dx,
          top: widget.position.dy,
          child: GestureDetector(
            onTap: () {}, // 防止点击菜单本身时触发背景的 onTap
            child: IntrinsicWidth(
              child: _MenuItemsPanel<T>(
                key: _menuKey,
                groups: widget.groups,
                onSelected: widget.onSelected,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 菜单项面板
class _MenuItemsPanel<T> extends StatefulWidget {
  final List<ContextMenuGroup<T>> groups;
  final Function(T) onSelected;

  const _MenuItemsPanel({
    super.key,
    required this.groups,
    required this.onSelected,
  });

  @override
  State<_MenuItemsPanel<T>> createState() => _MenuItemsPanelState<T>();
}

class _MenuItemsPanelState<T> extends State<_MenuItemsPanel<T>> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(
          color: colors.divider,
          width: 0.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: colors.divider,
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int groupIndex = 0; groupIndex < widget.groups.length; groupIndex++) ...{
                if (groupIndex > 0)
                  Container(
                    height: 0.5,
                    color: colors.divider,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                for (final item in widget.groups[groupIndex].items)
                  _MenuItem<T>(
                    item: item,
                    onTap: item.enabled
                        ? () {
                            widget.onSelected(item.value);
                          }
                        : null,
                  ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

/// 单个菜单项
class _MenuItem<T> extends StatefulWidget {
  final ContextMenuItem<T> item;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.item,
    required this.onTap,
  });

  @override
  State<_MenuItem<T>> createState() => _MenuItemState<T>();
}

class _MenuItemState<T> extends State<_MenuItem<T>> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isHovered ? _scaleAnimation.value : 1.0,
          child: MouseRegion(
            cursor: !widget.item.enabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
            onEnter: (_) {
              setState(() => _isHovered = true);
              _animationController.forward();
            },
            onExit: (_) {
              setState(() => _isHovered = false);
              _animationController.reverse();
            },
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: _getBackgroundColor(colors, _isHovered),
                  borderRadius: BorderRadius.zero,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (widget.item.icon != null) ...{
                      Icon(
                        widget.item.icon,
                        size: AppTheme.iconSizeMd,
                        color: _getIconColor(colors, _isHovered),
                      ),
                      const SizedBox(width: 10),
                    },
                    Expanded(
                      child: Text(
                        widget.item.label,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSm,
                          color: _getTextColor(colors, _isHovered),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (widget.item.shortcut != null || widget.item.showArrow) ...{
                      const SizedBox(width: 12),
                      if (widget.item.shortcut != null)
                        Text(
                          widget.item.shortcut!,
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeXs,
                            color: colors.textHint,
                            fontWeight: FontWeight.normal,
                          ),
                        )
                      else if (widget.item.showArrow)
                        Icon(
                          Icons.chevron_right,
                          size: AppTheme.iconSizeMd,
                          color: colors.textHint,
                        ),
                    },
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(AppColors colors, bool isHovered) {
    if (!widget.item.enabled) return Colors.transparent;
    return isHovered ? colors.primary.withValues(alpha: 0.08) : Colors.transparent;
  }

  Color _getTextColor(AppColors colors, bool isHovered) {
    if (!widget.item.enabled) return colors.textHint;
    if (widget.item.isDangerous) {
      return isHovered ? colors.error : colors.error.withValues(alpha: 0.8);
    }
    return isHovered ? colors.primary : colors.textPrimary;
  }

  Color _getIconColor(AppColors colors, bool isHovered) {
    if (!widget.item.enabled) return colors.textHint;
    if (widget.item.isDangerous) {
      return isHovered ? colors.error : colors.error.withValues(alpha: 0.8);
    }
    return isHovered ? colors.primary : colors.textSecondary;
  }
}
