import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/location_helper.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../models/brand_models.dart';
import '../providers/brand_provider.dart';

class BrandScansScreen extends StatefulWidget {
  final bool embedded;

  const BrandScansScreen({super.key, this.embedded = false});

  @override
  State<BrandScansScreen> createState() => _BrandScansScreenState();
}

class _BrandScansScreenState extends State<BrandScansScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrandProvider>().loadScans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BrandProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('Live scans'),
      ),
      body: PagedListView<BrandScan>(
        items: provider.scans,
        status: provider.status,
        errorMessage: provider.errorMessage,
        isNetworkError: provider.isNetworkError,
        onRefresh: () => provider.loadScans(refresh: true),
        onRetry: () => provider.loadScans(),
        emptyState: const EmptyState(
          icon: Icons.insights_rounded,
          title: 'No scans yet',
          message: 'Consumer scans of your products will stream in here.',
        ),
        itemBuilder: (context, scan, index) => _card(scan),
      ),
    );
  }

  Widget _card(BrandScan scan) {
    final coordinates = LocationHelper.readableCoordinates(scan.location);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          AppImage(url: scan.image, width: 52, height: 52),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      size: 13,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        scan.scannedBy.isEmpty ? 'Anonymous' : scan.scannedBy,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
                if (coordinates != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          coordinates,
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
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(
                label: scan.genuine ? 'Genuine' : 'Needs a look',
                tone: scan.genuine ? StatusTone.success : StatusTone.danger,
                dense: true,
              ),
              const SizedBox(height: 6),
              Text(scan.scannedAgo, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
