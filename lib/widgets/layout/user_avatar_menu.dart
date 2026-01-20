import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// User avatar with popup menu for Profile, Settings, Statistics, Logout
class UserAvatarMenu extends StatelessWidget {
  const UserAvatarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final username = user?.username ?? 'User';
        final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

        return PopupMenuButton<String>(
          offset: const Offset(60, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          tooltip: 'User menu',
          onSelected: (value) => _handleMenuSelection(context, value),
          itemBuilder: (context) => [
            _buildMenuItem(
              value: 'profile',
              icon: Icons.person_outline,
              label: 'Profile',
            ),
            _buildMenuItem(
              value: 'settings',
              icon: Icons.settings_outlined,
              label: 'Settings',
            ),
            _buildMenuItem(
              value: 'statistics',
              icon: Icons.bar_chart_outlined,
              label: 'Statistics',
            ),
            const PopupMenuDivider(),
            _buildMenuItem(
              value: 'logout',
              icon: Icons.logout,
              label: 'Logout',
              isDestructive: true,
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryColor.shade300,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMd,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: 56,
                child: Text(
                  username,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeXs,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppTheme.errorColor : AppTheme.textPrimary;

    return PopupMenuItem<String>(
      value: value,
      height: 36,
      child: Row(
        children: [
          Icon(icon, size: AppTheme.iconSizeMd, color: color),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTheme.fontSizeSm,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'profile':
        context.go('/app/profile');
        break;
      case 'settings':
        context.go('/app/settings');
        break;
      case 'statistics':
        context.go('/app/statistics');
        break;
      case 'logout':
        _handleLogout(context);
        break;
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (context.mounted) {
      context.go('/login');
    }
  }
}
