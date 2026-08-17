import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../../auth/providers/auth_provider.dart';
import '../../rewards/screens/rewards_screen.dart';
import '../../scanner/screens/scanner_screen.dart';
import '../models/consumer_models.dart';
import '../providers/consumer_provider.dart';
import 'notifications_screen.dart';
import 'report_product_screen.dart';
import 'scan_detail_screen.dart';
import 'scan_history_screen.dart';

class ConsumerHomeScreen extends StatefulWidget {
  const ConsumerHomeScreen({super.key});

  @override
  State<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends State<ConsumerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsumerProvider>().loadHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ConsumerProvider>();
    final home = provider.home;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => provider.loadHome(refresh: true),
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(auth)),
            if (provider.isLoading && home == null)
              const SliverToBoxAdapter(child: DashboardSkeleton())
            else if (provider.isError && home == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(
                  message: provider.errorMessage,
                  isNetwork: provider.isNetworkError,
                  onRetry: () => provider.loadHome(),
                ),
              )
            else if (home != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    StatGrid(tiles: home.stats),
                    const SizedBox(height: 24),
                    _walletCard(home.wallet),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: 'Recent scans',
                      actionLabel: home.recentScans.isEmpty ? null : 'See all',
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ScanHistoryScreen(),
                        ),
                      ),
                    ),
                    if (home.recentScans.isEmpty)
                      _emptyScans()
                    else
                      ...home.recentScans.map(_scanTile),
                    if (home.highlights.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'From TraceSci'),
                      SizedBox(
                        height: 196,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: home.highlights.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) =>
                              _highlightCard(home.highlights[index]),
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(AuthProvider auth) {
    final home = context.watch<ConsumerProvider>().home;

    return GradientHeader(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.28)),
                ),
                alignment: Alignment.center,
                child: Text(
                  auth.profile.initials,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.theming.greeting,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.78),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      auth.profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              _headerAction(
                icon: Icons.notifications_rounded,
                badge: home?.openReports ?? 0,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _scanPrompt(),
          const SizedBox(height: 16),
          _quickActions(auth),
        ],
      ),
    );
  }

  Widget _headerAction({
    required IconData icon,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          if (badge > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1.4),
                ),
                child: Text(
                  '$badge',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _scanPrompt() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ScannerScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan a product',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Check authenticity in seconds',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.78),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(AuthProvider auth) {
    final actions = auth.quickActions;

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (final action in actions.where((a) => !a.primary)) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => _handleQuickAction(action.key),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Column(
                  children: [
                    Icon(
                      AppIcons.resolve(action.icon),
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      action.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _handleQuickAction(String key) {
    switch (key) {
      case 'rewards':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RewardsScreen()),
        );
        break;
      case 'report':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReportProductScreen()),
        );
        break;
      case 'scan':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ScannerScreen()),
        );
        break;
      default:
        Notify.info(context, 'Coming soon');
    }
  }

  Widget _walletCard(WalletSnapshot wallet) {
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RewardsScreen()),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.warning,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Points', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      Formats.points(wallet.totalPoints),
                      style: AppTextStyles.metric,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
          if (wallet.brands.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final brand in wallet.brands)
                  StatusChip(
                    label: '${brand.brand} · ${Formats.points(brand.points)}',
                    tone: StatusTone.primary,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _scanTile(ScanCard scan) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScanDetailScreen(scanId: scan.scanId),
          ),
        ),
        child: Row(
          children: [
            AppImage(url: scan.image, width: 52, height: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    scan.brand ?? scan.scannedAgo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            StatusChip(
              label: scan.statusLabel,
              tone: scan.genuine ? StatusTone.success : StatusTone.danger,
              icon: scan.genuine
                  ? Icons.verified_rounded
                  : Icons.error_outline_rounded,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyScans() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text('No scans yet', style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Scan your first product to check whether it is genuine.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _highlightCard(Highlight highlight) {
    return SizedBox(
      width: 240,
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppImage(
              url: highlight.image,
              width: 240,
              height: 96,
              radius: BorderRadius.zero,
              placeholderIcon: Icons.article_rounded,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    highlight.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    highlight.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
