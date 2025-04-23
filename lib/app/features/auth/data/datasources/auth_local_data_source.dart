import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalDataSource {
  static const _tokenKey = 'firebase_token';

  final SharedPreferences _prefs;

  AuthLocalDataSource(this._prefs);

  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }
}
