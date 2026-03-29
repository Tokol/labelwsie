class BackendApiConfig {
  static const String baseUrl = "https://label-wise-server.onrender.com";
  static const String apiBaseUrl = "$baseUrl/api";

  static const String registerInstallationUrl =
      "$apiBaseUrl/installations/register";
  static const String recordsUrl = "$apiBaseUrl/records";
}
