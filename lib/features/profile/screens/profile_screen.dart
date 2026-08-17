import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/surfaces.dart';
import '../../auth/providers/auth_provider.dart';
import '../../alerts/screens/alerts_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../consumer/screens/reports_screen.dart';
import '../../consumer/screens/scan_history_screen.dart';
import '../../shell/models/bootstrap.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !embedded,
        title: const Text('Profile'),
      ),
      body: RefreshIndicator(
        onRefresh: () => auth.loadBootstrap(),
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _identityCard(context, profile, auth),
            const SizedBox(height: 20),
            if (profile.company != null) ...[
              const SectionHeader(title: 'Company'),
              AppCard(
                child: Column(
                  children: [
                    InfoRow(
                      label: 'Name',
                      value: profile.company!.name,
                      icon: Icons.business_rounded,
                    ),
                    if (profile.company!.gst != null)
                      InfoRow(
                        label: 'GST',
                        value: profile.company!.gst!,
                        icon: Icons.receipt_rounded,
                      ),
                    if (profile.company!.address != null)
                      InfoRow(
                        label: 'Address',
                        value: profile.company!.address!,
                        icon: Icons.location_on_rounded,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (profile.supplyChain != null) ...[
              const SectionHeader(title: 'Supply chain node'),
              AppCard(
                child: Column(
                  children: [
                    InfoRow(
                      label: 'Role',
                      value: profile.supplyChain!.nodeRole,
                      icon: Icons.badge_rounded,
                    ),
                    InfoRow(
                      label: 'Reports to',
                      value: profile.supplyChain!.parent ?? 'Brand owner',
                      icon: Icons.account_tree_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            const SectionHeader(title: 'Account'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _menuTile(
                    context,
                    icon: Icons.history_rounded,
                    label: 'My scans',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ScanHistoryScreen(),
                      ),
                    ),
                  ),
                  const Divider(indent: 58),
                  _menuTile(
                    context,
                    icon: Icons.notifications_active_outlined,
                    label: 'Alerts',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AlertsScreen()),
                    ),
                  ),
                  const Divider(indent: 58),
                  _menuTile(
                    context,
                    icon: Icons.person_outline_rounded,
                    label: 'Edit profile',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ),
                  ),
                  if (auth.capabilities.reportProduct) ...[
                    const Divider(indent: 58),
                    _menuTile(
                      context,
                      icon: Icons.flag_outlined,
                      label: 'My reports',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ReportsScreen(),
                        ),
                      ),
                    ),
                  ],
                  const Divider(indent: 58),
                  _menuTile(
                    context,
                    icon: Icons.help_outline_rounded,
                    label: 'Help and support',
                    onTap: () => Notify.info(context, 'Coming soon'),
                  ),
                  const Divider(indent: 58),
                  _menuTile(
                    context,
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy policy',
                    onTap: () => Notify.info(context, 'Coming soon'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Sign out',
              icon: Icons.logout_rounded,
              variant: AppButtonVariant.ghost,
              onPressed: () => _confirmLogout(context, auth),
            ),
            if (auth.role == UserRole.consumer) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _confirmDelete(context, auth),
                child: Text(
                  'Delete my account',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: Text(
                'TraceSci v${AppConfig.appVersion}',
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identityCard(
    BuildContext context,
    UserProfile profile,
    AuthProvider auth,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            alignment: Alignment.center,
            child: Text(
              profile.initials,
              style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                if (profile.displayPhone.isNotEmpty)
                  Text(
                    profile.displayPhone,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                if (profile.email != null && profile.email!.isNotEmpty)
                  Text(
                    profile.email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    profile.roleLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 19, color: AppColors.textSecondary),
      ),
      title: Text(label, style: AppTextStyles.bodyLarge),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to log in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Sign out',
              style: AppTextStyles.button.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await auth.logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmDelete(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This removes your profile, scan history and reward points. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep account'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
              style: AppTextStyles.button.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final done = await auth.deleteAccount();

    if (!context.mounted) return;

    if (!done) {
      Notify.error(context, auth.error);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
