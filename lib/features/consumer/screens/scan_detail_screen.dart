import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/location_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/journey_strip.dart';
import '../../../core/widgets/timeline_view.dart';
import '../models/consumer_models.dart';
import '../providers/consumer_provider.dart';
import 'report_product_screen.dart';

class ScanDetailScreen extends StatefulWidget {
  final int scanId;

  const ScanDetailScreen({super.key, required this.scanId});

  @override
  State<ScanDetailScreen> createState() => _ScanDetailScreenState();
}

class _ScanDetailScreenState extends State<ScanDetailScreen> {
  ScanDetail? _detail;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final detail = await context.read<ConsumerProvider>().scanDetail(
          widget.scanId,
        );

    if (!mounted) return;

    setState(() {
      _detail = detail;
      _loading = false;
      _error = detail == null ? 'This scan could not be loaded.' : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan details')),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const ListSkeleton(itemCount: 4, itemHeight: 120);

    final detail = _detail;

    if (detail == null) {
      return ErrorView(message: _error, onRetry: _load);
    }

    final product = detail.product;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _verdict(detail),
          const SizedBox(height: 18),
          if (product != null) _productCard(product),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Journey'),
          if (detail.journey.isNotEmpty) ...[
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: JourneyStrip(hops: _hops(detail.journey)),
            ),
            const SizedBox(height: 12),
          ],
          AppCard(child: TimelineView(entries: _entries(detail.journey))),
          const SizedBox(height: 20),
          if (detail.location != null) ...[
            AppCard(
              child: InfoRow(
                label: 'Scanned at',
                value: LocationHelper.readableCoordinates(detail.location) ??
                    'Location unavailable',
                icon: Icons.location_on_rounded,
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (!detail.reported)
            AppButton(
              label: 'Report a problem with this product',
              icon: Icons.outlined_flag_rounded,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportProductScreen(
                    codeData: product?.codeData,
                    productId: product?.id,
                    productName: product?.name,
                  ),
                ),
              ),
            )
          else
            AppCard(
              color: AppColors.warningSoft,
              shadow: const [],
              child: Row(
                children: [
                  const Icon(
                    Icons.flag_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You have already reported this product. We will update you.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _verdict(ScanDetail detail) {
    final genuine = detail.genuine;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: genuine
              ? AppColors.successGradient
              : AppColors.dangerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(
              genuine ? Icons.verified_rounded : Icons.gpp_bad_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  genuine ? 'Verified genuine' : 'Could not verify',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail.scannedAt,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(ProductDetail product) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppImage(url: product.image, width: 66, height: 66),
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
                    if (product.isExpired)
                      const StatusChip(
                        label: 'Expired',
                        tone: StatusTone.danger,
                        dense: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 6),
          InfoRow(label: 'Manufacturer', value: product.manufacturer),
          InfoRow(label: 'Batch', value: product.batchCode),
          InfoRow(label: 'Manufactured on', value: product.manufacturedOn),
          InfoRow(label: 'Expires on', value: product.expiryOn),
          InfoRow(label: 'Total scans', value: '${product.scanCount}'),
        ],
      ),
    );
  }

  List<TimelineEntry> _entries(List<JourneyStep> journey) {
    return journey.map((step) {
      final isCheckout = step.action.toLowerCase() == 'checkout';

      return TimelineEntry(
        title: isCheckout
            ? 'Sent by ${step.scannedBy}'
            : 'Received by ${step.scannedBy}',
        subtitle: step.actionFor != null ? 'to ${step.actionFor}' : step.type,
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

  List<JourneyHop> _hops(List<JourneyStep> journey) {
    final hops = <JourneyHop>[];

    for (final step in journey.reversed) {
      final name = step.scannedBy.trim();
      if (name.isEmpty) continue;
      if (hops.isNotEmpty && hops.last.name == name) continue;
      hops.add(JourneyHop(name: name, level: step.type.isEmpty ? null : step.type));
    }

    return hops;
  }

}
