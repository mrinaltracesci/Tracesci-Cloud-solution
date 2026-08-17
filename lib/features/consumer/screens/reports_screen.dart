import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../models/consumer_models.dart';
import '../providers/consumer_provider.dart';
import 'report_product_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsumerProvider>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConsumerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My reports')),
      body: PagedListView<ReportItem>(
        items: provider.reports,
        status: provider.status,
        errorMessage: provider.errorMessage,
        isNetworkError: provider.isNetworkError,
        onRefresh: () => provider.loadReports(refresh: true),
        onRetry: () => provider.loadReports(),
        separatorHeight: 14,
        emptyState: EmptyState(
          icon: Icons.outlined_flag_rounded,
          title: 'No reports filed',
          message: 'If a product looks wrong, report it and we will investigate.',
          actionLabel: 'Report a product',
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReportProductScreen()),
          ),
        ),
        itemBuilder: (context, report, index) => _card(report),
      ),
    );
  }

  Widget _card(ReportItem report) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(report.reference, style: AppTextStyles.caption),
                  ],
                ),
              ),
              StatusChip.forStatus(report.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              StatusChip(
                label: report.issueType,
                tone: StatusTone.neutral,
                dense: true,
              ),
              const Spacer(),
              Text(report.createdAgo, style: AppTextStyles.caption),
            ],
          ),
          if (report.resolution != null && report.resolution!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 17,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.resolution!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
