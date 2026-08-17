import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../../auth/providers/auth_provider.dart';
import '../../scanner/screens/scanner_screen.dart';
import '../models/case_models.dart';
import '../providers/inspector_provider.dart';
import 'case_detail_screen.dart';
import 'cases_screen.dart';

class InspectorHomeScreen extends StatefulWidget {
  const InspectorHomeScreen({super.key});

  @override
  State<InspectorHomeScreen> createState() => _InspectorHomeScreenState();
}

class _InspectorHomeScreenState extends State<InspectorHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InspectorProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<InspectorProvider>();
    final dashboard = provider.dashboard;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => provider.loadDashboard(refresh: true),
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(auth)),
            if (provider.isLoading && dashboard == null)
              const SliverToBoxAdapter(child: DashboardSkeleton())
            else if (provider.isError && dashboard == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(
                  message: provider.errorMessage,
                  isNetwork: provider.isNetworkError,
                  onRetry: () => provider.loadDashboard(),
                ),
              )
            else if (dashboard != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    StatGrid(
                      tiles: dashboard.stats,
                      onTileTap: (tile) {
                        provider.setStatusFilter(tile.filter);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CasesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: 'Recent reports',
                      actionLabel:
                          dashboard.recentCases.isEmpty ? null : 'See all',
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CasesScreen()),
                      ),
                    ),
                    if (dashboard.recentCases.isEmpty)
                      _emptyCases()
                    else
                      ...dashboard.recentCases.map(_caseTile),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(AuthProvider auth) {
    return GradientHeader(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.28)),
                ),
                alignment: Alignment.center,
                child: Text(
                  auth.profile.initials,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      auth.profile.designation ?? auth.profile.roleLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _headerAction(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Verify a product',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ScannerScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _headerAction(
                  icon: Icons.gpp_bad_rounded,
                  label: 'Block a pack',
                  onTap: _openSeizeSheet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSeizeSheet() async {
    final controller = TextEditingController();
    final provider = context.read<InspectorProvider>();
    var type = '0';
    var busy = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> submit() async {
            if (controller.text.trim().isEmpty) {
              Notify.error(sheetContext, 'Enter the code to deactivate');
              return;
            }

            setSheetState(() => busy = true);

            try {
              final result = await provider.seize(
                type: type,
                code: controller.text.trim(),
              );
              if (!sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
              if (!mounted) return;
              Notify.success(
                context,
                '${result.affected} item(s) deactivated.',
              );
            } on ApiException catch (failure) {
              setSheetState(() => busy = false);
              if (!sheetContext.mounted) return;
              Notify.error(sheetContext, failure.message);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deactivate stock', style: AppTextStyles.headingMedium),
                const SizedBox(height: 6),
                Text(
                  'Counterfeit or recalled stock found in the field can be deactivated immediately.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _typeOption(
                        'Single code',
                        type == '0',
                        () => setSheetState(() => type = '0'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _typeOption(
                        'Whole batch',
                        type == '1',
                        () => setSheetState(() => type = '1'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: type == '0' ? 'Product code' : 'Batch code',
                    prefixIcon: const Icon(Icons.qr_code_2_rounded),
                  ),
                ),
                const SizedBox(height: 22),
                AppButton(
                  label: 'Deactivate',
                  variant: AppButtonVariant.danger,
                  loading: busy,
                  onPressed: submit,
                ),
              ],
            ),
          );
        },
      ),
    );

    controller.dispose();
  }

  Widget _typeOption(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _caseTile(CaseCard item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(15),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CaseDetailScreen(caseId: item.id),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium,
                  ),
                ),
                StatusChip.forStatus(item.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                StatusChip(
                  label: item.kind,
                  tone: StatusTone.neutral,
                  dense: true,
                ),
                const Spacer(),
                Text(item.createdAgo, style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCases() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: const BoxDecoration(
              color: AppColors.successSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.success,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text('Queue is clear', style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(
            'No reports are waiting for you right now.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
