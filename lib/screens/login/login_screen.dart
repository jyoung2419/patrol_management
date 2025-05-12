import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/secure_storage_util.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/patrol_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _userPwController = TextEditingController();
  final storage = const FlutterSecureStorage();

  bool _isLoading = false;

  void _checkAutoLogin() async {
    String? token = await SecureStorageUtil.getToken();
    if (token != null) {
      _navigateToHome();
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);

    final String id = _userIdController.text.trim();
    final String password = _userPwController.text.trim();

    if (id.isEmpty || password.isEmpty) {
      _showErrorDialog("아이디와 비밀번호를 입력하세요.");
      setState(() => _isLoading = false);
      return;
    }

    final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2';
    final String port = dotenv.env['PORT'] ?? '8080';
    final Uri url = Uri.parse('$baseUrl:$port/api/v1/user/login');
    print("Sending request with userCode: $id");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = jsonDecode(decodedResponse);

        final String? token = data['token'];
        final String? name = data['name'];

        print("Decoded Response: $decodedResponse");

        if (token != null && name != null) {
          await SecureStorageUtil.saveToken(token);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('id', id);
          await prefs.setString('password', password);
          _navigateToHome();
        } else {
          _showErrorDialog("서버에서 토큰 또는 이름을 반환하지 않았습니다.");
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorDialog("로그인 실패: ${errorData['message'] ?? '알 수 없는 오류'}");
      }
    } catch (e) {
      _showErrorDialog("로그인 실패: 네트워크 오류 또는 서버에 접근할 수 없습니다.");
    }

    setState(() => _isLoading = false);
  }


  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/controller');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("로그인 오류"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF33CCC3),
        statusBarIconBrightness: Brightness.light,
      ),
    );
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20, // 키보드 높이에 맞게 여유 공간 추가
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 270,
                    color: const Color(0xFF33CCC3),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.5,
                    ),
                  ),
                  Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "스마트 안전 관리 시스템",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Nextcare Safety 3D technology",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    "SIGN IN",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        TextField(
                          controller: _userIdController,
                          decoration: InputDecoration(
                            hintText: "아이디를 입력하세요",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: const BorderSide(color: Colors.black54),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _userPwController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "비밀번호를 입력하세요",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: const BorderSide(color: Colors.black54),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.78,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF33CCC3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "로그인",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Copyright (c) 2021 NextcoreTechnology\nAll right reserved.",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
