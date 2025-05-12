import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../widgets/header.dart';
import 'package:flutter/services.dart';

class PatrolHistoryScreen extends StatefulWidget {
  const PatrolHistoryScreen({super.key});

  @override
  State<PatrolHistoryScreen> createState() => _PatrolHistoryScreenState();
}

class _PatrolHistoryScreenState extends State<PatrolHistoryScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse('http://192.168.10.225/mobile/webView/patrolHistory.html'),
      );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF3F3F3),
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(
              isControllerScreen: false,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: WebViewWidget(controller: _controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
