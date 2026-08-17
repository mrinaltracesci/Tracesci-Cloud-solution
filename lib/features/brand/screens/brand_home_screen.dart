import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/brand_models.dart';
import '../providers/brand_provider.dart';
import 'brand_alerts_screen.dart';
import 'brand_network_screen.dart';
import 'brand_product_detail_screen.dart';

class BrandHomeScreen extends StatefulWidget {
  const BrandHomeScreen({super.key});

  @override
  State<BrandHomeScreen> createState() => _BrandHomeScreenState();
}

class _BrandHomeScreenState extends State<BrandHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrandProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<BrandProvider>();
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
                    StatGrid(tiles: dashboard.stats),
                    const SizedBox(height: 22),
                    _trendCard(dashboard),
                    const SizedBox(height: 20),
                    _creditsCard(dashboard.credits),
                    if (dashboard.topProducts.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      const SectionHeader(
                        title: 'Most scanned this month',
                      ),
                      ...dashboard.topProducts.map(_topProductTile),
                    ],
                    if (dashboard.recentAlerts.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      SectionHeader(
                        title: 'Needs attention',
                        actionLabel: 'See all',
                        onAction: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BrandAlertsScreen(),
                          ),
                        ),
                      ),
                      ...dashboard.recentAlerts.map(_alertTile),
                    ],
                    const SizedBox(height: 22),
                    _networkCard(dashboard),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(AuthProvider auth, BrandDashboard? dashboard) {
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
                      auth.profile.company?.name ?? auth.profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      auth.theming.greeting,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: Row(
              children: [
                _headerMetric(
                  'Scans this month',
                  '${dashboard?.thisMonth.scans ?? 0}',
                ),
                Container(
                  height: 34,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white.withOpacity(0.24),
                ),
                _headerMetric(
                  'Codes uploaded',
                  '${dashboard?.thisMonth.codesUploaded ?? 0}',
                ),
                Container(
                  height: 34,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white.withOpacity(0.24),
                ),
                _headerMetric(
                  'Active today',
                  '${dashboard?.thisMonth.activatedToday ?? 0}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerMetric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withOpacity(0.78),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendCard(BrandDashboard dashboard) {
    final trend = dashboard.scanTrend;

    if (trend.isEmpty) return const SizedBox.shrink();

    final maxY = trend
        .map((point) => point.count)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scans over the last 7 days', style: AppTextStyles.headingSmall),
          const SizedBox(height: 4),
          Text(
            '${trend.fold<int>(0, (sum, p) => sum + p.count)} scans this week',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: maxY == 0 ? 4 : maxY * 1.25,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= trend.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            trend[index].day,
                            style: AppTextStyles.caption,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${trend[group.x].date}\n${rod.toY.toInt()} scans',
                        AppTextStyles.caption.copyWith(color: Colors.white),
                      );
                    },
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < trend.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: trend[i].count.toDouble(),
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGradient,
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _creditsCard(CreditSnapshot credits) {
    return AppCard(
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
                  Icons.confirmation_number_rounded,
                  color: AppColors.warning,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Label credits', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      Formats.compact(credits.available),
                      style: AppTextStyles.metric,
                    ),
                  ],
                ),
              ),
              Text(
                'of ${Formats.compact(credits.total)}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: credits.usedRatio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.warning,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${Formats.compact(credits.used)} credits used',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _topProductTile(TopProduct product) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(13),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BrandProductDetailScreen(productId: product.id),
          ),
        ),
        child: Row(
          children: [
            AppImage(url: product.image, width: 50, height: 50),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium,
                  ),
                  if (product.brand != null) ...[
                    const SizedBox(height: 3),
                    Text(product.brand!, style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${product.scans}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertTile(BrandAlertPreview alert) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BrandAlertsScreen()),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.danger,
                size: 20,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    alert.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(alert.createdAgo, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _networkCard(BrandDashboard dashboard) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BrandNetworkScreen()),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.account_tree_rounded,
              color: AppColors.info,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Supply chain network', style: AppTextStyles.titleMedium),
                const SizedBox(height: 3),
                Text(
                  '${dashboard.networkNodes} nodes · ${dashboard.networkAlerts} warnings',
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
}
