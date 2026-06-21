class PermissionService {
  static bool canAccessManager(String role) {
    return [
      'platform_admin',
      'company_admin',
      'manager',
    ].contains(role);
  }
}