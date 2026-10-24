import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'application/music_store.dart';
import 'platform/native_audio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSizeBytes = 40 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 120;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Inter',
    ], await rootBundle.loadString('assets/fonts/OFL-Inter.txt'));
    yield LicenseEntryWithLineBreaks([
      'Plus Jakarta Sans',
    ], await rootBundle.loadString('assets/fonts/OFL-Jakarta.txt'));
    yield LicenseEntryWithLineBreaks([
      'JetBrains Mono',
    ], await rootBundle.loadString('assets/fonts/OFL-Mono.txt'));
  });
  final store = MusicStore(NativeAudio());
  runApp(AuraApp(store: store));
  await store.initialize();
}
