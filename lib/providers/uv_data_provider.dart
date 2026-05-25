import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/repositories/health_repository.dart';
import '../core/utils/vitamin_d_calculator.dart';
import '../core/services/usb_sensor_service.dart';

class UVDataProvider extends ChangeNotifier {
  final HealthRepository _repo;
  StreamSubscription<UVReading>? _sensorSub;

  double _synthesizedIU  = 0;
  double _supplementIU   = 0;
  double _dietaryIU      = 0;
  double _currentUVIndex = 0;
  double _sessionMinutes = 0;
  bool   _sessionActive  = false;
  DateTime? _sessionStart;
  double _bodyExposure = 1.0;
  int    _spf = 0;
  List<UVSession>     _weeklySessions   = [];
  List<SupplementLog> _todaySupplements = [];
  UserProfile?        _profile;

  UVDataProvider(this._repo) {
    _sensorSub = SensorService.create().readingStream.listen((reading) {
      _currentUVIndex = reading.uvIndex;
      if (_sessionActive && _sessionStart != null) {
        // Sync synthesized IU
        if (reading.synthesizedIU > 0.0) {
          _synthesizedIU = reading.synthesizedIU;
        } else {
          final elapsed = DateTime.now().difference(_sessionStart!).inSeconds / 60.0;
          _synthesizedIU = VitaminDCalculator.calculateSynthesis(
            uvIndex: reading.uvIndex, durationMin: elapsed,
            skinTone: _profile?.skinTone ?? 5,
            bodyExposure: _bodyExposure, spf: _spf,
          );
        }

        // Sync session minutes
        if (reading.elapsedSeconds > 0) {
          _sessionMinutes = reading.elapsedSeconds / 60.0;
        } else {
          _sessionMinutes = DateTime.now().difference(_sessionStart!).inSeconds / 60.0;
        }
      }
      notifyListeners();
    });
  }

  double get synthesizedIU  => _synthesizedIU;
  double get supplementIU   => _supplementIU;
  double get dietaryIU      => _dietaryIU;
  double get totalIU        => _synthesizedIU + _supplementIU + _dietaryIU;
  double get currentUVIndex => _currentUVIndex;
  double get sessionMinutes => _sessionMinutes;
  bool   get sessionActive  => _sessionActive;
  double get bodyExposure   => _bodyExposure;
  int    get spf            => _spf;
  List<UVSession>     get weeklySessions   => _weeklySessions;
  List<SupplementLog> get todaySupplements => _todaySupplements;

  VitaminDStatus get status =>
      VitaminDCalculator.getStatus(totalIU, _profile?.age ?? 25);
  double get progressRatio =>
      VitaminDCalculator.progressRatio(totalIU, _profile?.age ?? 25);

  void setProfile(UserProfile? p) { _profile = p; notifyListeners(); }
  void setBodyExposure(double v)  { _bodyExposure = v; notifyListeners(); }
  void setSpf(int v)              { _spf = v; notifyListeners(); }

  void updateFromSensor(double uvIndex) {
    _currentUVIndex = uvIndex;
    if (_sessionActive && _sessionStart != null) {
      final elapsed = DateTime.now().difference(_sessionStart!).inSeconds / 60.0;
      _sessionMinutes = elapsed;
      _synthesizedIU  = VitaminDCalculator.calculateSynthesis(
        uvIndex: uvIndex, durationMin: elapsed,
        skinTone: _profile?.skinTone ?? 5,
        bodyExposure: _bodyExposure, spf: _spf,
      );
    }
    notifyListeners();
  }

  void startSession() {
    _sessionActive = true; _sessionStart = DateTime.now(); notifyListeners();
  }

  Future<void> stopSession(String userId) async {
    if (!_sessionActive) return;
    _sessionActive = false;
    final session = _repo.makeUVSession(
      userId: userId, uvIndex: _currentUVIndex,
      durationMinutes: _sessionMinutes, synthesizedIU: _synthesizedIU,
      bodyExposure: _bodyExposure, skinToneUsed: _profile?.skinTone ?? 5, spf: _spf,
    );
    await _repo.saveUVSession(session);
    _sessionMinutes = 0; _sessionStart = null;
    await loadTodayData(userId);
  }

  Future<void> addSupplement(String userId, String name, double dosageIU, String type) async {
    final log = _repo.makeSupplementLog(userId: userId, type: type, name: name, dosageIU: dosageIU);
    await _repo.logSupplement(log);
    await loadTodayData(userId);
  }

  Future<void> removeSupplement(String userId, String supplementId) async {
    await _repo.deleteSupplement(userId, supplementId);
    await loadTodayData(userId);
  }

  Future<void> loadTodayData(String userId) async {
    _synthesizedIU    = await _repo.getTodaySynthesized(userId);
    _todaySupplements = await _repo.getTodaySupplements(userId);
    _supplementIU = _todaySupplements.where((l) => l.type == 'supplement').fold(0, (s, l) => s + l.dosageIU);
    _dietaryIU    = _todaySupplements.where((l) => l.type == 'food').fold(0, (s, l) => s + l.dosageIU);
    _weeklySessions = await _repo.getUVSessions(userId, days: 30);
    notifyListeners();
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    super.dispose();
  }
}
