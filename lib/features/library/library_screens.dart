part of '../../presentation/screens.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, bounds) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: bounds.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BrandMark(size: 30),
                      SizedBox(width: 12),
                      Eyebrow('Aura Audio'),
                    ],
                  ),
                  const SizedBox(height: 42),
                  SizedBox(
                    height: 250,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.translate(
                          offset: const Offset(-80, 20),
                          child: Transform.rotate(
                            angle: -.18,
                            child: const Artwork(
                              asset: 'assets/art/solaris.png',
                              size: 170,
                              radius: 28,
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(80, 20),
                          child: Transform.rotate(
                            angle: .18,
                            child: const Artwork(
                              asset: 'assets/art/stillness.png',
                              size: 170,
                              radius: 28,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: context.accent.withValues(alpha: .2),
                                blurRadius: 45,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Artwork(
                            asset: 'assets/art/ethereal.png',
                            size: 218,
                            radius: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Your music.\nBeautifully yours.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge
                        ?.copyWith(fontSize: 34, height: 1.18),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A little space for everything you love.\nLocal listening. Pure sound. No distractions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.muted, height: 1.7),
                  ),
                  const SizedBox(height: 28),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: double.infinity,
                      minHeight: 54,
                    ),
                    child: FilledButton(
                      onPressed: () => context.music.scan('pickFolder'),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_open_rounded),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Choose music folder',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => context.music.scan('scanDevice'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.library_music_outlined),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Scan device music',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.music.welcomed = true;
                      context.music.changed();
                    },
                    child: const Text('Explore your player'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 13,
                        color: context.muted,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          'Always offline. Always yours.',
                          style: TextStyle(fontSize: 10, color: context.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onLibrary});
  final VoidCallback onLibrary;
  @override
  Widget build(BuildContext context) {
    final s = context.music;
    final recent = s.resolve(s.history);
    final session =
        s.current ??
        recent.firstOrNull ??
        s.tracks.where((t) => !t.missing).firstOrNull;
    final albums = <String, Track>{};
    for (final t in recent.isEmpty ? s.tracks : recent) {
      albums.putIfAbsent('${t.artist}|${t.album}', () => t);
    }
    final favorites = s.tracks
        .where((t) => s.favorites.contains(t.id))
        .take(4)
        .toList();
    final added = List<Track>.of(s.tracks)
      ..sort((a, b) => b.added.compareTo(a.added));
    return ListView(
      key: const PageStorageKey('home'),
      padding: const EdgeInsets.only(bottom: 180),
      children: [
        PageHeader(
          'Home',
          trailing: IconButton(
            tooltip: 'Import music',
            onPressed: () => importSheet(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Eyebrow(
                      '●  Your local collection',
                      color: context.cyan,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${s.tracks.where((t) => !t.missing).length} tracks',
                    style: TextStyle(
                      fontFamily: 'Mono',
                      fontSize: 10,
                      color: context.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                DateTime.now().hour < 12
                    ? 'Good morning'
                    : DateTime.now().hour < 18
                    ? 'Good afternoon'
                    : 'Good evening',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 3),
              Text(
                'Find your rhythm. Feel every detail.',
                style: TextStyle(color: context.muted),
              ),
              const SizedBox(height: 20),
              if (session != null)
                _ContinueCard(session)
              else
                EmptyState(
                  'Your next favorite is already yours',
                  'Add a music folder to start listening.\nNo accounts. No connection needed.',
                  action: FilledButton.icon(
                    onPressed: () => importSheet(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add your music'),
                  ),
                ),
              if (albums.isNotEmpty) ...[
                SectionTitle(
                  recent.isEmpty ? 'Your albums' : 'Recently played',
                  action: 'VIEW ALL',
                  onTap: () => openPage(
                    context,
                    TrackListPage(
                      title: 'Listening history',
                      selection: recent,
                    ),
                  ),
                ),
                SizedBox(
                  height: 215,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: albums.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, i) {
                      final t = albums.values.elementAt(i);
                      return SizedBox(
                        width: 154,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => albumPage(context, t),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Artwork(track: t, size: 154, radius: 22),
                              const SizedBox(height: 10),
                              Text(
                                t.album,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                t.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SectionTitle(
                  'Your favorites',
                  action: 'VIEW ALL',
                  onTap: () => openPage(context, const FavoritesPage()),
                ),
                if (favorites.isEmpty)
                  Panel(
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite_border_rounded,
                          color: context.accent,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Tap a heart to keep a song close.',
                            style: TextStyle(color: context.muted),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Panel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Column(
                      children: favorites
                          .map(
                            (t) => TrackTile(
                              t,
                              onTap: () =>
                                  s.playTracks(favorites, favorites.indexOf(t)),
                              trailing: IconButton(
                                tooltip: 'Remove favorite',
                                onPressed: () => s.favorite(t),
                                icon: Icon(
                                  Icons.favorite_rounded,
                                  size: 20,
                                  color: context.accent,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                SectionTitle(
                  'Recently added',
                  action: 'LIBRARY',
                  onTap: onLibrary,
                ),
                ...added
                    .take(5)
                    .map(
                      (t) => TrackTile(
                        t,
                        onTap: () => s.playTracks(added, added.indexOf(t)),
                        onMore: () => trackActions(context, t),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard(this.track);
  final Track track;
  @override
  Widget build(BuildContext context) => Panel(
    radius: 30,
    blur: true,
    child: Column(
      children: [
        Row(
          children: [
            Artwork(track: track, size: 94, radius: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Continue listening', color: Color(0xffffb95f)),
                  const SizedBox(height: 8),
                  Text(
                    track.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value:
                        context.music.current?.id == track.id &&
                            track.duration > 0
                        ? (context.music.position.value / track.duration).clamp(
                            0,
                            1,
                          )
                        : 0,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(Icons.offline_bolt_outlined, color: context.cyan, size: 16),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                '${track.format} · ON DEVICE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Mono',
                  fontSize: 9,
                  color: context.muted,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Favorite track',
              onPressed: () => context.music.favorite(track),
              icon: Icon(
                context.music.favorites.contains(track.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: context.accent,
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                if (context.music.current?.id == track.id) {
                  context.music.togglePlayback();
                } else {
                  context.music.playTracks(
                    context.music.tracks,
                    context.music.tracks.indexOf(track),
                  );
                }
              },
              icon: Icon(
                context.music.current?.id == track.id && context.music.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 20,
              ),
              label: Text(
                context.music.current?.id == track.id && context.music.playing
                    ? 'Pause'
                    : 'Resume',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

void albumPage(BuildContext context, Track t) => openPage(
  context,
  CollectionPage(
    title: t.album,
    subtitle: t.artist,
    selection: context.music.tracks
        .where((x) => x.album == t.album && x.artist == t.artist)
        .toList(),
    albumKey: '${t.artist}|${t.album}',
  ),
);

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String view = 'Songs', sort = 'Title';
  bool grid = true;
  @override
  Widget build(BuildContext context) {
    final s = context.music;
    final tracks = List<Track>.of(s.tracks)
      ..sort(
        (a, b) => switch (sort) {
          'Artist' => a.artist.compareTo(b.artist),
          'Recently added' => b.added.compareTo(a.added),
          'Duration' => b.duration.compareTo(a.duration),
          _ => a.title.compareTo(b.title),
        },
      );
    final groups = <String, List<Track>>{};
    for (final t in tracks) {
      final key = switch (view) {
        'Albums' => '${t.album}\n${t.artist}',
        'Artists' => t.artist,
        'Folders' => t.folder,
        _ => '',
      };
      (groups[key] ??= []).add(t);
    }
    return CustomScrollView(
      key: const PageStorageKey('library'),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            'Library',
            trailing: IconButton(
              tooltip: 'Add music',
              onPressed: () => importSheet(context),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Songs', 'Albums', 'Artists', 'Folders']
                        .map(
                          (v) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(v),
                              selected: view == v,
                              onSelected: (_) => setState(() => view = v),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${tracks.length} ${view.toLowerCase() == 'songs' ? 'songs' : 'tracks'}',
                      style: TextStyle(fontSize: 11, color: context.muted),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      tooltip: 'Sort library',
                      initialValue: sort,
                      onSelected: (v) => setState(() => sort = v),
                      itemBuilder: (_) =>
                          ['Title', 'Artist', 'Recently added', 'Duration']
                              .map(
                                (v) => PopupMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.sort_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text(sort, style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                    if (view != 'Songs')
                      IconButton(
                        tooltip: 'Toggle grid view',
                        onPressed: () => setState(() => grid = !grid),
                        icon: Icon(
                          grid
                              ? Icons.view_list_outlined
                              : Icons.grid_view_rounded,
                        ),
                      ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      avatar: Icon(
                        Icons.playlist_play_rounded,
                        color: context.accent,
                        size: 18,
                      ),
                      label: const Text('Playlists'),
                      onPressed: () => openPage(context, const PlaylistsPage()),
                    ),
                    ActionChip(
                      avatar: Icon(
                        Icons.favorite_outline_rounded,
                        color: context.accent,
                        size: 16,
                      ),
                      label: const Text('Favorites'),
                      onPressed: () => openPage(context, const FavoritesPage()),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.history_rounded, size: 16),
                      label: const Text('History'),
                      onPressed: () => openPage(
                        context,
                        TrackListPage(
                          title: 'Listening history',
                          selection: s.resolve(s.history),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        if (tracks.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              'A library that feels like you',
              'Add a folder or scan device audio. Your songs will appear here.',
              action: FilledButton(
                onPressed: () => importSheet(context),
                child: const Text('Add music'),
              ),
            ),
          )
        else if (view == 'Songs')
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            sliver: SliverList.builder(
              itemCount: tracks.length,
              itemBuilder: (context, i) => TrackTile(
                tracks[i],
                onTap: () => s.playTracks(tracks, i),
                onMore: () => trackActions(context, tracks[i]),
              ),
            ),
          )
        else if (grid && view == 'Albums')
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: .65,
                mainAxisSpacing: 12,
                crossAxisSpacing: 14,
              ),
              itemCount: groups.length,
              itemBuilder: (context, i) {
                final group = groups.values.elementAt(i);
                final t = group.first;
                return LayoutBuilder(
                  builder: (context, constraints) => InkWell(
                    onTap: () => albumPage(context, t),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Artwork(
                          track: t,
                          size: constraints.maxWidth,
                          radius: 22,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.album,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          t.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: context.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: groups.length,
              itemBuilder: (context, i) {
                final title = groups.keys.elementAt(i);
                final group = groups.values.elementAt(i);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  leading: view == 'Folders'
                      ? Icon(
                          Icons.folder_outlined,
                          color: context.accent,
                          size: 32,
                        )
                      : Artwork(
                          track: group.first,
                          radius: view == 'Artists' ? 30 : 12,
                        ),
                  title: Text(
                    title.split('\n').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${group.length} tracks'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => openPage(
                    context,
                    CollectionPage(
                      title: title.split('\n').first,
                      subtitle: view == 'Artists'
                          ? 'Artist · ${group.length} tracks'
                          : '${group.length} tracks · On device',
                      selection: group,
                    ),
                  ),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 190)),
      ],
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final input = TextEditingController();
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.music, q = input.text.toLowerCase().trim();
    final songs = s.tracks
        .where(
          (t) => '${t.title} ${t.artist} ${t.album}'.toLowerCase().contains(q),
        )
        .toList();
    final albums = <String, Track>{}, artists = <String, Track>{};
    for (final t in s.tracks) {
      if (t.album.toLowerCase().contains(q)) {
        albums['${t.artist}|${t.album}'] = t;
      }
      if (t.artist.toLowerCase().contains(q)) artists[t.artist] = t;
    }
    final lists = s.playlists
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 190),
      children: [
        const PageHeader('Search'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: input,
                onChanged: (_) => setState(() {}),
                onSubmitted: s.rememberSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Songs, albums, artists, playlists',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: input.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () => setState(input.clear),
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              if (q.isEmpty) ...[
                SectionTitle(
                  'Recent searches',
                  action: 'CLEAR',
                  onTap: () {
                    s.recentSearches.clear();
                    s.changed();
                  },
                ),
                if (s.recentSearches.isEmpty)
                  const EmptyState(
                    'Find something you love',
                    'Search every corner of your local collection.',
                    icon: Icons.search_rounded,
                  ),
                ...s.recentSearches.map(
                  (v) => ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: Text(v),
                    trailing: const Icon(Icons.north_west_rounded),
                    onTap: () => setState(() => input.text = v),
                  ),
                ),
              ] else if (songs.isEmpty &&
                  albums.isEmpty &&
                  artists.isEmpty &&
                  lists.isEmpty)
                EmptyState(
                  'No matches for “${input.text}”',
                  'Try another title, artist, or album.',
                  icon: Icons.search_off_rounded,
                )
              else ...[
                if (songs.isNotEmpty) ...[
                  const SectionTitle('Songs'),
                  ...songs
                      .take(30)
                      .map(
                        (t) => TrackTile(
                          t,
                          onTap: () {
                            s.rememberSearch(input.text);
                            s.playTracks(songs, songs.indexOf(t));
                          },
                          onMore: () => trackActions(context, t),
                        ),
                      ),
                ],
                if (albums.isNotEmpty) ...[
                  const SectionTitle('Albums'),
                  ...albums.values.map(
                    (t) => ListTile(
                      leading: Artwork(track: t),
                      title: Text(t.album),
                      subtitle: Text(t.artist),
                      onTap: () => albumPage(context, t),
                    ),
                  ),
                ],
                if (artists.isNotEmpty) ...[
                  const SectionTitle('Artists'),
                  ...artists.keys.map(
                    (artist) => ListTile(
                      leading: const Icon(Icons.person_outline_rounded),
                      title: Text(artist),
                      onTap: () => openPage(
                        context,
                        CollectionPage(
                          title: artist,
                          subtitle: 'Artist',
                          selection: s.tracks
                              .where((t) => t.artist == artist)
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ],
                if (lists.isNotEmpty) ...[
                  const SectionTitle('Playlists'),
                  ...lists.map(
                    (p) => ListTile(
                      leading: const Icon(Icons.playlist_play_rounded),
                      title: Text(p.name),
                      onTap: () => openPage(context, PlaylistPage(p)),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class TrackListPage extends StatelessWidget {
  const TrackListPage({
    super.key,
    required this.title,
    required this.selection,
  });
  final String title;
  final List<Track> selection;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: context.music,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title, back: true),
            Expanded(
              child: selection.isEmpty
                  ? const EmptyState(
                      'Nothing here just yet',
                      'Your listening story starts with a song.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: selection.length,
                      itemBuilder: (context, i) => TrackTile(
                        selection[i],
                        onTap: () => context.music.playTracks(selection, i),
                        onMore: () => trackActions(context, selection[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CollectionPage extends StatelessWidget {
  const CollectionPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selection,
    this.albumKey,
  });
  final String title, subtitle;
  final String? albumKey;
  final List<Track> selection;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: context.music,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                albumKey == null ? 'Collection' : 'Album',
                back: true,
                trailing: albumKey == null
                    ? null
                    : IconButton(
                        tooltip: 'Favorite album',
                        onPressed: () => context.music.favoriteAlbum(albumKey!),
                        icon: Icon(
                          context.music.favoriteAlbums.contains(albumKey)
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          color: context.accent,
                        ),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Artwork(
                      track: selection.firstOrNull,
                      size: math.min(
                        MediaQuery.sizeOf(context).width - 80,
                        280,
                      ),
                      radius: 28,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.muted),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                context.music.playTracks(selection),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Play'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final store = context.music;
                              await store.command('shuffle', true);
                              await store.playTracks(selection);
                            },
                            icon: const Icon(Icons.shuffle_rounded),
                            label: const Text('Shuffle'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              sliver: SliverList.builder(
                itemCount: selection.length,
                itemBuilder: (context, i) => TrackTile(
                  selection[i],
                  number: i + 1,
                  onTap: () => context.music.playTracks(selection, i),
                  onMore: () => trackActions(context, selection[i]),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    ),
  );
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: context.music,
    builder: (context, _) {
      final s = context.music;
      final songs = s.tracks.where((t) => s.favorites.contains(t.id)).toList();
      final albums = <String, Track>{};
      for (final t in s.tracks) {
        final k = '${t.artist}|${t.album}';
        if (s.favoriteAlbums.contains(k)) albums[k] = t;
      }
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 30),
            children: [
              const PageHeader('Favorites', back: true),
              if (songs.isEmpty && albums.isEmpty)
                const EmptyState(
                  'Keep your favorites close',
                  'Tap the heart on a song or album to save it here.',
                  icon: Icons.favorite_outline_rounded,
                ),
              if (albums.isNotEmpty) ...[
                const SectionTitle('Albums'),
                ...albums.values.map(
                  (t) => ListTile(
                    leading: Artwork(track: t),
                    title: Text(t.album),
                    subtitle: Text(t.artist),
                    onTap: () => albumPage(context, t),
                  ),
                ),
              ],
              if (songs.isNotEmpty) ...[
                const SectionTitle('Songs'),
                ...songs.map(
                  (t) => TrackTile(
                    t,
                    onTap: () => s.playTracks(songs, songs.indexOf(t)),
                    onMore: () => trackActions(context, t),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

void trackActions(BuildContext context, Track t) => sheet(
  context,
  (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Artwork(track: t, size: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title, style: Theme.of(context).textTheme.titleMedium),
                Text(t.artist, style: TextStyle(color: context.muted)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      ListTile(
        leading: Icon(
          context.music.favorites.contains(t.id)
              ? Icons.favorite
              : Icons.favorite_outline,
        ),
        title: Text(
          context.music.favorites.contains(t.id)
              ? 'Remove from favorites'
              : 'Add to favorites',
        ),
        onTap: () => context.music.favorite(t),
      ),
      ListTile(
        leading: const Icon(Icons.queue_music_rounded),
        title: const Text('Add to queue'),
        onTap: () {
          context.music.command('append', t.mediaItem);
          Navigator.pop(context);
        },
      ),
      ListTile(
        leading: const Icon(Icons.playlist_add_rounded),
        title: const Text('Add to playlist'),
        onTap: () {
          Navigator.pop(context);
          addToPlaylist(context, t);
        },
      ),
      ListTile(
        leading: const Icon(Icons.album_outlined),
        title: const Text('Go to album'),
        onTap: () {
          Navigator.pop(context);
          albumPage(context, t);
        },
      ),
      ListTile(
        leading: const Icon(Icons.info_outline_rounded),
        title: const Text('Track information'),
        onTap: () {
          Navigator.pop(context);
          trackInfo(context, t);
        },
      ),
    ],
  ),
);

void trackInfo(BuildContext context, Track t) => sheet(
  context,
  (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Track information',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 16),
      ...{
        'Title': t.title,
        'Artist': t.artist,
        'Album': t.album,
        'Track': '${t.number}',
        'Duration': timeLabel(t.duration),
        'Format': t.format,
        'Size': '${(t.size / 1048576).toStringAsFixed(1)} MB',
        'Folder': t.folder,
        'Status': t.missing
            ? 'Unavailable — rescan or grant access'
            : 'Available locally',
      }.entries.map(
        (e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Text(e.key, style: TextStyle(color: context.muted)),
              ),
              Expanded(child: SelectableText(e.value)),
            ],
          ),
        ),
      ),
    ],
  ),
);
