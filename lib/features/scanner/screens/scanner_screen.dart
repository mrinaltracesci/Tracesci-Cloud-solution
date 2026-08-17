import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/location_helper.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/motion.dart';
import '../../auth/providers/auth_provider.dart';
import '../../consumer/providers/consumer_provider.dart';
import '../../consumer/models/verdict.dart';
import '../../consumer/screens/product_result_screen.dart';
import '../../consumer/screens/scan_problem_screen.dart';
import '../../shell/models/bootstrap.dart';
import '../../supplychain/providers/supply_chain_provider.dart';
import '../../supplychain/screens/chain_scan_result_screen.dart';
import '../widgets/scanner_overlay.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _processing = false;
  bool _torch = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;

    final raw = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .firstWhere((value) => value != null && value.isNotEmpty, orElse: () => null);

    if (raw == null) return;

    await _handleCode(_normalise(raw));
  }

  String _normalise(String value) {
    final trimmed = value.trim();

    if (trimmed.startsWith('http')) {
      final segments = Uri.tryParse(trimmed)?.pathSegments ?? const [];
      if (segments.isNotEmpty) return segments.last;
    }

    return trimmed;
  }

  Future<void> _handleCode(String code) async {
    setState(() => _processing = true);

    await _controller.stop();

    final auth = context.read<AuthProvider>();
    final config = auth.scanner;

    Map<String, dynamic>? location;

    if (config.requiresLocation) {
      location = await LocationHelper.current();
    }

    if (!mounted) return;

    try {
      if (config.mode == ScannerMode.supplyChain) {
        final result = await context
            .read<SupplyChainProvider>()
            .scan(code: code, location: location);

        if (!mounted) return;

        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChainScanResultScreen(result: result),
          ),
        );
        return;
      }

      final result = await context
          .read<ConsumerProvider>()
          .repository
          .scanCode(code: code, location: location);

      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProductResultScreen(result: result, code: code),
        ),
      );
    } on ApiException catch (failure) {
      if (!mounted) return;
      await _showFailure(failure, code);
    } catch (_) {
      if (!mounted) return;
      Notify.error(context, 'Could not read this code. Please try again.');
      _resume();
    }
  }

  Future<void> _showFailure(ApiException failure, String code) async {
    if (failure.isNetwork || failure.isUnauthorized) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => _FailureSheet(
          message: failure.message,
          code: code,
          isNetwork: failure.isNetwork,
          onRetry: () => Navigator.of(sheetContext).pop(),
        ),
      );

      if (!mounted) return;
      _resume();
      return;
    }

    ScanVerdict verdict;

    try {
      verdict = await context.read<ConsumerProvider>().repository.diagnose(code);
    } catch (_) {
      verdict = ScanVerdict.offline(code, failure.message);
    }

    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      SmoothPageRoute(page: ScanProblemScreen(verdict: verdict)),
    );
  }

  void _resume() {
    setState(() => _processing = false);
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final config = auth.scanner;
    final isChain = config.mode == ScannerMode.supplyChain;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) => _CameraError(
              message: error.errorDetails?.message ??
                  'Camera unavailable. Check app permissions.',
            ),
          ),
          const ScannerOverlay(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      _CircleButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const Spacer(),
                      _CircleButton(
                        icon: _torch
                            ? Icons.flashlight_on_rounded
                            : Icons.flashlight_off_rounded,
                        active: _torch,
                        onTap: () {
                          setState(() => _torch = !_torch);
                          _controller.toggleTorch();
                        },
                      ),
                      const SizedBox(width: 10),
                      _CircleButton(
                        icon: Icons.cameraswitch_rounded,
                        onTap: () => _controller.switchCamera(),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 38,
                            width: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isChain
                                  ? Icons.local_shipping_rounded
                                  : Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isChain
                                      ? 'Shipment scan'
                                      : 'Product verification',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  config.hint,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.72),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_processing) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Verifying with TraceSci...',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary
              : Colors.black.withOpacity(0.42),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final String message;

  const _CameraError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.no_photography_rounded,
            color: Colors.white54,
            size: 46,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _FailureSheet extends StatelessWidget {
  final String message;
  final String code;
  final bool isNetwork;
  final VoidCallback onRetry;

  const _FailureSheet({
    required this.message,
    required this.code,
    required this.isNetwork,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: const BoxDecoration(
              color: AppColors.dangerSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isNetwork ? Icons.wifi_off_rounded : Icons.gpp_bad_rounded,
              color: AppColors.danger,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isNetwork ? 'No connection' : 'Verification failed',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              code,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
              child: const Text('Scan again'),
            ),
          ),
        ],
      ),
    );
  }
}
