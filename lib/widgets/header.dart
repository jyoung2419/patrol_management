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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isControllerScreen)
            Row(
              children: const [
                SizedBox(width: 10),
                Text(
                  '스마트 순찰시스템',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF213547),
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_left, color: Color(0xFF33CCC3), size: 30),
              onPressed: () {
                if (onBack != null) {
                  onBack!();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          if (!isControllerScreen && title != null)
            Expanded(
              child: Center(
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Color(0xFF33CCC3),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          if (isControllerScreen)
            IconButton(
              icon: const Icon(Icons.power_settings_new, color: Colors.white),
              onPressed: () => _showLogoutDialog(context),
            )
          else
            const SizedBox(width: 48),
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
