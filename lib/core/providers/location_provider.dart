import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationState {
  final Position? position;
  final String address;
  final bool isLoading;
  final String? error;

  LocationState({
    this.position,
    this.address = 'Fetching location...',
    this.isLoading = false,
    this.error,
  });

  LocationState copyWith({
    Position? position,
    String? address,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      position: position ?? this.position,
      address: address ?? this.address,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier(this._locationService) : super(LocationState()) {
    fetchLocation();
  }

  Future<void> fetchLocation() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final address = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        state = state.copyWith(
          position: position,
          address: address,
          isLoading: false,
        );
      } else {
        // Location unavailable — use friendly fallback
        state = state.copyWith(
          isLoading: false,
          address: 'Sri Lanka',
          error: 'Location unavailable',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        address: 'Sri Lanka',
        error: e.toString(),
      );
    }
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final service = ref.watch(locationServiceProvider);
  return LocationNotifier(service);
});
