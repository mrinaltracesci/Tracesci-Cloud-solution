import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../models/brand_models.dart';
import '../providers/brand_provider.dart';

class BrandNetworkScreen extends StatefulWidget {
  const BrandNetworkScreen({super.key});

  @override
  State<BrandNetworkScreen> createState() => _BrandNetworkScreenState();
}

class _BrandNetworkScreenState extends State<BrandNetworkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrandProvider>().loadNetwork();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BrandProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Supply chain network')),
      body: PagedListView<NetworkNode>(
        items: provider.network,
        status: provider.status,
        errorMessage: provider.errorMessage,
        isNetworkError: provider.isNetworkError,
        onRefresh: () => provider.loadNetwork(refresh: true),
        onRetry: () => provider.loadNetwork(),
        emptyState: const EmptyState(
          icon: Icons.account_tree_rounded,
          title: 'No nodes yet',
          message: 'Distributors and retailers you add will appear here.',
        ),
        itemBuilder: (context, node, index) => _card(node, provider.network),
      ),
    );
  }

  Widget _card(NetworkNode node, List<NetworkNode> all) {
    final parent = node.parentId == null
        ? null
        : all.where((n) => n.id == node.parentId).firstOrNull;

    return AppCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: node.isActive
                  ? AppColors.primarySoft
                  : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              node.name.isEmpty ? '?' : node.name.substring(0, 1).toUpperCase(),
              style: AppTextStyles.titleMedium.copyWith(
                color: node.isActive
                    ? AppColors.primary
                    : AppColors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  node.role ?? 'Supply chain user',
                  style: AppTextStyles.bodySmall,
                ),
                if (parent != null) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.subdirectory_arrow_right_rounded,
                        size: 13,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'reports to ${parent.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          StatusChip.forStatus(node.status),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
