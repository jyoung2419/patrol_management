import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../../widgets/header.dart';

class PatrolMediaViewerScreen extends StatelessWidget {
  final List<String> images;
  final List<String> videos;

  const PatrolMediaViewerScreen({
    super.key,
    required this.images,
    required this.videos,
  });

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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  const Text(
                    '📷 이미지 갤러리',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (images.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    ...images.map((img) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Image.memory(base64Decode(img)),
                    )),
                  ] else
                    const Text('이미지가 없습니다.'),
                  const SizedBox(height: 20),
                  const Text(
                    '🎥 비디오 갤러리',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (videos.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    ...videos.map((video) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: VideoPlayerWidget(base64Video: video),
                      ),
                    )),
                  ] else
                    const Text('영상이 없습니다.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String base64Video;

  const VideoPlayerWidget({super.key, required this.base64Video});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final bytes = base64Decode(widget.base64Video);
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4').create();
    await file.writeAsBytes(bytes);

    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    controller.setLooping(false); // 자동 반복도 꺼둡니다

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        isPlaying = false;
      } else {
        _controller!.play();
        isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        IconButton(
          iconSize: 64,
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            color: Colors.white70,
          ),
          onPressed: _togglePlayPause,
        ),
      ],
    );
  }
}
