import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/motion.dart';
import '../data/auth_repository.dart';
import '../providers/auth_provider.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _consumerKey = GlobalKey<FormState>();
  final _officialKey = GlobalKey<FormState>();

  LoginMode _mode = LoginMode.consumer;
  final String _countryCode = '91';
  bool _obscure = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isConsumer => _mode == LoginMode.consumer;

  void _switchMode(LoginMode mode) {
    if (_mode == mode) return;
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() => _mode = mode);
    context.read<AuthProvider>().setLoginMode(mode);
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();

    final form = _isConsumer ? _consumerKey : _officialKey;
    if (!form.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    final sent = _isConsumer
        ? await auth.requestConsumerOtp(
            phoneCode: _countryCode,
            phone: _phoneController.text.trim(),
          )
        : await auth.requestOfficialOtp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

    if (!mounted) return;

    if (!sent) {
      HapticFeedback.heavyImpact();
      Notify.error(context, auth.error);
      return;
    }

    Navigator.of(context).push(SmoothPageRoute(page: const OtpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: AuroraBackground(
              colors: _isConsumer
                  ? const [Color(0xFF0F62FE), Color(0xFF6E56CF)]
                  : const [Color(0xFF12A150), Color(0xFF0F62FE)],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 32 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FadeSlideIn(child: _Brand()),
                  const SizedBox(height: 32),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 90),
                    child: _ModeSwitch(mode: _mode, onChanged: _switchMode),
                  ),
                  const SizedBox(height: 30),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.06, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _isConsumer
                          ? _consumerForm(auth)
                          : _officialForm(auth),
                    ),
                  ),
                  const SizedBox(height: 26),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 260),
                    child: AppButton(
                      label: _isConsumer ? 'Send code' : 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      loading: auth.busy,
                      onPressed: _submit,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 320),
                    child: Center(
                      child: Text(
                        _isConsumer
                            ? 'New here? Just enter your number — your account is created automatically.'
                            : 'Official accounts are issued by your administrator.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _consumerForm(AuthProvider auth) {
    return Form(
      key: _consumerKey,
      child: Column(
        key: const ValueKey('consumer'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back', style: AppTextStyles.displayLarge),
          const SizedBox(height: 8),
          Text(
            'Sign in with your mobile number to verify products and collect rewards.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 26),
          Text('MOBILE NUMBER', style: AppTextStyles.label),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Text('🇮🇳', style: TextStyle(fontSize: 19)),
                    const SizedBox(width: 8),
                    Text('+$_countryCode', style: AppTextStyles.titleMedium),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  style: AppTextStyles.headingSmall,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: '9876543210',
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length != 10) {
                      return 'Enter a 10 digit mobile number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 15,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'We will text you a 4 digit verification code.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _officialForm(AuthProvider auth) {
    return Form(
      key: _officialKey,
      child: Column(
        key: const ValueKey('official'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Official sign in', style: AppTextStyles.displayLarge),
          const SizedBox(height: 8),
          Text(
            'For supply chain, inspection and brand accounts issued by your organisation.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 26),
          Text('WORK EMAIL', style: AppTextStyles.label),
          const SizedBox(height: 10),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'you@company.com',
              prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
            ),
            validator: (value) {
              if (value == null || !value.contains('@')) {
                return 'Enter a valid work email';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          Text('PASSWORD', style: AppTextStyles.label),
          const SizedBox(height: 10),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 15,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Two step: password, then a 4 digit code.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.32),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TraceSci', style: AppTextStyles.headingMedium),
            const SizedBox(height: 2),
            Text(
              'Verify. Track. Trust.',
              style: AppTextStyles.caption.copyWith(letterSpacing: 1.4),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  final LoginMode mode;
  final ValueChanged<LoginMode> onChanged;

  const _ModeSwitch({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium + 2),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segment = (constraints.maxWidth - 10) / 2;

          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                alignment: mode == LoginMode.consumer
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  height: 46,
                  width: segment,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B1220).withOpacity(0.09),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _segment(
                    label: 'Consumer',
                    icon: Icons.person_rounded,
                    active: mode == LoginMode.consumer,
                    onTap: () => onChanged(LoginMode.consumer),
                  ),
                  _segment(
                    label: 'Official',
                    icon: Icons.badge_rounded,
                    active: mode == LoginMode.official,
                    onTap: () => onChanged(LoginMode.official),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _segment({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                child: Icon(
                  icon,
                  size: 18,
                  color: active ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 260),
                style: AppTextStyles.button.copyWith(
                  color: active ? AppColors.textPrimary : AppColors.textTertiary,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
