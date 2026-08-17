import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/journey_strip.dart';
import '../../../core/widgets/timeline_view.dart';
import '../../scanner/screens/scanner_screen.dart';
import '../data/consumer_repository.dart';
import '../models/consumer_models.dart';
import 'report_product_screen.dart';

class ProductResultScreen extends StatelessWidget {
  final ProductScanResult result;
  final String code;

  const ProductResultScreen({
    super.key,
    required this.result,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    final product = result.product;
    final genuine = result.genuine;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _verdictHeader(context, genuine, product)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _productCard(product),
                if (result.appliedOffer != null &&
                    result.appliedOffer!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _offerBanner(result.appliedOffer!),
                ],
                const SizedBox(height: 20),
                const SectionHeader(
                  title: 'Supply chain journey',
                  subtitle: 'Every hand this pack passed through',
                ),
                if (result.journey.isNotEmpty) ...[
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: JourneyStrip(hops: _hops(result.journey)),
                  ),
                  const SizedBox(height: 12),
                ],
                AppCard(
                  child: TimelineView(entries: _journeyEntries(result.journey)),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Scan another',
                        icon: Icons.qr_code_scanner_rounded,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const ScannerScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Report issue',
                        icon: Icons.outlined_flag_rounded,
                        variant: AppButtonVariant.ghost,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportProductScreen(
                              codeData: product.codeData ?? code,
                              productId: product.id,
                              productName: product.name,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verdictHeader(
    BuildContext context,
    bool genuine,
    ProductDetail product,
  ) {
    final colors =
        genuine ? AppColors.successGradient : AppColors.dangerGradient;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const Spacer(),
                if (product.scanCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Scanned ${product.scanCount}x',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 76,
              width: 76,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: Icon(
                genuine ? Icons.verified_rounded : Icons.gpp_bad_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              genuine ? 'Genuine product' : 'Could not be verified',
              style: AppTextStyles.displayLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              genuine
                  ? 'This pack is authentic and registered with the brand.'
                  : 'Treat this pack with caution and report it to us.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.86),
              ),
            ),
            if (product.isExpired) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_busy_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'This product is past its expiry date',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
                    if (product.price.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        product.price,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (product.description != null &&
              product.description!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(product.description!, style: AppTextStyles.bodyMedium),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 6),
          InfoRow(
            label: 'Manufacturer',
            value: product.manufacturer,
            icon: Icons.factory_rounded,
          ),
          InfoRow(
            label: 'Batch',
            value: product.batchCode,
            icon: Icons.inventory_rounded,
          ),
          InfoRow(
            label: 'Manufactured on',
            value: product.manufacturedOn,
            icon: Icons.calendar_today_rounded,
          ),
          InfoRow(
            label: 'Expires on',
            value: product.expiryOn,
            icon: Icons.event_rounded,
            valueColor: product.isExpired ? AppColors.danger : null,
          ),
          if (product.codeData != null)
            InfoRow(
              label: 'Code',
              value: product.codeData!,
              icon: Icons.qr_code_2_rounded,
            ),
        ],
      ),
    );
  }

  Widget _offerBanner(String offer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5A524), Color(0xFFFFC55C)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        children: [
          const Icon(Icons.redeem_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You unlocked an offer',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  offer,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TimelineEntry> _journeyEntries(List<JourneyStep> journey) {
    return journey.map((step) {
      final isCheckout = step.action.toLowerCase() == 'checkout';

      return TimelineEntry(
        title: isCheckout
            ? 'Sent by ${step.scannedBy}'
            : 'Received by ${step.scannedBy}',
        subtitle: [
          if (step.type.isNotEmpty) step.type,
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
