import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../models/patrol_search_model.dart';
import '../../models/patrol_spot_result_model.dart';

class PatrolSearchService {
  static Uri buildUri(String path) {
    final base = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2';
    final port = dotenv.env['PORT'] ?? '8080';
    return Uri.parse('$base:$port$path');
  }

  static Future<PatrolSearchPage?> fetchPatrolSearchList({
    required List<String> mainStatuses,
    DateTime? startTime,
    DateTime? endTime,
    String? userCode,
    String? patrolPointId,
    String? adminId,
    int size = 10,
    int page = 0,
    String sortOrder = 'ASC',
  }) async {
    const int companyId = 1;

    final queryParams = {
      'companyId': companyId.toString(),
      'page': page.toString(),
      'size': size.toString(),
      'sortOrder': sortOrder,
      if (startTime != null)
        'startTime': _startOfDay(startTime).toIso8601String(),
      if (endTime != null)
        'endTime': _endOfDay(endTime).toIso8601String(),
      if (userCode != null && userCode.isNotEmpty)
        'userCode': userCode,
      if (patrolPointId != null && patrolPointId.isNotEmpty)
        'patrolPointId': patrolPointId,
      if (adminId != null && adminId.isNotEmpty)
        'adminId': adminId,
    };

    final uri = buildUri('/api/v1/patrol/search').replace(queryParameters: {
      ...queryParams,
      if (mainStatuses.isNotEmpty)
        for (var s in mainStatuses) 'mainStatus': s,
    });
    try {
      final res = await http.get(uri);
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));

      if (res.statusCode == 200) {
        print('📊 전체 데이터 개수: ${decoded["totalElements"]}');
        return PatrolSearchPage.fromJson(decoded);
      } else {
        print('❌ Patrol search failed: ${res.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error during fetchPatrolSearchList: $e');
      return null;
    }
  }

  static Future<List<PatrolSpotResultModel>> fetchPatrolSpotResults(int patrolId) async {
    final uri = buildUri('/api/v1/patrolResult/data/$patrolId');
    try {
      final res = await http.get(uri);
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));

      if (res.statusCode == 200) {
        final List list = decoded;
        return list.map((e) => PatrolSpotResultModel.fromJson(e)).toList();
      } else {
        print('❌ 스팟 결과 요청 실패: ${res.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ 스팟 결과 요청 중 오류: $e');
      return [];
    }
  }

  static Future<List<String>> fetchPatrolResultImage(int patrolResultId) async {
    final uri = buildUri('/api/v1/patrolResult/image/$patrolResultId');
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        return List<String>.from(decoded);
      } else {
        return [];
      }
    } catch (e) {
      print('❌ 이미지 요청 오류: $e');
      return [];
    }
  }

  static Future<List<String>> fetchPatrolResultVideo(int patrolResultId) async {
    final videoIdsUri = buildUri('/api/v1/patrolResult/video/$patrolResultId');
    print('🎥 영상 ID 요청 URI: $videoIdsUri');

    try {
      final res = await http.get(videoIdsUri);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        print('✅ 영상 ID 응답: $decoded');

        if (decoded is List) {
          List<String> base64Videos = [];

          for (var id in decoded) {
            final downloadUri = buildUri('/api/v1/patrolResult/download/$id');
            print('⬇️ 영상 다운로드 요청: $downloadUri');

            final downloadRes = await http.get(downloadUri);
            if (downloadRes.statusCode == 200) {
              final base64 = base64Encode(downloadRes.bodyBytes);
              base64Videos.add(base64);
            } else {
              print('❌ 다운로드 실패: $id - ${downloadRes.statusCode}');
            }
          }
          return base64Videos;
        }
      }
      return [];
    } catch (e) {
      print('❌ 영상 요청 오류: $e');
      return [];
    }
  }

  static DateTime _startOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, 0, 0, 0);

  static DateTime _endOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, 23, 59, 59, 999);
}
