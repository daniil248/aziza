import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/design/theme.dart';
import 'core/i18n/generated/app_localizations.dart';
import 'core/providers.dart';
import 'core/router/client_router.dart';
import 'features/client/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const AzizaClientApp(),
    ),
  );
}

class AzizaClientApp extends ConsumerWidget {
  const AzizaClientApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final router = buildClientRouter(
      seenOnboarding: ref.read(onboardingSeenProvider),
    );
    return MaterialApp.router(
      title: 'Aziza Food',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
    );
  }
}
