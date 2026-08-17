import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const String _keyToken = 'tracesci_token';
  static const String _keyProfile = 'tracesci_profile';
  static const String _keyBootstrap = 'tracesci_bootstrap';
  static const String _keyMasters = 'tracesci_masters';
  static const String _keyOnboarded = 'tracesci_onboarded';

  SharedPreferences? _prefs;
  String? _cachedToken;

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> init() async {
    final prefs = await _instance;
    _cachedToken = prefs.getString(_keyToken);
  }

  String? get token => _cachedToken;

  bool get hasSession => _cachedToken != null && _cachedToken!.isNotEmpty;

  Future<void> saveToken(String token) async {
    final prefs = await _instance;
    _cachedToken = token;
    await prefs.setString(_keyToken, token);
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    final prefs = await _instance;
    await prefs.setString(_keyProfile, jsonEncode(profile));
  }

  Future<Map<String, dynamic>?> readProfile() async {
    return _readMap(_keyProfile);
  }

  Future<void> saveBootstrap(Map<String, dynamic> bootstrap) async {
    final prefs = await _instance;
    await prefs.setString(_keyBootstrap, jsonEncode(bootstrap));
  }

  Future<Map<String, dynamic>?> readBootstrap() async {
    return _readMap(_keyBootstrap);
  }

  Future<void> saveMasters(Map<String, dynamic> masters) async {
    final prefs = await _instance;
    await prefs.setString(_keyMasters, jsonEncode(masters));
  }

  Future<Map<String, dynamic>?> readMasters() async {
    return _readMap(_keyMasters);
  }

  Future<bool> isOnboarded() async {
    final prefs = await _instance;
    return prefs.getBool(_keyOnboarded) ?? false;
  }

  Future<void> markOnboarded() async {
    final prefs = await _instance;
    await prefs.setBool(_keyOnboarded, true);
  }

  Future<void> clear() async {
    final prefs = await _instance;
    _cachedToken = null;
    await prefs.remove(_keyToken);
    await prefs.remove(_keyProfile);
    await prefs.remove(_keyBootstrap);
  }

  Future<Map<String, dynamic>?> _readMap(String key) async {
    final prefs = await _instance;
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
    return null;
  }
}
