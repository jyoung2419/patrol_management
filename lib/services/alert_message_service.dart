import 'dart:async';

class AlertMessageService {
  final _controller = StreamController<String?>.broadcast();

  Stream<String?> get stream => _controller.stream;

  void show(String message) {
    _controller.add(message);
    Future.delayed(const Duration(seconds: 3), () => clear());
  }

  void clear() {
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}

final alertMessageService = AlertMessageService();
