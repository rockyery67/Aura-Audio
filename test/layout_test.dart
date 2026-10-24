import 'package:aura_audio/app.dart';
import 'package:aura_audio/application/music_store.dart';
import 'package:aura_audio/presentation/screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'music_store_test.dart' show FakeAudio, one, two;

void main() {
  testWidgets(
    '390x844 player, equalizer, themes, sheets, and keyboard keep playback state',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final audio = FakeAudio(), store = MusicStore(FakeAudio());
      store.initialized = true;
      store.welcomed = true;
      store.appearance = 'Dark';
      store.tracks.addAll([one, two]);
      store.queueIds.addAll(['one', 'two']);
      store.queueIndex = 0;
      store.playing = true;
      await tester.pumpWidget(AuraApp(store: store));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('EQ').last);
      await tester.pumpAndSettle();
      expect(find.text('Acoustic Sculptor EQ'), findsOneWidget);
      expect(tester.takeException(), isNull);
      store.queueIndex = 1;
      store.playing = false;
      store.changed();
      await tester.pumpAndSettle();
      expect(find.text('Two'), findsNWidgets(2));
      expect(find.byTooltip('Play mini player'), findsOneWidget);
      store.queueIndex = 0;
      store.playing = true;
      store.changed();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appearance').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Classic').last);
      await tester.pumpAndSettle();
      expect(store.glass, false);
      expect(store.playing, true);
      expect(store.queueIds, ['one', 'two']);
      await tester.tap(find.text('Light').last);
      await tester.pumpAndSettle();
      expect(store.appearance, 'Light');
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.byType(AppearancePage))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('One').last);
      await tester.pumpAndSettle();
      expect(find.byType(NowPlayingPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
      await audio.controller.close();
    },
  );
  testWidgets(
    '320 wide and large text retain scrollable welcome and empty states',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MusicStore(FakeAudio())..initialized = true;
      await tester.pumpWidget(AuraApp(store: store));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Explore your player'), 200);
      await tester.tap(find.text('Explore your player'));
      await tester.pumpAndSettle();
      expect(find.text('Add your music'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
