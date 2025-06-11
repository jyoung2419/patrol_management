import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:patrol_management_app/screens/history/patrol_history_detail_screen.dart';
import '../../models/patrol_search_model.dart';
import '../../services/history/patrol_history_service.dart';
import '../../widgets/common_button.dart';
import '../../widgets/header.dart';
import '../../widgets/history/patrol_status_modal.dart';

class PatrolHistoryScreen extends StatefulWidget {
  final PageController? pageController;

  const PatrolHistoryScreen({super.key, this.pageController});

  @override
  State<PatrolHistoryScreen> createState() => _PatrolHistoryScreenState();
}

class _PatrolHistoryScreenState extends State<PatrolHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  int currentPage = 0;
  final int pageSize = 10;
  bool isLoading = false;
  bool hasMore = true;
  String selectedStatus = '작업 시작';
  DateTime startDate = DateTime.now();
  DateTime? endDate;
  List<PatrolSearchResult> resultList = [];

  Map<String, String> statusCodeMap = {
    '작업 시작': 'WORK_START',
    '작업 중': 'PROGRESS',
    '작업 완료': 'WORK_COMPLETE',
    '관리자 확인 완료': 'ADMIN_CHECK_COMPLETE',
  };

  @override
  void initState() {
    super.initState();
    fetchHistory();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 && !isLoading && hasMore) {
        currentPage++;
        fetchHistory();
      }
    });
  }

  bool isInitialLoad = true;

  Future<void> fetchHistory() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    final int effectiveSize = isInitialLoad ? 9999 : pageSize;

    final res = await PatrolSearchService.fetchPatrolSearchList(
      page: currentPage,
      size: effectiveSize,
      mainStatuses: isInitialLoad ? [] : [statusCodeMap[selectedStatus] ?? ''],
      startTime: isInitialLoad ? null : startDate,
      endTime: isInitialLoad ? null : endDate,
    );

    setState(() {
      if (currentPage == 0) resultList.clear();
      if (res != null && res.content.isNotEmpty) {
        resultList.addAll(res.content);
        hasMore = !isInitialLoad && res.content.length == pageSize;
      } else {
        hasMore = false;
      }
      isInitialLoad = false;
      isLoading = false;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : (endDate ?? DateTime.now()),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Color(0xFF33CCC3),
            ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFFF3F3F3)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  String format(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('yyyy-MM-dd').format(dt);
  }
  String formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
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
              onBack: () {
                if (widget.pageController != null) {
                  widget.pageController!.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('검색 조건 설정',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (_) => PatrolStatusModal(
                                onSelect: (value) {
                                  setState(() => selectedStatus = value);
                                },
                              ),
                            );
                          },
                          child: _FilterBox(
                            text: selectedStatus.isEmpty ? '작업 시작' : selectedStatus,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(isStart: true),
                          child: _FilterBox(
                            text: (startDate == null
                                ? '${DateFormat('yyyy-MM-dd').format(DateTime.now())} 시작'
                                : '${format(startDate)} 시작'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: selectedStatus == '작업 시작' || selectedStatus == '작업 중'
                              ? null
                              : () => _pickDate(isStart: false),
                          child: _FilterBox(
                            text: (selectedStatus == '작업 시작' || selectedStatus == '작업 중')
                                ? ''
                                : (endDate == null
                                ? '${DateFormat('yyyy-MM-dd').format(DateTime.now())} 종료'
                                : '${format(endDate)} 종료'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CommonButton(
                    text: '검색',
                    height: 45,
                      onPressed: () {
                        setState(() {
                          isInitialLoad = false;
                          currentPage = 0;
                          hasMore = true;
                        });
                        fetchHistory();
                      }
                  ),
                ],
              ),
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
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: resultList.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < resultList.length) {
                        final item = resultList[index];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PatrolHistoryDetailScreen(item: item), // item 넘김
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
                                      child: Text(item.patrolPointName ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('작업자 ID: ${item.userId ?? '-'}'),
                                          Text('시작 시간: ${formatDateTime(item.patrolStartTime)}'),
                                          Text('종료 시간: ${formatDateTime(item.patrolEndTime)}'),
                                          Text('관리자 확인 시간: ${formatDateTime(item.adminCheckTime)}'),
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
                      } else {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _FilterBox extends StatelessWidget {
  final String text;

  const _FilterBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text
      ),
    );
  }
}