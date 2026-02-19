import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// Profile page - User profile information with account details and sign-out
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
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg,
            36,
            AppTheme.spacingLg,
            AppTheme.spacingLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page header
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

              // Content area with max width constraint and scrollable
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Avatar + Name Card ---
                          _buildIdentityCard(context, user, l10n, colors),

                          const SizedBox(height: AppTheme.spacingLg),

                          // --- Account Info Card ---
                          _buildAccountInfoCard(context, user, l10n, colors),

                          const SizedBox(height: AppTheme.spacingXl),

                          // --- Sign Out Button ---
                          Align(
                            alignment: Alignment.centerRight,
                            child: _SignOutButton(authProvider: authProvider, l10n: l10n),
                          ),
                        ],
                      ),
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

  Widget _buildIdentityCard(
    BuildContext context,
    dynamic user,
    AppLocalizations l10n,
    dynamic colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
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
                user?.username?.isNotEmpty == true
                    ? user!.username![0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeDisplay,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingLg),
          // Name and email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.username ?? l10n.profileUnknownUser,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? l10n.profileNoEmail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(
    BuildContext context,
    dynamic user,
    AppLocalizations l10n,
    dynamic colors,
  ) {
    final isEmailVerified = user?.emailVerifiedAt != null;
    final totalSeconds = user?.totalOnlineTime ?? 0;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Text(
          l10n.profileAccountInfo,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingMd,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            children: [
              // Member since
              if (user?.createdAt != null) ...[
                _InfoRow(
                  label: l10n.profileMemberSince,
                  value: _formatDate(user!.createdAt!),
                  colors: colors,
                  context: context,
                ),
                _Divider(colors: colors),
              ],
              // Last login
              if (user?.lastLoginAt != null) ...[
                _InfoRow(
                  label: l10n.profileLastLogin(''),
                  labelRaw: true,
                  labelText: _lastLoginLabel(l10n),
                  value: _formatDateTime(user!.lastLoginAt!),
                  colors: colors,
                  context: context,
                ),
                _Divider(colors: colors),
              ],
              // Email verified
              _InfoRow(
                label: l10n.profileEmailVerified,
                value: isEmailVerified ? l10n.profileVerified : l10n.profileNotVerified,
                valueColor: isEmailVerified ? Colors.green : Colors.orange,
                trailingIcon: isEmailVerified ? Icons.verified_rounded : Icons.warning_amber_rounded,
                trailingIconColor: isEmailVerified ? Colors.green : Colors.orange,
                colors: colors,
                context: context,
              ),
              // Registration source
              if (user?.registrationSource != null) ...[
                _Divider(colors: colors),
                _InfoRow(
                  label: l10n.profileRegistrationSource,
                  value: user!.registrationSource!,
                  colors: colors,
                  context: context,
                ),
              ],
              // Total online time
              if (totalSeconds > 0) ...[
                _Divider(colors: colors),
                _InfoRow(
                  label: l10n.profileTotalOnlineTime,
                  value: l10n.profileOnlineTimeFormat(hours, minutes),
                  colors: colors,
                  context: context,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _lastLoginLabel(AppLocalizations l10n) {
    // Extract the prefix before the time placeholder
    final template = l10n.profileLastLogin('');
    return template.replaceAll(': ', '').trim();
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// A single labeled row inside the account info card
class _InfoRow extends StatelessWidget {
  final String label;
  final bool labelRaw;
  final String? labelText;
  final String value;
  final Color? valueColor;
  final IconData? trailingIcon;
  final Color? trailingIconColor;
  final dynamic colors;
  final BuildContext context;

  const _InfoRow({
    required this.label,
    this.labelRaw = false,
    this.labelText,
    required this.value,
    this.valueColor,
    this.trailingIcon,
    this.trailingIconColor,
    required this.colors,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final displayLabel = labelRaw ? (labelText ?? label) : label;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              displayLabel,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ),
          if (trailingIcon != null) ...[
            Icon(trailingIcon, size: 16, color: trailingIconColor),
            const SizedBox(width: 4),
          ],
          Text(
            value,
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? colors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final dynamic colors;

  const _Divider({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: colors.divider);
  }
}

/// Red outlined sign-out button with confirmation dialog
class _SignOutButton extends StatefulWidget {
  final AuthProvider authProvider;
  final AppLocalizations l10n;

  const _SignOutButton({
    required this.authProvider,
    required this.l10n,
  });

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
  bool _isLoading = false;

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.l10n.profileLogoutConfirmTitle),
        content: Text(widget.l10n.profileLogoutConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(widget.l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(widget.l10n.profileLogout),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await widget.authProvider.logout();
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLg,
          vertical: AppTheme.spacingMd,
        ),
      ),
      onPressed: _isLoading ? null : _handleSignOut,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
            )
          : const Icon(Icons.logout_rounded, size: 18),
      label: Text(l10n.profileLogout),
    );
  }
}
