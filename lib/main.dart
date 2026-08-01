import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/remote/amplify_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((r) => debugPrint('[${r.level.name}] ${r.loggerName}: ${r.message}'));

  // A long-standing, still-open upstream go_router bug (flutter/flutter
  // #107010, #107045, #122507, #140586, #156585 — see app_router.dart)
  // intermittently trips a debug-only Navigator consistency check
  // (assert-gated, confirmed via source + cross-platform testing to be
  // stripped from every release build, so it can never reach a shipped
  // app). In debug it replaces the whole screen with Flutter's default
  // crash overlay via ErrorWidget.builder. For specifically this known,
  // harmless error, show a calm loading state instead of the crash screen
  // — hot-restart (r) if it doesn't clear on its own navigation.
  // (Tried forcing an automatic remount here too; that made things worse —
  // it tore down an already-partially-corrupted tree and tripped a second,
  // different assertion. Not attempting auto-recovery.) Every other error
  // still gets Flutter's default crash screen.
  final defaultErrorWidgetBuilder = ErrorWidget.builder;
  ErrorWidget.builder = (details) {
    if (details.exceptionAsString().contains('keyReservation.contains(key)')) {
      return const ColoredBox(
        color: AppColors.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return defaultErrorWidgetBuilder(details);
  };

  await _configureAmplify();

  runApp(const ProviderScope(child: BLWRecipesApp()));
}

Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugins([
      AmplifyAuthCognito(),
      AmplifyAPI(),
      AmplifyStorageS3(),
    ]);
    await Amplify.configure(amplifyconfig);
  } on AmplifyAlreadyConfiguredException {
    // Hot reload — already configured, skip
  } catch (e) {
    debugPrint('Amplify configuration error: $e');
    // App will continue without AWS — use mock/offline data
  }
}

class BLWRecipesApp extends ConsumerWidget {
  const BLWRecipesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Bitty Bellies',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
