import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/firebase_options.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'core.dart';
import 'data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initWindowManager();

  await dotenv.load(fileName: ".env");
  await LocalStorage.init();

  if (!kIsWeb && !_isDesktop()) {
    MobileAds.instance.initialize();
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  setupLogger();

  runApp(const ProviderScope(
    child: PixelVerseApp(),
  ));
}

Future<void> initWindowManager() async {
  if (kIsWeb || !_isDesktop()) {
    return;
  }

  const size = Size(1280, 720);
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: size,
    center: true,
    fullScreen: true,
    backgroundColor: Color.fromARGB(255, 255, 255, 255),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'Pixel Verse',
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

bool _isDesktop() {
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}
