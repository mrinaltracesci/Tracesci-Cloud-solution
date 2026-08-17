import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/location_helper.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/surfaces.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/consumer_models.dart';
import '../providers/consumer_provider.dart';

class ReportProductScreen extends StatefulWidget {
  final String? codeData;
  final int? productId;
  final String? productName;
  final int? scanId;
  final String? presetIssue;

  const ReportProductScreen({
    super.key,
    this.codeData,
    this.productId,
    this.productName,
    this.scanId,
    this.presetIssue,
  });

  @override
  State<ReportProductScreen> createState() => _ReportProductScreenState();
}

class _ReportProductScreenState extends State<ReportProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _codeController = TextEditingController();
  final _batchController = TextEditingController();
  final _picker = ImagePicker();

  String? _issueType;
  bool _submitting = false;
  XFile? _photo;

  @override
  void initState() {
    super.initState();
    if (widget.codeData != null) _codeController.text = widget.codeData!;
    _issueType = widget.presetIssue;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _codeController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  List<IssueType> get _issueTypes {
    final fromApi = context.read<AuthProvider>().masters.reportIssueTypes;

    if (fromApi.isNotEmpty) return fromApi;

    return const [
      IssueType(label: 'Looks fake', value: 'counterfeit'),
      IssueType(label: 'Pack is damaged', value: 'damaged'),
      IssueType(label: 'Past its expiry date', value: 'expired'),
      IssueType(label: 'Wrong item inside', value: 'wrong_product'),
      IssueType(label: 'Something else', value: 'other'),
    ];
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (file != null && mounted) setState(() => _photo = file);
    } catch (_) {
      if (mounted) Notify.error(context, 'Could not open the camera.');
    }
  }

  Future<void> _choosePhotoSource() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              height: 4,
              width: 44,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_issueType == null) {
      Notify.error(context, 'Please pick what went wrong');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final location = await LocationHelper.current();

    if (!mounted) return;

    try {
      final report = await context.read<ConsumerProvider>().repository.report(
            issueType: _issueType!,
            description: _descriptionController.text.trim(),
            codeData: _codeController.text.trim(),
            productId: widget.productId,
            batch: _batchController.text.trim(),
            scanId: widget.scanId,
            photoPath: _photo?.path,
            location: location,
          );

      if (!mounted) return;
      await _showSuccess(report);
    } on ApiException catch (failure) {
      if (!mounted) return;
      setState(() => _submitting = false);
      Notify.error(context, failure.message);
    }
  }

  Future<void> _showSuccess(ReportItem report) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                height: 76,
                width: 76,
                decoration: const BoxDecoration(
                  color: AppColors.successSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Thanks for telling us', style: AppTextStyles.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Our team and the brand can now trace this pack. We will let you know what we find.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                'Reference ${report.reference}',
                style: AppTextStyles.titleMedium,
              ),
            ),
            const SizedBox(height: 26),
            AppButton(
              label: 'Done',
              onPressed: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).pop(true);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tell us what is wrong')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            if (widget.productName != null) ...[
              FadeSlideIn(
                child: AppCard(
                  color: AppColors.primarySoft,
                  shadow: const [],
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.productName!,
                          style: AppTextStyles.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
            ],
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: Text('What went wrong?', style: AppTextStyles.headingSmall),
            ),
            const SizedBox(height: 12),
            ..._issueTypes.asMap().entries.map(
                  (entry) => FadeSlideIn(
                    delay: Duration(milliseconds: 80 + entry.key * 45),
                    child: _issueOption(entry.value),
                  ),
                ),
            const SizedBox(height: 22),
            FadeSlideIn(
              delay: const Duration(milliseconds: 260),
              child: _photoSection(),
            ),
            const SizedBox(height: 22),
            Text('Describe it in your words', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText:
                    'Where did you buy it? What looked wrong? Anything else we should know.',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().length < 10) {
                  return 'Please write at least a sentence';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text('Code on the pack', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                hintText: 'Optional if you already scanned it',
                prefixIcon: Icon(Icons.qr_code_2_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            Text('Batch number', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _batchController,
              decoration: const InputDecoration(
                hintText: 'Optional',
                prefixIcon: Icon(Icons.inventory_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Send report',
              icon: Icons.send_rounded,
              loading: _submitting,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Your location is attached so we can trace where it came from.',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add a photo', style: AppTextStyles.label),
        const SizedBox(height: 4),
        Text(
          'A picture of the pack helps us a lot.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 12),
        if (_photo == null)
          Pressable(
            onTap: _choosePhotoSource,
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      color: AppColors.primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Tap to add a photo', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          )
        else
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Image.file(
                  File(_photo!.path),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Pressable(
                  onTap: () => setState(() => _photo = null),
                  child: Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _issueOption(IssueType type) {
    final selected = _issueType == type.value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: () => setState(() => _issueType = type.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
                size: 21,
                color: selected ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  type.label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
