import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/timeline_view.dart';
import '../models/supply_chain_models.dart';
import '../providers/supply_chain_provider.dart';

class ConsignmentDetailScreen extends StatefulWidget {
  final String code;

  const ConsignmentDetailScreen({super.key, required this.code});

  @override
  State<ConsignmentDetailScreen> createState() =>
      _ConsignmentDetailScreenState();
}

class _ConsignmentDetailScreenState extends State<ConsignmentDetailScreen> {
  ConsignmentDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final detail = await context.read<SupplyChainProvider>().consignment(
          widget.code,
        );

    if (!mounted) return;

    setState(() {
      _detail = detail;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.code)),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const ListSkeleton(itemCount: 4, itemHeight: 130);

    final detail = _detail;

    if (detail == null) {
      return ErrorView(
        message: 'This shipment could not be loaded.',
        onRetry: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _summaryCard(detail),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'What is inside',
            subtitle: '${detail.totalUnits} units in total',
          ),
          if (detail.products.isEmpty)
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No unit codes linked to this shipment yet.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall,
                ),
              ),
            )
          else
            ...detail.products.map(_productTile),
          const SizedBox(height: 22),
          const SectionHeader(title: 'History'),
          AppCard(child: TimelineView(entries: _entries(detail.timeline))),
        ],
      ),
    );
  }

  Widget _summaryCard(ConsignmentDetail detail) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail.code, style: AppTextStyles.headingSmall),
                    const SizedBox(height: 3),
                    Text(
                      detail.level.isEmpty ? 'Pack' : detail.level,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusChip.forStatus(detail.custody),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              MiniStat(
                label: 'Units',
                value: '${detail.totalUnits}',
                icon: Icons.inventory_rounded,
              ),
              const SizedBox(width: 26),
              MiniStat(
                label: 'Sub packs',
                value: '${detail.childCount}',
                icon: Icons.widgets_rounded,
                color: AppColors.info,
              ),
            ],
          ),
          if (detail.lastAction != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            InfoRow(
              label: 'Last action',
              value: detail.lastAction!.title,
              icon: Icons.history_rounded,
            ),
            InfoRow(
              label: 'Recorded',
              value: detail.lastAction!.createdAt,
              icon: Icons.schedule_rounded,
            ),
            if (detail.lastAction!.verified)
              const InfoRow(
                label: 'Integrity',
                value: 'Hash verified',
                icon: Icons.verified_rounded,
                valueColor: AppColors.success,
              ),
          ],
        ],
      ),
    );
  }

  Widget _productTile(PackedProduct product) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            AppImage(url: product.image, width: 54, height: 54),
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
                  const SizedBox(height: 3),
                  Text(
                    'Batch ${product.batchCode.isEmpty ? '-' : product.batchCode}',
                    style: AppTextStyles.caption,
                  ),
                  if (product.expiryOn.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    StatusChip(
                      label: product.isExpired
                          ? 'Expired ${product.expiryOn}'
                          : 'Expires ${product.expiryOn}',
                      tone: product.isExpired
                          ? StatusTone.danger
                          : StatusTone.neutral,
                      dense: true,
                    ),
                  ],
                ],
              ),
            ),
            if (product.quantity > 0)
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
                  '${product.quantity}',
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

  List<TimelineEntry> _entries(List<JourneyStep> steps) {
    return steps.map((step) {
      final isCheckout = step.action.toLowerCase() == 'checkout';

      return TimelineEntry(
        title: isCheckout
            ? 'Sent by ${step.scannedBy}'
            : 'Received by ${step.scannedBy}',
        subtitle: [
          if (step.actionFor != null) 'to ${step.actionFor}',
          if (step.comment != null && step.comment!.isNotEmpty) step.comment!,
        ].join(' · '),
        meta: step.scannedAt,
        badge: step.type.isEmpty ? null : step.type,
        code: step.code.isEmpty ? null : step.code,
        trailing: step.status,
        icon: isCheckout
            ? Icons.local_shipping_rounded
            : Icons.inventory_2_rounded,
        color: isCheckout ? AppColors.warning : AppColors.success,
      );
    }).toList();
  }
}
