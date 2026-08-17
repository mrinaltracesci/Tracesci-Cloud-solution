import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'chips.dart';

class TimelineEntry {
  final String title;
  final String? subtitle;
  final String? meta;
  final String? trailing;
  final String? badge;
  final String? code;
  final IconData icon;
  final Color color;
  final bool verified;

  const TimelineEntry({
    required this.title,
    this.subtitle,
    this.meta,
    this.trailing,
    this.badge,
    this.code,
    this.icon = Icons.circle,
    this.color = AppColors.primary,
    this.verified = false,
  });
}

class _LevelBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _LevelBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class TimelineView extends StatelessWidget {
  final List<TimelineEntry> entries;
  final bool shrinkWrap;
  final EdgeInsetsGeometry padding;

  const TimelineView({
    super.key,
    required this.entries,
    this.shrinkWrap = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No movement recorded yet',
            style: AppTextStyles.bodySmall,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      padding: padding,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isLast = index == entries.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      color: entry.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: entry.color.withOpacity(0.35),
                      ),
                    ),
                    child: Icon(entry.icon, size: 15, color: entry.color),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: AppColors.divider,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.title,
                              style: AppTextStyles.titleMedium,
                            ),
                          ),
                          if (entry.verified)
                            const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppColors.success,
                            ),
                        ],
                      ),
                      if (entry.badge != null || entry.code != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (entry.badge != null)
                              _LevelBadge(
                                label: entry.badge!,
                                color: entry.color,
                              ),
                            if (entry.badge != null && entry.code != null)
                              const SizedBox(width: 6),
                            if (entry.code != null)
                              Flexible(
                                child: Text(
                                  entry.code!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (entry.subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(entry.subtitle!, style: AppTextStyles.bodySmall),
                      ],
                      if (entry.trailing != null) ...[
                        const SizedBox(height: 8),
                        StatusChip.forStatus(entry.trailing!),
                      ],
                      if (entry.meta != null) ...[
                        const SizedBox(height: 6),
                        Text(entry.meta!, style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
