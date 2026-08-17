import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../models/reward_models.dart';
import '../providers/reward_provider.dart';

class RewardCatalogScreen extends StatefulWidget {
  const RewardCatalogScreen({super.key});

  @override
  State<RewardCatalogScreen> createState() => _RewardCatalogScreenState();
}

class _RewardCatalogScreenState extends State<RewardCatalogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RewardProvider>().loadCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RewardProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('What you can get')),
      body: PagedListView<RewardScheme>(
        items: provider.catalog,
        status: provider.status,
        errorMessage: provider.errorMessage,
        isNetworkError: provider.isNetworkError,
        onRefresh: () => provider.loadCatalog(refresh: true),
        onRetry: () => provider.loadCatalog(),
        separatorHeight: 16,
        emptyState: const EmptyState(
          icon: Icons.redeem_rounded,
          title: 'No rewards right now',
          message: 'Brands publish new reward schemes regularly. Check back soon.',
        ),
        itemBuilder: (context, scheme, index) => _schemeCard(scheme),
      ),
    );
  }

  Widget _schemeCard(RewardScheme scheme) {
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
                    Text(scheme.title, style: AppTextStyles.headingSmall),
                    if (scheme.brand != null && scheme.brand!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(scheme.brand!, style: AppTextStyles.bodySmall),
                    ],
                  ],
                ),
              ),
              StatusChip(
                label: '${Formats.points(scheme.balance)} pts',
                tone: StatusTone.primary,
              ),
            ],
          ),
          if (scheme.validTo.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Valid till ${scheme.validTo}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          ...scheme.items.map((item) => _itemRow(scheme, item)),
        ],
      ),
    );
  }

  Widget _itemRow(RewardScheme scheme, RewardItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.canRedeem ? AppColors.surface : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: item.canRedeem ? AppColors.border : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: (item.isCash ? AppColors.success : AppColors.info)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.isCash
                    ? Icons.account_balance_wallet_rounded
                    : Icons.card_giftcard_rounded,
                size: 19,
                color: item.isCash ? AppColors.success : AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.canRedeem
                        ? '${Formats.points(item.points)} points'
                        : '${Formats.points(item.shortBy)} points short',
                    style: AppTextStyles.caption.copyWith(
                      color: item.canRedeem
                          ? AppColors.textSecondary
                          : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AppButton(
              label: 'Redeem',
              expanded: false,
              height: 38,
              variant: item.canRedeem
                  ? AppButtonVariant.primary
                  : AppButtonVariant.ghost,
              onPressed:
                  item.canRedeem ? () => _startRedeem(scheme, item) : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRedeem(RewardScheme scheme, RewardItem item) async {
    if (item.isCash) {
      await _cashSheet(scheme, item);
    } else {
      await _addressSheet(scheme, item);
    }
  }

  Future<void> _cashSheet(RewardScheme scheme, RewardItem item) async {
    final upiController = TextEditingController();
    final provider = context.read<RewardProvider>();
    var busy = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> submit() async {
            if (upiController.text.trim().length < 5) {
              Notify.error(sheetContext, 'Enter a valid UPI id');
              return;
            }

            setSheetState(() => busy = true);

            try {
              await provider.redeemCash(
                schemeId: scheme.schemeId,
                points: item.points,
                upiId: upiController.text.trim(),
                brand: scheme.brand,
              );
              if (!sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
              if (!mounted) return;
              provider.loadCatalog(refresh: true);
              Notify.success(context, 'Payout initiated successfully.');
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
                Text('Money to your UPI', style: AppTextStyles.headingMedium),
                const SizedBox(height: 6),
                Text(
                  'Redeeming ${Formats.points(item.points)} points for ${item.item}.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: upiController,
                  decoration: const InputDecoration(
                    hintText: 'yourname@upi',
                    prefixIcon: Icon(Icons.account_balance_rounded),
                  ),
                ),
                const SizedBox(height: 22),
                AppButton(
                  label: 'Send money',
                  loading: busy,
                  onPressed: submit,
                ),
              ],
            ),
          );
        },
      ),
    );

    upiController.dispose();
  }

  Future<void> _addressSheet(RewardScheme scheme, RewardItem item) async {
    final name = TextEditingController();
    final address = TextEditingController();
    final city = TextEditingController();
    final state = TextEditingController();
    final pin = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final provider = context.read<RewardProvider>();
    var busy = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;

            setSheetState(() => busy = true);

            try {
              await provider.placeOrder(
                schemeId: scheme.schemeId,
                points: item.points,
                name: name.text.trim(),
                address: address.text.trim(),
                city: city.text.trim(),
                state: state.text.trim(),
                pinCode: pin.text.trim(),
                brand: scheme.brand,
              );
              if (!sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
              if (!mounted) return;
              provider.loadCatalog(refresh: true);
              Notify.success(context, 'Order placed successfully.');
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
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery details', style: AppTextStyles.headingMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Redeeming ${Formats.points(item.points)} points for ${item.item}.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    _field(name, 'Full name'),
                    const SizedBox(height: 12),
                    _field(address, 'Address'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field(city, 'City')),
                        const SizedBox(width: 12),
                        Expanded(child: _field(state, 'State')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _field(pin, 'PIN code', keyboard: TextInputType.number),
                    const SizedBox(height: 22),
                    AppButton(
                      label: 'Place order',
                      loading: busy,
                      onPressed: submit,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    name.dispose();
    address.dispose();
    city.dispose();
    state.dispose();
    pin.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(hintText: hint),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$hint is required';
        }
        return null;
      },
    );
  }
}
