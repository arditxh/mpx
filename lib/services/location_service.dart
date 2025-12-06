import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationFailureReason {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  timeout,
  unavailable,
}

class LocationResult {
  const LocationResult.success(this.position) : error = null;

  const LocationResult.failure(this.error) : position = null;

  final Position? position;
  final LocationFailureReason? error;

  bool get hasLocation => position != null;
}

class LocationService {
  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  Future<LocationResult> getCurrentPosition() async {
    final permissionFailure = await _ensurePermission();
    if (permissionFailure != null) {
      return LocationResult.failure(permissionFailure);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );
      return LocationResult.success(position);
    } on TimeoutException {
      return const LocationResult.failure(LocationFailureReason.timeout);
    } on LocationServiceDisabledException {
      return const LocationResult.failure(LocationFailureReason.serviceDisabled);
    } catch (_) {
      return const LocationResult.failure(LocationFailureReason.unavailable);
    }
  }

  Future<LocationFailureReason?> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return LocationFailureReason.permissionDenied;
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationFailureReason.permissionPermanentlyDenied;
    }
    return null;
  }
}
