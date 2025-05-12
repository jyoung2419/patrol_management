import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/patrol_service.dart';
import '../../../widgets/common_button.dart';
import '../../../services/page_control.dart';
import '../../../widgets/alert_modal.dart';
import '../../../widgets/header.dart';
import '../../providers/global_provider.dart';
import 'package:flutter/services.dart';

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  _ControllerScreenState createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  Future<void> _handleQRScan(BuildContext context) async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      PageControl.next(context, 'qr');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('카메라 권한이 없습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF33CCC3),
        statusBarIconBrightness: Brightness.light,
      ),
    );
    return Scaffold(
      backgroundColor: const Color(0xFF33CCC3),
      body: SafeArea(
        bottom: false,
        child: Container(
          color: const Color(0xFFFFFFFF),
          child: Column(
            children: [
              const CustomHeader(isControllerScreen: true),
              Container(
                height: screenHeight * 0.4,
                color: const Color(0xFF33CCC3),
                child: const Center(
                  child: Text(
                    '스마트 순찰시스템',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF213547),
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: GlobalProvider.patrolInProgress,
                builder: (context, isProgress, _) {
                  return !isProgress
                      ? const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Text(
                          '순찰을 시작하시려면 "순찰 시작하기"를 눌러주세요.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF213547),
                          ),
                        ),
                      )
                      : const SizedBox.shrink();
                },
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: screenHeight * 0.4,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 20,
                    ),
                    color: Colors.white,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: GlobalProvider.patrolInProgress,
                      builder: (context, isProgress, _) {
                        return Column(
                          children:
                              isProgress
                                  ? [
                                    CommonButton(
                                      text: '순찰지점 스캔하기(QR)',
                                      onPressed: () => _handleQRScan(context),
                                    ),
                                    const SizedBox(height: 10),
                                    const CommonButton(
                                      text: '지점코드 직접입력하기',
                                      disabled: true,
                                    ),
                                    const SizedBox(height: 10),
                                    CommonButton(
                                      text: '순찰 중단하기',
                                      onPressed: () {
                                        PatrolService.askAbortPatrol(context);
                                      },
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: const [
                                        Text('NFC 활성화'),
                                        Switch(value: false, onChanged: null),
                                      ],
                                    ),
                                  ]
                                  : [
                                    CommonButton(
                                      text: '순찰 시작하기',
                                      onPressed:
                                          () => PageControl.next(
                                            context,
                                            'list_group',
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    CommonButton(
                                      text: '순찰 기록조회',
                                      onPressed:
                                          () => PageControl.next(
                                            context,
                                            'patrol_history',
                                          ),
                                    ),
                                  ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  width: double.infinity,
                  child: const Center(
                    child: Text(
                      'Copyright (c) 2024 NextcoreTechnology\nAll right reserved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF33CCC3), fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const AlertModal(),
            ],
          ),
        ),
      ),
    );
  }
}
