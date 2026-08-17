enum Environment { local, staging, production }

class AppConfig {
  static Environment environment = Environment.local;

  static const Map<Environment, String> _baseUrls = {
    Environment.local: 'http://10.126.140.176:8000/api',
    Environment.staging: 'https://staging.tracesci.in/api',
    Environment.production: 'https://tracesci.in/api',
  };

  static String get baseUrl => _baseUrls[environment]!;

  static bool get isProduction => environment == Environment.production;

  static bool get allowBadCertificates => !isProduction;

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const int defaultPageSize = 20;

  static const String appName = 'TraceSci';
  static const String appVersion = '1.0.0';
}
