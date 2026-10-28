import 'dart:async';

import 'package:picell/app/theme/pv_tokens.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  PvTokens.useDesignFonts = false;
  await testMain();
}
