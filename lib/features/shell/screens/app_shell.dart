import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../alerts/screens/alerts_screen.dart';
import '../../brand/screens/brand_alerts_screen.dart';
import '../../brand/screens/brand_home_screen.dart';
import '../../brand/screens/brand_products_screen.dart';
import '../../brand/screens/brand_scans_screen.dart';
import '../../consumer/screens/consumer_home_screen.dart';
import '../../consumer/screens/scan_history_screen.dart';
import '../../inspector/screens/cases_screen.dart';
import '../../inspector/screens/inspector_home_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../rewards/screens/rewards_screen.dart';
import '../../scanner/screens/scanner_screen.dart';
import '../../supplychain/screens/chain_alerts_screen.dart';
import '../../supplychain/screens/consignments_screen.dart';
import '../../supplychain/screens/supply_chain_home_screen.dart';
import '../models/bootstrap.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  DateTime? _lastBackPress;

  Future<void> _handleBack() async {
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }

    final now = DateTime.now();
    final canExit = _lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2);

    if (canExit) {
      await SystemNavigator.pop();
      return;
    }

    _lastBackPress = now;

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 1600),
          content: Text('Press back again to exit'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.stage == AuthStage.loggedOut) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tabs = auth.tabs.isNotEmpty ? auth.tabs : _fallbackTabs(auth.role);
    final safeIndex = _index.clamp(0, tabs.length - 1);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: [
          for (final tab in tabs) _pageFor(tab, auth.role),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        tabs: tabs,
        currentIndex: safeIndex,
        onTap: (index) {
          final tab = tabs[index];

          if (tab.key == 'scan') {
            _openScanner();
            return;
          }

          setState(() => _index = index);
        },
      ),
      ),
    );
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
  }

  Widget _pageFor(AppTab tab, UserRole role) {
    switch (tab.key) {
      case 'home':
        return _homeFor(role);
      case 'rewards':
        return const RewardsScreen(embedded: true);
      case 'history':
        return const ScanHistoryScreen(embedded: true);
      case 'consignments':
        return const ConsignmentsScreen(embedded: true);
      case 'alerts':
        if (role.isBrandSide) return const BrandAlertsScreen(embedded: true);
        if (role.isSupplyChain) return const ChainAlertsScreen(embedded: true);
        return const AlertsScreen(embedded: true);
      case 'cases':
        return const CasesScreen(embedded: true);
      case 'products':
        return const BrandProductsScreen(embedded: true);
      case 'scans':
        return const BrandScansScreen(embedded: true);
      case 'profile':
        return const ProfileScreen(embedded: true);
      case 'scan':
        return _homeFor(role);
      default:
        return _homeFor(role);
    }
  }

  Widget _homeFor(UserRole role) {
    switch (role) {
      case UserRole.supplyChain:
        return const SupplyChainHomeScreen();
      case UserRole.inspector:
      case UserRole.authority:
        return const InspectorHomeScreen();
      case UserRole.brand:
      case UserRole.admin:
        return const BrandHomeScreen();
      case UserRole.consumer:
        return const ConsumerHomeScreen();
    }
  }

  List<AppTab> _fallbackTabs(UserRole role) {
    if (role.isSupplyChain) {
      return const [
        AppTab(key: 'home', label: 'Home', icon: 'dashboard', endpoint: ''),
        AppTab(key: 'scan', label: 'Scan', icon: 'qr_scanner', endpoint: ''),
        AppTab(
          key: 'shipments',
          label: 'Shipments',
          icon: 'package',
          endpoint: '',
        ),
        AppTab(key: 'profile', label: 'Profile', icon: 'user', endpoint: ''),
      ];
    }

    if (role.isFieldAgent) {
      return const [
        AppTab(key: 'home', label: 'Home', icon: 'dashboard', endpoint: ''),
        AppTab(key: 'reports', label: 'Reports', icon: 'folder', endpoint: ''),
        AppTab(key: 'scan', label: 'Verify', icon: 'qr_scanner', endpoint: ''),
        AppTab(key: 'profile', label: 'Profile', icon: 'user', endpoint: ''),
      ];
    }

    if (role.isBrandSide) {
      return const [
        AppTab(key: 'home', label: 'Home', icon: 'dashboard', endpoint: ''),
        AppTab(key: 'products', label: 'Products', icon: 'box', endpoint: ''),
        AppTab(key: 'scans', label: 'Scans', icon: 'activity', endpoint: ''),
        AppTab(key: 'profile', label: 'Profile', icon: 'user', endpoint: ''),
      ];
    }

    return const [
      AppTab(key: 'home', label: 'Home', icon: 'home', endpoint: ''),
      AppTab(key: 'scan', label: 'Scan', icon: 'qr_scanner', endpoint: ''),
      AppTab(key: 'rewards', label: 'Rewards', icon: 'gift', endpoint: ''),
      AppTab(key: 'history', label: 'History', icon: 'history', endpoint: ''),
      AppTab(key: 'profile', label: 'Profile', icon: 'user', endpoint: ''),
    ];
  }
}

class _BottomBar extends StatelessWidget {
  final List<AppTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1220).withOpacity(0.07),
            blurRadius: 22,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < tabs.length; i++)
                _BottomItem(
                  tab: tabs[i],
                  active: i == currentIndex,
                  isScan: tabs[i].key == 'scan',
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final AppTab tab;
  final bool active;
  final bool isScan;
  final VoidCallback onTap;

  const _BottomItem({
    required this.tab,
    required this.active,
    required this.isScan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isScan) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                AppIcons.resolve(tab.icon),
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
        ),
      );
    }

    final color = active ? AppColors.primary : AppColors.textTertiary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: active ? AppColors.primarySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(AppIcons.resolve(tab.icon), size: 22, color: color),
            ),
            const SizedBox(height: 3),
            Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
