import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/login/login_screen.dart';
import 'screens/patrol/controller_screen.dart';
import 'screens/patrol/list_group_screen.dart';
import 'screens/patrol/qr_screen.dart';
import 'screens/patrol/patrol_result_screen.dart';
import 'screens/patrol/patrol_history_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/env/.env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '스마트 순찰시스템',
      theme: ThemeData(fontFamily: "Pretendard"),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/controller': (context) => const ControllerScreen(),
        '/list_group': (context) => const ListGroupScreen(),
        '/qr': (context) => const QRScreen(),
        '/patrolResult': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PatrolResultScreen(
            spotId: args['spotId'],
            companyId: args['companyId'],
            spotUuid: args['spotUuid'],
          );
        },
        '/patrol_history': (context) => const PatrolHistoryScreen(),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
    );
  }
}