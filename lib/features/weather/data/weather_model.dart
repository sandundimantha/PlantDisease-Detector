/// One hour of the Open-Meteo forecast.
class HourlyForecast {
  final DateTime time;
  final double temperature;
  final int weatherCode;
  const HourlyForecast({required this.time, required this.temperature, required this.weatherCode});
}

/// One day of the Open-Meteo forecast.
class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;
  final int rainChance; // %
  const DailyForecast({required this.date, required this.maxTemp, required this.minTemp, required this.weatherCode, required this.rainChance});
}

class WeatherModel {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String condition;
  final String iconCode;
  final bool isDay;
  final List<HourlyForecast> hourly; // next hours, starting with the current one
  final List<DailyForecast> daily; // today and the next days

  WeatherModel({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.iconCode,
    required this.isDay,
    this.hourly = const [],
    this.daily = const [],
  });

  /// Short English description of a WMO weather code.
  static String conditionFor(int code, {bool isDay = true}) {
    if (code == 0) return isDay ? 'Clear Sky' : 'Clear Night';
    if (code >= 1 && code <= 3) return 'Partly Cloudy';
    if (code == 45 || code == 48) return 'Fog';
    if (code >= 51 && code <= 67) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Rain Showers';
    if (code >= 95 && code <= 99) return 'Thunderstorm';
    return isDay ? 'Sunny' : 'Clear Night';
  }

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final current = json['current_weather'];
    final temp = (current['temperature'] as num).toDouble();
    final wind = (current['windspeed'] as num).toDouble();
    final code = current['weathercode'] as int;
    final isDayNum = current['is_day'];
    final isDay = isDayNum == null || isDayNum == 1; // Default to true if missing
    final currentTime = DateTime.tryParse(current['time']?.toString() ?? '');

    // Hourly series: find the current hour, then take the next 12 hours.
    final hourly = <HourlyForecast>[];
    int rh = 60;
    double feels = temp;
    try {
      final h = json['hourly'] as Map<String, dynamic>;
      final times = (h['time'] as List).map((t) => DateTime.parse(t as String)).toList();
      var start = 0;
      if (currentTime != null) {
        start = times.indexWhere((t) => !t.isBefore(DateTime(currentTime.year, currentTime.month, currentTime.day, currentTime.hour)));
        if (start < 0) start = 0;
      }
      rh = ((h['relative_humidity_2m'] as List)[start] as num).round();
      final apparent = h['apparent_temperature'] as List?;
      if (apparent != null) feels = (apparent[start] as num).toDouble();
      final temps = h['temperature_2m'] as List?;
      final codes = h['weathercode'] as List?;
      if (temps != null && codes != null) {
        for (var i = start; i < times.length && hourly.length < 12; i++) {
          hourly.add(HourlyForecast(time: times[i], temperature: (temps[i] as num).toDouble(), weatherCode: (codes[i] as num).toInt()));
        }
      }
    } catch (_) {}

    final daily = <DailyForecast>[];
    try {
      final d = json['daily'] as Map<String, dynamic>;
      final days = d['time'] as List;
      for (var i = 0; i < days.length; i++) {
        daily.add(DailyForecast(
          date: DateTime.parse(days[i] as String),
          maxTemp: ((d['temperature_2m_max'] as List)[i] as num).toDouble(),
          minTemp: ((d['temperature_2m_min'] as List)[i] as num).toDouble(),
          weatherCode: ((d['weathercode'] as List)[i] as num).toInt(),
          rainChance: (((d['precipitation_probability_max'] as List?)?[i] ?? 0) as num).round(),
        ));
      }
    } catch (_) {}

    String iCode = isDay ? '01d' : '01n';
    if (code >= 1 && code <= 3) { iCode = isDay ? '02d' : '02n'; }
    else if (code == 45 || code == 48) { iCode = '50d'; }
    else if (code >= 51 && code <= 67) { iCode = '10d'; }
    else if (code >= 71 && code <= 77) { iCode = '13d'; }
    else if (code >= 80 && code <= 82) { iCode = '09d'; }
    else if (code >= 95 && code <= 99) { iCode = '11d'; }

    return WeatherModel(
      temperature: temp,
      feelsLike: feels,
      humidity: rh,
      windSpeed: wind,
      condition: conditionFor(code, isDay: isDay),
      iconCode: iCode,
      isDay: isDay,
      hourly: hourly,
      daily: daily,
    );
  }
}
