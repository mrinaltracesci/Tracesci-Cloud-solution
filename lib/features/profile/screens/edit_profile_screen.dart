import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/surfaces.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _addressOne;
  late final TextEditingController _addressTwo;
  late final TextEditingController _zip;

  String? _gender;
  DateTime? _dob;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();

    final profile = context.read<AuthProvider>().profile;

    _firstName = TextEditingController(text: profile.firstName ?? '');
    _lastName = TextEditingController(text: profile.lastName ?? '');
    _email = TextEditingController(text: profile.email ?? '');
    _addressOne = TextEditingController(text: profile.addressOne ?? '');
    _addressTwo = TextEditingController(text: profile.addressTwo ?? '');
    _zip = TextEditingController(text: profile.zip ?? '');
    _gender = _normaliseGender(profile.gender);
    _dob = _parseDob(profile.dob);

    for (final c in [
      _firstName,
      _lastName,
      _email,
      _addressOne,
      _addressTwo,
      _zip,
    ]) {
      c.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _addressOne,
      _addressTwo,
      _zip,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty && mounted) setState(() => _dirty = true);
  }

  String? _normaliseGender(String? value) {
    if (value == null) return null;
    final lower = value.toLowerCase();
    return ['m', 'f', 'o'].contains(lower) ? lower : null;
  }

  DateTime? _parseDob(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String get _dobLabel {
    if (_dob == null) return 'Select your date of birth';
    return '${_dob!.day.toString().padLeft(2, '0')}/'
        '${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}';
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Your date of birth',
    );

    if (picked != null && mounted) {
      setState(() {
        _dob = picked;
        _dirty = true;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    final auth = context.read<AuthProvider>();

    final saved = await auth.updateProfile({
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'name': '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim(),
      'email': _email.text.trim(),
      'gender': _gender,
      'dob': _dob == null
          ? null
          : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-'
              '${_dob!.day.toString().padLeft(2, '0')}',
      'address_one': _addressOne.text.trim(),
      'address_two': _addressTwo.text.trim(),
      'zip': _zip.text.trim(),
    });

    if (!mounted) return;

    if (!saved) {
      Notify.error(context, auth.error);
      return;
    }

    Notify.success(context, 'Profile saved');
    Navigator.of(context).pop();
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits have not been saved yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Discard',
              style: AppTextStyles.button.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit profile')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              FadeSlideIn(child: _avatarBlock(profile.initials, profile.name)),
              const SizedBox(height: 26),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: _lockedField(
                  label: 'MOBILE NUMBER',
                  value: profile.displayPhone.isEmpty
                      ? 'Not set'
                      : profile.displayPhone,
                  icon: Icons.phone_rounded,
                  note: 'Your number is your login and cannot be changed here.',
                ),
              ),
              const SizedBox(height: 22),
              _label('FIRST NAME'),
              TextFormField(
                controller: _firstName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'First name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _label('LAST NAME'),
              TextFormField(
                controller: _lastName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Last name'),
              ),
              const SizedBox(height: 18),
              _label('EMAIL'),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _label('DATE OF BIRTH'),
              Pressable(
                onTap: _pickDob,
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cake_rounded,
                        size: 20,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dobLabel,
                          style: _dob == null
                              ? AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textTertiary,
                                )
                              : AppTextStyles.bodyLarge,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _label('GENDER'),
              Row(
                children: [
                  _genderChip('m', 'Male', Icons.male_rounded),
                  const SizedBox(width: 10),
                  _genderChip('f', 'Female', Icons.female_rounded),
                  const SizedBox(width: 10),
                  _genderChip('o', 'Other', Icons.transgender_rounded),
                ],
              ),
              const SizedBox(height: 22),
              _label('ADDRESS'),
              TextFormField(
                controller: _addressOne,
                decoration: const InputDecoration(
                  hintText: 'House, street, area',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressTwo,
                decoration: const InputDecoration(hintText: 'City, state'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _zip,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'PIN code',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 30),
              AppButton(
                label: _dirty ? 'Save changes' : 'Saved',
                icon: _dirty ? Icons.check_rounded : null,
                loading: auth.busy,
                onPressed: _dirty ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarBlock(String initials, String name) {
    return Center(
      child: Column(
        children: [
          Container(
            height: 92,
            width: 92,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppTextStyles.displayLarge.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(name, style: AppTextStyles.headingSmall),
        ],
      ),
    );
  }

  Widget _lockedField({
    required String label,
    required String value,
    required IconData icon,
    required String note,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textTertiary),
              const SizedBox(width: 12),
              Expanded(child: Text(value, style: AppTextStyles.bodyLarge)),
              const Icon(
                Icons.lock_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Text(note, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _genderChip(String value, String label, IconData icon) {
    final selected = _gender == value;

    return Expanded(
      child: Pressable(
        onTap: () => setState(() {
          _gender = value;
          _dirty = true;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.label),
    );
  }
}
