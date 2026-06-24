import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _userIdKey = 'user_id';
  static const _companyIdKey = 'company_id';
  static const _roleKey = 'role';
  static const _tokenKey = 'token';
  static const _firstNameKey = 'first_name';
  static const _lastNameKey = 'last_name';
  static const _companyNameKey = 'company_name';

  static Future<void> saveSession({
    required int userId,
    required int companyId,
    required String role,
    required String token,
    String? firstName,
    String? lastName,
    String? companyName,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_userIdKey, userId);
    await prefs.setInt(_companyIdKey, companyId);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_tokenKey, token);

    await prefs.setString(_firstNameKey, firstName ?? '');
    await prefs.setString(_lastNameKey, lastName ?? '');
    await prefs.setString(_companyNameKey, companyName ?? '');
  }

  static Future<String> getFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_firstNameKey) ?? '';
  }

  static Future<String> getLastName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastNameKey) ?? '';
  }

  static Future<String> getCompanyName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_companyNameKey) ?? '';
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<int?> getCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_companyIdKey);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getInt(_userIdKey);
    final companyId = prefs.getInt(_companyIdKey);
    final role = prefs.getString(_roleKey);

    return userId != null &&
        userId > 0 &&
        companyId != null &&
        companyId > 0 &&
        role != null &&
        role.isNotEmpty;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_userIdKey);
    await prefs.remove(_companyIdKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_firstNameKey);
    await prefs.remove(_lastNameKey);
    await prefs.remove(_companyNameKey);
  }
}
