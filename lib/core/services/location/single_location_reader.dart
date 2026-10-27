// lib/core/services/location/single_location_reader.dart
import 'package:geolocator/geolocator.dart';

/// Standalone one-off location fetch. Use this any time, independent of
/// whether background tracking is running — e.g. "Capture Outlet Location".
class SingleLocationReader {
  static Future<Position> getCurrentLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
