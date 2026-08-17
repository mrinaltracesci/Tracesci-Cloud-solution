import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/timeline_view.dart';
import '../../scanner/screens/scanner_screen.dart';
import '../models/supply_chain_models.dart';
import '../providers/supply_chain_provider.dart';

class ChainScanResultScreen extends StatefulWidget {
  final SupplyChainScanResult result;

  const ChainScanResultScreen({super.key, required this.result});

  @override
  State<ChainScanResultScreen> createState() => _ChainScanResultScreenState();
}

class _ChainScanResultScreenState extends State<ChainScanResultScreen> {
  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(result)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (result.hasAction) _actionCard(result),
                if (result.hasAction) const SizedBox(height: 20),
                SectionHeader(
                  title: 'Contents',
                  subtitle: '${result.total} units inside',
                ),
                if (result.products.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No product details linked to this code.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  )
                else
                  ...result.products.map(_productTile),
                const SizedBox(height: 22),
                const SectionHeader(title: 'History'),
                AppCard(child: TimelineView(entries: _entries(result.history))),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Scan another',
                  icon: Icons.qr_code_scanner_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const ScannerScreen()),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(SupplyChainScanResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
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
                    '${result.total} units',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              result.aggregationUniqueId,
              style: AppTextStyles.headingLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              result.lastScanned == null
                  ? 'First scan of this shipment'
                  : 'Last scanned ${result.lastScanned}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.84),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(SupplyChainScanResult result) {
    final isCheckout = result.isCheckout;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: (isCheckout ? AppColors.warning : AppColors.success)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isCheckout
                      ? Icons.local_shipping_rounded
                      : Icons.inventory_2_rounded,
                  color: isCheckout ? AppColors.warning : AppColors.success,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCheckout ? 'Ready to send' : 'Ready to receive',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCheckout
                          ? 'Hand this shipment over to the next node'
                          : 'Confirm you have received this shipment',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AppButton(
            label: isCheckout ? 'Send shipment' : 'Receive',
            icon: isCheckout
                ? Icons.arrow_outward_rounded
                : Icons.download_done_rounded,
            onPressed: () => _openActionSheet(result),
          ),
        ],
      ),
    );
  }

  Future<void> _openActionSheet(SupplyChainScanResult result) async {
    final provider = context.read<SupplyChainProvider>();
    final commentController = TextEditingController();

    int? selectedUser;
    String? selectedStatus;
    var busy = false;

    final statuses = result.statuses.isNotEmpty
        ? result.statuses
        : provider.statuses;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> submit() async {
            if (result.isCheckout && selectedUser == null) {
              Notify.error(sheetContext, 'Choose who receives this');
              return;
            }

            setSheetState(() => busy = true);

            try {
              final message = await provider.performAction(
                scanId: result.scanId!,
                action: result.eligibleFor,
                user: selectedUser,
                comment: commentController.text.trim(),
                status: selectedStatus,
              );

              if (!sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();

              if (!mounted) return;
              Notify.success(context, message);
              Navigator.of(context).pop();
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
              top: 22,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 28,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text(
                    result.isCheckout ? 'Dispatch' : 'Receive',
                    style: AppTextStyles.headingMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.aggregationUniqueId,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 22),
                  if (result.isCheckout) ...[
                    Text('Handing over to', style: AppTextStyles.label),
                    const SizedBox(height: 10),
                    ...result.users.map(
                      (user) => _userOption(
                        user,
                        selectedUser == user.value,
                        () => setSheetState(() => selectedUser = user.value),
                      ),
                    ),
                    if (result.users.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                        child: Text(
                          'No downstream nodes are linked to your account yet.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                  if (statuses.isNotEmpty) ...[
                    Text('Condition', style: AppTextStyles.label),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: statuses
                          .map(
                            (status) => GestureDetector(
                              onTap: () => setSheetState(() {
                                selectedStatus = status.value;
                                if (status.comment != null &&
                                    commentController.text.isEmpty) {
                                  commentController.text = status.comment!;
                                }
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedStatus == status.value
                                      ? AppColors.primary
                                      : AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  status.label,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: selectedStatus == status.value
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text('Remarks', style: AppTextStyles.label),
                  const SizedBox(height: 10),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Optional note for this movement',
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: result.isCheckout ? 'Confirm send' : 'Confirm receive',
                    loading: busy,
                    onPressed: submit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    commentController.dispose();
  }

  Widget _userOption(ScanActionUser user, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(user.label, style: AppTextStyles.bodyLarge),
              ),
            ],
          ),
        ),
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
                    product.brand ?? 'Batch ${product.batchCode}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (product.isExpired)
              const StatusChip(
                label: 'Expired',
                tone: StatusTone.danger,
                dense: true,
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
        subtitle: step.actionFor != null ? 'to ${step.actionFor}' : null,
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
