import 'dart:async';
import 'dart:convert';

import 'package:aura_audio/application/music_store.dart';
import 'package:aura_audio/core/models.dart';
import 'package:aura_audio/platform/native_audio.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAudio implements AudioGateway {
  final controller = StreamController<dynamic>.broadcast(sync: true);
  final calls = <(String, dynamic)>[];
  String saved = '{}';
  @override
  Stream<dynamic> get events => controller.stream;
  @override
  Future<dynamic> invoke(String method, [dynamic arguments]) async {
    calls.add((
      method,
      arguments == null ? null : jsonDecode(jsonEncode(arguments)),
    ));
    return switch (method) {
      'loadState' => saved,
      'saveState' => saved = arguments as String,
      'sources' => <String>[],
      'history' => <String>[],
      'validate' => (arguments as List).map((_) => true).toList(),
      'eq' => {'response': List.filled(160, 0.0), 'headroom': 0.0},
      _ => true,
    };
  }

  void playback({
    List<String> ids = const ['one', 'two'],
    int index = 0,
    bool playing = true,
    int position = 1000,
  }) => controller.add({
    'type': 'playback',
    'ready': true,
    'playing': playing,
    'position': position,
    'duration': 120000,
    'index': index,
    'ids': ids,
    'repeat': 0,
    'speed': 1.0,
    'sleepAt': 0,
  });
}

const one = Track(
  id: 'one',
  uri: 'content://media/1',
  title: 'One',
  artist: 'Artist',
  album: 'Album',
  duration: 120000,
);
const two = Track(
  id: 'two',
  uri: 'content://media/2',
  title: 'Two',
  artist: 'Artist',
  album: 'Album',
  duration: 120000,
);

void main() {
  test(
    'persistent library, playlists, themes, and presets round-trip',
    () async {
      final audio = FakeAudio(), s = MusicStore(FakeAudio());
      s.tracks.addAll([one, two]);
      s.favorite(one);
      s.favoriteAlbum('Artist|Album');
      final p = s.createPlaylist('Evening');
      s.addToPlaylist(p, one);
      s.addToPlaylist(p, two);
      s.addToPlaylist(p, one);
      s.reorderPlaylist(p, 0, 1);
      s.glass = false;
      s.appearance = 'Light';
      s.welcomed = true;
      s.reducedMotion = true;
      s.gains[0] = 3;
      s.savePreset('Warm');
      s.renamePreset('Warm', 'Sunset');
      audio.saved = jsonEncode(s.toJson());
      final restored = MusicStore(audio);
      await restored.initialize();
      expect(restored.tracks.length, 2);
      expect(restored.playlists.single.ids, ['two', 'one']);
      expect(restored.favorites, {'one'});
      expect(restored.favoriteAlbums, {'Artist|Album'});
      expect(restored.glass, false);
      expect(restored.appearance, 'Light');
      expect(restored.reducedMotion, true);
      expect(restored.customPresets['Sunset']!['gains'][0], 3);
      expect(
        audio.calls.where((c) => c.$1 == 'play' || c.$1 == 'setQueue'),
        isEmpty,
      );
      restored.dispose();
      s.dispose();
      await audio.controller.close();
    },
  );
  test('one authoritative service updates queue and history; position does not rebuild screens', () async {
    final audio = FakeAudio(), s = MusicStore(FakeAudio());
    s.dispose();
    final store = MusicStore(audio);
    store.tracks.addAll([one, two]);
    audio.saved = jsonEncode(store.toJson());
    await store.initialize();
    var notifications = 0;
    store.addListener(() => notifications++);
    audio.playback();
    final count = notifications;
    audio.playback(position: 2000);
    expect(notifications, count);
    expect(store.position.value, 2000);
    audio.controller.add({'type': 'position', 'position': 2500});
    expect(store.position.value, 2500);
    expect(notifications, count);
    expect(store.queueIds, ['one', 'two']);
    expect(store.playing, true);
    audio.playback(ids: ['two', 'one'], index: 0);
    expect(store.current?.id, 'two');
    expect(store.history.take(2), ['two', 'one']);
    store.glass = false;
    store.changed();
    expect(store.playing, true);
    expect(store.current?.id, 'two');
    expect(
      audio.calls.where((c) => c.$1 == 'setQueue' || c.$1 == 'pause'),
      isEmpty,
    );
    store.dispose();
    await audio.controller.close();
  });
  test(
    'play queue excludes missing files and preserves requested playable track',
    () async {
      final audio = FakeAudio(), s = MusicStore(FakeAudio());
      s.dispose();
      final store = MusicStore(audio);
      await store.playTracks([one.copy(missing: true), two], 1);
      final call = audio.calls.firstWhere((c) => c.$1 == 'setQueue').$2 as Map;
      expect((call['tracks'] as List).length, 1);
      expect(call['index'], 0);
      await store.playTracks([one.copy(missing: true)]);
      expect(store.error, contains('unavailable'));
      final callCount = audio.calls.where((c) => c.$1 == 'setQueue').length;
      await store.playTracks([one.copy(missing: true), two], 0);
      expect(audio.calls.where((c) => c.$1 == 'setQueue').length, callCount);
      store.dispose();
      await audio.controller.close();
    },
  );
  test(
    'built-in/custom presets are independent and deletion retains edited sound',
    () {
      final store = MusicStore(FakeAudio());
      store.selectPreset('Rock');
      store.gains[0] = 10;
      expect(builtInPresets['Rock']!.first, 3);
      store.savePreset('Custom A');
      store.gains[0] = 2;
      expect((store.customPresets['Custom A']!['gains'] as List).first, 10);
      store.selectPreset('Custom A');
      expect(store.gains.first, 10);
      store.deletePreset('Custom A');
      expect(store.preset, 'Custom');
      expect(store.gains.first, 10);
      store.dispose();
    },
  );
  test('local LRC timestamps, fractions, multiple tags and plain text', () {
    final lines = parseLyrics(
      '[00:01.5][00:03.050]Hello\n[00:02]World\n[ar:Artist]',
    );
    expect(lines.map((l) => l.milliseconds), [1500, 2000, 3050]);
    expect(lines.map((l) => l.text), ['Hello', 'World', 'Hello']);
    expect(parseLyrics('Plain lyrics'), isEmpty);
  });
  testWidgets(
    'continuous EQ gestures stream bounded native updates before the gesture ends',
    (tester) async {
      final audio = FakeAudio(), store = MusicStore(FakeAudio());
      store.dispose();
      final live = MusicStore(audio);
      for (var i = 0; i < 6; i++) {
        live.gains[0] = i.toDouble();
        live.eqChanged();
        await tester.pump(const Duration(milliseconds: 20));
      }
      final updates = audio.calls.where((call) => call.$1 == 'eq').toList();
      expect(updates.length, inInclusiveRange(2, 4));
      expect((updates.first.$2 as Map)['gains'][0], lessThan(5));
      expect((updates.last.$2 as Map)['gains'][0], 5);
      live.dispose();
      await audio.controller.close();
    },
  );
}
