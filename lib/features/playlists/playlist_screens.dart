part of '../../presentation/screens.dart';

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: context.music,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            PageHeader(
              'Playlists',
              back: true,
              trailing: IconButton(
                tooltip: 'Create playlist',
                onPressed: () async {
                  final s = context.music;
                  final name = await askName(context, 'New playlist');
                  if (name != null && context.mounted) {
                    final p = s.createPlaylist(name);
                    openPage(context, PlaylistPage(p));
                  }
                },
                icon: const Icon(Icons.add_rounded),
              ),
            ),
            if (context.music.playlists.isEmpty)
              const EmptyState(
                'Make a little mixtape',
                'Create a playlist for a mood, a moment, or the road ahead.',
                icon: Icons.playlist_add_rounded,
              ),
            ...context.music.playlists.map(
              (p) => ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                leading: Artwork(
                  path: p.artwork.isEmpty
                      ? context.music.resolve(p.ids).firstOrNull?.artwork
                      : p.artwork,
                ),
                title: Text(p.name),
                subtitle: Text('${p.ids.length} tracks · Saved on device'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => openPage(context, PlaylistPage(p)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class PlaylistPage extends StatelessWidget {
  const PlaylistPage(this.playlist, {super.key});
  final LocalPlaylist playlist;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: context.music,
    builder: (context, _) {
      final s = context.music, songs = s.resolve(playlist.ids);
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              PageHeader(
                playlist.name,
                back: true,
                trailing: PopupMenuButton<String>(
                  tooltip: 'Edit playlist',
                  onSelected: (value) async {
                    if (value == 'Rename') {
                      final name = await askName(
                        context,
                        'Rename playlist',
                        initial: playlist.name,
                      );
                      if (name != null) {
                        playlist.name = name;
                        s.changed();
                      }
                    } else if (value == 'Artwork') {
                      final path = await s.command('pickArtwork');
                      if (path is String) {
                        playlist.artwork = path;
                        s.changed();
                      }
                    } else if (value == 'Delete') {
                      s.playlists.remove(playlist);
                      s.changed();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  itemBuilder: (_) => ['Rename', 'Artwork', 'Delete']
                      .map((v) => PopupMenuItem(value: v, child: Text(v)))
                      .toList(),
                ),
              ),
              Artwork(
                path: playlist.artwork.isEmpty
                    ? songs.firstOrNull?.artwork
                    : playlist.artwork,
                size: 160,
                radius: 28,
              ),
              const SizedBox(height: 16),
              Text(
                '${songs.length} tracks · Your own collection',
                style: TextStyle(color: context.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: songs.isEmpty ? null : () => s.playTracks(songs),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => addTracksSheet(context, playlist),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add tracks'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: songs.isEmpty
                    ? const EmptyState(
                        'Your mix starts here',
                        'Add a few tracks and make it your own.',
                        icon: Icons.music_note_rounded,
                      )
                    : ReorderableListView.builder(
                        itemCount: songs.length,
                        onReorderItem: (old, next) =>
                            s.reorderPlaylist(playlist, old, next),
                        itemBuilder: (context, i) => Padding(
                          key: ValueKey(songs[i].id),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TrackTile(
                            songs[i],
                            onTap: () => s.playTracks(songs, i),
                            trailing: IconButton(
                              tooltip: 'Remove from playlist',
                              onPressed: () {
                                playlist.ids.remove(songs[i].id);
                                s.changed();
                              },
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void addToPlaylist(BuildContext context, Track t) => sheet(
  context,
  (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Add to playlist',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      ListTile(
        leading: const Icon(Icons.add_rounded),
        title: const Text('Create playlist'),
        onTap: () async {
          final s = context.music;
          final name = await askName(context, 'New playlist');
          if (name != null) {
            s.addToPlaylist(s.createPlaylist(name), t);
            if (context.mounted) Navigator.pop(context);
          }
        },
      ),
      ...context.music.playlists.map(
        (p) => ListTile(
          leading: const Icon(Icons.playlist_play_rounded),
          title: Text(p.name),
          trailing: p.ids.contains(t.id)
              ? const Icon(Icons.check_rounded)
              : null,
          onTap: () {
            context.music.addToPlaylist(p, t);
            Navigator.pop(context);
          },
        ),
      ),
    ],
  ),
);
void addTracksSheet(BuildContext context, LocalPlaylist p) => sheet(
  context,
  (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Add a little more',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      if (context.music.tracks.isEmpty)
        const EmptyState(
          'Your library is empty',
          'Import music before adding tracks to a playlist.',
        ),
      ...context.music.tracks.map(
        (t) => TrackTile(
          t,
          onTap: () => context.music.addToPlaylist(p, t),
          trailing: IconButton(
            tooltip: 'Add track to playlist',
            onPressed: () => context.music.addToPlaylist(p, t),
            icon: Icon(
              p.ids.contains(t.id)
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              color: context.accent,
            ),
          ),
        ),
      ),
    ],
  ),
);
