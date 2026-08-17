import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/session_store.dart';
import '../../shell/models/bootstrap.dart';
import '../data/auth_repository.dart';

enum AuthStage { unknown, loggedOut, loggedIn }

class AuthProvider extends ChangeNotifier {
  final AuthRepository repository;
  final SessionStore sessionStore;
  final ApiClient client;

  AuthProvider({
    required this.repository,
    required this.sessionStore,
    required this.client,
  }) {
    client.onUnauthorized = _handleUnauthorized;
  }

  AuthStage _stage = AuthStage.unknown;
  BootstrapData? _bootstrap;
  MastersData _masters = MastersData.empty();
  bool _busy = false;
  String _error = '';
  String _pendingCountryCode = '91';
  String _pendingPhone = '';
  String _pendingEmail = '';
  String? _debugOtp;
  LoginMode _loginMode = LoginMode.consumer;
  bool _pendingIsNewUser = false;
  String? _pendingDisplayName;
  String? _pendingRoleLabel;

  AuthStage get stage => _stage;

  BootstrapData? get bootstrap => _bootstrap;

  MastersData get masters => _masters;

  bool get busy => _busy;

  String get error => _error;

  String get pendingCountryCode => _pendingCountryCode;

  String get pendingPhone => _pendingPhone;

  String get pendingEmail => _pendingEmail;

  String? get debugOtp => _debugOtp;

  LoginMode get loginMode => _loginMode;

  bool get pendingIsNewUser => _pendingIsNewUser;

  String? get pendingDisplayName => _pendingDisplayName;

  String? get pendingRoleLabel => _pendingRoleLabel;

  String get pendingIdentity => _loginMode == LoginMode.consumer
      ? '+$_pendingCountryCode $_pendingPhone'
      : _pendingEmail;

  UserProfile get profile => _bootstrap?.profile ?? UserProfile.empty();

  UserRole get role => _bootstrap?.role ?? UserRole.consumer;

  Capabilities get capabilities =>
      _bootstrap?.capabilities ?? Capabilities.empty();

  List<AppTab> get tabs => _bootstrap?.tabs ?? const [];

  List<QuickAction> get quickActions => _bootstrap?.quickActions ?? const [];

  ScannerConfig get scanner => _bootstrap?.scanner ?? ScannerConfig.fallback();

  AppTheming get theming => _bootstrap?.theme ?? AppTheming.fallback();

  Future<void> restore() async {
    await sessionStore.init();

    final cachedMasters = await sessionStore.readMasters();
    if (cachedMasters != null) {
      _masters = MastersData.fromJson(cachedMasters);
    }

    if (!sessionStore.hasSession) {
      _stage = AuthStage.loggedOut;
      notifyListeners();
      return;
    }

    final cached = await sessionStore.readBootstrap();
    if (cached != null) {
      _bootstrap = BootstrapData.fromJson(cached);
      _stage = AuthStage.loggedIn;
      notifyListeners();
    }

    try {
      await loadBootstrap();
      _stage = AuthStage.loggedIn;
    } on ApiException catch (failure) {
      if (failure.isUnauthorized) {
        await _clearSession();
      } else if (_bootstrap == null) {
        _error = failure.message;
        _stage = AuthStage.loggedOut;
      } else {
        _stage = AuthStage.loggedIn;
      }
    }

    notifyListeners();
  }

  void setLoginMode(LoginMode mode) {
    if (_loginMode == mode) return;
    _loginMode = mode;
    _error = '';
    notifyListeners();
  }

  Future<bool> requestConsumerOtp({
    required String phoneCode,
    required String phone,
  }) async {
    _setBusy(true);
    try {
      final result = await repository.requestConsumerOtp(
        phoneCode: phoneCode,
        phone: phone,
      );
      _loginMode = LoginMode.consumer;
      _pendingCountryCode = phoneCode;
      _pendingPhone = phone;
      _pendingIsNewUser = result.isNewUser;
      _debugOtp = result.debugOtp;
      _setBusy(false);
      return true;
    } on ApiException catch (failure) {
      _fail(failure.message);
      return false;
    }
  }

  Future<bool> requestOfficialOtp({
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    try {
      final result = await repository.requestOfficialOtp(
        email: email,
        password: password,
      );
      _loginMode = LoginMode.official;
      _pendingEmail = email;
      _pendingIsNewUser = false;
      _pendingDisplayName = result.displayName;
      _pendingRoleLabel = result.roleLabel;
      _debugOtp = result.debugOtp;
      _setBusy(false);
      return true;
    } on ApiException catch (failure) {
      _fail(failure.message);
      return false;
    }
  }

  Future<bool> resendOtp() {
    if (_loginMode == LoginMode.consumer) {
      return requestConsumerOtp(
        phoneCode: _pendingCountryCode,
        phone: _pendingPhone,
      );
    }
    return Future<bool>.value(false);
  }

  Future<bool> verifyOtp(String otp) async {
    _setBusy(true);
    try {
      final result = _loginMode == LoginMode.consumer
          ? await repository.verifyConsumerOtp(
              phoneCode: _pendingCountryCode,
              phone: _pendingPhone,
              otp: otp,
            )
          : await repository.verifyOfficialOtp(
              email: _pendingEmail,
              otp: otp,
            );

      if (result.token.isEmpty) {
        _fail('Login failed. Please try again.');
        return false;
      }

      await _completeLogin(result);
      return true;
    } on ApiException catch (failure) {
      _fail(failure.message);
      return false;
    }
  }

  Future<void> loadBootstrap() async {
    final data = await repository.bootstrap();
    _bootstrap = data;
    await sessionStore.saveBootstrap(_bootstrapToJson(data));
    notifyListeners();
    unawaitedMasters();
  }

  void unawaitedMasters() {
    repository.masters().then((value) async {
      _masters = value;
      await sessionStore.saveMasters({
        'countries': value.countries,
        'supply_chain_status': value.supplyChainStatus
            .map((e) => {
                  'label': e.label,
                  'value': e.value,
                  'comment': e.comment,
                })
            .toList(),
        'report_issue_types': value.reportIssueTypes
            .map((e) => {'label': e.label, 'value': e.value})
            .toList(),
      });
      notifyListeners();
    }).catchError((_) {});
  }

  Future<void> refreshProfile() async {
    try {
      final updated = await repository.me();
      if (_bootstrap != null) {
        _bootstrap = BootstrapData(
          profile: updated,
          role: _bootstrap!.role,
          roleLabel: _bootstrap!.roleLabel,
          capabilities: _bootstrap!.capabilities,
          tabs: _bootstrap!.tabs,
          quickActions: _bootstrap!.quickActions,
          scanner: _bootstrap!.scanner,
          theme: _bootstrap!.theme,
        );
        notifyListeners();
      }
    } on ApiException {
      return;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    _setBusy(true);
    try {
      await repository.updateProfile(fields);
      await refreshProfile();
      _setBusy(false);
      return true;
    } on ApiException catch (failure) {
      _fail(failure.message);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await repository.logout();
    } catch (_) {
      _error = '';
    }
    await _clearSession();
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    _setBusy(true);
    try {
      await repository.deleteAccount();
      await _clearSession();
      _setBusy(false);
      notifyListeners();
      return true;
    } on ApiException catch (failure) {
      _fail(failure.message);
      return false;
    }
  }

  void clearError() {
    if (_error.isEmpty) return;
    _error = '';
    notifyListeners();
  }

  Future<void> _completeLogin(LoginResult result) async {
    await sessionStore.saveToken(result.token);
    await sessionStore.saveProfile({'id': result.profile.id});

    try {
      await loadBootstrap();
    } on ApiException {
      _bootstrap = BootstrapData(
        profile: result.profile,
        role: result.profile.role,
        roleLabel: result.profile.roleLabel,
        capabilities: Capabilities.empty(),
        tabs: const [],
        quickActions: const [],
        scanner: ScannerConfig.fallback(),
        theme: AppTheming.fallback(),
      );
    }

    _stage = AuthStage.loggedIn;
    _busy = false;
    _error = '';
    notifyListeners();
  }

  void _handleUnauthorized() {
    if (_stage == AuthStage.loggedOut) return;
    _clearSession().then((_) => notifyListeners());
  }

  Future<void> _clearSession() async {
    await sessionStore.clear();
    _bootstrap = null;
    _stage = AuthStage.loggedOut;
    _debugOtp = null;
    _pendingPhone = '';
  }

  void _setBusy(bool value) {
    _busy = value;
    if (value) _error = '';
    notifyListeners();
  }

  void _fail(String message) {
    _busy = false;
    _error = message;
    notifyListeners();
  }

  Map<String, dynamic> _bootstrapToJson(BootstrapData data) {
    return {
      'profile': {
        'id': data.profile.id,
        'name': data.profile.name,
        'first_name': data.profile.firstName,
        'middle_name': data.profile.middleName,
        'last_name': data.profile.lastName,
        'phone_code': data.profile.phoneCode,
        'phone': data.profile.phone,
        'email': data.profile.email,
        'dob': data.profile.dob,
        'gender': data.profile.gender,
        'photo': data.profile.photo,
        'address_one': data.profile.addressOne,
        'address_two': data.profile.addressTwo,
        'zip': data.profile.zip,
        'type': data.profile.type,
        'role': data.profile.role.name,
        'role_label': data.profile.roleLabel,
        'designation': data.profile.designation,
        'brand': data.profile.brand,
        'member_since': data.profile.memberSince,
      },
      'role': _roleSlug(data.role),
      'role_label': data.roleLabel,
      'capabilities': data.capabilities.toJson(),
      'tabs': data.tabs
          .map((e) => {
                'key': e.key,
                'label': e.label,
                'icon': e.icon,
                'endpoint': e.endpoint,
              })
          .toList(),
      'quick_actions': data.quickActions
          .map((e) => {
                'key': e.key,
                'label': e.label,
                'icon': e.icon,
                'primary': e.primary,
              })
          .toList(),
      'scanner': {
        'mode': data.scanner.mode == ScannerMode.supplyChain
            ? 'supply_chain'
            : 'product',
        'submit_endpoint': data.scanner.submitEndpoint,
        'requires_location': data.scanner.requiresLocation,
        'hint': data.scanner.hint,
      },
      'theme': {
        'accent': data.theme.accent,
        'greeting': data.theme.greeting,
        'display_name': data.theme.displayName,
      },
    };
  }

  String _roleSlug(UserRole role) {
    switch (role) {
      case UserRole.supplyChain:
        return 'supply_chain';
      case UserRole.brand:
        return 'brand';
      case UserRole.inspector:
        return 'inspector';
      case UserRole.authority:
        return 'authority';
      case UserRole.admin:
        return 'admin';
      case UserRole.consumer:
        return 'consumer';
    }
  }
}
