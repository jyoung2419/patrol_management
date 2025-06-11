import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/patrol_service.dart';
import '../../../widgets/common_button.dart';
import '../../../services/page_control.dart';
import '../../../widgets/alert_modal.dart';
import '../../../widgets/header.dart';
import '../../providers/global_provider.dart';
import 'package:flutter/services.dart';

import '../../services/nfc_scan_service.dart';
import '../../utils/user_util.dart';

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  _ControllerScreenState createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  String? _userName;
  bool nfcEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (NfcScanService.nfcToggle.value) {
        NfcScanService.toggleNfc(false, context);
        NfcScanService.toggleNfc(true, context);
      }
    });
  }

  void _loadUserName() async {
    final name = await getUserName();
    setState(() {
      _userName = name;
    });
  }

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

  void _toggleNfc(bool value) {
    NfcScanService.toggleNfc(value, context);
  }

  @override
  void dispose() {
    NfcScanService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: const Color(0xFFFFFFFF),
                child: Column(
                  children: [
                    const CustomHeader(isControllerScreen: true),
                    Flexible(
                      flex: 2,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF33CCC3),
                              Color(0xFF7EE0DA),
                              Color(0xFFCCF0EC),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            const Spacer(),
                            Center(
                              child: Text(
                                _userName != null ? '$_userName 님' : '스마트 순찰시스템',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF213547),
                                ),
                              ),
                            ),
                            const Spacer(),
                            ValueListenableBuilder<bool>(
                              valueListenable: GlobalProvider.patrolInProgress,
                              builder: (context, isProgress, _) {
                                return !isProgress
                                    ? const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    '순찰을 시작하시려면 "순찰 시작하기"를 눌러주세요.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF213547),
                                    ),
                                  ),
                                )
                                    : const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Patrol buttons
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: GlobalProvider.patrolInProgress,
                          builder: (context, isProgress, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: isProgress
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
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text('NFC 활성화'),
                                    ValueListenableBuilder<bool>(
                                      valueListenable: NfcScanService.nfcToggle,
                                      builder: (context, enabled, _) {
                                        return Switch(
                                          value: enabled,
                                          onChanged: _toggleNfc,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ]
                                  : [
                                CommonButton(
                                  text: '순찰 시작하기',
                                  onPressed: () =>
                                      PageControl.next(context, 'list_group'),
                                ),
                                const SizedBox(height: 10),
                                CommonButton(
                                  text: '순찰 기록조회',
                                  onPressed: () => PageControl.next(
                                      context, 'patrol_history'),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Fixed bottom area
            const AlertModal(),
            Container(
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
          ],
        ),
      ),
    );
  }
}
