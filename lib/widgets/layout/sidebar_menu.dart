import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

/// Sidebar menu with navigation items
class SidebarMenu extends StatelessWidget {
  const SidebarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current location to highlight active menu item
    final currentLocation = GoRouterState.of(context).uri.path;

    return Column(
      children: [
        _SidebarMenuItem(
          icon: Icons.list_alt_outlined,
          activeIcon: Icons.list_alt,
          label: 'List',
          route: '/app/list',
          isActive: currentLocation == '/app/list',
        ),
        const SizedBox(height: AppTheme.spacingXs),
        _SidebarMenuItem(
          icon: Icons.calendar_month_outlined,
          activeIcon: Icons.calendar_month,
          label: 'Schedule',
          route: '/app/schedule',
          isActive: currentLocation == '/app/schedule',
        ),
        const SizedBox(height: AppTheme.spacingXs),
        _SidebarMenuItem(
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
          label: 'Settings',
          route: '/app/settings',
          isActive: currentLocation == '/app/settings',
        ),
      ],
    );
  }
}

class _SidebarMenuItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isActive;

  const _SidebarMenuItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  @override
  State<_SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<_SidebarMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = widget.isActive || _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppTheme.primaryColor.withValues(alpha: 0.12)
                : _isHovered
                    ? AppTheme.primaryColor.withValues(alpha: 0.06)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isHighlighted ? widget.activeIcon : widget.icon,
                size: 18,
                color: widget.isActive
                    ? AppTheme.primaryColor
                    : isHighlighted
                        ? AppTheme.primaryColor.shade600
                        : AppTheme.textSecondary,
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                  color: widget.isActive
                      ? AppTheme.primaryColor
                      : isHighlighted
                          ? AppTheme.primaryColor.shade600
                          : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
