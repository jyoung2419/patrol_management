import 'dart:convert';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/patrol_service.dart';
import 'camera_screen.dart';
import '../../widgets/header.dart';
import 'dart:typed_data';
import '../../widgets/common_button.dart';
import 'video_player_screen.dart';
import '../../providers/global_provider.dart';
import 'package:flutter/services.dart';

class PatrolResultScreen extends StatefulWidget {
  final int spotId;
  final int companyId;
  final String spotUuid;

  const PatrolResultScreen({
    super.key,
    required this.spotId,
    required this.companyId,
    required this.spotUuid
  });

  @override
  State<PatrolResultScreen> createState() => _PatrolResultScreenState();
}

class _PatrolResultScreenState extends State<PatrolResultScreen> {
  String spotName = '';
  String spotUuid = '';
  List<String> comments = [];
  String selectedComment = '';
  bool isManual = false;
  String manualText = '';
  List<Uint8List> images = [];
  List<String> videos = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final spotData = await PatrolService.getSpot(widget.spotId);
    final commentList = await PatrolService.getPatrolComments(widget.companyId);

    setState(() {
      spotName = spotData?['name'] ?? '';
      spotUuid = spotData?['uuid'] ?? '';
      comments = commentList;
      selectedComment = commentList.first;
    });
  }

  Future<void> openCamera() async {
    if (images.length >= 8) {
      showToast('최대 8개까지 첨부 가능합니다.');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CameraScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      if (result['type'] == 'image' && result['data'] is Uint8List) {
        setState(() => images.add(result['data']));
      } else if (result['type'] == 'video' && result['path'] is String) {
        setState(() => videos.add(result['path']));
      }
    }
  }

  Future<Uint8List?> generateVideoThumbnail(String path) async {
    return await VideoThumbnail.thumbnailData(
      video: path,
      imageFormat: ImageFormat.PNG,
      maxWidth: 100,
      quality: 75,
    );
  }

  Future<void> pickImage(ImageSource source) async {
    if (images.length >= 8) return;
    final file = await _picker.pickImage(source: source);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => images.add(bytes));
    }
  }

  void onSubmit() async {
    final patrolId = GlobalProvider.patrolId.value;

    if (patrolId == null) {
      showToast('순찰 ID가 없습니다.');
      return;
    }
    if (isManual && manualText.isEmpty) {
      showToast('순찰 결과를 입력해주세요.');
      return;
    }
    if (selectedComment != '이상없음' && images.isEmpty) {
      showToast('순찰 결과 사진을 촬영해주세요.');
      return;
    }

    final memo = isManual ? manualText : selectedComment;
    final patrolResult = selectedComment == '이상없음' ? 'OK' : 'Issue Found';

    try {
      final response = await PatrolService.postPatrolResult(
        patrolId: patrolId,
        spotId: widget.spotId,
        spotUuid: spotUuid,
        memo: memo,
        patrolResult: patrolResult,
        images: images,
        videos: videos,
      );
      if (response.statusCode == 200) {
        final res = await response.stream.bytesToString();
        final body = jsonDecode(res);

        if (body['checkCompleted'] == true) {
          await PatrolService.resetPatrolProgress();
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                '스마트 순찰 시스템',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
              content: const Text(
                '순찰이 등록되었습니다.\n모든 지점 순찰이 완료되었습니다. 수고하셨습니다.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Alert 닫기
                    Navigator.pushReplacementNamed(context, '/controller'); // 이동
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                '스마트 순찰 시스템',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              content: const Text(
                '순찰이 등록되었습니다.\n다음 순찰 지점으로 이동하여 "순찰지점 스캔하기(QR)"를 눌러주세요.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Alert 닫기
                    Navigator.pushReplacementNamed(context, '/controller'); // 이동
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        showToast('등록에 실패했습니다.');
      }
    } catch (e) {
      showToast('오류 발생: $e');
    }
  }

  void showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      backgroundColor: const Color(0xFFF2F2F2),
      body: Column(
        children: [
          const CustomHeader(isControllerScreen: false, title: '순찰결과 등록'),
          const SizedBox(height: 2),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  sectionBox(
                    title: '순찰지점 정보',
                    borderColor: const Color(0xFFEB5757),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spotName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '점검 결과를 입력해주세요.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  sectionBox(
                    title: '순찰 결과 입력',
                    borderColor: const Color(0xFF2D9CDB),
                    child: Column(
                      children: [
                        ...comments
                            .map(
                              (c) => RadioListTile(
                                title: Text(c,style: const TextStyle(fontWeight: FontWeight.bold)),
                                value: c,
                                groupValue: selectedComment,
                                activeColor: const Color(0xFF2D9CDB),
                                onChanged: (val) {
                                  setState(() {
                                    selectedComment = val!;
                                    isManual = val == '직접 입력';
                                  });
                                },
                              ),
                            )
                            .toList(),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFB3B3B3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: TextField(
                            maxLines: 4,
                            enabled: selectedComment == '직접 입력',
                            onChanged: (v) => manualText = v,
                            decoration: const InputDecoration.collapsed(
                              hintText: '직접 입력',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  sectionBox(
                    title: '사진 / 동영상 등록',
                    borderColor: const Color(0xFFF2994A),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (images.length >= 8)
                          const Text('사진/동영상 첨부는 8개까지 가능합니다.'),
                        Row(
                          children: [
                            GestureDetector(
                              onTap:
                                  images.length >= 8
                                      ? null
                                      : () => openCamera(),
                              child: Container(
                                width: 100,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      images.length >= 8
                                          ? Colors.grey.shade200
                                          : Colors.transparent,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '카메라 촬영',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        images.length >= 8
                                            ? Colors.grey
                                            : const Color(0xFFB3B3B3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap:
                                  images.length >= 8
                                      ? null
                                      : () => pickImage(ImageSource.gallery),
                              child: Container(
                                width: 100,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      images.length >= 8
                                          ? Colors.grey.shade200
                                          : Colors.transparent,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '갤러리 선택',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        images.length >= 8
                                            ? Colors.grey
                                            : const Color(0xFFB3B3B3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (images.isNotEmpty)
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              itemBuilder:
                                  (context, i) => Stack(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(
                                          right: 10,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.memory(
                                            images[i],
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              images.removeAt(i);
                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        if (videos.isNotEmpty)
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: videos.length,
                              itemBuilder: (context, i) {
                                return FutureBuilder<Uint8List?>(
                                  future: generateVideoThumbnail(videos[i]),
                                  builder: (context, snapshot) {
                                    final thumb = snapshot.data;
                                    return Stack(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => VideoPlayerScreen(videoPath: videos[i]),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(right: 10),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: thumb != null
                                                  ? Image.memory(
                                                thumb,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              )
                                                  : Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.black12,
                                                child: const Icon(
                                                  Icons.videocam,
                                                  color: Colors.black54,
                                                  size: 40,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                videos.removeAt(i);
                                              });
                                            },
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          )
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  CommonButton(
                    text: '순찰결과 등록',
                    onPressed: onSubmit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionBox({
    required String title,
    required Widget child,
    required Color borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: borderColor,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
