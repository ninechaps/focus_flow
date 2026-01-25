import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// ContextMenu - 右键菜单组件
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

/// 右键菜单组件
class ContextMenu<T> {
  /// 显示右键菜单
  static Future<T?> show<T>({
    required BuildContext context,
    required List<ContextMenuGroup<T>> groups,
    required Offset position,
  }) {
    return showGeneralDialog<T>(
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
        // 背景点击区域 - 点击任何地方都可以关闭菜单
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
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
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int groupIndex = 0; groupIndex < widget.groups.length; groupIndex++) ...{
              if (groupIndex > 0)
                Container(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.1),
                  margin: const EdgeInsets.symmetric(vertical: 4),
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

class _MenuItemState<T> extends State<_MenuItem<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: !widget.item.enabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: _getBackgroundColor(_isHovered),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (widget.item.icon != null) ...{
                Icon(
                  widget.item.icon,
                  size: 16,
                  color: _getIconColor(_isHovered),
                ),
                const SizedBox(width: 10),
              },
              Text(
                widget.item.label,
                style: TextStyle(
                  fontSize: 13,
                  color: _getTextColor(_isHovered),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.item.shortcut != null || widget.item.showArrow) ...{
                const SizedBox(width: 16),
                if (widget.item.shortcut != null)
                  Text(
                    widget.item.shortcut!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textHint,
                      fontWeight: FontWeight.normal,
                    ),
                  )
                else if (widget.item.showArrow)
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppTheme.textHint,
                  ),
              },
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isHovered) {
    if (!widget.item.enabled) return Colors.transparent;
    return isHovered ? AppTheme.primaryColor.withValues(alpha: 0.08) : Colors.transparent;
  }

  Color _getTextColor(bool isHovered) {
    if (!widget.item.enabled) return AppTheme.textHint;
    if (widget.item.isDangerous) {
      return isHovered ? const Color(0xFFDC2626) : const Color(0xFFEF4444);
    }
    return isHovered ? AppTheme.primaryColor : AppTheme.textPrimary;
  }

  Color _getIconColor(bool isHovered) {
    if (!widget.item.enabled) return AppTheme.textHint;
    if (widget.item.isDangerous) {
      return isHovered ? const Color(0xFFDC2626) : const Color(0xFFEF4444);
    }
    return isHovered ? AppTheme.primaryColor : AppTheme.textSecondary;
  }
}
