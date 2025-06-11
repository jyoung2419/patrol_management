import 'package:flutter/material.dart';

class PatrolStatusModal extends StatelessWidget {
  final Function(String) onSelect;

  const PatrolStatusModal({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = ['작업 시작', '작업 중', '작업 완료', '관리자 확인 완료'];

    return Container(
      height: 550,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '작업 상태 선택',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...options.map(
                (opt) => ListTile(
              title: Text(
                opt,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                onSelect(opt);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}