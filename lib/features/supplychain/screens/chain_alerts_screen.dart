import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../models/supply_chain_models.dart';
import '../providers/supply_chain_provider.dart';
import 'consignment_detail_screen.dart';

class ChainAlertsScreen extends StatefulWidget {
  final bool embedded;

  const ChainAlertsScreen({super.key, this.embedded = false});

  @override
  State<ChainAlertsScreen> createState() => _ChainAlertsScreenState();
}

class _ChainAlertsScreenState extends State<ChainAlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplyChainProvider>().loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplyChainProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('Warnings'),
      ),
      body: PagedListView<ChainAlert>(
        items: provider.alerts,
        status: provider.status,
        errorMessage: provider.errorMessage,
        isNetworkError: provider.isNetworkError,
        onRefresh: () => provider.loadAlerts(refresh: true),
        onRetry: () => provider.loadAlerts(),
        emptyState: const EmptyState(
          icon: Icons.verified_user_rounded,
          title: 'No warnings',
          message: 'Everything in your network has moved as expected.',
        ),
        itemBuilder: (context, alert, index) => _card(alert),
      ),
    );
  }

  Widget _card(ChainAlert alert) {
    return AppCard(
      padding: const EdgeInsets.all(15),
      onTap: alert.code == null
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ConsignmentDetailScreen(code: alert.code!),
                ),
              ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.message, style: AppTextStyles.titleMedium),
                const SizedBox(height: 6),
                if (alert.code != null)
                  Text(
                    '${alert.level ?? 'Code'} · ${alert.code}',
                    style: AppTextStyles.bodySmall,
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (alert.scannedBy != null) ...[
                      const Icon(
                        Icons.person_rounded,
                        size: 13,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          alert.scannedBy!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(alert.createdAgo, style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
