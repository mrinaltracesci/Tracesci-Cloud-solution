import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/surfaces.dart';
import '../../scanner/screens/scanner_screen.dart';
import '../models/verdict.dart';
import 'report_product_screen.dart';

class ScanProblemScreen extends StatelessWidget {
  final ScanVerdict verdict;

  const ScanProblemScreen({super.key, required this.verdict});

  @override
  Widget build(BuildContext context) {
    final status = verdict.status;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(context, status)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: _whatThisMeans(),
                ),
                if (verdict.product != null) ...[
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 190),
                    child: _productCard(verdict.product!),
                  ),
                ],
                const SizedBox(height: 18),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 250),
                  child: _codeCard(),
                ),
                const SizedBox(height: 26),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 310),
                  child: Column(
                    children: [
                      if (verdict.canReport && !verdict.alreadyReported)
                        AppButton(
                          label: 'Report this product',
                          icon: Icons.outlined_flag_rounded,
                          variant: AppButtonVariant.danger,
                          onPressed: () => Navigator.of(context).push(
                            SmoothPageRoute(
                              page: ReportProductScreen(
                                codeData: verdict.codeData,
                                productId: verdict.product?.id,
                                productName: verdict.product?.name,
                                presetIssue: _presetIssue(status),
                              ),
                            ),
                          ),
                        )
                      else if (verdict.alreadyReported)
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
                                  'This pack has already been reported. Our team is looking into it.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Scan another product',
                        icon: Icons.qr_code_scanner_rounded,
                        variant: AppButtonVariant.ghost,
                        onPressed: () => Navigator.of(context).pushReplacement(
                          SmoothPageRoute(page: const ScannerScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, VerdictStatus status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: status.gradient,
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
            const SizedBox(height: 26),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.7, end: 1),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                height: 82,
                width: 82,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.42)),
                ),
                child: Icon(status.icon, color: Colors.white, size: 42),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              verdict.title,
              style: AppTextStyles.displayLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              verdict.message,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white.withOpacity(0.92),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _whatThisMeans() {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: verdict.status.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 20,
              color: verdict.status.color,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What you should do', style: AppTextStyles.label),
                const SizedBox(height: 5),
                Text(verdict.status.advice, style: AppTextStyles.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(VerdictProduct product) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppImage(url: product.image, width: 62, height: 62),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: AppTextStyles.titleMedium),
                    if (product.brand != null) ...[
                      const SizedBox(height: 3),
                      Text(product.brand!, style: AppTextStyles.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 6),
          if (product.manufacturer != null)
            InfoRow(label: 'Made by', value: product.manufacturer!),
          if (product.batchCode != null)
            InfoRow(label: 'Batch', value: product.batchCode!),
          if (product.manufacturedOn != null)
            InfoRow(label: 'Made on', value: product.manufacturedOn!),
          if (product.expiryOn != null)
            InfoRow(
              label: 'Use before',
              value: product.expiryOn!,
              valueColor: verdict.status == VerdictStatus.expired
                  ? AppColors.danger
                  : null,
            ),
        ],
      ),
    );
  }

  Widget _codeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.qr_code_2_rounded,
            size: 20,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Code you scanned', style: AppTextStyles.label),
                const SizedBox(height: 3),
                Text(
                  verdict.scannedCode,
                  style: AppTextStyles.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _presetIssue(VerdictStatus status) {
    switch (status) {
      case VerdictStatus.fake:
      case VerdictStatus.overScanned:
        return 'counterfeit';
      case VerdictStatus.expired:
        return 'expired';
      case VerdictStatus.deactivated:
      case VerdictStatus.blocked:
      case VerdictStatus.notActivated:
        return 'other';
      default:
        return 'other';
    }
  }
}
