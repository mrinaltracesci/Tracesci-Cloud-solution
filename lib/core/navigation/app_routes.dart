import 'package:flutter/material.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/brand/screens/brand_alerts_screen.dart';
import '../../features/brand/screens/brand_network_screen.dart';
import '../../features/brand/screens/brand_product_detail_screen.dart';
import '../../features/brand/screens/brand_products_screen.dart';
import '../../features/brand/screens/brand_scans_screen.dart';
import '../../features/consumer/screens/notifications_screen.dart';
import '../../features/consumer/screens/report_product_screen.dart';
import '../../features/consumer/screens/reports_screen.dart';
import '../../features/consumer/screens/scan_detail_screen.dart';
import '../../features/consumer/screens/scan_history_screen.dart';
import '../../features/inspector/screens/case_detail_screen.dart';
import '../../features/inspector/screens/cases_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/rewards/screens/reward_catalog_screen.dart';
import '../../features/rewards/screens/reward_ledger_screen.dart';
import '../../features/rewards/screens/reward_orders_screen.dart';
import '../../features/rewards/screens/rewards_screen.dart';
import '../../features/scanner/screens/scanner_screen.dart';
import '../../features/shell/screens/app_shell.dart';
import '../../features/supplychain/screens/chain_activity_screen.dart';
import '../../features/supplychain/screens/chain_alerts_screen.dart';
import '../../features/supplychain/screens/consignment_detail_screen.dart';
import '../../features/supplychain/screens/consignments_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String shell = '/shell';
  static const String scanner = '/scanner';

  static const String scanHistory = '/consumer/scans';
  static const String scanDetail = '/consumer/scan';
  static const String reportProduct = '/consumer/report';
  static const String reports = '/consumer/reports';
  static const String notifications = '/consumer/notifications';

  static const String rewards = '/rewards';
  static const String rewardCatalog = '/rewards/catalog';
  static const String rewardLedger = '/rewards/ledger';
  static const String rewardOrders = '/rewards/orders';

  static const String consignments = '/supply-chain/consignments';
  static const String consignmentDetail = '/supply-chain/consignment';
  static const String chainAlerts = '/supply-chain/alerts';
  static const String chainActivity = '/supply-chain/activity';

  static const String cases = '/inspector/cases';
  static const String caseDetail = '/inspector/case';

  static const String brandProducts = '/brand/products';
  static const String brandProductDetail = '/brand/product';
  static const String brandScans = '/brand/scans';
  static const String brandAlerts = '/brand/alerts';
  static const String brandNetwork = '/brand/network';

  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';

  static Route<dynamic>? generate(RouteSettings settings) {
    final arguments = settings.arguments;

    Widget? page;

    switch (settings.name) {
      case splash:
        page = const SplashScreen();
        break;
      case login:
        page = const LoginScreen();
        break;
      case otp:
        page = const OtpScreen();
        break;
      case shell:
        page = const AppShell();
        break;
      case scanner:
        page = const ScannerScreen();
        break;
      case scanHistory:
        page = const ScanHistoryScreen();
        break;
      case scanDetail:
        if (arguments is int) page = ScanDetailScreen(scanId: arguments);
        break;
      case reportProduct:
        if (arguments is Map<String, dynamic>) {
          page = ReportProductScreen(
            codeData: arguments['code_data'] as String?,
            productId: arguments['product_id'] as int?,
            productName: arguments['product_name'] as String?,
          );
        } else {
          page = const ReportProductScreen();
        }
        break;
      case reports:
        page = const ReportsScreen();
        break;
      case notifications:
        page = const NotificationsScreen();
        break;
      case rewards:
        page = const RewardsScreen();
        break;
      case rewardCatalog:
        page = const RewardCatalogScreen();
        break;
      case rewardLedger:
        page = const RewardLedgerScreen();
        break;
      case rewardOrders:
        page = const RewardOrdersScreen();
        break;
      case consignments:
        page = const ConsignmentsScreen();
        break;
      case consignmentDetail:
        if (arguments is String) {
          page = ConsignmentDetailScreen(code: arguments);
        }
        break;
      case chainAlerts:
        page = const ChainAlertsScreen();
        break;
      case chainActivity:
        page = const ChainActivityScreen();
        break;
      case cases:
        page = const CasesScreen();
        break;
      case caseDetail:
        if (arguments is int) page = CaseDetailScreen(caseId: arguments);
        break;
      case brandProducts:
        page = const BrandProductsScreen();
        break;
      case brandProductDetail:
        if (arguments is int) {
          page = BrandProductDetailScreen(productId: arguments);
        }
        break;
      case brandScans:
        page = const BrandScansScreen();
        break;
      case brandAlerts:
        page = const BrandAlertsScreen();
        break;
      case brandNetwork:
        page = const BrandNetworkScreen();
        break;
      case profile:
        page = const ProfileScreen();
        break;
      case editProfile:
        page = const EditProfileScreen();
        break;
    }

    if (page == null) return null;

    final destination = page;

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => destination,
    );
  }
}
