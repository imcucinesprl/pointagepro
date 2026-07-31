class ApiService {
  static const String authBaseUrl =
      "https://taskflowapp.eu/auth";

  static const String pointageBaseUrl =
      "https://taskflowapp.eu/pointagepro";

  static const String usersBaseUrl =
      "https://taskflowapp.eu/users";

  static const String synkroBaseUrl =
      "https://synkroapp.be/notify/api";

  static Uri auth(String endpoint) {
    return Uri.parse("$authBaseUrl/$endpoint");
  }

  static Uri pointage(String endpoint) {
    return Uri.parse("$pointageBaseUrl/$endpoint");
  }

  static Uri users(String endpoint) {
    return Uri.parse("$usersBaseUrl/$endpoint");
  }

  static Uri communications(String endpoint) {
    return Uri.parse(
      "$synkroBaseUrl/communications/$endpoint",
    );
  }
}