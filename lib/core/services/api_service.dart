class ApiService {
  static const String authBaseUrl = "https://taskflowapp.eu/auth";
  static const String pointageBaseUrl = "https://taskflowapp.eu/pointagepro";

  static Uri auth(String endpoint) {
    return Uri.parse("$authBaseUrl/$endpoint");
  }

  static Uri pointage(String endpoint) {
    return Uri.parse("$pointageBaseUrl/$endpoint");
  }
}