import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/navigation/app_routes.dart';
import 'core/network/api_client.dart';
import 'core/storage/session_store.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/alerts/data/alert_repository.dart';
import 'features/alerts/providers/alert_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/brand/data/brand_repository.dart';
import 'features/brand/providers/brand_provider.dart';
import 'features/consumer/data/consumer_repository.dart';
import 'features/consumer/providers/consumer_provider.dart';
import 'features/inspector/data/inspector_repository.dart';
import 'features/inspector/providers/inspector_provider.dart';
import 'features/rewards/data/reward_repository.dart';
import 'features/rewards/providers/reward_provider.dart';
import 'features/supplychain/data/supply_chain_repository.dart';
import 'features/supplychain/providers/supply_chain_provider.dart';

class TraceSciApp extends StatefulWidget {
  const TraceSciApp({super.key});

  @override
  State<TraceSciApp> createState() => _TraceSciAppState();
}

class _TraceSciAppState extends State<TraceSciApp> {
  late final SessionStore _sessionStore;
  late final ApiClient _client;

  @override
  void initState() {
    super.initState();
    _sessionStore = SessionStore();
    _client = ApiClient(sessionStore: _sessionStore);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SessionStore>.value(value: _sessionStore),
        Provider<ApiClient>.value(value: _client),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            repository: AuthRepository(_client),
            sessionStore: _sessionStore,
            client: _client,
          ),
        ),
        ChangeNotifierProvider<ConsumerProvider>(
          create: (_) => ConsumerProvider(ConsumerRepository(_client)),
        ),
        ChangeNotifierProvider<RewardProvider>(
          create: (_) => RewardProvider(RewardRepository(_client)),
        ),
        ChangeNotifierProvider<SupplyChainProvider>(
          create: (_) => SupplyChainProvider(SupplyChainRepository(_client)),
        ),
        ChangeNotifierProvider<InspectorProvider>(
          create: (_) => InspectorProvider(InspectorRepository(_client)),
        ),
        ChangeNotifierProvider<BrandProvider>(
          create: (_) => BrandProvider(BrandRepository(_client)),
        ),
        ChangeNotifierProvider<AlertProvider>(
          create: (_) => AlertProvider(AlertRepository(_client)),
        ),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
        onGenerateRoute: AppRoutes.generate,
        builder: (context, child) {
          return MediaQuery.withNoTextScaling(child: child ?? const SizedBox());
        },
      ),
    );
  }
}


/*
*
* 1. Scan result should show photo of products
* 2. Supply chain should be optimized
* 3. Rename top corner bell icon to Notification
* 4. Rename Navigation bar to Reports & alerts
* 5. If supplychain user have any parent they should share the History of supplychain + Scan history
* 6. Add serial number in scan result (remove duplicate)
* 7. Scan count should not be increase when any inspector scans
* 8. add deactivate batch+serial feature for Audit team member
* 9. Make default behaviour for all scans by anyone
* 10 user can also redeem goods by scanning.
* 11. Rename my orders to Transection
* 12. add contact number in supply chain for manufacturer
* 13. add ** in mobile number
* 14. add search everywhere in app where list is shown
* 15. sending to instead of handing over to in shipment release
* 16. remove alerts from all supplychain members
* 17. instead of scan history rename it to Tracking history
*
*/
