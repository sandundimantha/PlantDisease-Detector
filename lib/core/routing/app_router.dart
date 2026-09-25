import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:plant_disease_detector/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:plant_disease_detector/features/auth/presentation/screens/login_screen.dart';
import 'package:plant_disease_detector/features/auth/presentation/screens/signup_screen.dart';
import 'package:plant_disease_detector/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:plant_disease_detector/features/home/presentation/screens/main_screen.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/camera_capture_screen.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/scanning_screen.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/diagnostic_result_screen.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/treatment_detail_screen.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/treatment_reminder_screen.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/disease_catalogue_screen.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/disease_comparison_screen.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/nearest_officer_screen.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/photo_guide_screen.dart';
import 'package:plant_disease_detector/features/treatment/data/disease_model.dart';

import 'package:plant_disease_detector/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:plant_disease_detector/features/weather/presentation/screens/weather_forecast_screen.dart';
import 'package:plant_disease_detector/features/farm_log/presentation/screens/add_farm_log_screen.dart';
import 'package:plant_disease_detector/features/profile/presentation/screens/language_selection_screen.dart';
import 'package:plant_disease_detector/features/profile/presentation/screens/notifications_screen.dart';
import 'package:plant_disease_detector/features/community/presentation/screens/community_feed_screen.dart';
import 'package:plant_disease_detector/features/farm_log/presentation/screens/yield_tracker_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/language',
  routes: [
    GoRoute(
      path: '/language',
      builder: (context, state) => const LanguageSelectionScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) => const OtpVerificationScreen(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainScreen(),
    ),
    GoRoute(
      path: '/camera_capture',
      builder: (context, state) => const CameraCaptureScreen(),
    ),
    GoRoute(
      path: '/photo_guide',
      builder: (context, state) => const PhotoGuideScreen(),
    ),
    GoRoute(
      path: '/scanning',
      builder: (context, state) {
        final imagePath = state.extra as String? ?? '';
        return ScanningScreen(imagePath: imagePath);
      },
    ),
    GoRoute(
      path: '/diagnostic_result',
      builder: (context, state) => const DiagnosticResultScreen(),
    ),
    GoRoute(
      path: '/treatment_detail',
      builder: (context, state) => const TreatmentDetailScreen(),
    ),
    GoRoute(
      path: '/treatment_reminder',
      builder: (context, state) => const TreatmentReminderScreen(),
    ),
    GoRoute(
      path: '/disease_catalogue',
      builder: (context, state) => const DiseaseCatalogueScreen(),
    ),
    GoRoute(
      path: '/nearest_officer',
      builder: (context, state) => const NearestOfficerScreen(),
    ),
    GoRoute(
      path: '/disease_comparison',
      builder: (context, state) {
        final extra = state.extra as List<Disease>?;
        return DiseaseComparisonScreen(
          diseaseA: extra != null && extra.isNotEmpty ? extra[0] : null,
          diseaseB: extra != null && extra.length > 1 ? extra[1] : null,
        );
      },
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/weather',
      builder: (context, state) => const WeatherForecastScreen(),
    ),
    GoRoute(
      path: '/add_farm_log',
      builder: (context, state) => const AddFarmLogScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/community',
      builder: (context, state) => const CommunityFeedScreen(),
    ),
    GoRoute(
      path: '/yield',
      builder: (context, state) => const YieldTrackerScreen(),
    ),
  ],
);
