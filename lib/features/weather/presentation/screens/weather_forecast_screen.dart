import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/providers/location_provider.dart';
import 'package:plant_disease_detector/features/weather/presentation/providers/weather_provider.dart';
import 'dart:ui';

class WeatherForecastScreen extends ConsumerWidget {
  const WeatherForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    final weatherState = ref.watch(weatherProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient (Dynamic based on weather)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.skyBlue, AppColors.skyLight], // Sunny/Clear sky colors
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
                      Text(
                        locationState.isLoading ? context.tr(en: 'LOCATING...', si: 'ස්ථානය සොයමින්...', ta: 'இருப்பிடம் அறியப்படுகிறது...') : locationState.address.toUpperCase(),
                        style: AppTextStyles.titleMedium.copyWith(color: Colors.white, letterSpacing: 1.2),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.search_rounded, color: Colors.white),
                        onPressed: () {},
                      ),
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
                            const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 90),
                            const SizedBox(width: 16),
                            Text(
                              weatherState.isLoading ? '--°C' : '${weatherState.weather?.temperature.round() ?? 24}°C',
                              style: AppTextStyles.headlineLarge.copyWith(color: Colors.white, fontSize: 80, fontWeight: FontWeight.w300),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          weatherState.isLoading ? context.tr(en: 'LOADING...', si: 'පූරණය වෙමින්...', ta: 'ஏற்றுகிறது...') : '${context.tr(en: 'CURRENTLY', si: 'දැනට', ta: 'தற்போது')}, ${weatherState.weather?.condition.toUpperCase() ?? "SUNNY"}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleMedium.copyWith(color: Colors.white, letterSpacing: 2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${context.tr(en: 'Feels like', si: 'දැනෙන උෂ්ණත්වය', ta: 'உணர்வது')} 26°C  |  H: 28°  |  L: 19°',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                        ),
                        const SizedBox(height: 40),

                        // Bottom Sheet with Glassmorphism
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 30,
                                offset: const Offset(0, -10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.tr(en: 'HOURLY FORECAST', si: 'පැයක කාලගුණ අනාවැකිය', ta: 'மணிநேர முன்னறிவிப்பு'), style: AppTextStyles.titleSmall.copyWith(color: AppColors.textSecondary, letterSpacing: 1.5)),
                                const SizedBox(height: 16),
                                
                                // Hourly List
                                SizedBox(
                                  height: 110,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      _buildHourlyCard('12 PM', Icons.wb_sunny_rounded, '24°', Colors.amber, true),
                                      _buildHourlyCard('1 PM', Icons.cloud_queue_rounded, '25°', Colors.grey, false),
                                      _buildHourlyCard('2 PM', Icons.cloud_rounded, '25°', Colors.grey, false),
                                      _buildHourlyCard('3 PM', Icons.wb_sunny_rounded, '26°', Colors.amber, false),
                                      _buildHourlyCard('4 PM', Icons.wb_sunny_rounded, '26°', Colors.amber, false),
                                      _buildHourlyCard('5 PM', Icons.wb_sunny_rounded, '25°', Colors.amber, false),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 32),
                                Text(context.tr(en: '7-DAY FORECAST', si: 'දින 7ක අනාවැකිය', ta: '7 நாள் முன்னறிவிப்பு'), style: AppTextStyles.titleSmall.copyWith(color: AppColors.textSecondary, letterSpacing: 1.5)),
                                const SizedBox(height: 16),
                                
                                // 7-Day List
                                _buildDailyRow('MON', Icons.wb_sunny_rounded, '28°', '19°', Colors.amber),
                                _buildDailyRow('TUE', Icons.cloud_queue_rounded, '28°', '19°', Colors.grey),
                                _buildDailyRow('WED', Icons.water_drop_rounded, '27°', '20°', Colors.blue),
                                _buildDailyRow('THU', Icons.water_drop_rounded, '27°', '21°', Colors.blue),
                                _buildDailyRow('FRI', Icons.wb_sunny_rounded, '29°', '19°', Colors.amber),
                                _buildDailyRow('SAT', Icons.wb_cloudy_rounded, '28°', '18°', Colors.grey),
                                _buildDailyRow('SUN', Icons.wb_sunny_rounded, '30°', '19°', Colors.amber),
                              ],
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

  Widget _buildHourlyCard(String time, IconData icon, String temp, Color iconColor, bool isSelected) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: AppTextStyles.bodyMedium.copyWith(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Icon(icon, color: isSelected ? Colors.white : iconColor, size: 28),
          const SizedBox(height: 8),
          Text(temp, style: AppTextStyles.titleSmall.copyWith(color: isSelected ? Colors.white : AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildDailyRow(String day, IconData icon, String high, String low, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: Text(day, style: AppTextStyles.titleSmall)),
          Expanded(flex: 1, child: Icon(icon, color: iconColor, size: 28)),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('H: $high ', style: AppTextStyles.titleSmall),
                Text('/ L: $low', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
