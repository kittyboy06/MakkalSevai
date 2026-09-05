import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationState {
  final double lat;
  final double lng;
  final double accuracy;
  final String shortAddress;
  final String fullAddress;
  final String locality;
  final String city;
  final String postalCode;
  final DateTime timestamp;
  final bool isLiveGps;

  LocationState({
    required this.lat,
    required this.lng,
    required this.accuracy,
    required this.shortAddress,
    required this.fullAddress,
    required this.locality,
    required this.city,
    required this.postalCode,
    required this.timestamp,
    this.isLiveGps = true,
  });

  String get accuracyLabel => '±${accuracy.toStringAsFixed(1)}m';

  String get coordinatesDisplay => '${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E';
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final ValueNotifier<LocationState?> liveLocation = ValueNotifier<LocationState?>(null);
  final ValueNotifier<bool> isLocating = ValueNotifier<bool>(false);
  final ValueNotifier<String?> locationError = ValueNotifier<String?>(null);

  LocationState? _cachedState;

  /// Acquires live physical GPS position from the device and reverse-geocodes to an address.
  /// Debounces Nominatim calls unless distance moved > 100 meters or forceRefresh is true.
  Future<LocationState?> acquireLiveLocation({bool forceRefresh = false}) async {
    isLocating.value = true;
    locationError.value = null;

    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationError.value = 'Device location services are disabled. Please enable GPS.';
        isLocating.value = false;
        return _cachedState;
      }

      // 2. Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          locationError.value = 'Location permission was denied by the user.';
          isLocating.value = false;
          return _cachedState;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        locationError.value = 'Location permissions are permanently denied. Please enable in Settings.';
        isLocating.value = false;
        return _cachedState;
      }

      // 3. Acquire current device position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // 4. Check cache & calculate distance delta (in meters)
      if (!forceRefresh && _cachedState != null) {
        final distanceMoved = _calculateDistanceMeters(
          _cachedState!.lat,
          _cachedState!.lng,
          position.latitude,
          position.longitude,
        );

        if (distanceMoved < 100.0) {
          final updated = LocationState(
            lat: position.latitude,
            lng: position.longitude,
            accuracy: position.accuracy,
            shortAddress: _cachedState!.shortAddress,
            fullAddress: _cachedState!.fullAddress,
            locality: _cachedState!.locality,
            city: _cachedState!.city,
            postalCode: _cachedState!.postalCode,
            timestamp: DateTime.now(),
            isLiveGps: true,
          );
          _cachedState = updated;
          liveLocation.value = updated;
          isLocating.value = false;
          return updated;
        }
      }

      // 5. Reverse Geocode via OpenStreetMap Nominatim with proper headers
      final geocoded = await _reverseGeocodeNominatim(position.latitude, position.longitude);

      final newState = LocationState(
        lat: position.latitude,
        lng: position.longitude,
        accuracy: position.accuracy,
        shortAddress: geocoded['shortAddress'] ?? '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        fullAddress: geocoded['fullAddress'] ?? 'Current GPS Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})',
        locality: geocoded['locality'] ?? 'Nearby',
        city: geocoded['city'] ?? 'Tamil Nadu',
        postalCode: geocoded['postalCode'] ?? '',
        timestamp: DateTime.now(),
        isLiveGps: true,
      );

      _cachedState = newState;
      liveLocation.value = newState;
      isLocating.value = false;
      return newState;
    } catch (e) {
      debugPrint('[LocationService] Error acquiring live GPS: $e');
      locationError.value = 'Failed to obtain live GPS location: $e';
      isLocating.value = false;
      return _cachedState;
    }
  }

  /// Reverse geocoding via OpenStreetMap Nominatim
  Future<Map<String, String>> _reverseGeocodeNominatim(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'MakkalSevai-Citizen-App/1.0 (sih2026.makkalsevai@gov.in)',
          'Accept-Language': 'en,ta',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>? ?? {};

        final road = address['road'] ?? address['pedestrian'] ?? address['street'] ?? '';
        final neighbourhood = address['neighbourhood'] ?? address['suburb'] ?? address['residential'] ?? '';
        final city = address['city'] ?? address['town'] ?? address['municipality'] ?? address['county'] ?? 'Chennai';
        final state = address['state'] ?? 'Tamil Nadu';
        final postcode = address['postcode'] ?? '';

        String locality = neighbourhood.isNotEmpty ? neighbourhood : (road.isNotEmpty ? road : city);
        String shortAddr = locality.isNotEmpty ? '$locality, $city' : city;

        List<String> fullParts = [];
        if (road.isNotEmpty) fullParts.add(road.toString());
        if (neighbourhood.isNotEmpty && neighbourhood != road) fullParts.add(neighbourhood.toString());
        if (city.isNotEmpty) fullParts.add(city.toString());
        if (state.isNotEmpty) fullParts.add(state.toString());
        if (postcode.isNotEmpty) fullParts.add(postcode.toString());

        String fullAddr = fullParts.join(', ');
        if (fullAddr.isEmpty) {
          fullAddr = data['display_name'] as String? ?? 'Lat: $lat, Lng: $lng';
        }

        return {
          'shortAddress': shortAddr,
          'fullAddress': fullAddr,
          'locality': locality,
          'city': city.toString(),
          'postalCode': postcode.toString(),
        };
      }
    } catch (e) {
      debugPrint('[LocationService] Reverse geocode error: $e');
    }

    // Graceful fallback showing actual physical coordinates rather than placeholder text
    return {
      'shortAddress': '${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E',
      'fullAddress': 'Current GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
      'locality': 'Current Location',
      'city': 'Detected Area',
      'postalCode': '',
    };
  }

  /// Calculates Haversine distance in meters between two lat/lng points
  double _calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }
}
