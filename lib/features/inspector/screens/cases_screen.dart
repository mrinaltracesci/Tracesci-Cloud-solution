import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../models/case_models.dart';
import '../providers/inspector_provider.dart';
import 'case_detail_screen.dart';

class CasesScreen extends StatefulWidget {
  final bool embedded;

  const CasesScreen({super.key, this.embedded = false});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InspectorProvider>().loadCases();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InspectorProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('Reports'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: provider.setSearch,
                  decoration: InputDecoration(
                    hintText: 'Search product, batch or description',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearch('');
                            },
                          ),
                  ),
                ),
              ),
              FilterChipsRow(
                selected: provider.statusFilter,
                onSelected: provider.setStatusFilter,
                options: const [
                  FilterOption(label: 'All'),
                  FilterOption(label: 'Open', value: '0'),
                  FilterOption(label: 'Closed', value: '1'),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: PagedListView<CaseCard>(
        items: provider.cases,
        status: provider.status,
        errorMessage: provider.errorMessage,
        isNetworkError: provider.isNetworkError,
        loadingMore: provider.loadingMore,
        hasMore: provider.hasMore,
        onRefresh: () => provider.loadCases(refresh: true),
        onLoadMore: provider.loadMoreCases,
        onRetry: () => provider.loadCases(),
        separatorHeight: 14,
        emptyState: const EmptyState(
          icon: Icons.folder_open_rounded,
          title: 'No reports found',
          message: 'Nothing matches this filter right now.',
        ),
        itemBuilder: (context, item, index) => _card(item),
      ),
    );
  }

  Widget _card(CaseCard item) {
    final isReport = item.kind.toLowerCase().contains('consumer');

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: item.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: (isReport ? AppColors.info : AppColors.warning)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isReport
                      ? Icons.outlined_flag_rounded
                      : Icons.warning_amber_rounded,
                  color: isReport ? AppColors.info : AppColors.warning,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(item.reference, style: AppTextStyles.caption),
                  ],
                ),
              ),
              StatusChip.forStatus(item.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              StatusChip(
                label: item.kind,
                tone: StatusTone.neutral,
                dense: true,
              ),
              if (item.batch != null && item.batch!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: StatusChip(
                    label: 'Batch ${item.batch}',
                    tone: StatusTone.neutral,
                    dense: true,
                  ),
                ),
              ],
              const Spacer(),
              Text(item.createdAgo, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
