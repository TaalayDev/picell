import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app/bootstrap_app.dart';
import 'core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initWindowManager();
  setupLogger();
  runApp(const BootstrapApp());
}

Future<void> initWindowManager() async {
  if (kIsWeb || !_isDesktop() || kDebugMode) {
    return;
  }

  const size = Size(1280, 720);
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: size,
    center: true,
    fullScreen: true,
    backgroundColor: Color(0xFF0D0F21),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'Picell',
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

bool _isDesktop() {
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}
