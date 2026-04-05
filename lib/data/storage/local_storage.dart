import 'dart:convert';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

enum StorageKey {
  token,
  themeType,
  locale,
  notificationsEnabled,
  deviceId,
  firstRun,
  authSkipped,
  currentUser,
  hasBioAuth,
  feedbackPromptNeverAskAgain,
  // Editor settings
  editorInputMode,
  editorShowGrid,
  editorZoomSensitivity,
  editorMinZoom,
  editorMaxZoom,
  editorTwoFingerUndo,
  editorShowPixelGrid,
  editorPixelGridOpacity,
}

/// A singleton class to handle simple storage operations.
/// It also provides a way to listen to changes in the stored values.
///
/// Initialize the instance using [LocalStorage.init] before using it.
///
/// ```dart
/// final storage = LocalStorage.instance;
///
/// storage.setInt('key', 1);
/// storage.addListener('key', (value) => print(value));
///
/// final value = storage.getInt('key');
/// ```
abstract class LocalStorage {
  static LocalStorage? _instance;
  static LocalStorage get instance => _instance!;

  factory LocalStorage() => instance;

  LocalStorage._();

  static init() async {
    assert(_instance == null);
    _instance = await SharedPrefLocalStorageImpl._().init();
    return _instance!;
  }

  void setInt(String key, int value);
  void setDouble(String key, double value);
  void setBool(String key, bool value);
  void setString(String key, String value);
  void setStringList(String key, List<String> value);
  void setObject(String key, Object? value);

  bool? getBool(String key);
  int? getInt(String key);
  double? getDouble(String key);
  String? getString(String key);
  List<String>? getStringList(String key);
  dynamic getObject(String key);

  void addListener<T>(StorageKey key, Function(dynamic value) listener);
  void removeListener(StorageKey key);

  bool get notificationsEnabled => getBool(StorageKey.notificationsEnabled.name) ?? true;
  set notificationsEnabled(bool val) => setBool(StorageKey.notificationsEnabled.name, val);

  int? get deviceId => getInt(StorageKey.deviceId.name);
  set deviceId(int? id) => setInt(StorageKey.deviceId.name, id ?? -1);

  bool get firstRun => getBool(StorageKey.firstRun.name) ?? true;

  set firstRun(bool val) => setBool(StorageKey.firstRun.name, val);

  bool get authSkipped => getBool(StorageKey.authSkipped.name) ?? true;
  set authSkipped(bool val) => setBool(StorageKey.authSkipped.name, val);

  Locale? get locale {
    final map = getObject(StorageKey.locale.name);
    return map != null
        ? Locale.fromSubtags(
            languageCode: map['language_code'],
            countryCode: map['country_code'],
          )
        : null;
  }

  set locale(Locale? locale) => setObject(
        StorageKey.locale.name,
        locale != null
            ? {
                'language_code': locale.languageCode,
                'country_code': locale.countryCode,
              }
            : null,
      );

  bool get hasBioAuth => getBool(StorageKey.hasBioAuth.name) ?? false;
  set hasBioAuth(bool val) => setBool(StorageKey.hasBioAuth.name, val);

  String? get token => getString(StorageKey.token.name);
  set token(String? token) => setString(StorageKey.token.name, token ?? '');

  void clearToken() => setString(StorageKey.token.name, '');
  void setToken(String? token) {
    if (token != null) {
      setString(StorageKey.token.name, token);
    } else {
      setString(StorageKey.token.name, '');
    }
  }

  bool get feedbackPromptNeverAskAgain => getBool(StorageKey.feedbackPromptNeverAskAgain.name) ?? false;
  set feedbackPromptNeverAskAgain(bool val) => setBool(StorageKey.feedbackPromptNeverAskAgain.name, val);
}

class SharedPrefLocalStorageImpl extends LocalStorage {
  SharedPreferences? _preferences;
  Map<String, Function(dynamic value)> listeners = {};

  SharedPrefLocalStorageImpl._() : super._();

  Future<SharedPrefLocalStorageImpl> init() async {
    _preferences = await SharedPreferences.getInstance();

    return this;
  }

  @override
  void setInt(String key, int value) {
    _preferences?.setInt(key, value);
    listeners[key]?.call(value);
  }

  @override
  void setDouble(String key, double value) {
    _preferences?.setDouble(key, value);
    listeners[key]?.call(value);
  }

  @override
  void setBool(String key, bool value) {
    _preferences?.setBool(key, value);

    listeners[key]?.call(value);
  }

  @override
  void setString(String key, String value) {
    _preferences?.setString(key, value);
    listeners[key]?.call(value);
  }

  @override
  void setStringList(String key, List<String> value) {
    _preferences?.setStringList(key, value);
    listeners[key]?.call(value);
  }

  @override
  void setObject(String key, Object? value) {
    _preferences?.setString(key, jsonEncode(value));
    listeners[key]?.call(value);
  }

  @override
  bool? getBool(String key) => _preferences?.getBool(key);
  @override
  int? getInt(String key) => _preferences?.getInt(key);
  @override
  double? getDouble(String key) => _preferences?.getDouble(key);
  @override
  String? getString(String key) => _preferences?.getString(key);
  @override
  List<String>? getStringList(String key) => _preferences?.getStringList(key);
  @override
  dynamic getObject(String key) {
    final value = _preferences?.getString(key);
    if (value != null) return jsonDecode(value);
    return null;
  }

  @override
  void addListener<T>(StorageKey key, Function(dynamic value) listener) {
    // _preferences?.
    listeners[key.name] = listener;
  }

  @override
  void removeListener(StorageKey key) => listeners.remove(key.name);
}
