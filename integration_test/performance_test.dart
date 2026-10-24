import 'package:aura_audio/app.dart';
import 'package:aura_audio/application/music_store.dart';
import 'package:aura_audio/platform/native_audio.dart';
import 'package:aura_audio/presentation/screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'profile localized glass and reduced transparency on the EQ screen',
    (tester) async {
      final store = MusicStore(NativeAudio());
      runApp(AuraApp(store: store));
      await store.initialize();
      store.welcomed = true;
      store.glass = true;
      store.appearance = 'Dark';
      store.changed();
      await store.command('pause');
      await tester.pumpAndSettle();
      await tester.tap(find.text('EQ').last);
      await tester.pumpAndSettle();
      final list = find.descendant(
        of: find.byType(EqualizerPage),
        matching: find.byType(ListView),
      );
      for (final reduced in [false, true]) {
        store.reducedTransparency = reduced;
        store.changed();
        await tester.pumpAndSettle();
        await binding.watchPerformance(() async {
          for (var i = 0; i < 3; i++) {
            await tester.fling(list, const Offset(0, -550), 1800);
            await tester.pumpAndSettle();
            await tester.fling(list, const Offset(0, 550), 1800);
            await tester.pumpAndSettle();
          }
        }, reportKey: reduced ? 'reduced_transparency' : 'liquid_glass');
      }
      store.reducedTransparency = false;
      store.changed();
      await store.save();
    },
  );
}
