import 'dart:developer';

import 'package:geolocator/geolocator.dart';

class LocationHelper {
  static Position? _cachedPosition;
  static DateTime? _cacheTime;
  static const _cacheValidDuration = Duration(minutes: 5);
  static Future<Position?> getCurrentPosition({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedPosition != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < _cacheValidDuration) {
        log("📍 Using cached location");
        return _cachedPosition;
      }
    }
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    // Always get a fresh GPS fix for precise location
    _cachedPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );
    _cacheTime = DateTime.now();
    return _cachedPosition;
  }
}