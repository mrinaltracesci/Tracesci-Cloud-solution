import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../models/supply_chain_models.dart';
import '../providers/supply_chain_provider.dart';
import 'consignment_detail_screen.dart';

class ChainActivityScreen extends StatefulWidget {
  const ChainActivityScreen({super.key});

  @override
  State<ChainActivityScreen> createState() => _ChainActivityScreenState();
}

class _ChainActivityScreenState extends State<ChainActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplyChainProvider>().loadActivity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplyChainProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: PagedListView<ChainActivity>(
        items: provider.activity,
        status: provider.status,
        errorMessage: provider.errorMessage,
        isNetworkError: provider.isNetworkError,
        onRefresh: () => provider.loadActivity(refresh: true),
        onRetry: () => provider.loadActivity(),
        emptyState: const EmptyState(
          icon: Icons.timeline_rounded,
          title: 'No movements recorded',
          message: 'Receives and dispatches you make will be listed here.',
        ),
        itemBuilder: (context, activity, index) => _card(activity),
      ),
    );
  }

  Widget _card(ChainActivity activity) {
    final isCheckout = activity.action.toLowerCase() == 'checkout';

    return AppCard(
      padding: const EdgeInsets.all(15),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConsignmentDetailScreen(code: activity.code),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
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
                  size: 20,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      maxLines: 2,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(activity.code, style: AppTextStyles.caption),
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
          if (activity.comment != null && activity.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                activity.comment!,
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (activity.status != null)
                StatusChip.forStatus(activity.status!),
              const Spacer(),
              Text(activity.createdAt, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
