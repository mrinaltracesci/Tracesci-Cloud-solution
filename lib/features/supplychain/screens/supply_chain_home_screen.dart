import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../../auth/providers/auth_provider.dart';
import '../../scanner/screens/scanner_screen.dart';
import '../models/supply_chain_models.dart';
import '../providers/supply_chain_provider.dart';
import 'chain_activity_screen.dart';
import 'chain_alerts_screen.dart';
import 'consignment_detail_screen.dart';
import 'consignments_screen.dart';

class SupplyChainHomeScreen extends StatefulWidget {
  const SupplyChainHomeScreen({super.key});

  @override
  State<SupplyChainHomeScreen> createState() => _SupplyChainHomeScreenState();
}

class _SupplyChainHomeScreenState extends State<SupplyChainHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SupplyChainProvider>();
      provider.loadDashboard();
      provider.ensureMasters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<SupplyChainProvider>();
    final dashboard = provider.dashboard;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => provider.loadDashboard(refresh: true),
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(auth, dashboard)),
            if (provider.isLoading && dashboard == null)
              const SliverToBoxAdapter(child: DashboardSkeleton())
            else if (provider.isError && dashboard == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(
                  message: provider.errorMessage,
                  isNetwork: provider.isNetworkError,
                  onRetry: () => provider.loadDashboard(),
                ),
              )
            else if (dashboard != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    StatGrid(
                      tiles: dashboard.stats,
                      onTileTap: (tile) {
                        if (tile.filter == null) return;
                        provider.setFilter(tile.filter!);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ConsignmentsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    if (dashboard.alertsOpen > 0) _alertBanner(dashboard),
                    if (dashboard.alertsOpen > 0) const SizedBox(height: 22),
                    SectionHeader(
                      title: 'Recent activity',
                      actionLabel: dashboard.activity.isEmpty ? null : 'See all',
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ChainActivityScreen(),
                        ),
                      ),
                    ),
                    if (dashboard.activity.isEmpty)
                      _emptyActivity()
                    else
                      ...dashboard.activity.map(_activityTile),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(AuthProvider auth, SupplyChainDashboard? dashboard) {
    final node = auth.profile.supplyChain;

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
                      auth.profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      node?.nodeRole ?? 'Supply chain',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ChainAlertsScreen(),
                  ),
                ),
                child: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          GestureDetector(
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
                          'Scan a shipment',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Receive or dispatch in one tap',
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
          ),
        ],
      ),
    );
  }

  Widget _alertBanner(SupplyChainDashboard dashboard) {
    return AppCard(
      color: AppColors.dangerSoft,
      shadow: const [],
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChainAlertsScreen()),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dashboard.alertsOpen} warning${dashboard.alertsOpen == 1 ? '' : 's'} logged',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Scans recorded at an unexpected point in the chain',
                  style: AppTextStyles.bodySmall,
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
    );
  }

  Widget _activityTile(ChainActivity activity) {
    final isCheckout = activity.action.toLowerCase() == 'checkout';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConsignmentDetailScreen(code: activity.code),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: (isCheckout ? AppColors.warning : AppColors.success)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isCheckout
                    ? Icons.local_shipping_rounded
                    : Icons.inventory_2_rounded,
                color: isCheckout ? AppColors.warning : AppColors.success,
                size: 21,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${activity.code} · ${activity.createdAgo}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (activity.verified)
              const Icon(
                Icons.verified_rounded,
                size: 18,
                color: AppColors.success,
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyActivity() {
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
              Icons.local_shipping_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text('No movements yet', style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Scan a carton or pallet to record your first check-in.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
