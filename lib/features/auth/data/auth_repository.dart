import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/json_utils.dart';
import '../../consumer/models/consumer_models.dart';
import '../../shell/models/bootstrap.dart';
import '../../supplychain/models/supply_chain_models.dart';

enum LoginMode { consumer, official }

class OtpRequestResult {
  final String message;
  final String? debugOtp;
  final bool isNewUser;
  final String? displayName;
  final String? roleLabel;

  const OtpRequestResult({
    required this.message,
    this.debugOtp,
    this.isNewUser = false,
    this.displayName,
    this.roleLabel,
  });
}

class LoginResult {
  final String token;
  final UserProfile profile;

  const LoginResult({required this.token, required this.profile});
}

class MastersData {
  final List<Map<String, dynamic>> countries;
  final List<ChainStatusOption> supplyChainStatus;
  final List<IssueType> reportIssueTypes;

  const MastersData({
    required this.countries,
    required this.supplyChainStatus,
    required this.reportIssueTypes,
  });

  factory MastersData.empty() => const MastersData(
        countries: [],
        supplyChainStatus: [],
        reportIssueTypes: [],
      );

  factory MastersData.fromJson(Map<String, dynamic> json) {
    return MastersData(
      countries: asMapList(json['countries']),
      supplyChainStatus:
          asList(json['supply_chain_status'], ChainStatusOption.fromJson),
      reportIssueTypes: asList(json['report_issue_types'], IssueType.fromJson),
    );
  }
}

class AuthRepository {
  final ApiClient client;

  const AuthRepository(this.client);

  Future<OtpRequestResult> requestConsumerOtp({
    required String phoneCode,
    required String phone,
  }) async {
    final response = await client.post(
      ApiEndpoints.consumerRequestOtp,
      body: {'phone_code': phoneCode, 'phone': phone},
    );

    return OtpRequestResult(
      message: response.message,
      debugOtp: asStringOrNull(response.data['dev_otp']),
      isNewUser: asBool(response.data['is_new_user']),
    );
  }

  Future<LoginResult> verifyConsumerOtp({
    required String phoneCode,
    required String phone,
    required String otp,
  }) async {
    final response = await client.post(
      ApiEndpoints.consumerVerifyOtp,
      body: {'phone_code': phoneCode, 'phone': phone, 'otp': otp},
    );

    return _loginResultFrom(response.data);
  }

  Future<OtpRequestResult> requestOfficialOtp({
    required String email,
    required String password,
  }) async {
    final response = await client.post(
      ApiEndpoints.officialRequestOtp,
      body: {'email': email, 'password': password},
    );

    return OtpRequestResult(
      message: response.message,
      debugOtp: asStringOrNull(response.data['dev_otp']),
      displayName: asStringOrNull(response.data['name']),
      roleLabel: asStringOrNull(response.data['role_label']),
    );
  }

  Future<LoginResult> verifyOfficialOtp({
    required String email,
    required String otp,
  }) async {
    final response = await client.post(
      ApiEndpoints.officialVerifyOtp,
      body: {'email': email, 'otp': otp},
    );

    return _loginResultFrom(response.data);
  }

  Future<LoginResult> passwordLogin({
    required String username,
    required String password,
  }) async {
    final response = await client.post(
      ApiEndpoints.passwordLogin,
      body: {'username': username, 'password': password},
    );

    final token = asString(response.data['token']);

    if (token.isEmpty) {
      return _loginResultFrom(response.data);
    }

    return LoginResult(
      token: token,
      profile: UserProfile.fromJson(asMap(response.data['profile'])),
    );
  }

  Future<BootstrapData> bootstrap() async {
    final response = await client.post(ApiEndpoints.bootstrap);
    return BootstrapData.fromJson(response.data);
  }

  Future<UserProfile> me() async {
    final response = await client.post(ApiEndpoints.me);
    return UserProfile.fromJson(response.object('profile'));
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> fields) async {
    final response = await client.post(
      ApiEndpoints.updateProfile,
      body: fields,
    );
    return UserProfile.fromJson(response.object('profile'));
  }

  Future<MastersData> masters() async {
    final response = await client.post(ApiEndpoints.masters);
    return MastersData.fromJson(response.data);
  }

  Future<void> logout() async {
    await client.post(ApiEndpoints.logout);
  }

  Future<void> deleteAccount() async {
    await client.post(ApiEndpoints.deleteAccount);
  }

  LoginResult _loginResultFrom(Map<String, dynamic> data) {
    final nested = asMap(data['data']);
    final source = nested.isNotEmpty ? nested : data;

    return LoginResult(
      token: asString(source['token']),
      profile: UserProfile.fromJson(asMap(source['profile'])),
    );
  }
}
