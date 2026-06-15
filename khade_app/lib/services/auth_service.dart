import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'khade_api.dart';
import 'push_notification_service.dart';

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _tokenKey = 'khade_auth_token';
  static const _onboardingKey = 'khade_onboarding_done';

  String? _token;
  UserModel? _authUser;
  bool onboardingDone = false;

  String? get token => _token;
  UserModel? get authUser => _authUser;
  bool get isLoggedIn => _token != null && _authUser != null;
  bool get isGuest => !isLoggedIn;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    onboardingDone = prefs.getBool(_onboardingKey) ?? false;
    _token = prefs.getString(_tokenKey);
    if (_token != null) {
      khadeApi.setToken(_token);
      try {
        _authUser = await khadeApi.getMe();
        await PushNotificationService.instance.registerIfLoggedIn();
      } catch (_) {
        await clearSession();
      }
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboardingDone = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }

  Future<UserModel> login({required String email, required String password}) async {
    final result = await khadeApi.login(email: email, password: password);
    await _persistSession(result.token, result.user);
    return result.user;
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    String role = 'customer',
    String city = 'Abuja',
    String? phone,
    String? businessName,
    String? cacNumber,
    String visitTypes = 'both',
    String area = 'Wuse II',
  }) async {
    final result = await khadeApi.register(
      email: email,
      password: password,
      name: name,
      role: role,
      city: city,
      phone: phone,
      businessName: businessName,
      cacNumber: cacNumber,
      visitTypes: visitTypes,
      area: area,
    );
    await _persistSession(result.token, result.user);
    _lastWelcomeBonus = result.welcomeBonus;
    return result.user;
  }

  int? _lastWelcomeBonus;
  int? consumeWelcomeBonus() {
    final b = _lastWelcomeBonus;
    _lastWelcomeBonus = null;
    return b;
  }

  Future<void> continueAsGuest() async {
    await clearSession();
    notifyListeners();
  }

  Future<void> logout() async {
    await clearSession();
    notifyListeners();
  }

  Future<void> _persistSession(String token, UserModel user) async {
    _token = token;
    _authUser = user;
    khadeApi.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    notifyListeners();
    await PushNotificationService.instance.registerIfLoggedIn();
  }

  Future<void> clearSession() async {
    _token = null;
    _authUser = null;
    khadeApi.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  void updateUser(UserModel user) {
    _authUser = user;
    notifyListeners();
  }
}
