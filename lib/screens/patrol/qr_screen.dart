import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../../services/patrol_service.dart';

class QRScreen extends StatefulWidget {
  const QRScreen({super.key});

  @override
  _QRScreenState createState() => _QRScreenState();
}

class _QRScreenState extends State<QRScreen> with WidgetsBindingObserver, RouteAware {
  final MobileScannerController controller = MobileScannerController();
  bool flashOn = false;
  bool isScanned = false;

  void _onDetect(BarcodeCapture capture) async {
    if (isScanned) return; // 중복 방지

    if (capture.barcodes.isEmpty || capture.barcodes.first.rawValue == null) return;
    final String code = capture.barcodes.first.rawValue!;
    if (code == null) return;

    setState(() => isScanned = true);

    final regex = RegExp(r'^Spot Seq: (\d+)$');
    final match = regex.firstMatch(code);

    if (match != null) {
      final spotId = int.parse(match.group(1)!);
      final spotData = await PatrolService.getSpot(spotId);
      if (spotData == null || spotData['uuid'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('스팟 정보를 불러올 수 없습니다.')),
        );
        return;
      }
      await controller.stop();
      await Future.delayed(Duration(milliseconds: 300));
      Navigator.pushNamed(context, '/patrolResult',
        arguments: {
          'spotId': spotId,
          'companyId': 1,
          'spotUuid': spotData['uuid'],
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 QR코드를 스캔해주세요.')),
      );
      setState(() => isScanned = false); // 다시 스캔 가능하도록
    }
  }

  void _toggleFlash() {
    setState(() {
      flashOn = !flashOn;
      controller.toggleTorch();
    });
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    controller.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  void didPopNext() {
    controller.start();
    setState(() => isScanned = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: MediaQuery.of(context).size.width * 0.15,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '순찰 지역 QR코드를 스캔해주세요.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // 하단 플래시 버튼 영역
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Text("플래시"),
                      Switch(
                        value: flashOn,
                        onChanged: (_) => _toggleFlash(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
