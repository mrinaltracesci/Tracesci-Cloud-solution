import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../models/brand_models.dart';
import '../providers/brand_provider.dart';

class BrandProductDetailScreen extends StatefulWidget {
  final int productId;

  const BrandProductDetailScreen({super.key, required this.productId});

  @override
  State<BrandProductDetailScreen> createState() =>
      _BrandProductDetailScreenState();
}

class _BrandProductDetailScreenState extends State<BrandProductDetailScreen> {
  BrandProductDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final detail = await context.read<BrandProvider>().product(
          widget.productId,
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
      appBar: AppBar(title: Text(_detail?.product.name ?? 'Product')),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const ListSkeleton(itemCount: 4, itemHeight: 130);

    final detail = _detail;

    if (detail == null) {
      return ErrorView(
        message: 'This product could not be loaded.',
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
          const SectionHeader(title: 'Performance'),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MiniStat(
                        label: 'Codes generated',
                        value: '${detail.codesGenerated}',
                        icon: Icons.qr_code_2_rounded,
                      ),
                    ),
                    Expanded(
                      child: MiniStat(
                        label: 'Active codes',
                        value: '${detail.codesActive}',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: MiniStat(
                        label: 'Total scans',
                        value: '${detail.totalScans}',
                        icon: Icons.insights_rounded,
                        color: AppColors.info,
                      ),
                    ),
                    Expanded(
                      child: MiniStat(
                        label: 'Open alerts',
                        value: '${detail.openAlerts}',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Batches',
            subtitle: '${detail.batches.length} recorded',
          ),
          if (detail.batches.isEmpty)
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No batches created for this product yet.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            )
          else
            ...detail.batches.map(_batchTile),
        ],
      ),
    );
  }

  Widget _summaryCard(BrandProductDetail detail) {
    final product = detail.product;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppImage(url: product.image, width: 72, height: 72),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: AppTextStyles.headingSmall),
                    if (product.brand != null && product.brand!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(product.brand!, style: AppTextStyles.bodySmall),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusChip.forStatus(product.status),
                        if (detail.pinRequired) ...[
                          const SizedBox(width: 8),
                          const StatusChip(
                            label: 'PIN protected',
                            tone: StatusTone.primary,
                            dense: true,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (detail.description != null &&
              detail.description!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(detail.description!, style: AppTextStyles.bodyMedium),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 6),
          InfoRow(label: 'Price', value: product.price),
          InfoRow(label: 'Created', value: product.createdAt),
          InfoRow(
            label: 'Authentication',
            value: detail.authRequired ? 'Required' : 'Not required',
          ),
        ],
      ),
    );
  }

  Widget _batchTile(BrandBatch batch) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    batch.code.isEmpty ? 'Batch ${batch.id}' : batch.code,
                    style: AppTextStyles.titleMedium,
                  ),
                ),
                StatusChip.forStatus(batch.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _batchMeta('Manufactured', batch.manufacturedOn),
                ),
                Expanded(
                  child: _batchMeta(
                    'Expires',
                    batch.expiryOn,
                    danger: batch.isExpired,
                  ),
                ),
                Expanded(child: _batchMeta('Codes', '${batch.codes}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _batchMeta(String label, String value, {bool danger = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? '-' : value,
          style: AppTextStyles.bodySmall.copyWith(
            color: danger ? AppColors.danger : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
