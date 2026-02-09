import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// Profile page - User profile information
/// TODO: Implement actual profile editing functionality
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final l10n = AppLocalizations.of(context)!;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        return Padding(
          padding: const EdgeInsets.fromLTRB(AppTheme.spacingLg, 36, AppTheme.spacingLg, AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.profileTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                l10n.profileSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingXl),
              Expanded(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(AppTheme.spacingXl),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: colors.divider),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor.shade300,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              user?.username.isNotEmpty == true
                                  ? user!.username[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeDisplay,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        // Username
                        Text(
                          user?.username ?? l10n.profileUnknownUser,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        // Email
                        Text(
                          user?.email ?? l10n.profileNoEmail,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        // Last login
                        if (user?.lastLoginTime != null)
                          Text(
                            l10n.profileLastLogin(_formatDateTime(user!.lastLoginTime!)),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.textHint,
                                ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
