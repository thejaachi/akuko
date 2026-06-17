import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:akuko/app.dart';
import 'package:akuko/core/config/env.dart';
import 'package:akuko/core/config/shared_preferences_provider.dart';
import 'package:akuko/core/network/api_client_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _loadDotEnv();

  if (!Env.isConfigured) {
    runApp(const _ConfigErrorApp());
    return;
  }

  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  await container.read(authSessionManagerProvider).bootstrap(
        container.read(authApiProvider),
      );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AkukoApp(),
    ),
  );
}

Future<void> _loadDotEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env bundled — rely on --dart-define.
  }
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.settings_suggest_outlined, size: 56),
                SizedBox(height: 16),
                Text(
                  'Akuko is not configured',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Set AKUKO_API_BASE_URL via a .env file or --dart-define, '
                  'then restart. See README.md.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
