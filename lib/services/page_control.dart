import 'package:flutter/material.dart';

class PageControl {
  /// 일반적인 페이지 이동
  static void next(BuildContext context, String routeName) {
    Navigator.pushNamed(context, '/$routeName');
  }

  /// 현재 페이지 대체 (뒤로가기 막기용)
  static void replace(BuildContext context, String routeName) {
    Navigator.pushReplacementNamed(context, '/$routeName');
  }

  /// 스택 비우고 이동 (로그아웃 등)
  static void offAll(BuildContext context, String routeName) {
    Navigator.pushNamedAndRemoveUntil(context, '/$routeName', (route) => false);
  }

  /// 뒤로가기
  static void back(BuildContext context) {
    Navigator.pop(context);
  }
}