import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../../scanner/screens/scanner_screen.dart';
import '../models/consumer_models.dart';
import '../providers/consumer_provider.dart';
import 'scan_detail_screen.dart';

class ScanHistoryScreen extends StatefulWidget {
  final bool embedded;

  const ScanHistoryScreen({super.key, this.embedded = false});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsumerProvider>().loadScans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConsumerProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('Scan history'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilterChipsRow(
              selected: provider.genuineFilter,
              onSelected: provider.setGenuineFilter,
              options: const [
                FilterOption(label: 'All'),
                FilterOption(label: 'Genuine', value: '1'),
                FilterOption(label: 'Needs a look', value: '0'),
              ],
            ),
          ),
        ),
      ),
      body: PagedListView<ScanCard>(
        items: provider.scans,
        status: provider.status,
        errorMessage: provider.errorMessage,
        isNetworkError: provider.isNetworkError,
        loadingMore: provider.loadingMore,
        hasMore: provider.hasMoreScans,
        onRefresh: () => provider.loadScans(refresh: true),
        onLoadMore: provider.loadMoreScans,
        onRetry: () => provider.loadScans(),
        emptyState: EmptyState(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Nothing scanned yet',
          message: 'Your verified products will appear here.',
          actionLabel: 'Scan a product',
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ScannerScreen()),
          ),
        ),
        itemBuilder: (context, scan, index) => _tile(scan),
      ),
    );
  }

  Widget _tile(ScanCard scan) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScanDetailScreen(scanId: scan.scanId),
        ),
      ),
      child: Row(
        children: [
          AppImage(url: scan.image, width: 56, height: 56),
          const SizedBox(width: 14),
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
                const SizedBox(height: 4),
                if (scan.brand != null && scan.brand!.isNotEmpty)
                  Text(
                    scan.brand!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatusChip(
                      label: scan.statusLabel,
                      tone: scan.genuine
                          ? StatusTone.success
                          : StatusTone.danger,
                      dense: true,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        scan.scannedAgo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
