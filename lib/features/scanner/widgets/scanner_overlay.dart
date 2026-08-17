import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ScannerOverlay extends StatefulWidget {
  final double windowSize;

  const ScannerOverlay({super.key, this.windowSize = 260});

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = widget.windowSize;
        final left = (constraints.maxWidth - size) / 2;
        final top = (constraints.maxHeight - size) / 2 - 40;

        return Stack(
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                AppColors.scannerOverlay,
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      height: size,
                      width: size,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: SizedBox(
                height: size,
                width: size,
                child: Stack(
                  children: [
                    _corner(Alignment.topLeft),
                    _corner(Alignment.topRight),
                    _corner(Alignment.bottomLeft),
                    _corner(Alignment.bottomRight),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Positioned(
                          top: 12 + (size - 24) * _controller.value,
                          left: 18,
                          right: 18,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0),
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.6),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _corner(Alignment alignment) {
    const thickness = 3.5;
    const length = 32.0;

    final isTop = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft =
        alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Align(
      alignment: alignment,
      child: Container(
        height: length,
        width: length,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Colors.white, width: thickness)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Colors.white, width: thickness)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Colors.white, width: thickness)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Colors.white, width: thickness)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(20) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(20) : Radius.zero,
            bottomLeft:
                !isTop && isLeft ? const Radius.circular(20) : Radius.zero,
            bottomRight:
                !isTop && !isLeft ? const Radius.circular(20) : Radius.zero,
          ),
        ),
      ),
    );
  }
}
