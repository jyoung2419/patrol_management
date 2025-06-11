import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getUserCode() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('id'); // 로그인 시 저장한 사용자 ID
}

Future<String?> getUserName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('name');
}
