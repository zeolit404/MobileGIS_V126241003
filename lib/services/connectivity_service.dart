import 'dart:async';
import 'package:http/http.dart' as http;

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  bool _isOnline = true;
  Timer? _pollingTimer;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  bool get isOnline => _isOnline;
  Stream<bool> get statusStream => _controller.stream;

  void start() {
    _checkStatus();
    _pollingTimer?.cancel();
    // Memeriksa status konektivitas internet secara periodik (setiap 3 detik)
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkStatus();
    });
  }

  void stop() {
    _pollingTimer?.cancel();
  }

  Future<void> _checkStatus() async {
    try {
      // Endpoint standar Google captive portal (0 byte, 204 No Content, sangat cepat)
      final res = await http.get(
        Uri.parse('https://clients3.google.com/generate_204'),
      ).timeout(const Duration(milliseconds: 2000));

      final active = res.statusCode == 204 || res.statusCode == 200;
      if (active != _isOnline) {
        _isOnline = active;
        _controller.add(_isOnline);
      }
    } catch (_) {
      if (_isOnline) {
        _isOnline = false;
        _controller.add(false);
      }
    }
  }
}
