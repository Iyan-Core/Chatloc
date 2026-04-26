import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  final auth = ref.watch(authServiceProvider);
  return LocationService(auth);
});

final currentPositionProvider = FutureProvider<Position?>((ref) {
  final service = ref.watch(locationServiceProvider);
  return service.getCurrentPosition();
});

class LocationService {
  final AuthService _auth;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  LocationService(this._auth);

  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final parts = <String>[];
      if (place.street?.isNotEmpty == true) parts.add(place.street!);
      if (place.subLocality?.isNotEmpty == true) parts.add(place.subLocality!);
      if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
      if (place.country?.isNotEmpty == true) parts.add(place.country!);

      return parts.join(', ');
    } catch (_) {
      return '$latitude, $longitude';
    }
  }

  Stream<Position> getLiveLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters
      ),
    );
  }

  Future<void> updateUserLocation(double lat, double lng) async {
    final uid = _auth.currentUserId;
    if (uid == null) return;

    await _db.collection('users').doc(uid).update({
      'lastLocation': GeoPoint(lat, lng),
    });
  }

  Future<void> toggleLocationSharing(bool enabled) async {
    final uid = _auth.currentUserId;
    if (uid == null) return;

    await _db.collection('users').doc(uid).update({
      'locationSharingEnabled': enabled,
    });
  }

  double distanceBetween(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}
