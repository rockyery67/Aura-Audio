class Track {
  const Track({
    required this.id,
    required this.uri,
    required this.title,
    required this.artist,
    required this.album,
    this.duration = 0,
    this.number = 0,
    this.folder = '',
    this.artwork = '',
    this.color = 0xffa078ff,
    this.lyrics = '',
    this.format = '',
    this.size = 0,
    this.added = 0,
    this.missing = false,
  });
  final String id, uri, title, artist, album, folder, artwork, lyrics, format;
  final int duration, number, color, size, added;
  final bool missing;
  factory Track.fromJson(Map<String, dynamic> j) => Track(
    id: j['id'] as String,
    uri: j['uri'] as String,
    title: j['title'] as String? ?? 'Unknown track',
    artist: j['artist'] as String? ?? 'Unknown artist',
    album: j['album'] as String? ?? 'Unknown album',
    duration: (j['duration'] as num?)?.toInt() ?? 0,
    number: (j['track'] as num?)?.toInt() ?? 0,
    folder: j['folder'] as String? ?? '',
    artwork: j['artwork'] as String? ?? '',
    color: (j['color'] as num?)?.toInt() ?? 0xffa078ff,
    lyrics: j['lyrics'] as String? ?? '',
    format: j['format'] as String? ?? '',
    size: (j['size'] as num?)?.toInt() ?? 0,
    added: (j['added'] as num?)?.toInt() ?? 0,
    missing: j['missing'] == true,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'uri': uri,
    'title': title,
    'artist': artist,
    'album': album,
    'duration': duration,
    'track': number,
    'folder': folder,
    'artwork': artwork,
    'color': color,
    'lyrics': lyrics,
    'format': format,
    'size': size,
    'added': added,
    'missing': missing,
  };
  Track copy({bool? missing, String? lyrics, int? added}) => Track.fromJson({
    ...toJson(),
    'missing': missing ?? this.missing,
    'lyrics': lyrics ?? this.lyrics,
    'added': added ?? this.added,
  });
  Map<String, dynamic> get mediaItem => {
    'id': id,
    'uri': uri,
    'title': title,
    'artist': artist,
    'album': album,
    'artwork': artwork.isEmpty ? '' : Uri.file(artwork).toString(),
  };
}

class LocalPlaylist {
  LocalPlaylist({
    required this.id,
    required this.name,
    List<String>? ids,
    this.artwork = '',
  }) : ids = ids ?? [];
  final String id;
  String name, artwork;
  final List<String> ids;
  factory LocalPlaylist.fromJson(Map<String, dynamic> j) => LocalPlaylist(
    id: j['id'] as String,
    name: j['name'] as String,
    ids: List<String>.from(j['ids'] as List? ?? []),
    artwork: j['artwork'] as String? ?? '',
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ids': ids,
    'artwork': artwork,
  };
}

const frequencies = [
  '31',
  '62',
  '125',
  '250',
  '500',
  '1k',
  '2k',
  '4k',
  '8k',
  '16k',
];
const frequencyValues = [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
const builtInPresets = <String, List<double>>{
  'Flat': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  'Bass Boost': [5, 4, 3, 1, 0, 0, 0, 0, 0, 0],
  'Vocal': [-2, -2, -1, 0, 2, 3, 3, 2, 0, -1],
  'Rock': [3, 2, 0, -1, -2, 0, 1, 2, 3, 3],
  'Pop': [-1, 1, 2, 3, 2, 0, -1, -1, 1, 2],
  'Jazz': [2, 1, 0, 1, -1, -1, 0, 1, 2, 3],
  'Classical': [2, 1, 0, -1, -1, 0, 1, 2, 2, 3],
};

String timeLabel(int milliseconds) {
  final seconds = milliseconds ~/ 1000;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class LyricLine {
  const LyricLine(this.milliseconds, this.text);
  final int milliseconds;
  final String text;
}

List<LyricLine> parseLyrics(String source) {
  final result = <LyricLine>[];
  final pattern = RegExp(r'\[(\d+):(\d{2})(?:[.:](\d{1,3}))?\]');
  for (final line in source.split('\n')) {
    final matches = pattern.allMatches(line);
    final text = line.replaceAll(pattern, '').trim();
    for (final m in matches) {
      final fraction = (m[3] ?? '0').padRight(3, '0');
      result.add(
        LyricLine(
          (int.parse(m[1]!) * 60 + int.parse(m[2]!)) * 1000 +
              int.parse(fraction),
          text,
        ),
      );
    }
  }
  result.sort((a, b) => a.milliseconds.compareTo(b.milliseconds));
  return result;
}
