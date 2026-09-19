import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Request location permissions and get current position.
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      Position? position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Location timeout'),
      ).catchError((_) => null);

      position ??= await Geolocator.getLastKnownPosition();
      return position;
    } catch (e) {
      return null;
    }
  }

  /// Convert coordinates to a readable address.
  Future<String> getAddressFromCoordinates(double lat, double lon) async {
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(lat, lon)
          .timeout(const Duration(seconds: 8));
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final city = place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            '';
        final country = place.country ?? '';
        if (city.isNotEmpty) {
          return country.isNotEmpty ? '$city, $country' : city;
        }
      }
    } catch (_) {}

    // Fallback: OSM Nominatim API
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'PlantDiseaseDetectorApp/1.0',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        if (address != null) {
          final city = address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'] ??
              address['state_district'] ??
              '';
          final country = address['country'] ?? '';
          if (city.isNotEmpty) {
            return country.isNotEmpty ? '$city, $country' : city;
          }
        }
      }
    } catch (_) {}

    // Last resort: show coordinates
    return '${lat.toStringAsFixed(3)}, ${lon.toStringAsFixed(3)}';
  }
}
