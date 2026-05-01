class AppConfig {
  static const String appName = 'المشرق العربي';
  static const String wordpressBaseUrl = String.fromEnvironment(
    'WP_BASE_URL',
    defaultValue: 'https://www.arabmashreq.com/wp-json/wp/v2',
  );
  static const String backendBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.arabmashreq.com/api/v1',
  );
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
}
