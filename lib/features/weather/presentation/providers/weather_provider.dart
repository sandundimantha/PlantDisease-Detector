import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/location_provider.dart';
import '../../data/weather_api_service.dart';
import '../../data/weather_model.dart';

final weatherApiServiceProvider = Provider<WeatherApiService>((ref) {
  return WeatherApiService();
});

class WeatherState {
  final WeatherModel? weather;
  final bool isLoading;
  final String? error;

  WeatherState({
    this.weather,
    this.isLoading = false,
    this.error,
  });

  WeatherState copyWith({
    WeatherModel? weather,
    bool? isLoading,
    String? error,
  }) {
    return WeatherState(
      weather: weather ?? this.weather,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class WeatherNotifier extends StateNotifier<WeatherState> {
  final WeatherApiService _weatherService;
  final Ref _ref;

  WeatherNotifier(this._weatherService, this._ref) : super(WeatherState(isLoading: true)) {
    // Listen to location changes. When location is fetched, get weather.
    _ref.listen<LocationState>(locationProvider, (previous, next) {
      if (next.position != null && !next.isLoading && previous?.position != next.position) {
        fetchWeather(next.position!.latitude, next.position!.longitude);
      } else if (next.error != null) {
        // If location fails, still provide fallback weather so UI doesn't break
        fetchWeather(6.9271, 79.8612); // Default to Colombo coordinates
      }
    });
    
    // Initial fetch if location is already available
    final locState = _ref.read(locationProvider);
    if (locState.position != null) {
       fetchWeather(locState.position!.latitude, locState.position!.longitude);
    } else if (locState.error != null) {
       fetchWeather(6.9271, 79.8612); // Location off or unavailable: Colombo
    }
  }

  Future<void> fetchWeather(double lat, double lon) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final weather = await _weatherService.fetchCurrentWeather(lat, lon);
      state = state.copyWith(isLoading: false, weather: weather);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  final service = ref.watch(weatherApiServiceProvider);
  return WeatherNotifier(service, ref);
});
