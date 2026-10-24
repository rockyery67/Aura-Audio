import 'dart:io';
import 'dart:convert';

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
    'real Android library, playback, native EQ and persistence in airplane mode',
    (tester) async {
      final store = MusicStore(NativeAudio());
      runApp(AuraApp(store: store));
      await store.initialize();
      store.welcomed = true;
      store.appearance = 'Dark';
      store.changed();
      Future<void> until(bool Function() condition) async {
        for (var i = 0; i < 100 && !condition(); i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(condition(), true);
      }

      await until(() => store.ready);
      await store.scan('scanDevice');
      await tester.pumpAndSettle();
      final fixtures =
          store.tracks
              .where(
                (t) => [
                  'Cosmic Drift',
                  'Amber Horizon',
                  'Monolith Reflections',
                ].contains(t.title),
              )
              .toList()
            ..sort((a, b) => a.title.compareTo(b.title));
      expect(fixtures.length, 3);
      expect(
        fixtures.every(
          (t) => t.artwork.isNotEmpty && File(t.artwork).existsSync(),
        ),
        true,
      );
      expect(fixtures.every((t) => t.duration >= 89000 && !t.missing), true);
      await store.playTracks(fixtures);
      await until(() => store.playing && store.duration > 0);
      await store.command('seek', 30000);
      await until(() => store.position.value >= 29500);
      final firstId = store.current!.id;
      if (!store.favorites.contains(store.current!.id)) {
        store.favorite(store.current!);
      }
      final existing = store.playlists
          .where((p) => p.name == 'Airplane Mix')
          .toList();
      store.playlists.removeWhere((p) => existing.contains(p));
      final playlist = store.createPlaylist('Airplane Mix');
      for (final t in fixtures) {
        store.addToPlaylist(playlist, t);
      }
      store.reorderPlaylist(playlist, 0, 2);
      expect(playlist.ids.last, fixtures.first.id);
      store.selectPreset('Bass Boost');
      await store.updateEq();
      expect(store.response.any((v) => v.abs() > 1), true);
      expect(store.headroom, greaterThan(0));
      store.savePreset('Offline Bass');
      await tester.pump(const Duration(milliseconds: 400));
      final processing = await store.command('diagnostics') as Map;
      expect(processing['processedFrames'] as int, greaterThan(0));
      expect((processing['appliedGains'] as List).first, 5.0);
      expect(processing['appliedEnabled'], true);
      expect(await store.command('history'), contains(firstId));
      store.eqEnabled = false;
      await store.updateEq();
      expect(store.response.every((v) => v == 0), true);
      await tester.pump(const Duration(milliseconds: 400));
      final bypassed = await store.command('diagnostics') as Map;
      expect(bypassed['appliedEnabled'], false);
      store.eqEnabled = true;
      store.selectPreset('Offline Bass');
      await store.updateEq();
      await store.command('move', [2, 1]);
      await until(() => store.queueIds[1] == fixtures[2].id);
      await store.command('remove', 2);
      await until(() => store.queueIds.length == 2);
      await store.command('append', fixtures[1].mediaItem);
      await until(() => store.queueIds.length == 3);
      await store.command('shuffle', true);
      await until(() => store.shuffle);
      await store.command('repeat', 2);
      await until(() => store.repeat == 2);
      await store.command('speed', 1.25);
      await until(() => store.speed == 1.25);
      await store.command('next');
      await until(() => store.current?.id != firstId);
      await store.command('jump', 2);
      await until(() => store.queueIndex == 2);
      await store.command('jump', 0);
      await until(() => store.current?.id == firstId && store.playing);
      await store.command('shuffle', false);
      await store.command('seek', 30000);
      await until(() => store.position.value >= 29500);
      store.glass = false;
      store.changed();
      await tester.pumpAndSettle();
      expect(store.current!.id, firstId);
      expect(store.playing, true);
      expect(store.position.value, greaterThan(29000));
      await store.command('speed', 1.0);
      await binding.convertFlutterSurfaceToImage();
      final screenshotDir = Directory(
        '${Directory.systemTemp.path}/aura-screens',
      )..createSync(recursive: true);
      Future<void> capture(String name) async {
        await tester.pump(const Duration(milliseconds: 350));
        final bytes = await binding.takeScreenshot(name);
        File('${screenshotDir.path}/$name.png').writeAsBytesSync(bytes);
      }

      for (final glass in [true, false]) {
        for (final appearance in ['Dark', 'Light']) {
          store.glass = glass;
          store.appearance = appearance;
          store.changed();
          await tester.pumpAndSettle();
          final prefix =
              '${glass ? 'glass' : 'classic'}-${appearance.toLowerCase()}';
          for (final tab in ['Home', 'Library', 'EQ', 'Settings']) {
            await tester.tap(find.text(tab).last);
            await tester.pumpAndSettle();
            if (tab == 'EQ') {
              expect(find.textContaining('TUNING TARGET'), findsOneWidget);
              expect(
                find.byWidgetPredicate(
                  (w) =>
                      w is CustomPaint &&
                      w.painter is ResponsePainter &&
                      (w.painter as ResponsePainter).values.any(
                        (v) => v.abs() > 1,
                      ),
                ),
                findsOneWidget,
              );
            }
            await capture('$prefix-${tab.toLowerCase()}');
          }
          await store.command('pause');
          await until(() => !store.playing);
          final shellContext = tester.element(find.byType(MainShell));
          openPage(shellContext, const NowPlayingPage());
          await tester.pumpAndSettle();
          await capture('$prefix-player');
          Navigator.of(tester.element(find.byType(NowPlayingPage))).pop();
          await tester.pumpAndSettle();
          openPage(shellContext, const QueuePage());
          await tester.pumpAndSettle();
          await capture('$prefix-queue');
          Navigator.of(tester.element(find.byType(QueuePage))).pop();
          await tester.pumpAndSettle();
          await store.command('play');
          await until(() => store.playing);
        }
      }
      store.glass = true;
      store.appearance = 'Dark';
      store.changed();
      await store.command('shuffle', false);
      await store.command('seek', 15000);
      await store.save();
      final saved = jsonDecode(
        await store.audio.invoke('loadState') as String,
      ) as Map<String, dynamic>;
      expect(
        (saved['playlists'] as List).any((p) => p['name'] == 'Airplane Mix'),
        true,
      );
      expect(saved['preset'], 'Offline Bass');
      expect(saved['glass'], true);
      expect(saved['appearance'], 'Dark');
      expect(tester.takeException(), isNull);
      // Keep playback alive to inspect background notification controls over adb.
      debugPrint(
        'OFFLINE_NATIVE_PASS: metadata, artwork, queue, seek, EQ, presets, themes, persistence. Screenshots: ${screenshotDir.path}',
      );
    },
  );
}
