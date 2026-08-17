import 'package:flutter/material.dart';

class AppIcons {
  static const Map<String, IconData> _map = {
    'home': Icons.home_rounded,
    'dashboard': Icons.space_dashboard_rounded,
    'qr_scanner': Icons.qr_code_scanner_rounded,
    'qr_code': Icons.qr_code_2_rounded,
    'gift': Icons.card_giftcard_rounded,
    'history': Icons.history_rounded,
    'user': Icons.person_rounded,
    'package': Icons.inventory_2_rounded,
    'bell': Icons.notifications_rounded,
    'folder': Icons.folder_rounded,
    'folder_open': Icons.folder_open_rounded,
    'box': Icons.widgets_rounded,
    'activity': Icons.insights_rounded,
    'alert': Icons.warning_amber_rounded,
    'flag': Icons.outlined_flag_rounded,
    'shield_check': Icons.verified_user_rounded,
    'check_circle': Icons.check_circle_rounded,
    'clock': Icons.schedule_rounded,
    'calendar': Icons.calendar_month_rounded,
    'truck': Icons.local_shipping_rounded,
    'download': Icons.download_rounded,
    'route': Icons.timeline_rounded,
    'map': Icons.map_rounded,
    'search': Icons.search_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
    'settings': Icons.settings_rounded,
    'logout': Icons.logout_rounded,
  };

  static IconData resolve(String key, {IconData fallback = Icons.circle_outlined}) {
    return _map[key] ?? fallback;
  }
}
