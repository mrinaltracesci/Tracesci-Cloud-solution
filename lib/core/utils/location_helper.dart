import 'package:geolocator/geolocator.dart';

class LocationHelper {
  static Future<Map<String, dynamic>?> current({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: timeout,
        ),
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      };
    } catch (_) {
      return null;
    }
  }

  static String? readableCoordinates(Map<String, dynamic>? location) {
    if (location == null) return null;

    final lat = location['latitude'] ?? location['lat'];
    final lng = location['longitude'] ?? location['lng'];

    if (lat == null || lng == null) return null;

    final latValue = double.tryParse('$lat');
    final lngValue = double.tryParse('$lng');

    if (latValue == null || lngValue == null) return null;

    return '${latValue.toStringAsFixed(5)}, ${lngValue.toStringAsFixed(5)}';
  }
}
