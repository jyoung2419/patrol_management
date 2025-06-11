import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'patrol_media_viewer_screen.dart';
import '../../models/patrol_search_model.dart';
import '../../models/patrol_spot_result_model.dart';
import '../../services/history/patrol_history_service.dart';
import '../../widgets/header.dart';

class PatrolHistoryDetailScreen extends StatefulWidget {
  final PatrolSearchResult item;

  const PatrolHistoryDetailScreen({super.key, required this.item});

  @override
  State<PatrolHistoryDetailScreen> createState() => _PatrolHistoryDetailScreenState();
}

class _PatrolHistoryDetailScreenState extends State<PatrolHistoryDetailScreen> {
  List<PatrolSpotResultModel> spotResults = [];

  @override
  void initState() {
    super.initState();
    _loadSpotResults();
  }

  Future<void> _loadSpotResults() async {
    final results = await PatrolSearchService.fetchPatrolSpotResults(widget.item.id);
    setState(() {
      spotResults = results;
    });
  }

  String formatDateTime(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              isControllerScreen: false,
              title: '순찰 기록 조회',
              onBack: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: spotResults.isEmpty
                      ? const Center(
                    child: Text(
                      '순찰 상세 결과가 없습니다.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  )
                      : ListView.builder(
                    itemCount: spotResults.length,
                      itemBuilder: (context, index) {
                        final spot = spotResults[index];
                        return GestureDetector(
                          onTap: () async {
                            final images = await PatrolSearchService.fetchPatrolResultImage(spot.seq);
                            final videos = await PatrolSearchService.fetchPatrolResultVideo(spot.seq);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PatrolMediaViewerScreen(images: images, videos: videos),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        spot.spotName,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '순찰 결과: ${spot.memo} ${spot.checkFlag ? '(${spot.patrolResult})' : '-'}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            '순찰 등록: ${spot.checkFlag ? formatDateTime(spot.lastUpdateDate) : '-'}',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                            ],
                          ),
                        );
                      }
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
