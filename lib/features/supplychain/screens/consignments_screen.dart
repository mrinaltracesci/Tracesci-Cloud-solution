import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../../scanner/screens/scanner_screen.dart';
import '../models/supply_chain_models.dart';
import '../providers/supply_chain_provider.dart';
import 'consignment_detail_screen.dart';

class ConsignmentsScreen extends StatefulWidget {
  final bool embedded;

  const ConsignmentsScreen({super.key, this.embedded = false});

  @override
  State<ConsignmentsScreen> createState() => _ConsignmentsScreenState();
}

class _ConsignmentsScreenState extends State<ConsignmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplyChainProvider>().loadConsignments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplyChainProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('Shipments'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilterChipsRow(
              selected: provider.filter,
              onSelected: (value) => provider.setFilter(value ?? 'all'),
              options: const [
                FilterOption(label: 'All', value: 'all'),
                FilterOption(label: 'With me', value: 'in_custody'),
                FilterOption(label: 'Incoming', value: 'incoming'),
                FilterOption(label: 'Dispatched', value: 'dispatched'),
              ],
            ),
          ),
        ),
      ),
      body: PagedListView<ConsignmentCard>(
        items: provider.consignments,
        status: provider.status,
        errorMessage: provider.errorMessage,
        isNetworkError: provider.isNetworkError,
        loadingMore: provider.loadingMore,
        hasMore: provider.hasMore,
        onRefresh: () => provider.loadConsignments(refresh: true),
        onLoadMore: provider.loadMoreConsignments,
        onRetry: () => provider.loadConsignments(),
        separatorHeight: 14,
        emptyState: EmptyState(
          icon: Icons.inventory_2_rounded,
          title: 'Nothing here yet',
          message: 'Shipments you scan will show up in this list.',
          actionLabel: 'Scan a shipment',
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ScannerScreen()),
          ),
        ),
        itemBuilder: (context, item, index) => _card(item),
      ),
    );
  }

  Widget _card(ConsignmentCard item) {
    final isCheckout = item.action.toLowerCase() == 'checkout';

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConsignmentDetailScreen(code: item.code),
        ),
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
                      item.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.level.isEmpty ? 'Pack' : item.level,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              StatusChip.forStatus(item.custody),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.swap_horiz_rounded,
                size: 15,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.counterparty == null
                      ? item.action
                      : '${item.action} · ${item.counterparty}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall,
                ),
              ),
              Text(item.updatedAgo, style: AppTextStyles.caption),
            ],
          ),
          if (item.eligibleFor.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.canCheckIn
                        ? 'Ready to receive'
                        : 'Ready to send',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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
