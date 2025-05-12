import 'package:flutter/material.dart';
import '../utils/secure_storage_util.dart';

class CustomHeader extends StatelessWidget {
  final bool isControllerScreen;
  final String? title;
  final VoidCallback? onBack;

  const CustomHeader({
    super.key,
    this.isControllerScreen = false,
    this.title,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      // color: isControllerScreen ? Colors.yellow : Colors.red,
      color: isControllerScreen ? const Color(0xFF33CCC3) : Colors.transparent,

      // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: isControllerScreen
                ? const Icon(Icons.power_settings_new, color: Colors.white)
                : const Icon(Icons.keyboard_arrow_left, color: Color(0xFF33CCC3), size: 30),
            onPressed: () {
              if (isControllerScreen) {
                _showLogoutDialog(context);
              } else {
                if (onBack != null) {
                  onBack!();
                } else {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          if (!isControllerScreen && title != null)
            Expanded(
              child: Center(
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF33CCC3),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 50),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("로그아웃"),
        content: const Text("로그아웃 하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await SecureStorageUtil.deleteToken();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text("로그아웃"),
          ),
        ],
      ),
    );
  }
}
