import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/motion.dart';
import '../../shell/screens/app_shell.dart';
import '../data/auth_repository.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _errorShake = GlobalKey<_ShakeState>();

  Timer? _timer;
  int _seconds = 30;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _startTimer();

    final debugOtp = context.read<AuthProvider>().debugOtp;
    if (debugOtp != null && debugOtp.length == 4) {
      _controller.text = debugOtp;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 30);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _seconds = 0);
        return;
      }
      if (mounted) setState(() => _seconds -= 1);
    });
  }

  Future<void> _verify() async {
    if (_controller.text.trim().length != 4) {
      _errorShake.currentState?.shake();
      Notify.error(context, 'Enter the 4 digit code');
      return;
    }

    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(_controller.text.trim());

    if (!mounted) return;

    if (!success) {
      HapticFeedback.heavyImpact();
      _errorShake.currentState?.shake();
      Notify.error(context, auth.error);
      _controller.clear();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _verified = true);

    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      SmoothPageRoute(page: const AppShell()),
      (route) => false,
    );
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();

    if (auth.loginMode == LoginMode.official) {
      Notify.info(context, 'Please sign in again to receive a new code.');
      return;
    }

    final sent = await auth.resendOtp();

    if (!mounted) return;

    if (sent) {
      _startTimer();
      Notify.success(context, 'A new code has been sent.');
    } else {
      Notify.error(context, auth.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isConsumer = auth.loginMode == LoginMode.consumer;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: AuroraBackground(
              colors: _verified
                  ? const [Color(0xFF12A150), Color(0xFF38C97D)]
                  : const [Color(0xFF0F62FE), Color(0xFF6E56CF)],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                32 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 18),
                  FadeSlideIn(child: _badge(isConsumer, auth)),
                  const SizedBox(height: 26),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: Text(
                      auth.pendingIsNewUser
                          ? 'Create your account'
                          : 'Verify it is you',
                      style: AppTextStyles.displayLarge,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodyMedium,
                        children: [
                          const TextSpan(text: 'Enter the 4 digit code sent to '),
                          TextSpan(
                            text: auth.pendingIdentity,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: _Shake(
                      key: _errorShake,
                      child: PinCodeTextField(
                        appContext: context,
                        length: 4,
                        controller: _controller,
                        autoFocus: true,
                        enabled: !_verified,
                        keyboardType: TextInputType.number,
                        animationType: AnimationType.scale,
                        animationDuration: const Duration(milliseconds: 220),
                        enableActiveFill: true,
                        cursorColor: AppColors.primary,
                        textStyle: AppTextStyles.headingMedium,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium + 2,
                          ),
                          fieldHeight: 66,
                          fieldWidth: 62,
                          activeColor: _verified
                              ? AppColors.success
                              : AppColors.primary,
                          selectedColor: AppColors.primary,
                          inactiveColor: AppColors.border,
                          activeFillColor: _verified
                              ? AppColors.successSoft
                              : AppColors.primarySoft,
                          selectedFillColor: AppColors.surface,
                          inactiveFillColor: AppColors.surfaceAlt,
                          borderWidth: 1.5,
                        ),
                        onChanged: (_) {},
                        onCompleted: (_) => _verify(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 260),
                    child: Center(child: _resendRow(isConsumer)),
                  ),
                  const SizedBox(height: 30),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: _verified
                          ? const _SuccessPill(key: ValueKey('done'))
                          : AppButton(
                              key: const ValueKey('verify'),
                              label: 'Verify and continue',
                              loading: auth.busy,
                              onPressed: _verify,
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

  Widget _badge(bool isConsumer, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConsumer ? Icons.person_rounded : Icons.badge_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            isConsumer
                ? 'Consumer'
                : (auth.pendingRoleLabel ?? 'Official'),
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          if (!isConsumer && auth.pendingDisplayName != null) ...[
            const SizedBox(width: 8),
            Container(width: 1, height: 12, color: AppColors.border),
            const SizedBox(width: 8),
            Text(
              auth.pendingDisplayName!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resendRow(bool isConsumer) {
    if (!isConsumer) {
      return Text(
        'Code expires shortly. Go back to sign in again if needed.',
        textAlign: TextAlign.center,
        style: AppTextStyles.caption,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Didn't get the code? ", style: AppTextStyles.bodySmall),
        if (_seconds > 0)
          Text(
            'Resend in ${_seconds}s',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Pressable(
            onTap: _resend,
            child: Text(
              'Resend code',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _SuccessPill extends StatelessWidget {
  const _SuccessPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 21),
          const SizedBox(width: 10),
          Text(
            'Verified',
            style: AppTextStyles.button.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _Shake extends StatefulWidget {
  final Widget child;

  const _Shake({super.key, required this.child});

  @override
  State<_Shake> createState() => _ShakeState();
}

class _ShakeState extends State<_Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final dx = t == 0 ? 0.0 : (1 - t) * 14 * _wave(t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }

  double _wave(double t) {
    return (t * 22) % 2 < 1 ? 1 : -1;
  }
}
