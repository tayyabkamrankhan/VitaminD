import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/services/usb_sensor_service.dart';

class USBProvider extends ChangeNotifier {
  late final SensorService _service;
  List<String> _ports     = [];
  bool         _connected = false;
  UVReading?   _latestReading;
  String?      _error;
  StreamSubscription? _readingSub;
  StreamSubscription? _connSub;

  bool         get connected     => _connected;
  List<String> get ports         => _ports;
  UVReading?   get latestReading => _latestReading;
  String?      get error         => _error;

  USBProvider() {
    _service = SensorService.create();
    _connSub = _service.connectionStream.listen((c) { _connected = c; notifyListeners(); });
  }

  Future<void> scanPorts() async { _ports = await _service.getAvailablePorts(); notifyListeners(); }

  Future<bool> connect(String port) async {
    _error = null;
    final ok = await _service.connect(port);
    if (ok) {
      _readingSub = _service.readingStream.listen((r) { _latestReading = r; notifyListeners(); });
    } else {
      _error = 'Could not open $port. Check USB connection.'; notifyListeners();
    }
    return ok;
  }

  Future<void> disconnect() async { await _readingSub?.cancel(); await _service.disconnect(); }

  @override
  void dispose() { _connSub?.cancel(); _service.dispose(); super.dispose(); }
}
