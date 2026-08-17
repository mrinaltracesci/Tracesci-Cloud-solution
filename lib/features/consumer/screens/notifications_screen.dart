import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../models/consumer_models.dart';
import '../providers/consumer_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsumerProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConsumerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: PagedListView<AppNotification>(
        items: provider.notifications,
        status: provider.status,
        errorMessage: provider.errorMessage,
        isNetworkError: provider.isNetworkError,
        onRefresh: () => provider.loadNotifications(refresh: true),
        onRetry: () => provider.loadNotifications(),
        emptyState: const EmptyState(
          icon: Icons.notifications_rounded,
          title: 'All caught up',
          message: 'Reward credits and report updates will show up here.',
        ),
        itemBuilder: (context, item, index) => _tile(item),
      ),
    );
  }

  Widget _tile(AppNotification item) {
    final isReward = item.type == 'reward';
    final color = isReward ? AppColors.warning : AppColors.primary;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(AppIcons.resolve(item.icon), color: color, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(item.body, style: AppTextStyles.bodySmall),
                const SizedBox(height: 8),
                Text(item.createdAgo, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
