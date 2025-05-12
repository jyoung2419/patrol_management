import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:typed_data';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isRecording = false;
  bool _isVideoMode = false;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라 권한이 없습니다.')),
      );
      Navigator.pop(context);
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    _controller = CameraController(_cameras[0], ResolutionPreset.medium, enableAudio: true,);
    await _controller!.initialize();
    setState(() {});
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final file = await _controller!.takePicture();
    final bytes = await File(file.path).readAsBytes();
    Navigator.pop(context, {
      'type': 'image',
      'data': bytes, // Uint8List
    });
  }

  Future<void> _toggleRecording() async {
    if (_controller == null) return;
    if (_isRecording) {
      final file = await _controller!.stopVideoRecording();
      setState(() => _isRecording = false);
      Navigator.pop(context, {
        'type': 'video',
        'path': file.path,
      });
    } else {
      await _controller!.startVideoRecording();
      setState(() => _isRecording = true);

      Future.delayed(const Duration(minutes: 1), () async {
        if (_isRecording) {
          final file = await _controller!.stopVideoRecording();
          if (mounted) {
            setState(() => _isRecording = false);
            Navigator.pop(context, {
              'type': 'video',
              'path': file.path,
            });
          }
        }
      });
    }
  }

  void _toggleFlash() async {
    if (_controller == null) return;
    _flashOn = !_flashOn;
    await _controller!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_isVideoMode ? Colors.green : Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => setState(() => _isVideoMode = false),
                      child: const Text('사진', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isVideoMode ? Colors.green : Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        if (!_isVideoMode) {
                          final micStatus = await Permission.microphone.request();
                          if (!micStatus.isGranted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('마이크 권한이 필요합니다.')),
                            );
                            return;
                          }
                        }
                        setState(() => _isVideoMode = true);
                      },
                      child: const Text('동영상', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('플래시', style: TextStyle(fontSize: 12)),
                      Switch(value: _flashOn, onChanged: (v) => _toggleFlash()),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (_isVideoMode) {
                    _toggleRecording();
                  } else {
                    _takePhoto();
                  }
                },
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isVideoMode ? Colors.red : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
