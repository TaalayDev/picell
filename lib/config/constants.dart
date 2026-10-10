class Constants {
  const Constants._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://keremetapps.if.ua',
  );
  static const apiUrl = '$baseUrl/api/v1';
  static const privacyPolicyUrl = 'https://taalaydev.github.io/files/pixelverse-privacy-policy.html';
  static const termsOfServiceUrl = 'https://taalaydev.github.io/files/pixelverse-terms-of-service.html';
  static const kofiUrl = 'https://ko-fi.com/akbulut';
  static const websiteUrl = 'https://pixelverse.app';

  /// Public web page of a community project (used for sharing / copy link).
  static String projectUrl(int projectId) => '$websiteUrl/project/$projectId';
}

const kIsDemo = bool.fromEnvironment('IS_DEMO', defaultValue: false);
