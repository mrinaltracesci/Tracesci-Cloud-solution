import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

enum StatusTone { neutral, success, warning, danger, info, primary }

class StatusChip extends StatelessWidget {
  final String label;
  final StatusTone tone;
  final IconData? icon;
  final bool dense;

  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.dense = false,
  });

  factory StatusChip.forStatus(String status, {IconData? icon}) {
    final lower = status.toLowerCase();

    StatusTone tone = StatusTone.neutral;

    if (lower.contains('genuine') ||
        lower.contains('active') ||
        lower.contains('closed') ||
        lower.contains('delivered') ||
        lower.contains('received') ||
        lower.contains('with you')) {
      tone = StatusTone.success;
    } else if (lower.contains('open') ||
        lower.contains('pending') ||
        lower.contains('transit') ||
        lower.contains('dispatch')) {
      tone = StatusTone.warning;
    } else if (lower.contains('fake') ||
        lower.contains('damag') ||
        lower.contains('expired') ||
        lower.contains('recall') ||
        lower.contains('not verified') ||
        lower.contains('inactive')) {
      tone = StatusTone.danger;
    }

    return StatusChip(label: status, tone: tone, icon: icon);
  }

  Color get _background {
    switch (tone) {
      case StatusTone.success:
        return AppColors.successSoft;
      case StatusTone.warning:
        return AppColors.warningSoft;
      case StatusTone.danger:
        return AppColors.dangerSoft;
      case StatusTone.info:
        return AppColors.infoSoft;
      case StatusTone.primary:
        return AppColors.primarySoft;
      case StatusTone.neutral:
        return AppColors.surfaceAlt;
    }
  }

  Color get _foreground {
    switch (tone) {
      case StatusTone.success:
        return AppColors.success;
      case StatusTone.warning:
        return AppColors.warning;
      case StatusTone.danger:
        return AppColors.danger;
      case StatusTone.info:
        return AppColors.info;
      case StatusTone.primary:
        return AppColors.primary;
      case StatusTone.neutral:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: _foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: _foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class FilterOption {
  final String label;
  final String? value;
  final int? count;

  const FilterOption({required this.label, this.value, this.count});
}

class FilterChipsRow extends StatelessWidget {
  final List<FilterOption> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final EdgeInsetsGeometry padding;

  const FilterChipsRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final active = option.value == selected;

          return GestureDetector(
            onTap: () => onSelected(option.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border,
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: active ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (option.count != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white.withOpacity(0.22)
                            : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${option.count}',
                        style: AppTextStyles.caption.copyWith(
                          color:
                              active ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
