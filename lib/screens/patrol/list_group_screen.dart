import 'package:flutter/material.dart';
import '../../services/patrol_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_list_screen.dart';
import 'patrol_list_screen.dart';
import 'package:flutter/services.dart';

class ListGroupScreen extends StatefulWidget {
  const ListGroupScreen({super.key});

  @override
  State<ListGroupScreen> createState() => _ListGroupScreenState();
}

class _ListGroupScreenState extends State<ListGroupScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _checkPatrol(); // 진입 시 순찰 상태 확인
  }

  Future<void> _checkPatrol() async {
    final prefs = await SharedPreferences.getInstance();
    final userCode = prefs.getString('id');

    if (userCode != null) {
      await PatrolService.checkOngoingPatrolWithCallback(
        context,
        userCode,
        onNewPatrol: () => _pageController.animateToPage(0, duration: Duration(milliseconds: 300), curve: Curves.ease),
        onNoPatrol: () => _pageController.animateToPage(0, duration: Duration(milliseconds: 300), curve: Curves.ease),  // 서버에 미완료 순찰이 없을때
      );
    } else {
      print('userCode가 없습니다.');
    }
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
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          LocationListScreen(
            onLocationSelected: (id) {
              selectedLocationId.value = id;
              print('✅ 선택된 locationId: $id');
              _pageController.animateToPage(1, duration: Duration(milliseconds: 300), curve: Curves.ease);
            },
          ),
          PatrolListScreen(pageController: _pageController),
        ],
      ),
    );
  }
}