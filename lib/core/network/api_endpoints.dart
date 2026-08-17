class ApiEndpoints {
  static const String consumerRequestOtp = '/app/auth/consumer/request-otp';
  static const String consumerVerifyOtp = '/app/auth/consumer/verify';
  static const String officialRequestOtp = '/app/auth/official/request-otp';
  static const String officialVerifyOtp = '/app/auth/official/verify';

  static const String getOtp = '/get-otp';
  static const String verifyOtp = '/verify-otp';
  static const String passwordLogin = '/password-login';
  static const String withoutAuth = '/without-auth';
  static const String verifySecretCode = '/verify-secret-code';

  static const String bootstrap = '/app/bootstrap';
  static const String me = '/app/me';
  static const String updateProfile = '/app/update-profile';
  static const String masters = '/app/masters';
  static const String logout = '/app/logout';
  static const String deleteAccount = '/app/delete-account';

  static const String consumerHome = '/consumer/home';
  static const String consumerScans = '/consumer/scans';
  static const String consumerReport = '/consumer/report';
  static const String consumerReports = '/consumer/reports';
  static const String consumerNotifications = '/consumer/notifications';
  static const String consumerDiagnose = '/consumer/diagnose';

  static const String alertsFeed = '/alerts';

  static String consumerScanDetail(int scanId) => '/consumer/scan/$scanId';

  static String scanProduct(String code) => '/p/$code';

  static const String rewardsSummary = '/rewards/summary';
  static const String rewardsLedger = '/rewards/ledger';
  static const String rewardsCatalog = '/rewards/catalog';
  static const String rewardsRedeemCoupon = '/rewards/redeem-coupon';
  static const String rewardsRedeemCash = '/rewards/redeem-cash';
  static const String rewardsOrder = '/rewards/order';
  static const String rewardsOrders = '/rewards/orders';

  static const String supplyChainScan = '/supply-chain/scan';
  static const String supplyChainAction = '/supply-chain/action';
  static const String supplyChainDashboard = '/supply-chain/dashboard';
  static const String supplyChainConsignments = '/supply-chain/consignments';
  static const String supplyChainCounterparties = '/supply-chain/counterparties';
  static const String supplyChainStatuses = '/supply-chain/statuses';
  static const String supplyChainAlerts = '/supply-chain/alerts';
  static const String supplyChainActivity = '/supply-chain/my-activity';

  static String supplyChainConsignment(String uniqueId) =>
      '/supply-chain/consignment/$uniqueId';

  static String supplyChainTimeline(String uniqueId) =>
      '/supply-chain/timeline/$uniqueId';

  static const String inspectorDashboard = '/inspector/dashboard';
  static const String inspectorCases = '/inspector/cases';
  static const String inspectorSeize = '/inspector/seize';
  static const String inspectorMap = '/inspector/map';

  static String inspectorCase(int id) => '/inspector/case/$id';

  static String inspectorCaseUpdate(int id) => '/inspector/case/$id/update';

  static const String brandDashboard = '/brand/dashboard';
  static const String brandProducts = '/brand/products';
  static const String brandScans = '/brand/scans';
  static const String brandAlerts = '/brand/alerts';
  static const String brandNetwork = '/brand/network';
  static const String brandScanMap = '/brand/scan-map';

  static String brandProduct(int id) => '/brand/product/$id';
}
