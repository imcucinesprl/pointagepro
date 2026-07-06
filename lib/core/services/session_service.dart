import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _userIdKey = 'user_id';
  static const _companyIdKey = 'company_id';
  static const _roleKey = 'role';
  static const _tokenKey = 'token';
  static const _firstNameKey = 'first_name';
  static const _lastNameKey = 'last_name';
  static const _companyNameKey = 'company_name';

  // Abonnement
  static const _companyStatusKey = 'company_status';
  static const _subscriptionStatusKey = 'subscription_status';
  static const _planKey = 'plan';
  static const _trialEndsAtKey = 'trial_ends_at';
  static const _subscriptionEndsAtKey = 'subscription_ends_at';

  static Future<void> saveSession({
    required int userId,
    required int companyId,
    required String role,
    required String token,
    String? firstName,
    String? lastName,
    String? companyName,

    // Abonnement
    String? companyStatus,
    String? subscriptionStatus,
    String? plan,
    String? trialEndsAt,
    String? subscriptionEndsAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_userIdKey, userId);
    await prefs.setInt(_companyIdKey, companyId);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_tokenKey, token);

    await prefs.setString(_firstNameKey, firstName ?? '');
    await prefs.setString(_lastNameKey, lastName ?? '');
    await prefs.setString(_companyNameKey, companyName ?? '');

    await prefs.setString(_companyStatusKey, companyStatus ?? '');
    await prefs.setString(_subscriptionStatusKey, subscriptionStatus ?? '');
    await prefs.setString(_planKey, plan ?? '');
    await prefs.setString(_trialEndsAtKey, trialEndsAt ?? '');
    await prefs.setString(_subscriptionEndsAtKey, subscriptionEndsAt ?? '');
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

  static Future<String> getCompanyStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_companyStatusKey) ?? '';
  }

  static Future<String> getSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subscriptionStatusKey) ?? '';
  }

  static Future<String> getPlan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_planKey) ?? '';
  }

  static Future<String> getTrialEndsAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_trialEndsAtKey) ?? '';
  }

  static Future<String> getSubscriptionEndsAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subscriptionEndsAtKey) ?? '';
  }

  static Future<bool> hasActiveSubscription() async {
    final role = await getRole();

    if (role == 'employee') {
      return true;
    }

    final companyStatus = await getCompanyStatus();
    final subscriptionStatus = await getSubscriptionStatus();

    if (companyStatus == 'inactive' || companyStatus == 'blocked') {
      return false;
    }

    return subscriptionStatus == 'active' ||
        subscriptionStatus == 'trialing' ||
        subscriptionStatus == 'trial';
  }

  static Future<void> saveCompanyId(int companyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_companyIdKey, companyId);
  }

  static Future<void> saveCompanyName(String companyName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_companyNameKey, companyName);
  }

  static Future<void> saveFirstName(String firstName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_firstNameKey, firstName);
  }

  static Future<void> saveLastName(String lastName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastNameKey, lastName);
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

    await prefs.remove(_companyStatusKey);
    await prefs.remove(_subscriptionStatusKey);
    await prefs.remove(_planKey);
    await prefs.remove(_trialEndsAtKey);
    await prefs.remove(_subscriptionEndsAtKey);
  }

  static Future<void> clearSession() async {
    await logout();
  }
}
