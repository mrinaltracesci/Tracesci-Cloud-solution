import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/timeline_view.dart';
import '../models/reward_models.dart';
import '../providers/reward_provider.dart';

class RewardOrdersScreen extends StatefulWidget {
  const RewardOrdersScreen({super.key});

  @override
  State<RewardOrdersScreen> createState() => _RewardOrdersScreenState();
}

class _RewardOrdersScreenState extends State<RewardOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RewardProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RewardProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: PagedListView<RewardOrder>(
        items: provider.orders,
        status: provider.status,
        errorMessage: provider.errorMessage,
        isNetworkError: provider.isNetworkError,
        onRefresh: () => provider.loadOrders(refresh: true),
        onRetry: () => provider.loadOrders(),
        separatorHeight: 14,
        emptyState: const EmptyState(
          icon: Icons.local_shipping_rounded,
          title: 'No orders yet',
          message: 'Redeem your points for a reward and track delivery here.',
        ),
        itemBuilder: (context, order, index) => _card(order),
      ),
    );
  }

  Widget _card(RewardOrder order) {
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
                    Text(order.product, style: AppTextStyles.headingSmall),
                    const SizedBox(height: 3),
                    Text(order.reference, style: AppTextStyles.caption),
                  ],
                ),
              ),
              StatusChip.forStatus(order.status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.stars_rounded,
                size: 16,
                color: AppColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                '${Formats.points(order.points)} points',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.placedOn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(order.address, style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ),
          if (order.timeline.isNotEmpty) ...[
            const SizedBox(height: 16),
            TimelineView(
              entries: order.timeline
                  .map(
                    (entry) => TimelineEntry(
                      title: entry.message,
                      meta: entry.date,
                      icon: Icons.check_rounded,
                      color: AppColors.success,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
