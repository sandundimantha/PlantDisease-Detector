// Widget smoke tests that run without Supabase (no network or keys needed).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/providers/locale_provider.dart';
import 'package:plant_disease_detector/features/diagnosis/domain/disease_catalog.dart';
import 'package:plant_disease_detector/features/treatment/data/disease_model.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/disease_detail_screen.dart';

/// The real notifier listens to Supabase auth; tests use a fixed language.
class _FixedLocale extends LocaleNotifier {
  @override
  Locale build() => Locale(AppStrings.currentLocaleCode);
}

Widget _app(Widget child) => ProviderScope(
      overrides: [localeProvider.overrideWith(_FixedLocale.new)],
      child: MaterialApp(home: child),
    );

void main() {
  final lateBlight = Disease.fromCatalog(DiseaseCatalog.lookup('Tomato Late Blight')!);

  tearDown(() => AppStrings.currentLocaleCode = 'en');

  testWidgets('disease detail shows overview, symptoms and treatment plan', (tester) async {
    await tester.pumpWidget(_app(DiseaseDetailScreen(disease: lateBlight)));
    await tester.pump();

    expect(find.text('Tomato Late Blight'), findsOneWidget);
    expect(find.textContaining('Phytophthora infestans'), findsWidgets);
    expect(find.text('Symptoms'), findsOneWidget);
    expect(find.text(lateBlight.symptoms.first), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Open Treatment Plan'), 300);
    expect(find.text('Open Treatment Plan'), findsOneWidget);
  });

  testWidgets('disease detail switches to Sinhala text', (tester) async {
    AppStrings.currentLocaleCode = 'si';
    await tester.pumpWidget(_app(DiseaseDetailScreen(disease: lateBlight)));
    await tester.pump();

    expect(find.text(DiseaseCatalog.localizedName('Tomato Late Blight', 'si')), findsOneWidget);
    expect(find.text('රෝග ලක්ෂණ'), findsOneWidget);
  });
}
