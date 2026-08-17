import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../../inspector/screens/case_detail_screen.dart';
import '../models/brand_models.dart';
import '../providers/brand_provider.dart';

class BrandAlertsScreen extends StatefulWidget {
  final bool embedded;

  const BrandAlertsScreen({super.key, this.embedded = false});

  @override
  State<BrandAlertsScreen> createState() => _BrandAlertsScreenState();
}

class _BrandAlertsScreenState extends State<BrandAlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrandProvider>().loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BrandProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('Alerts'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilterChipsRow(
              selected: provider.alertStatus,
              onSelected: provider.setAlertStatus,
              options: const [
                FilterOption(label: 'All'),
                FilterOption(label: 'Open', value: '0'),
                FilterOption(label: 'Closed', value: '1'),
              ],
            ),
          ),
        ),
      ),
      body: PagedListView<BrandAlert>(
        items: provider.alerts,
        status: provider.status,
        errorMessage: provider.errorMessage,
        isNetworkError: provider.isNetworkError,
        onRefresh: () => provider.loadAlerts(refresh: true),
        onRetry: () => provider.loadAlerts(),
        separatorHeight: 14,
        emptyState: const EmptyState(
          icon: Icons.verified_user_rounded,
          title: 'Nothing flagged',
          message: 'No alerts or consumer reports against your products.',
        ),
        itemBuilder: (context, alert, index) => _card(alert),
      ),
    );
  }

  Widget _card(BrandAlert alert) {
    final isReport = alert.kind.toLowerCase().contains('consumer');

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: alert.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: (isReport ? AppColors.info : AppColors.warning)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isReport
                      ? Icons.outlined_flag_rounded
                      : Icons.warning_amber_rounded,
                  color: isReport ? AppColors.info : AppColors.warning,
                  size: 21,
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
                    Text(alert.reference, style: AppTextStyles.caption),
                  ],
                ),
              ),
              StatusChip.forStatus(alert.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              StatusChip(
                label: alert.kind,
                tone: StatusTone.neutral,
                dense: true,
              ),
              const Spacer(),
              Text(alert.createdAgo, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
