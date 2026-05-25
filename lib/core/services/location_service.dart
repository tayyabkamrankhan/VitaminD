import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Request permission and return current position
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  /// Stream position updates (for live tracking during session)
  Stream<Position> get positionStream => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 50, // update every 50 metres
    ),
  );

  /// Match lat/lon to nearest South Asian city
  String detectCity(double lat, double lon) {
    const cities = {
      'Karachi':    (24.8607, 67.0011),
      'Lahore':     (31.5204, 74.3587),
      'Islamabad':  (33.6844, 73.0479),
      'Rawalpindi': (33.6007, 73.0679),
      'Peshawar':   (34.0151, 71.5249),
      'Multan':     (30.1575, 71.5249),
      'Quetta':     (30.1798, 66.9750),
      'Faisalabad': (31.4504, 73.1350),
    };

    String nearest = 'Rawalpindi';
    double minDist = double.infinity;

    cities.forEach((name, coords) {
      final dist = Geolocator.distanceBetween(lat, lon, coords.$1, coords.$2);
      if (dist < minDist) { minDist = dist; nearest = name; }
    });
    return nearest;
  }
}
