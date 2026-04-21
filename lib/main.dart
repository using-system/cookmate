import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/observability/data/crashlytics_preference_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;

    final prefs = await SharedPreferences.getInstance();
    final crashlyticsEnabled = CrashlyticsPreferenceStorage(prefs).read();
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(crashlyticsEnabled);

    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }

  await FlutterGemma.initialize();

  if (firebaseReady) {
    runZonedGuarded(
      () => runApp(const ProviderScope(child: CookmateApp())),
      (error, stack) =>
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
    );
  } else {
    runApp(const ProviderScope(child: CookmateApp()));
  }
}
