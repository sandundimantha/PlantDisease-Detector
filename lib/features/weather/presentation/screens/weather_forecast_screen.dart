import 'package:flutter/material.dart';
import 'package:plant_disease_detector/features/weather/data/weather_model.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/core/providers/location_provider.dart';
import 'package:plant_disease_detector/features/weather/presentation/providers/weather_provider.dart';

class WeatherForecastScreen extends ConsumerWidget {
  const WeatherForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    final weatherState = ref.watch(weatherProvider);
    final bool isDay = weatherState.weather?.isDay ?? true;
    final List<Color> bgColors = isDay 
        ? const [Color(0xFF1976D2), Color(0xFF4FC3F7)] // Vibrant Day Sky
        : const [Color(0xFF0B0F19), Color(0xFF1A1A2E)]; // Premium Deep Midnight
    final IconData mainIcon = isDay ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded;
    final Color mainIconColor = isDay ? Colors.amber : Colors.indigo.shade300;
    final int currentTemp = weatherState.weather?.temperature.round() ?? 24;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient (Dynamic based on weather)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: bgColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Background blobs for glassmorphism effect
          Positioned(
            top: 50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationState.isLoading ? context.tr(en: 'LOCATING...', si: 'ස්ථානය සොයමින්...', ta: 'இருப்பிடம் அறியப்படுகிறது...') : locationState.address.toUpperCase(),
                          style: AppTextStyles.titleMedium.copyWith(color: Colors.white, letterSpacing: 1.2),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // keeps the title centred
                      const SizedBox(width: 4),
                      const LanguageSelectorButton(isDark: true, isCompact: true),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Current Weather Main
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: mainIconColor.withOpacity(0.35),
                                    blurRadius: 60,
                                    spreadRadius: 15,
                                  ),
                                ],
                              ),
                              child: Icon(mainIcon, color: mainIconColor, size: 100),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              weatherState.isLoading ? '--°C' : '${currentTemp}°C',
                              style: AppTextStyles.headlineLarge.copyWith(
                                color: Colors.white, 
                                fontSize: 90, 
                                fontWeight: FontWeight.w200,
                                shadows: [const Shadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          weatherState.isLoading ? context.tr(en: 'LOADING...', si: 'පූරණය වෙමින්...', ta: 'ஏற்றுகிறது...') : '${context.tr(en: 'CURRENTLY', si: 'දැනට', ta: 'தற்போது')}, ${weatherState.weather?.condition.toUpperCase() ?? (isDay ? "SUNNY" : "CLEAR")}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleMedium.copyWith(color: Colors.white, letterSpacing: 3, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          weatherState.weather == null
                              ? ''
                              : '${context.tr(en: 'Feels like', si: 'දැනෙන උෂ්ණත්වය', ta: 'உணர்வது')} ${weatherState.weather!.feelsLike.round()}°C'
                                  '${weatherState.weather!.daily.isEmpty ? '' : '  |  H: ${weatherState.weather!.daily.first.maxTemp.round()}°  |  L: ${weatherState.weather!.daily.first.minTemp.round()}°'}'
                                  '  |  ${context.tr(en: 'Humidity', si: 'ආර්ද්‍රතාවය', ta: 'ஈரப்பதம்')} ${weatherState.weather!.humidity}%',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w500, fontSize: 16),
                        ),
                        const SizedBox(height: 40),

                        // Bottom Sheet with Glassmorphism
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.05)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border(
                                  top: BorderSide(color: Colors.white.withOpacity(0.4), width: 1.5),
                                  left: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
                                  right: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(context.tr(en: 'HOURLY FORECAST', si: 'පැයක කාලගුණ අනාවැකිය', ta: 'மணிநேர முன்னறிவிப்பு'), style: AppTextStyles.titleSmall.copyWith(color: const Color(0xFFF5C842), letterSpacing: 1.5)),
                                const SizedBox(height: 16),
                                
                                // Hourly List
                                SizedBox(
                                  height: 140,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    children: _buildHourly(context, weatherState.weather),
                                  ),
                                ),
                                
                                const SizedBox(height: 32),
                                Text(context.tr(en: '7-DAY FORECAST', si: 'දින 7ක අනාවැකිය', ta: '7 நாள் முன்னறிவிப்பு'), style: AppTextStyles.titleSmall.copyWith(color: const Color(0xFFF5C842), letterSpacing: 1.5)),
                                const SizedBox(height: 16),
                                
                                // 7-Day List
                                ..._buildDaily(context, weatherState.weather),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static (IconData, Color) _iconFor(int code, bool isDay) {
    if (code >= 95) return (Icons.thunderstorm_rounded, Colors.blueGrey.shade200);
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return (Icons.water_drop_rounded, Colors.lightBlue.shade200);
    if (code == 45 || code == 48) return (Icons.foggy, Colors.grey.shade300);
    if (code >= 1 && code <= 3) return (Icons.cloud_queue_rounded, Colors.grey.shade300);
    return isDay ? (Icons.wb_sunny_rounded, Colors.amber) : (Icons.nights_stay_rounded, Colors.indigo.shade300);
  }

  /// Next six hours from Open-Meteo.
  List<Widget> _buildHourly(BuildContext context, WeatherModel? w) {
    final hours = w?.hourly.take(6).toList() ?? const <HourlyForecast>[];
    if (hours.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(context.tr(en: 'Forecast not available', si: 'අනාවැකිය ලබා ගත නොහැක', ta: 'முன்னறிவிப்பு கிடைக்கவில்லை'), style: const TextStyle(color: Colors.white70)),
        ),
      ];
    }
    return [
      for (var i = 0; i < hours.length; i++)
        () {
          final h = hours[i];
          final hour = h.time.hour;
          final isHourDay = hour > 5 && hour < 18;
          final timeStr = i == 0
              ? context.tr(en: 'Now', si: 'දැන්', ta: 'இப்போது')
              : '${hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)} ${hour >= 12 ? 'PM' : 'AM'}';
          final (icon, color) = _iconFor(h.weatherCode, isHourDay);
          return _buildHourlyCard(timeStr, icon, '${h.temperature.round()}°', color, i == 0);
        }(),
    ];
  }

  /// Seven-day forecast from Open-Meteo, with chance of rain.
  List<Widget> _buildDaily(BuildContext context, WeatherModel? w) {
    final days = w?.daily ?? const <DailyForecast>[];
    const names = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return [
      for (var i = 0; i < days.length; i++)
        () {
          final d = days[i];
          final name = i == 0 ? context.tr(en: 'TODAY', si: 'අද', ta: 'இன்று') : names[d.date.weekday - 1];
          final (icon, color) = _iconFor(d.weatherCode, true);
          final label = d.rainChance > 0 ? '$name  💧${d.rainChance}%' : name;
          return _buildDailyRow(label, icon, '${d.maxTemp.round()}°', '${d.minTemp.round()}°', color);
        }(),
    ];
  }

  Widget _buildHourlyCard(String time, IconData icon, String temp, Color iconColor, bool isSelected) {
    return Container(
      width: 75,
      margin: const EdgeInsets.only(right: 14, bottom: 8, top: 4),
      decoration: BoxDecoration(
        gradient: isSelected 
          ? const LinearGradient(colors: [Color(0xFFF5C842), Color(0xFFE2A066)], begin: Alignment.topLeft, end: Alignment.bottomRight) 
          : LinearGradient(colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFFF5C842).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: AppTextStyles.bodyMedium.copyWith(color: isSelected ? Colors.black87 : Colors.white70, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600)),
          const SizedBox(height: 12),
          Icon(icon, color: isSelected ? Colors.black87 : iconColor, size: 32),
          const SizedBox(height: 12),
          Text(temp, style: AppTextStyles.titleSmall.copyWith(color: isSelected ? Colors.black87 : Colors.white, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildDailyRow(String day, IconData icon, String high, String low, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: Text(day, style: AppTextStyles.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.1))),
          Expanded(flex: 1, child: Icon(icon, color: iconColor, size: 30)),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('$high ', style: AppTextStyles.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                Text('/ $low', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white54, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
