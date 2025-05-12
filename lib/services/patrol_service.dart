import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/global_provider.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../screens/patrol/controller_screen.dart';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';

class PatrolService {
  static const String _keyPatrolId = 'patrol.status.patrolId';
  static const String _keyPatrolPointId = 'patrol.status.patrolPointId';
  static const String _keyPatrolPointName = 'patrol.status.patrolPointName';
  static const String _keyLocationId = 'patrol.status.locationId';

  static Uri buildUri(String path) {
    final base = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2';
    final port = dotenv.env['PORT'] ?? '8080';
    return Uri.parse('$base:$port$path');
  }

  // 순찰 상태 초기화
  static Future<void> resetPatrolProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPatrolId);

    GlobalProvider.patrolInProgress.value = false;
  }

  // 순찰 상태 여부를 가져와 유지함
  static Future<void> restorePatrolProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final locationId = prefs.getString(_keyLocationId); // locationId는 String 타입으로 저장
    final patrolId = prefs.getInt(_keyPatrolId);

    if (locationId != null && patrolId != null) {
      GlobalProvider.patrolInProgress.value = true;
    }
    if (patrolId != null) {
      GlobalProvider.patrolId.value = patrolId;
    }
  }

  // 순찰 상태 true로 세팅하고 필요 시 데이터도 저장
  static Future<void> setPatrolProgress(
      int patrolId,
      int? patrolPointId,
      String patrolPointName,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_keyPatrolId, patrolId);
    if (patrolPointId != null) {
      await prefs.setInt(_keyPatrolPointId, patrolPointId);
    }
    await prefs.setString(_keyPatrolPointName, patrolPointName);

    GlobalProvider.patrolInProgress.value = true;
    GlobalProvider.patrolId.value = patrolId;
  }


  // 순찰 중단 확인
  static void askAbortPatrol(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('순찰 중단'),
        content: Text('현재 지점 순찰을 중단하시겠습니까?'),
        actions: [
          TextButton(
            child: Text('아니오'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('순찰 중단'),
            onPressed: () async {
              Navigator.of(context).pop(); // 알림 닫기
              await resetPatrolProgress();

              Fluttertoast.showToast(msg: '순찰을 중단하였습니다.');

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const ControllerScreen()),
                    (route) => false,
              );
            },
          )
        ],
      ),
    );
  }

  static Future<void> checkOngoingPatrolWithCallback(
      BuildContext context,
      String userCode, {
        required VoidCallback onNewPatrol,
        required VoidCallback onNoPatrol,
        bool recent = true,
      }) async {
    final url = buildUri('/api/v1/patrol/user/find');
    final body = {
      "userCode": userCode,
      "statuesOption": "NOT_COMPLETED",
      "recentlyOption": recent,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final bodyString = utf8.decode(response.bodyBytes);

        // 서버에서 문자열이 올 경우 대비
        if (bodyString.startsWith('[')) {
          final patrols = jsonDecode(bodyString);

          if (patrols.isNotEmpty) {
            final patrol = patrols[0];
            final String patrolPointName = patrol['patrolPointName'];

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                title: const Text('아직 완료하지 않은 순찰이 있습니다.\n순찰을 계속 하시겠습니까?',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                content: Text('순찰 경로: $patrolPointName'),
                actions: [
                  TextButton(
                    child: const Text('순찰 재개'),
                    onPressed: () async {
                      Navigator.of(context).pop();

                      // 순찰 재개 처리
                      final patrolId = patrol['seq'];
                      // final patrolPointId = patrol['patrolPointId'];  // patrolPointId 값 추가
                      final patrolPointName = patrol['patrolPointName'];

                      await setPatrolProgress(patrolId, null, patrolPointName);

                      // 순찰 재개 후 ControllerScreen으로 이동
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ControllerScreen()),
                      );
                    },
                  ),
                  TextButton(
                    child: const Text('신규 순찰'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onNewPatrol();
                    },
                  ),
                ],
              ),
            );
          } else {
            onNoPatrol();
          }
        } else {
          if (bodyString == "No patrols found for the user.") {
            print("서버 메시지: No patrols found for the user.");
          }
          onNoPatrol();
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  static Future<void> postPatrol({
    required String userCode,
    required BuildContext context,
    required bool recent,
    int? patrolPointId, // recent=false일 때만 사용됨
    String? patrolPointName,
  }) async {
    try {
      int patrolId;

      if (!recent) {
        // 신규 순찰 등록
        final url = buildUri('/api/v1/patrol/register');
        final headers = {'Content-Type': 'application/json'};
        final body = jsonEncode({
          'userCode': userCode,
          'companyId': 1,
          'patrolPointId': patrolPointId,
        });

        final response = await http.post(url, headers: headers, body: body);
        if (response.statusCode != 200) throw Exception('순찰 등록 실패');
        patrolId = int.parse(response.body.trim());

        await setPatrolProgress(patrolId, patrolPointId!, patrolPointName ?? '',);

      } else {
        // 진행 중 순찰 이어받기
        final url = buildUri('/api/v1/patrol/user/find');
        final headers = {'Content-Type': 'application/json'};
        final body = jsonEncode({
          'userCode': userCode,
          'statuesOption': 'NOT_COMPLETED',
          'recentlyOption': true,
        });

        final response = await http.post(url, headers: headers, body: body);
        if (response.statusCode != 200) throw Exception('진행 중 순찰 조회 실패');

        final patrols = jsonDecode(utf8.decode(response.bodyBytes));
        if (patrols.isEmpty) throw Exception('진행 중 순찰 없음');

        final patrol = patrols[0];
        patrolId = patrol['seq'];
        final patrolPointName = patrol['patrolPointName'];

        await setPatrolProgress(patrolId, null, patrolPointName);
      }

      Navigator.pushReplacementNamed(context, '/controller');
    } catch (e) {
      print('❗ postPatrol 오류: $e');
      Fluttertoast.showToast(msg: '순찰 처리 중 오류 발생');
    }
  }

  static Future<Map<String, String>?> getSpot(int spotId) async {
    final url = buildUri('/api/v1/spot/detail/$spotId');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return {
        'name': data['name'],
        'uuid': data['uuid'],
      };
    }
    return null;
  }

  static Future<List<String>> getPatrolComments(int companyId) async {
    final url = buildUri('/api/v1/patrol/comment/company/$companyId');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final List<dynamic> list = jsonDecode(utf8.decode(res.bodyBytes));
      final comments = list.map((e) => e['patrolComment'] as String).toList();
      comments.add('직접 입력');
      return comments;
    }
    return ['직접 입력'];
  }

  static Future<http.StreamedResponse> postPatrolResult({
    required int patrolId,
    required int spotId,
    required String spotUuid,
    required String memo,
    required String patrolResult,
    required List<Uint8List> images,
    required List<String> videos,
  }) async {
    final uri = buildUri('/api/v1/patrolResult/check/spot');
    final request = http.MultipartRequest('POST', uri);

    final jsonMap = {
      'patrolId': patrolId,
      'spotUuid': spotUuid,
      'memo': memo,
      'patrol_result': patrolResult,
    };
    final jsonString = jsonEncode(jsonMap);

    request.files.add(http.MultipartFile.fromString(
      'data',
      jsonString,
      contentType: MediaType('application', 'json'),
    ));

    for (var image in images) {
      request.files.add(http.MultipartFile.fromBytes(
        'images',
        image,
        filename: 'patrol_image.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    for (var videoPath in videos) {
      final videoFile = await http.MultipartFile.fromPath(
        'videos',
        videoPath,
        contentType: MediaType('video', 'mp4'),
      );
      request.files.add(videoFile);
    }

    return await request.send();
  }
}