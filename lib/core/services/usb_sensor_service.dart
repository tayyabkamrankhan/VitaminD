import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';

// Platform-specific imports handled via conditional factories below.
// Android  → usb_serial package
// Desktop  → Process serial reading on Windows

// ── Shared data class ─────────────────────────────────────────────────────────

class UVReading {
  final double uvIndex;
  final int skinR, skinG, skinB;
  final double temperatureC;
  final int fitzpatrickTone;
  final DateTime timestamp;
  final double synthesizedIU;
  final int elapsedSeconds;
  final int arduinoState;

  const UVReading({
    required this.uvIndex,
    required this.skinR,
    required this.skinG,
    required this.skinB,
    required this.temperatureC,
    required this.fitzpatrickTone,
    required this.timestamp,
    this.synthesizedIU = 0.0,
    this.elapsedSeconds = 0,
    this.arduinoState = 0,
  });
}

// ── Abstract interface ────────────────────────────────────────────────────────

abstract class SensorService {
  Stream<UVReading> get readingStream;
  Stream<bool>      get connectionStream;
  bool              get isConnected;

  Future<List<String>> getAvailablePorts();   // port names or device names
  Future<bool>         connect(String port);
  Future<void>         disconnect();
  void                 dispose();

  static SensorService? _instance;

  /// Factory — picks the right implementation for current platform as a Singleton
  factory SensorService.create() {
    if (_instance == null) {
      if (kIsWeb) {
        _instance = WebSensorService();
      } else if (Platform.isAndroid) {
        _instance = AndroidSensorService();
      } else if (Platform.isWindows) {
        _instance = DesktopSensorService();
      } else {
        _instance = WebSensorService(); // Fallback stub
      }
    }
    return _instance!;
  }

  // ── Shared packet parser ──────────────────────────────────────────────────
  static UVReading parsePacket(List<int> bytes) {
    final uvRaw   = (bytes[0] << 8) | bytes[1];
    final uvIndex = (uvRaw / 100.0).clamp(0.0, 16.0);
    final r       = bytes[2];
    final g       = bytes[3];
    final b       = bytes[4];
    final tempRaw = (bytes[5] << 8) | bytes[6];
    final tempC   = tempRaw / 100.0;
    final fitz    = _detectSkinTone(r, g, b);
    return UVReading(
      uvIndex: uvIndex, skinR: r, skinG: g, skinB: b,
      temperatureC: tempC, fitzpatrickTone: fitz, timestamp: DateTime.now(),
      synthesizedIU: 0.0, elapsedSeconds: 0, arduinoState: 0,
    );
  }

  static int _detectSkinTone(int r, int g, int b) {
    final brightness = r * 0.299 + g * 0.587 + b * 0.114;
    if (brightness > 220) return 1;
    if (brightness > 190) return 2;
    if (brightness > 155) return 3;
    if (brightness > 115) return 4;
    if (brightness > 75)  return 5;
    return 6;
  }
}

// ── Android implementation (usb_serial) ──────────────────────────────────────

class AndroidSensorService implements SensorService {
  UsbPort? _port;
  StreamSubscription? _sub;
  final _readings    = StreamController<UVReading>.broadcast();
  final _connections = StreamController<bool>.broadcast();
  bool _connected = false;

  @override Stream<UVReading> get readingStream    => _readings.stream;
  @override Stream<bool>      get connectionStream => _connections.stream;
  @override bool              get isConnected      => _connected;

  @override
  Future<List<String>> getAvailablePorts() async {
    try {
      final devices = await UsbSerial.listDevices();
      return devices.map((d) => '${d.productName ?? "Arduino"} (${d.deviceId})').toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> connect(String portIdentifier) async {
    try {
      final devices = await UsbSerial.listDevices();
      if (devices.isEmpty) return false;

      UsbDevice? targetDevice;
      for (final d in devices) {
        final id = '${d.productName ?? "Arduino"} (${d.deviceId})';
        if (id == portIdentifier || d.deviceId.toString() == portIdentifier) {
          targetDevice = d;
          break;
        }
      }
      targetDevice ??= devices.first;

      _port = await targetDevice.create();
      if (_port == null) return false;

      final openSuccess = await _port!.open();
      if (!openSuccess) return false;

      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(9600, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

      _listenToPort();
      _connected = true;
      _connections.add(true);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _listenToPort() {
    final lineBuffer = StringBuffer();
    _sub = _port!.inputStream!.listen((Uint8List data) {
      final text = String.fromCharCodes(data);
      for (var char in text.split('')) {
        if (char == '\n' || char == '\r') {
          final line = lineBuffer.toString().trim();
          if (line.isNotEmpty) _parseTextLine(line);
          lineBuffer.clear();
        } else {
          lineBuffer.write(char);
        }
      }
    }, onError: (_) => disconnect());
  }

  void _parseTextLine(String line) {
    try {
      final parts = <String, String>{};
      for (final segment in line.split(line.contains(',') ? ',' : ' ')) {
        final kv = segment.split(':');
        if (kv.length == 2) parts[kv[0].trim()] = kv[1].trim();
      }
      final uvIndex = double.tryParse(parts['UV'] ?? '') ?? 0.0;
      final skinTone = int.tryParse(parts['SKIN'] ?? '') ?? 2;
      final fitz = (skinTone + 1).clamp(1, 6);
      
      final vdValue = double.tryParse(parts['VD'] ?? '') ?? 0.0;
      final timeVal = int.tryParse(parts['TIME'] ?? '') ?? 0;
      final stateVal = int.tryParse(parts['STATE'] ?? '') ?? 0;

      // Mock temperature calculation (25C base + UV * 1.5C)
      final tempC = 25.0 + (uvIndex * 1.5);

      _readings.add(UVReading(
        uvIndex: uvIndex,
        skinR: 0, skinG: 0, skinB: 0,
        temperatureC: tempC,
        fitzpatrickTone: fitz,
        timestamp: DateTime.now(),
        synthesizedIU: vdValue,
        elapsedSeconds: timeVal,
        arduinoState: stateVal,
      ));
    } catch (_) {}
  }

  @override
  Future<void> disconnect() async {
    await _sub?.cancel();
    try { await _port?.close(); } catch (_) {}
    _port = null;
    _connected = false;
    _connections.add(false);
  }

  @override
  void dispose() {
    disconnect();
    _readings.close();
    _connections.close();
  }
}

// ── Desktop implementation (Process serial reading on Windows) ───────────────

class DesktopSensorService implements SensorService {
  final _readings    = StreamController<UVReading>.broadcast();
  final _connections = StreamController<bool>.broadcast();
  Process? _psProcess;
  bool _connected = false;

  @override Stream<UVReading> get readingStream    => _readings.stream;
  @override Stream<bool>      get connectionStream => _connections.stream;
  @override bool              get isConnected      => _connected;

  @override
  Future<List<String>> getAvailablePorts() async {
    if (!Platform.isWindows) return [];
    try {
      final res = await Process.run('powershell', [
        '-Command',
        '[System.IO.Ports.SerialPort]::getportnames()'
      ]);
      if (res.exitCode == 0) {
        return res.stdout
            .toString()
            .split('\r\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<bool> connect(String portName) async {
    if (_connected) await disconnect();
    try {
      // Start a background PowerShell process that reads from the serial port
      _psProcess = await Process.start('powershell', [
        '-Command',
        '\$port = New-Object System.IO.Ports.SerialPort $portName, 9600, None, 8, one; \$port.Open(); while (\$port.IsOpen) { \$line = \$port.ReadLine(); Write-Output \$line; }'
      ]);

      _connected = true;
      _connections.add(true);

      final lineBuffer = StringBuffer();
      _psProcess!.stdout.transform(const Utf8Decoder()).listen((data) {
        for (var i = 0; i < data.length; i++) {
          final char = data[i];
          if (char == '\n' || char == '\r') {
            final line = lineBuffer.toString().trim();
            if (line.isNotEmpty) _parseTextLine(line);
            lineBuffer.clear();
          } else {
            lineBuffer.write(char);
          }
        }
      }, onError: (_) => disconnect(), onDone: () => disconnect());

      return true;
    } catch (_) {
      _connected = false;
      _connections.add(false);
      return false;
    }
  }

  void _parseTextLine(String line) {
    try {
      final parts = <String, String>{};
      for (final segment in line.split(line.contains(',') ? ',' : ' ')) {
        final kv = segment.split(':');
        if (kv.length == 2) parts[kv[0].trim()] = kv[1].trim();
      }
      final uvIndex = double.tryParse(parts['UV'] ?? '') ?? 0.0;
      final skinTone = int.tryParse(parts['SKIN'] ?? '') ?? 2;
      final fitz = (skinTone + 1).clamp(1, 6);
      
      final vdValue = double.tryParse(parts['VD'] ?? '') ?? 0.0;
      final timeVal = int.tryParse(parts['TIME'] ?? '') ?? 0;
      final stateVal = int.tryParse(parts['STATE'] ?? '') ?? 0;

      // Mock temperature calculation (25C base + UV * 1.5C)
      final tempC = 25.0 + (uvIndex * 1.5);

      _readings.add(UVReading(
        uvIndex: uvIndex,
        skinR: 0, skinG: 0, skinB: 0,
        temperatureC: tempC,
        fitzpatrickTone: fitz,
        timestamp: DateTime.now(),
        synthesizedIU: vdValue,
        elapsedSeconds: timeVal,
        arduinoState: stateVal,
      ));
    } catch (_) {}
  }

  @override
  Future<void> disconnect() async {
    _psProcess?.kill();
    _psProcess = null;
    _connected = false;
    _connections.add(false);
  }

  @override
  void dispose() {
    disconnect();
    _readings.close();
    _connections.close();
  }
}

// ── Web implementation (Dummy) ────────────────────────────────────────────────

class WebSensorService implements SensorService {
  final _readings    = StreamController<UVReading>.broadcast();
  final _connections = StreamController<bool>.broadcast();

  @override Stream<UVReading> get readingStream    => _readings.stream;
  @override Stream<bool>      get connectionStream => _connections.stream;
  @override bool              get isConnected      => false;

  @override Future<List<String>> getAvailablePorts() async => [];
  @override Future<bool> connect(String port) async => false;
  @override Future<void> disconnect() async {}
  @override void dispose() {
    _readings.close();
    _connections.close();
  }
}

