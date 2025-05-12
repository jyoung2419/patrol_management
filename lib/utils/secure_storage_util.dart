import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageUtil {
  static final _storage = FlutterSecureStorage();
  static const _jwtKey = 'token';
  static const _expireKey = 'token_expire';
  static const int sessionDuration = 1000 * 60 * 60 * 24; // 24시간 유지

  static Future<void> saveToken(String token) async {
    int expireTime = DateTime.now().millisecondsSinceEpoch + sessionDuration;
    await _storage.write(key: _jwtKey, value: token);
    await _storage.write(key: _expireKey, value: expireTime.toString());
  }

  static Future<String?> getToken() async {
    String? token = await _storage.read(key: 'token');
    String? expireTimeString = await _storage.read(key: 'token_expire');

    if (token == null || expireTimeString == null) return null;

    int expireTime = int.parse(expireTimeString);
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    if (currentTime > expireTime) {
      print("세션 만료됨. JSESSIONID 삭제");
      await deleteToken();
      return null;
    }

    await _extendSession();

    return token;
  }

  static Future<void> _extendSession() async {
    int newExpireTime = DateTime.now().millisecondsSinceEpoch + sessionDuration;
    await _storage.write(key: 'token_expire', value: newExpireTime.toString());
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'token_expire');
  }
}
