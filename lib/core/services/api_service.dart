class ApiService {
  static const String baseUrl = "https://taskflowapp.eu/auth";

  static Uri uri(String endpoint) {
    return Uri.parse("$baseUrl/$endpoint");
  }
}
