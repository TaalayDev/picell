class Constants {
  const Constants._();

  static const baseUrl = 'https://keremetapps.if.ua';
  static const apiUrl = '$baseUrl/api/v1';
  static const privacyPolicyUrl = 'https://taalaydev.github.io/files/pixelverse-privacy-policy.html';
  static const termsOfServiceUrl = 'https://taalaydev.github.io/files/pixelverse-terms-of-service.html';
}

const kIsDemo = bool.fromEnvironment('IS_DEMO', defaultValue: false);
