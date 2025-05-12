import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../widgets/header.dart';
import '../../utils/user_util.dart';
import '../../services/patrol_service.dart';
import 'package:flutter/services.dart';

class PatrolPoint {
  final int id;
  final String name;

  PatrolPoint({required this.id, required this.name});

  factory PatrolPoint.fromJson(Map<String, dynamic> json) {
    return PatrolPoint(
      id: int.parse(json['id'].toString()),
      name: json['name'].toString(),
    );
  }
}

class PatrolListScreen extends StatefulWidget {
  final PageController pageController;
  const PatrolListScreen({super.key, required this.pageController});

  @override
  State<PatrolListScreen> createState() => _PatrolListScreenState();
}

class _PatrolListScreenState extends State<PatrolListScreen> {
  List<PatrolPoint> _patrolPoints = [];

  @override
  void initState() {
    super.initState();
    _fetchPatrolPoints();
  }

  Future<void> _fetchPatrolPoints() async {
    final int? locationId = selectedLocationId.value;
    if (locationId == null) return;

    final url = Uri.parse('${dotenv.env['BASE_URL']}:${dotenv.env['PORT']}/api/v1/patrolPoint/find?locationId=$locationId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> data = decoded['content'];
        final List<PatrolPoint> parsed = data.map((e) => PatrolPoint.fromJson(e)).toList();

        setState(() {
          _patrolPoints = parsed;
        });
      } catch (e) {
        print("❗️JSON 파싱 실패: ${response.body}");
      }
    } else {
      print("순찰 경로 조회 실패: ${response.statusCode}");
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              isControllerScreen: false,
              title: '순찰경로 선택',
              onBack: () {
                widget.pageController.animateToPage(0, duration: Duration(milliseconds: 300), curve: Curves.ease);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('순찰 경로 총 ${_patrolPoints.length}건', style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Colors.grey),
            Expanded(
              child: _patrolPoints.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: _patrolPoints.length,
                itemBuilder: (context, index) {
                  final item = _patrolPoints[index];
                  return ListTile(
                    title: Text(item.name, style: const TextStyle(fontSize: 16)),
                    onTap: () async {
                      final String? userCode = await getUserCode();

                      if (userCode != null) {
                        await PatrolService.postPatrol(
                          userCode: userCode,
                          context: context,
                          recent: false,
                          patrolPointId: item.id,
                          patrolPointName: item.name,
                        );
                      } else {
                        print("⚠️ 사용자 코드가 없습니다.");
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 전역 상태값 전달용
class selectedLocationId {
  static int? value;
}

class selectedPatrolPointId {
  static int? value;
}
