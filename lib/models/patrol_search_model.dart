class PatrolSearchResult {
  final int id;
  final String statues;
  final String? userId;
  final String? patrolPointName;
  final String? adminId;
  final DateTime? patrolStartTime;
  final DateTime? patrolEndTime;
  final DateTime? adminCheckTime;

  PatrolSearchResult({
    required this.id,
    required this.statues,
    this.userId,
    this.patrolPointName,
    this.adminId,
    this.patrolStartTime,
    this.patrolEndTime,
    this.adminCheckTime,
  });

  factory PatrolSearchResult.fromJson(Map<String, dynamic> json) {
    return PatrolSearchResult(
      id: json['id'],
      statues: json['statues'],
      userId: json['userId'],
      patrolPointName: json['patrolPointName'],
      adminId: json['adminId'],
      patrolStartTime: json['patrolStartTime'] != null ? DateTime.parse(json['patrolStartTime']) : null,
      patrolEndTime: json['patrolEndTime'] != null ? DateTime.parse(json['patrolEndTime']) : null,
      adminCheckTime: json['adminCheckTime'] != null ? DateTime.parse(json['adminCheckTime']) : null,
    );
  }
}

class PatrolSearchPage {
  final int totalPages;
  final int totalElements;
  final int size;
  final int number;
  final List<PatrolSearchResult> content;

  PatrolSearchPage({
    required this.totalPages,
    required this.totalElements,
    required this.size,
    required this.number,
    required this.content,
  });

  factory PatrolSearchPage.fromJson(Map<String, dynamic> json) {
    final page = json['page'] ?? {};

    return PatrolSearchPage(
      totalPages: page['totalPages'] ?? 0,
      totalElements: page['totalElements'] ?? 0,
      size: page['size'] ?? 0,
      number: page['number'] ?? 0,
      content: (json['content'] as List)
          .map((e) => PatrolSearchResult.fromJson(e))
          .toList(),
    );
  }
}
