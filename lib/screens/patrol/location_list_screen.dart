import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../widgets/header.dart';
import 'package:flutter/services.dart';

class Location {
  final int id;
  final String name;

  Location({required this.id, required this.name});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
    );
  }
}

class LocationListScreen extends StatefulWidget {
  final void Function(int locationId) onLocationSelected;

  const LocationListScreen({super.key, required this.onLocationSelected});

  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  List<Location> _locations = [];

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    final url = Uri.parse('${dotenv.env['BASE_URL']}:${dotenv.env['PORT']}/api/v1/location/companyById/1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<Location> parsed = data.map((e) => Location.fromJson(e)).toList();

        setState(() {
          _locations = parsed.where((e) => e.name.isNotEmpty).toList();
        });
      } catch (e) {
        print("❗️JSON 파싱 실패: ${response.body}");
      }
    } else {
      print("지역 목록 조회 실패: ${response.statusCode}");
    }
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(
              isControllerScreen: false,
              title: '순찰지역 선택',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('순찰 지역 총 ${_locations.length}건', style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Colors.grey),
            Expanded(
              child: _locations.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: _locations.length,
                itemBuilder: (context, index) {
                  final location = _locations[index];
                  return ListTile(
                    title: Text(location.name),
                    onTap: () {
                      print("📍 선택된 지역 ID: ${location.id}"); // 디버그용
                      widget.onLocationSelected(location.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
