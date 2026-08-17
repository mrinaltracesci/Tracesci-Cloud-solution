import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../models/reward_models.dart';
import '../providers/reward_provider.dart';

class RewardLedgerScreen extends StatefulWidget {
  const RewardLedgerScreen({super.key});

  @override
  State<RewardLedgerScreen> createState() => _RewardLedgerScreenState();
}

class _RewardLedgerScreenState extends State<RewardLedgerScreen> {
  String? _type;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RewardProvider>().loadLedger();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RewardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Points history'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilterChipsRow(
              selected: _type,
              onSelected: (value) {
                setState(() => _type = value);
                provider.loadLedger(type: value);
              },
              options: const [
                FilterOption(label: 'All'),
                FilterOption(label: 'Earned', value: 'credit'),
                FilterOption(label: 'Redeemed', value: 'debit'),
              ],
            ),
          ),
        ),
      ),
      body: PagedListView<LedgerEntry>(
        items: provider.ledger,
        status: provider.status,
        errorMessage: provider.errorMessage,
        isNetworkError: provider.isNetworkError,
        onRefresh: () => provider.loadLedger(refresh: true, type: _type),
        onRetry: () => provider.loadLedger(type: _type),
        emptyState: const EmptyState(
          icon: Icons.receipt_long_rounded,
          title: 'No transactions',
          message: 'Points you earn or redeem will be listed here.',
        ),
        itemBuilder: (context, entry, index) => _tile(entry),
      ),
    );
  }

  Widget _tile(LedgerEntry entry) {
    final credit = entry.isCredit;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: credit ? AppColors.successSoft : AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              credit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: credit ? AppColors.success : AppColors.danger,
              size: 19,
            ),
          ),
          const SizedBox(width: 13),
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
                Text(entry.createdAt, style: AppTextStyles.caption),
                if (entry.scheme != null) ...[
                  const SizedBox(height: 6),
                  StatusChip(
                    label: entry.scheme!,
                    tone: StatusTone.neutral,
                    dense: true,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.direction}${Formats.points(entry.points)}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: credit ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (entry.amount != null && entry.amount! > 0)
                Text(
                  '₹${Formats.points(entry.amount!)}',
                  style: AppTextStyles.caption,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
