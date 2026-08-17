import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'motion.dart';

class JourneyHop {
  final String name;
  final String? level;
  final String? at;

  const JourneyHop({required this.name, this.level, this.at});
}

class JourneyStrip extends StatelessWidget {
  final List<JourneyHop> hops;
  final String finalLabel;

  const JourneyStrip({
    super.key,
    required this.hops,
    this.finalLabel = 'You',
  });

  @override
  Widget build(BuildContext context) {
    if (hops.isEmpty) return const SizedBox.shrink();

    final nodes = [
      ...hops,
      JourneyHop(name: finalLabel),
    ];

    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: nodes.length,
        itemBuilder: (context, index) {
          final isLast = index == nodes.length - 1;

          return FadeSlideIn(
            delay: Duration(milliseconds: 90 * index),
            offsetX: 18,
            offsetY: 0,
            child: Row(
              children: [
                _node(nodes[index], index, isLast),
                if (!isLast) _connector(index),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _node(JourneyHop hop, int index, bool isLast) {
    final color = isLast ? AppColors.success : AppColors.primary;

    return SizedBox(
      width: 92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            ),
            child: Icon(
              isLast
                  ? Icons.emoji_people_rounded
                  : index == 0
                      ? Icons.factory_rounded
                      : Icons.local_shipping_rounded,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            hop.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (hop.level != null) ...[
            const SizedBox(height: 2),
            Text(
              hop.level!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _connector(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: SizedBox(
        width: 26,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.25),
                      AppColors.primary.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 15,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
