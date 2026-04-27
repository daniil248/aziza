import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/design/theme.dart';
import 'core/i18n/generated/app_localizations.dart';
import 'core/providers.dart';
import 'features/courier/courier_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const AzizaCourierApp(),
    ),
  );
}

class AzizaCourierApp extends ConsumerWidget {
  const AzizaCourierApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'Aziza Courier',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const CourierHomeScreen(),
      locale: locale,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
    );
  }
}
