import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plant_disease_detector/core/config/env.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/routing/app_router.dart';
import 'package:plant_disease_detector/core/providers/locale_provider.dart';
import 'package:plant_disease_detector/l10n/app_localizations.dart';
import 'package:plant_disease_detector/core/providers/tflite_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialise Supabase. Will be a no-op until real credentials are supplied.
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  } catch (_) {
    // Silently ignore in dev — placeholder credentials will fail gracefully.
  }

  final container = ProviderContainer();
  // Initialize TFLite service
  await container.read(tfliteProvider).initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CropGuardApp(),
    ),
  );
}

class CropGuardApp extends ConsumerWidget {
  const CropGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'CropGuard LK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,

      // ── Localisation ────────────────────────────────────────────────────
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('si'),
        Locale('ta'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      builder: (context, child) {
        return Container(
          color: AppColors.webOuterBg,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: ClipRect(child: child!),
            ),
          ),
        );
      },
    );
  }
}
