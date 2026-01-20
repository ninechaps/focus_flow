import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'window_controls.dart';
import 'user_avatar_menu.dart';
import 'sidebar_menu.dart';

/// Main sidebar widget containing window controls, user avatar, and navigation menu
class Sidebar extends StatelessWidget {
  /// Width of the sidebar
  static const double width = 68.0;

  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          right: BorderSide(
            color: AppTheme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Window controls at the top
          const WindowControls(),

          const SizedBox(height: AppTheme.spacingXl),

          // User avatar with popup menu
          const UserAvatarMenu(),

          const SizedBox(height: AppTheme.spacingMd),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
            child: Divider(
              height: 1,
              color: AppTheme.dividerColor,
            ),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Navigation menu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
            child: const SidebarMenu(),
          ),

          const Spacer(),

          // App version at bottom (optional)
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            child: Text(
              'v1.0',
              style: TextStyle(
                fontSize: AppTheme.fontSizeXs,
                color: AppTheme.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
