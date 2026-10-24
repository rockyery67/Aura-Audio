import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/models.dart';
import '../platform/native_audio.dart';

class MusicStore extends ChangeNotifier {
  MusicStore(this.audio);
  final AudioGateway audio;
  final position = ValueNotifier<int>(0);
  StreamSubscription<dynamic>? _subscription;
  Timer? _saveTimer, _eqTimer;
  bool initialized = false,
      welcomed = false,
      scanning = false,
      playing = false,
      loading = false,
      ready = false;
  bool glass = true,
      reducedMotion = false,
      reducedTransparency = false,
      artworkAccent = true;
  String appearance = 'System', error = '', scanName = '', preset = 'Flat';
  int scanCount = 0,
      duration = 0,
      queueIndex = -1,
      repeat = 0,
      sleepAt = 0,
      sampleRate = 48000;
  bool shuffle = false, eqEnabled = true;
  double speed = 1, preamp = 0, headroom = 0;
  List<double> gains = List.filled(10, 0), response = List.filled(160, 0);
  final customPresets = <String, Map<String, dynamic>>{};
  final tracks = <Track>[];
  final favorites = <String>{}, favoriteAlbums = <String>{};
  final history = <String>[],
      queueIds = <String>[],
      recentSearches = <String>[];
  final playlists = <LocalPlaylist>[];
  final sources = <String>[];
  Track? get current => queueIndex >= 0 && queueIndex < queueIds.length
      ? byId(queueIds[queueIndex])
      : null;
  Track? byId(String id) {
    for (final t in tracks) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<Track> resolve(Iterable<String> ids) =>
      ids.map(byId).whereType<Track>().toList();
  Future<void> initialize() async {
    try {
      final raw = await audio.invoke('loadState') as String? ?? '{}';
      restore(jsonDecode(raw) as Map<String, dynamic>);
      _subscription = audio.events.listen(
        _event,
        onError: (Object e) {
          error = 'The Android audio service is unavailable on this platform.';
          notifyListeners();
        },
      );
      initialized = true;
      notifyListeners();
      await updateEq();
      final nativeHistory = List<String>.from(
        await command('history') as List? ?? [],
      );
      if (nativeHistory.isNotEmpty) {
        final merged = {...nativeHistory, ...history}.take(200).toList();
        history
          ..clear()
          ..addAll(merged);
      }
      await validate();
      sources.addAll(
        List<String>.from(await audio.invoke('sources') as List? ?? []),
      );
    } catch (e) {
      initialized = true;
      error = 'Could not load local data: $e';
      notifyListeners();
    }
  }

  void restore(Map<String, dynamic> j) {
    tracks.clear();
    tracks.addAll(
      (j['tracks'] as List? ?? []).map(
        (e) => Track.fromJson(Map<String, dynamic>.from(e as Map)),
      ),
    );
    favorites.addAll(List<String>.from(j['favorites'] as List? ?? []));
    favoriteAlbums.addAll(
      List<String>.from(j['favoriteAlbums'] as List? ?? []),
    );
    history.addAll(List<String>.from(j['history'] as List? ?? []));
    recentSearches.addAll(
      List<String>.from(j['recentSearches'] as List? ?? []),
    );
    playlists.addAll(
      (j['playlists'] as List? ?? []).map(
        (e) => LocalPlaylist.fromJson(Map<String, dynamic>.from(e as Map)),
      ),
    );
    glass = j['glass'] != false;
    welcomed = j['welcomed'] == true;
    appearance = j['appearance'] as String? ?? 'System';
    reducedMotion = j['reducedMotion'] == true;
    reducedTransparency = j['reducedTransparency'] == true;
    artworkAccent = j['artworkAccent'] != false;
    eqEnabled = j['eqEnabled'] != false;
    preamp = (j['preamp'] as num?)?.toDouble() ?? 0;
    preset = j['preset'] as String? ?? 'Flat';
    final stored = (j['gains'] as List?)
        ?.map((e) => (e as num).toDouble().clamp(-12.0, 12.0))
        .toList();
    if (stored?.length == 10) gains = stored!;
    final custom = j['customPresets'] as Map? ?? {};
    custom.forEach((key, value) {
      customPresets[key as String] = Map<String, dynamic>.from(value as Map);
    });
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'tracks': tracks.map((t) => t.toJson()).toList(),
    'favorites': favorites.toList(),
    'favoriteAlbums': favoriteAlbums.toList(),
    'history': history,
    'playlists': playlists.map((p) => p.toJson()).toList(),
    'recentSearches': recentSearches,
    'welcomed': welcomed,
    'glass': glass,
    'appearance': appearance,
    'reducedMotion': reducedMotion,
    'reducedTransparency': reducedTransparency,
    'artworkAccent': artworkAccent,
    'eqEnabled': eqEnabled,
    'preamp': preamp,
    'gains': gains,
    'preset': preset,
    'customPresets': customPresets,
  };
  void changed() {
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 350), save);
  }

  Future<void> save() async {
    try {
      await audio.invoke('saveState', jsonEncode(toJson()));
    } catch (_) {
      error = 'Settings could not be saved. Check device storage.';
      notifyListeners();
    }
  }

  Future<dynamic> command(String method, [dynamic args]) async {
    try {
      return await audio.invoke(method, args);
    } catch (e) {
      error = e.toString().replaceFirst('PlatformException', '');
      notifyListeners();
      return null;
    }
  }

  void _event(dynamic value) {
    final e = Map<String, dynamic>.from(value as Map);
    if (e['type'] == 'position') {
      position.value = (e['position'] as num).toInt();
      return;
    }
    if (e['type'] == 'scan') {
      scanCount = e['count'] as int? ?? 0;
      scanName = e['name'] as String? ?? '';
      notifyListeners();
      return;
    }
    final newRate = (e['sampleRate'] as num?)?.toInt() ?? sampleRate;
    if (newRate > 0 && newRate != sampleRate) {
      sampleRate = newRate;
      updateEq();
    }
    final oldId = current?.id;
    final oldPlaying = playing;
    final oldSignature =
        '$queueIds|$queueIndex|$playing|$duration|$shuffle|$repeat|$speed|$sleepAt|$loading|$ready';
    position.value = (e['position'] as num?)?.toInt() ?? 0;
    playing = e['playing'] == true;
    loading = e['loading'] == true;
    ready = e['ready'] == true;
    duration = (e['duration'] as num?)?.toInt() ?? 0;
    queueIndex = (e['index'] as num?)?.toInt() ?? -1;
    queueIds.clear();
    queueIds.addAll(List<String>.from(e['ids'] as List? ?? []));
    shuffle = e['shuffle'] == true;
    repeat = (e['repeat'] as num?)?.toInt() ?? 0;
    speed = (e['speed'] as num?)?.toDouble() ?? 1;
    sleepAt = (e['sleepAt'] as num?)?.toInt() ?? 0;
    if ((e['error'] as String? ?? '').isNotEmpty) {
      error = e['error'] as String;
      notifyListeners();
    }
    if (playing && current != null && (oldId != current?.id || !oldPlaying)) {
      history.remove(current!.id);
      history.insert(0, current!.id);
      if (history.length > 200) history.removeRange(200, history.length);
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(milliseconds: 350), save);
    }
    if (oldSignature !=
        '$queueIds|$queueIndex|$playing|$duration|$shuffle|$repeat|$speed|$sleepAt|$loading|$ready') {
      notifyListeners();
    }
  }

  Future<void> validate() async {
    if (tracks.isEmpty) return;
    final results = await command(
      'validate',
      tracks.map((t) => t.uri).toList(),
    );
    if (results is List && results.length == tracks.length) {
      for (var i = 0; i < tracks.length; i++) {
        tracks[i] = tracks[i].copy(missing: results[i] != true);
      }
      changed();
    }
  }

  Future<void> scan(String method) async {
    if (scanning) return;
    scanning = true;
    scanCount = 0;
    scanName = 'Reading your music';
    notifyListeners();
    final result = await command(method);
    if (result is Map) {
      final found = (result['tracks'] as List)
          .map((e) => Track.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final old = {for (final t in tracks) t.id: t};
      tracks.clear();
      tracks.addAll(
        found.map(
          (t) => t.copy(
            added: old[t.id]?.added ?? t.added,
            lyrics: t.lyrics.isEmpty ? old[t.id]?.lyrics : t.lyrics,
          ),
        ),
      );
      final ids = found.map((t) => t.id).toSet();
      tracks.addAll(
        old.values
            .where((t) => !ids.contains(t.id))
            .map((t) => t.copy(missing: true)),
      );
      if ((result['skipped'] as num? ?? 0) > 0) {
        error =
            '${result['skipped']} unreadable or unsupported files were skipped.';
      }
      welcomed = true;
      sources.clear();
      sources.addAll(
        List<String>.from(await command('sources') as List? ?? []),
      );
      changed();
      await save();
      await command(
        'refreshReferences',
        tracks.map((t) => t.mediaItem).toList(),
      );
    }
    scanning = false;
    notifyListeners();
  }

  Future<void> playTracks(List<Track> selection, [int? index]) async {
    if (selection.isEmpty) return;
    final requested = selection[(index ?? 0).clamp(0, selection.length - 1)];
    if (index != null && requested.missing) {
      error = 'This file is unavailable. Reconnect its folder and rescan.';
      notifyListeners();
      return;
    }
    final wanted = requested.id;
    final playable = selection.where((t) => !t.missing).toList();
    if (playable.isEmpty) {
      error = 'These files are unavailable. Reconnect the folder or rescan your library.';
      notifyListeners();
      return;
    }
    await command('setQueue', {
      'tracks': playable.map((t) => t.mediaItem).toList(),
      'index': playable
          .indexWhere((t) => t.id == wanted)
          .clamp(0, playable.length - 1),
      'play': true,
    });
    await command('notifications');
  }

  Future<void> togglePlayback() async {
    if (current == null) {
      await playTracks(tracks);
    } else {
      await command(playing ? 'pause' : 'play');
    }
  }

  void favorite(Track t) {
    favorites.contains(t.id) ? favorites.remove(t.id) : favorites.add(t.id);
    changed();
  }

  void favoriteAlbum(String album) {
    favoriteAlbums.contains(album)
        ? favoriteAlbums.remove(album)
        : favoriteAlbums.add(album);
    changed();
  }

  LocalPlaylist createPlaylist(String name) {
    final p = LocalPlaylist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
    );
    playlists.add(p);
    changed();
    return p;
  }

  void addToPlaylist(LocalPlaylist p, Track t) {
    if (!p.ids.contains(t.id)) {
      p.ids.add(t.id);
      changed();
    }
  }

  void reorderPlaylist(LocalPlaylist p, int oldIndex, int newIndex) {
    final visible = resolve(p.ids).map((t) => t.id).toList();
    final hidden = p.ids.where((id) => !visible.contains(id)).toList();
    final id = visible.removeAt(oldIndex);
    visible.insert(newIndex, id);
    p.ids
      ..clear()
      ..addAll(visible)
      ..addAll(hidden);
    changed();
  }

  Future<void> updateEq() async {
    final result = await command('eq', {
      'enabled': eqEnabled,
      'gains': gains,
      'preamp': preamp,
    });
    if (result is Map) {
      response = (result['response'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
      headroom = (result['headroom'] as num).toDouble();
      notifyListeners();
    }
  }

  void eqChanged() {
    _eqTimer ??= Timer(const Duration(milliseconds: 35), () {
      _eqTimer = null;
      updateEq();
    });
    changed();
  }

  void selectPreset(String name) {
    final custom = customPresets[name];
    gains = List<double>.from(
      builtInPresets[name] ??
          (custom?['gains'] as List? ?? List.filled(10, 0)).map(
            (e) => (e as num).toDouble(),
          ),
    );
    preamp = (custom?['preamp'] as num?)?.toDouble() ?? 0;
    preset = name;
    eqChanged();
  }

  void savePreset(String name) {
    if (builtInPresets.containsKey(name)) {
      error = 'Choose a custom name. Built-in presets are kept unchanged.';
      notifyListeners();
      return;
    }
    customPresets[name] = {'gains': List<double>.of(gains), 'preamp': preamp};
    preset = name;
    changed();
  }

  void renamePreset(String old, String name) {
    if (builtInPresets.containsKey(name)) {
      error = 'Choose a custom name. Built-in presets are kept unchanged.';
      notifyListeners();
      return;
    }
    final value = customPresets.remove(old);
    if (value != null) {
      customPresets[name] = value;
      if (preset == old) preset = name;
      changed();
    }
  }

  void deletePreset(String name) {
    customPresets.remove(name);
    if (preset == name) preset = 'Custom';
    changed();
  }

  void rememberSearch(String query) {
    if (query.trim().isEmpty) return;
    recentSearches.remove(query);
    recentSearches.insert(0, query);
    if (recentSearches.length > 8) recentSearches.removeLast();
    changed();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _saveTimer?.cancel();
    _eqTimer?.cancel();
    position.dispose();
    super.dispose();
  }
}
