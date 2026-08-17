import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/location_helper.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../models/alert_item.dart';
import '../providers/alert_provider.dart';

class AlertsScreen extends StatefulWidget {
  final bool embedded;

  const AlertsScreen({super.key, this.embedded = false});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('Alerts'),
        bottom: provider.canSeeProducts
            ? PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilterChipsRow(
                    selected: provider.scope,
                    onSelected: provider.setScope,
                    options: [
                      const FilterOption(label: 'Everything'),
                      FilterOption(
                        label: 'I raised',
                        value: 'mine',
                        count: provider.mineCount,
                      ),
                      FilterOption(
                        label: 'On my products',
                        value: 'products',
                        count: provider.productCount,
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: PagedListView<AlertItem>(
        items: provider.alerts,
        status: provider.status,
        errorMessage: provider.errorMessage,
        isNetworkError: provider.isNetworkError,
        loadingMore: provider.loadingMore,
        hasMore: provider.hasMore,
        onRefresh: () => provider.load(refresh: true),
        onLoadMore: provider.loadMore,
        onRetry: () => provider.load(),
        separatorHeight: 14,
        emptyState: const EmptyState(
          icon: Icons.verified_user_rounded,
          title: 'Nothing to worry about',
          message: 'Warnings from your scans will show up here.',
        ),
        itemBuilder: (context, alert, index) => FadeSlideIn(
          delay: Duration(milliseconds: 40 * (index % 8)),
          child: _card(alert),
        ),
      ),
    );
  }

  Widget _card(AlertItem alert) {
    final tone = alert.isOpen ? AppColors.danger : AppColors.success;

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => _openDetail(alert),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: tone.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  alert.isReport
                      ? Icons.outlined_flag_rounded
                      : Icons.warning_amber_rounded,
                  color: tone,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(alert.productName, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              StatusChip.forStatus(alert.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              StatusChip(
                label: alert.raisedByMe ? 'You reported' : alert.raisedBy,
                tone: alert.raisedByMe ? StatusTone.primary : StatusTone.neutral,
                dense: true,
                icon: Icons.person_rounded,
              ),
              const Spacer(),
              Text(alert.createdAgo, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  void _openDetail(AlertItem alert) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Center(
              child: Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(alert.title, style: AppTextStyles.headingMedium),
            const SizedBox(height: 6),
            Text(alert.reference, style: AppTextStyles.caption),
            const SizedBox(height: 16),
            Row(
              children: [
                StatusChip.forStatus(alert.status),
                const SizedBox(width: 8),
                StatusChip(label: alert.kind, tone: StatusTone.neutral),
              ],
            ),
            const SizedBox(height: 18),
            if (alert.image.isNotEmpty) ...[
              AppImage(
                url: alert.image,
                width: double.infinity,
                height: 190,
                radius: BorderRadius.circular(14),
                placeholderIcon: Icons.image_rounded,
              ),
              const SizedBox(height: 18),
            ],
            AppCard(
              child: Column(
                children: [
                  InfoRow(label: 'Product', value: alert.productName),
                  if (alert.batch != null)
                    InfoRow(label: 'Batch', value: alert.batch!),
                  if (alert.issueType != null)
                    InfoRow(label: 'Problem', value: alert.issueType!),
                  InfoRow(label: 'Raised by', value: alert.raisedBy),
                  InfoRow(label: 'When', value: alert.createdAt),
                  if (alert.location != null)
                    InfoRow(
                      label: 'Where',
                      value:
                          LocationHelper.readableCoordinates(alert.location) ??
                              'Not available',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Details', style: AppTextStyles.label),
            const SizedBox(height: 6),
            Text(alert.description, style: AppTextStyles.bodyLarge),
            if (alert.resolution != null && alert.resolution!.isNotEmpty) ...[
              const SizedBox(height: 18),
              AppCard(
                color: AppColors.successSoft,
                shadow: const [],
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 19,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('What we found', style: AppTextStyles.label),
                          const SizedBox(height: 4),
                          Text(
                            alert.resolution!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
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
}
