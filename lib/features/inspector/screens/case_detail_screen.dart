import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/location_helper.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/timeline_view.dart';
import '../models/case_models.dart';
import '../providers/inspector_provider.dart';

class CaseDetailScreen extends StatefulWidget {
  final int caseId;

  const CaseDetailScreen({super.key, required this.caseId});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  CaseDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final detail = await context.read<InspectorProvider>().caseDetail(
          widget.caseId,
        );

    if (!mounted) return;

    setState(() {
      _detail = detail;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Scaffold(
      appBar: AppBar(title: Text(detail?.reference ?? 'Case')),
      body: _body(),
      bottomNavigationBar: detail == null || !detail.canClose
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    if (detail.canDeactivate) ...[
                      Expanded(
                        child: AppButton(
                          label: 'Block',
                          icon: Icons.gpp_bad_rounded,
                          variant: AppButtonVariant.ghost,
                          onPressed: () => _seize(detail),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: 'Close report',
                        icon: Icons.check_circle_rounded,
                        onPressed: () => _resolve(detail),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _body() {
    if (_loading) return const ListSkeleton(itemCount: 4, itemHeight: 130);

    final detail = _detail;

    if (detail == null) {
      return ErrorView(
        message: 'This report could not be loaded.',
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
          if (detail.product != null) ...[
            const SizedBox(height: 20),
            const SectionHeader(title: 'Product'),
            _productCard(detail.product!),
          ],
          if (detail.reportedBy != null) ...[
            const SizedBox(height: 20),
            const SectionHeader(title: 'Reported by'),
            _contactCard(detail.reportedBy!, Icons.person_rounded),
          ],
          if (detail.manufacturer != null) ...[
            const SizedBox(height: 20),
            const SectionHeader(title: 'Manufacturer'),
            _contactCard(detail.manufacturer!, Icons.factory_rounded),
          ],
          if (detail.location != null) ...[
            const SizedBox(height: 20),
            AppCard(
              child: InfoRow(
                label: 'Reported location',
                value: LocationHelper.readableCoordinates(detail.location) ??
                    'Not available',
                icon: Icons.location_on_rounded,
              ),
            ),
          ],
          if (detail.journey.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader(title: 'Supply chain journey'),
            AppCard(child: TimelineView(entries: _entries(detail.journey))),
          ],
          if (detail.resolution != null && detail.resolution!.isNotEmpty) ...[
            const SizedBox(height: 20),
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
                        Text('Resolution', style: AppTextStyles.label),
                        const SizedBox(height: 4),
                        Text(
                          detail.resolution!,
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
    );
  }

  Widget _summaryCard(CaseDetail detail) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail.kind, style: AppTextStyles.label),
                    const SizedBox(height: 4),
                    Text(detail.reference, style: AppTextStyles.headingSmall),
                  ],
                ),
              ),
              StatusChip.forStatus(detail.status),
            ],
          ),
          const SizedBox(height: 16),
          Text(detail.description, style: AppTextStyles.bodyLarge),
          if (detail.issueType != null && detail.issueType!.isNotEmpty) ...[
            const SizedBox(height: 12),
            StatusChip(label: detail.issueType!, tone: StatusTone.warning),
          ],
          if (detail.image.isNotEmpty) ...[
            const SizedBox(height: 16),
            AppImage(
              url: detail.image,
              width: double.infinity,
              height: 180,
              radius: BorderRadius.circular(AppTheme.radiusMedium),
              placeholderIcon: Icons.image_rounded,
            ),
          ],
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 6),
          InfoRow(
            label: 'Raised',
            value: detail.createdAt,
            icon: Icons.schedule_rounded,
          ),
        ],
      ),
    );
  }

  Widget _productCard(CaseProduct product) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppImage(url: product.image, width: 60, height: 60),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: AppTextStyles.titleMedium),
                    if (product.brand != null && product.brand!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(product.brand!, style: AppTextStyles.bodySmall),
                    ],
                    if (product.codeStatus != null) ...[
                      const SizedBox(height: 8),
                      StatusChip.forStatus(product.codeStatus!),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 6),
          if (product.codeData != null)
            InfoRow(label: 'Code', value: product.codeData!),
          InfoRow(label: 'Batch', value: product.batchCode ?? '-'),
          InfoRow(label: 'Manufactured on', value: product.manufacturedOn),
          InfoRow(label: 'Expires on', value: product.expiryOn),
        ],
      ),
    );
  }

  Widget _contactCard(ContactCard contact, IconData icon) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.primary, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(contact.name, style: AppTextStyles.titleMedium),
              ),
              if (contact.phone != null && contact.phone!.trim().isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.call_rounded,
                    color: AppColors.success,
                  ),
                  onPressed: () => _dial(contact.phone!),
                ),
            ],
          ),
          if (contact.email != null && contact.email!.isNotEmpty)
            InfoRow(
              label: 'Email',
              value: contact.email!,
              icon: Icons.mail_rounded,
            ),
          if (contact.address != null && contact.address!.isNotEmpty)
            InfoRow(
              label: 'Address',
              value: contact.address!,
              icon: Icons.location_on_rounded,
            ),
        ],
      ),
    );
  }

  Future<void> _dial(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      Notify.error(context, 'Could not start the call.');
    }
  }

  Future<void> _resolve(CaseDetail detail) async {
    final controller = TextEditingController();
    final provider = context.read<InspectorProvider>();
    var busy = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> submit() async {
            if (controller.text.trim().isEmpty) {
              Notify.error(sheetContext, 'Add a closing remark');
              return;
            }

            setSheetState(() => busy = true);

            try {
              await provider.updateCase(
                id: detail.id,
                status: '1',
                comments: controller.text.trim(),
              );
              if (!sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
              if (!mounted) return;
              Notify.success(context, 'Case closed.');
              _load();
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
                Text('Close report', style: AppTextStyles.headingMedium),
                const SizedBox(height: 6),
                Text(
                  'Record what you found and how it was handled. This is shared with the reporter.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText: 'Investigation outcome',
                  ),
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Close report',
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

  Future<void> _seize(CaseDetail detail) async {
    final code = detail.product?.codeData;

    if (code == null || code.isEmpty) {
      Notify.error(context, 'No product code linked to this report.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deactivate this product?'),
        content: Text(
          'Code $code will be marked inactive. Any future scan will flag it as suspicious.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Deactivate',
              style: AppTextStyles.button.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final result = await context.read<InspectorProvider>().seize(
            type: '0',
            code: code,
          );
      if (!mounted) return;
      Notify.success(context, result.message);
      _load();
    } on ApiException catch (failure) {
      if (!mounted) return;
      Notify.error(context, failure.message);
    }
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
