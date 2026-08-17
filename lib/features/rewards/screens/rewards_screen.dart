import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../models/reward_models.dart';
import '../providers/reward_provider.dart';
import 'reward_catalog_screen.dart';
import 'reward_ledger_screen.dart';
import 'reward_orders_screen.dart';

class RewardsScreen extends StatefulWidget {
  final bool embedded;

  const RewardsScreen({super.key, this.embedded = false});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RewardProvider>().loadSummary();
    });
  }

  Future<void> _openCouponSheet() async {
    final controller = TextEditingController();
    final provider = context.read<RewardProvider>();
    var busy = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> submit() async {
            if (controller.text.trim().isEmpty) return;

            setSheetState(() => busy = true);

            try {
              final result = await provider.redeemCoupon(
                controller.text.trim(),
              );
              if (!sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
              if (!mounted) return;
              Notify.success(
                context,
                'Added ${Formats.points(result.pointsAdded)} points to your wallet.',
              );
            } on ApiException catch (failure) {
              setSheetState(() => busy = false);
              if (!sheetContext.mounted) return;
              Notify.error(sheetContext, failure.message);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Redeem a coupon', style: AppTextStyles.headingMedium),
                const SizedBox(height: 6),
                Text(
                  'Enter the code printed under the product label.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'e.g. TRC4X9K2',
                    prefixIcon: Icon(Icons.confirmation_number_rounded),
                  ),
                ),
                const SizedBox(height: 22),
                AppButton(
                  label: 'Redeem',
                  loading: busy,
                  onPressed: submit,
                ),
              ],
            ),
          );
        },
      ),
    );

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RewardProvider>();
    final summary = provider.summary;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('Rewards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Points history',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RewardLedgerScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadSummary(refresh: true),
        color: AppColors.primary,
        child: provider.isLoading && summary == null
            ? const DashboardSkeleton()
            : provider.isError && summary == null
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: ErrorView(
                          message: provider.errorMessage,
                          isNetwork: provider.isNetworkError,
                          onRetry: () => provider.loadSummary(),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _balanceCard(summary),
                      const SizedBox(height: 16),
                      _actionRow(),
                      const SizedBox(height: 24),
                      if (summary != null && summary.brands.isNotEmpty) ...[
                        const SectionHeader(title: 'Points by brand'),
                        ...summary.brands.map(_brandTile),
                        const SizedBox(height: 20),
                      ],
                      SectionHeader(
                        title: 'Recent activity',
                        actionLabel: 'View all',
                        onAction: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RewardLedgerScreen(),
                          ),
                        ),
                      ),
                      if (summary == null || summary.recent.isEmpty)
                        AppCard(
                          padding: const EdgeInsets.symmetric(vertical: 26),
                          child: Center(
                            child: Text(
                              'No points earned yet. Scan a product to start.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        )
                      else
                        ...summary.recent.map(_ledgerTile),
                    ],
                  ),
      ),
    );
  }

  Widget _balanceCard(RewardSummary? summary) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Available balance',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.82),
                ),
              ),
              const Spacer(),
              if (summary != null && summary.pendingOrders > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${summary.pendingOrders} pending',
                    style: AppTextStyles.caption.copyWith(color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formats.points(summary?.balance ?? 0),
                style: AppTextStyles.displayLarge.copyWith(
                  color: Colors.white,
                  fontSize: 40,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'points',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.82),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _balanceStat('Earned', summary?.lifetimeEarned ?? 0),
              Container(
                height: 30,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                color: Colors.white.withOpacity(0.24),
              ),
              _balanceStat('Redeemed', summary?.lifetimeSpent ?? 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceStat(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Formats.points(value),
          style: AppTextStyles.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white.withOpacity(0.78),
          ),
        ),
      ],
    );
  }

  Widget _actionRow() {
    return Row(
      children: [
        Expanded(
          child: _actionTile(
            icon: Icons.confirmation_number_rounded,
            label: 'Use a coupon',
            color: AppColors.warning,
            onTap: _openCouponSheet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionTile(
            icon: Icons.redeem_rounded,
            label: 'What you can get',
            color: AppColors.info,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RewardCatalogScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionTile(
            icon: Icons.local_shipping_rounded,
            label: 'My orders',
            color: AppColors.success,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RewardOrdersScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 9),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandTile(BrandPoints brand) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                brand.brand.isEmpty
                    ? '?'
                    : brand.brand.substring(0, 1).toUpperCase(),
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(brand.brand, style: AppTextStyles.titleMedium),
            ),
            Text(
              Formats.points(brand.points),
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ledgerTile(LedgerEntry entry) {
    final credit = entry.isCredit;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: credit ? AppColors.successSoft : AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                credit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: credit ? AppColors.success : AppColors.danger,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(entry.createdAgo, style: AppTextStyles.caption),
                ],
              ),
            ),
            Text(
              '${entry.direction}${Formats.points(entry.points)}',
              style: AppTextStyles.titleMedium.copyWith(
                color: credit ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
