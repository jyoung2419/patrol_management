import 'package:flutter/material.dart';
import '../services/alert_message_service.dart';

class AlertModal extends StatelessWidget {
  const AlertModal({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: alertMessageService.stream,
      builder: (context, snapshot) {
        final message = snapshot.data;
        if (message == null) return const SizedBox.shrink();

        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Text(
                message,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
