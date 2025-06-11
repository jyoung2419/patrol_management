import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/patrol_service.dart';

class NfcScanService {
  static bool isNfcSupported = false;
  static bool _isScanning = false;
  static final ValueNotifier<bool> nfcToggle = ValueNotifier(false);
  static late BuildContext _cachedContext;

  static Future<void> initialize() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      isNfcSupported = availability == NFCAvailability.available;
    } catch (e) {
      isNfcSupported = false;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('patrol.nfc.enabled') ?? false;
    nfcToggle.value = saved;
  }

  static Future<void> toggleNfc(bool enabled, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('patrol.nfc.enabled', enabled);
    nfcToggle.value = enabled;

    if (!isNfcSupported) return;

    _cachedContext = context;

    if (enabled) {
      _isScanning = false;
      await Future.delayed(Duration(milliseconds: 200));
      startScan();
    } else {
      await stopScan();
    }
  }

  static Future<void> startScan() async {
    if (_isScanning) {
      debugPrint("⛔ 이미 스캔중");
      return;
    }
    _isScanning = true;

    while (true) {
      if (!_isScanning) break;

      try {
        final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 3));
        await processTag(tag);
        await FlutterNfcKit.finish();
        await Future.delayed(Duration(milliseconds: 300));
      } catch (e) {
        debugPrint("❌ NFC 오류: $e");
        await Future.delayed(Duration(milliseconds: 300));
      }
    }
  }

  static Future<void> stopScan() async {
    _isScanning = false;
    try {
      await FlutterNfcKit.finish();
    } catch (e) {
      debugPrint("❌ finish 무시: $e");
    }
  }

  static Future<void> processTag(NFCTag tag) async {
    try {
      final ndefRecords = await FlutterNfcKit.readNDEFRecords();
      if (ndefRecords.isEmpty) {
        _showError(_cachedContext, 'NDEF 데이터 없음');
        return;
      }
      final payload = ndefRecords.first.payload;
      if (payload == null) {
        _showError(_cachedContext, 'NDEF Payload 없음');
        return;
      }

      final text = String.fromCharCodes(payload);
      final uuid = text.substring(3);
      debugPrint('🧩 uuid: $uuid');

      final regex = RegExp(r'^[0-9a-f]{8}[0-9a-f]{4}[0-9a-f]{4}[0-9a-f]{4}[0-9a-f]{12}$');
      if (!regex.hasMatch(uuid)) {
        _showError(_cachedContext, 'UUID 형식 불일치');
        return;
      }

      final spotId = await PatrolService.getSpotIdFromUuid(uuid);
      if (spotId == null) {
        _showError(_cachedContext, 'Spot ID 조회 실패');
        return;
      }

      final spotData = await PatrolService.getSpot(spotId);
      if (spotData == null) {
        _showError(_cachedContext, 'Spot 정보 조회 실패');
        return;
      }

      _isScanning = false;

      await Navigator.pushNamed(_cachedContext, '/patrolResult', arguments: {
        'spotId': spotId,
        'companyId': 1,
        'spotUuid': spotData['uuid'],
      });

      await Future.delayed(Duration(milliseconds: 300));
      await startScan();
    } catch (e) {
      debugPrint('❌ 태그 처리 오류: $e');
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
