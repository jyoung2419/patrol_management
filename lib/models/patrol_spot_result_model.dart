class PatrolSpotResultModel {
  final int seq;
  final String memo;
  final String patrolResult;
  final bool checkFlag;
  final String spotName;
  final DateTime createdDate;
  final DateTime lastUpdateDate;

  PatrolSpotResultModel({
    required this.seq,
    required this.memo,
    required this.patrolResult,
    required this.checkFlag,
    required this.spotName,
    required this.createdDate,
    required this.lastUpdateDate,
  });

  factory PatrolSpotResultModel.fromJson(Map<String, dynamic> json) {
    return PatrolSpotResultModel(
      seq: json['seq'],
      memo: json['memo'] ?? '',
      patrolResult: json['patrolResult'] ?? '',
      checkFlag: json['checkFlag'] ?? false,
      spotName: json['spotName'] ?? '',
      createdDate: DateTime.parse(json['createdDate']),
      lastUpdateDate: DateTime.parse(json['lastUpdateDate']),
    );
  }
}
