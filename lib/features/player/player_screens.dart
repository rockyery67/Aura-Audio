part of '../../presentation/screens.dart';

class NowPlayingPage extends StatelessWidget {
  const NowPlayingPage({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: context.music,
    builder: (context, _) {
      final s = context.music, t = s.current;
      final color = s.artworkAccent && t != null
          ? Color(t.color).withValues(alpha: context.dark ? .35 : .17)
          : context.accent.withValues(alpha: .12);
      return Scaffold(
        body: AnimatedContainer(
          duration: context.motion(550),
          decoration: BoxDecoration(
            gradient: s.glass && !s.reducedTransparency
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      Theme.of(context).scaffoldBackgroundColor,
                      const Color(0xffab7b35).withValues(alpha: .10),
                    ],
                  )
                : null,
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                PageHeader(
                  'Now Playing',
                  back: true,
                  trailing: IconButton(
                    tooltip: 'Audio output',
                    onPressed: () => s.command('output'),
                    icon: const Icon(Icons.speaker_group_outlined),
                  ),
                ),
                if (t == null)
                  const EmptyState(
                    'Let something move you',
                    'Choose a song from your library to start listening.',
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              tooltip: 'Minimize player',
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                            ),
                            Eyebrow(
                              s.playing ? '●  Now playing' : 'Paused',
                              color: context.cyan,
                            ),
                            Text(
                              t.format,
                              style: TextStyle(
                                fontFamily: 'Mono',
                                color: context.muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              if (s.glass)
                                BoxShadow(
                                  color: color,
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: context.motion(350),
                            child: Artwork(
                              key: ValueKey(t.id),
                              track: t,
                              size: math.min(
                                MediaQuery.sizeOf(context).width - 52,
                                360,
                              ),
                              radius: 30,
                              hero: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                  const SizedBox(height: 5),
                                  InkWell(
                                    onTap: () => openPage(
                                      context,
                                      CollectionPage(
                                        title: t.artist,
                                        subtitle: 'Artist',
                                        selection: s.tracks
                                            .where((x) => x.artist == t.artist)
                                            .toList(),
                                      ),
                                    ),
                                    child: Text(
                                      t.artist,
                                      style: TextStyle(
                                        color: context.muted,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Favorite song',
                              onPressed: () => s.favorite(t),
                              icon: Icon(
                                s.favorites.contains(t.id)
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: context.accent,
                                size: 27,
                              ),
                            ),
                            IconButton(
                              tooltip: 'More playback actions',
                              onPressed: () => playbackExtras(context),
                              icon: const Icon(Icons.more_horiz_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const SeekControl(),
                        const SizedBox(height: 24),
                        const Transport(),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: _PlayerEntry(
                                Icons.lyrics_outlined,
                                'Lyrics',
                                context.cyan,
                                () => openPage(context, const LyricsPage()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PlayerEntry(
                                Icons.queue_music_rounded,
                                'Up next',
                                context.accent,
                                () => openPage(context, const QueuePage()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PlayerEntry(
                                Icons.equalizer_rounded,
                                'Equalizer',
                                const Color(0xffffb95f),
                                () => openPage(
                                  context,
                                  const EqualizerPage(standalone: true),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Panel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.headphones_rounded,
                              color: context.accent,
                            ),
                            title: const Text(
                              'System audio output',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Device, Bluetooth, or connected audio',
                              style: TextStyle(
                                color: context.muted,
                                fontSize: 10,
                              ),
                            ),
                            trailing: const Icon(Icons.tune_rounded, size: 20),
                            onTap: () => s.command('output'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _PlayerEntry extends StatelessWidget {
  const _PlayerEntry(this.icon, this.label, this.color, this.tap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: tap,
    borderRadius: BorderRadius.circular(24),
    child: Panel(
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 4),
      child: Column(
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

void playbackExtras(BuildContext context) => sheet(context, (context) {
  final s = context.music;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Make it your listening',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 16),
      ListTile(
        leading: const Icon(Icons.bedtime_outlined),
        title: const Text('Sleep timer'),
        subtitle: Text(
          s.sleepAt > 0
              ? 'Ends at ${DateTime.fromMillisecondsSinceEpoch(s.sleepAt).toLocal().toString().substring(11, 16)}'
              : 'Off',
        ),
        onTap: () {
          Navigator.pop(context);
          sleepSheet(context);
        },
      ),
      ListTile(
        leading: const Icon(Icons.speed_rounded),
        title: const Text('Playback speed'),
        trailing: Text('${s.speed}×'),
        onTap: () {
          Navigator.pop(context);
          speedSheet(context);
        },
      ),
      ListTile(
        leading: Icon(s.repeat == 1 ? Icons.repeat_one : Icons.repeat),
        title: const Text('Repeat'),
        trailing: Text(['Off', 'One', 'All'][s.repeat]),
        onTap: () => s.command('repeat', (s.repeat + 1) % 3),
      ),
      ListTile(
        leading: const Icon(Icons.speaker_group_outlined),
        title: const Text('Audio output'),
        onTap: () => s.command('output'),
      ),
      if (s.current != null)
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Track information'),
          onTap: () {
            Navigator.pop(context);
            trackInfo(context, s.current!);
          },
        ),
    ],
  );
});
void sleepSheet(BuildContext context) => sheet(
  context,
  (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Drift off to your favorites',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      Text(
        'Music pauses when the timer ends, even with the screen off.',
        style: TextStyle(color: context.muted),
      ),
      const SizedBox(height: 16),
      ...[5, 10, 15, 30, 45, 60].map(
        (minutes) => ListTile(
          leading: const Icon(Icons.bedtime_outlined),
          title: Text('$minutes minutes'),
          onTap: () {
            context.music.command('sleep', minutes);
            Navigator.pop(context);
          },
        ),
      ),
      ListTile(
        leading: const Icon(Icons.timer_off_outlined),
        title: const Text('Turn off timer'),
        onTap: () {
          context.music.command('sleep', 0);
          Navigator.pop(context);
        },
      ),
    ],
  ),
);
void speedSheet(BuildContext context) => sheet(
  context,
  (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Your pace', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      ...[.5, .75, 1.0, 1.25, 1.5, 1.75, 2.0].map(
        (speed) => ListTile(
          title: Text('$speed×${speed == 1 ? ' · Original' : ''}'),
          trailing: context.music.speed == speed
              ? Icon(Icons.check_rounded, color: context.accent)
              : null,
          onTap: () => context.music.command('speed', speed),
        ),
      ),
    ],
  ),
);

class QueuePage extends StatelessWidget {
  const QueuePage({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: context.music,
    builder: (context, _) {
      final s = context.music;
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              PageHeader(
                'Up next',
                back: true,
                trailing: TextButton(
                  onPressed: () => s.command('clear'),
                  child: const Text('Clear'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Eyebrow('${s.queueIds.length} tracks · On this device'),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Shuffle queue',
                      onPressed: () => s.command('shuffle', !s.shuffle),
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: s.shuffle ? context.accent : context.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: s.queueIds.isEmpty
                    ? const EmptyState(
                        'A little room for more',
                        'Play a song or add tracks from your library.',
                        icon: Icons.queue_music_rounded,
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
                        buildDefaultDragHandles: false,
                        itemCount: s.queueIds.length,
                        onReorderItem: (oldIndex, newIndex) =>
                            s.command('move', [oldIndex, newIndex]),
                        itemBuilder: (context, i) {
                          final t = s.byId(s.queueIds[i]);
                          return Material(
                            key: ValueKey('$i-${s.queueIds[i]}'),
                            color: Colors.transparent,
                            child: t == null
                                ? ListTile(
                                    title: const Text('Unavailable track'),
                                    trailing: IconButton(
                                      tooltip: 'Remove',
                                      onPressed: () => s.command('remove', i),
                                      icon: const Icon(Icons.close),
                                    ),
                                  )
                                : Row(
                                    children: [
                                      ReorderableDragStartListener(
                                        index: i,
                                        child: const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Icon(
                                            Icons.drag_handle_rounded,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: TrackTile(
                                          t,
                                          onTap: () => s.command('jump', i),
                                          trailing: IconButton(
                                            tooltip: 'Remove from queue',
                                            onPressed: () =>
                                                s.command('remove', i),
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class LyricsPage extends StatelessWidget {
  const LyricsPage({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: context.music,
    builder: (context, _) {
      final s = context.music, t = s.current;
      final lines = parseLyrics(t?.lyrics ?? '');
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const PageHeader('Lyrics', back: true),
              if (t != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Artwork(track: t, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${t.title}\n${t.artist}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: (t?.lyrics.isEmpty ?? true)
                    ? EmptyState(
                        'The words aren’t here yet',
                        'No local lyrics are available for this track. Import a matching .lrc or .txt file to read along.',
                        icon: Icons.lyrics_outlined,
                        action: t == null
                            ? null
                            : FilledButton.icon(
                                onPressed: () async {
                                  final text = await s.command('pickLyrics');
                                  if (text is String && text.isNotEmpty) {
                                    final i = s.tracks.indexWhere(
                                      (x) => x.id == t.id,
                                    );
                                    if (i >= 0) {
                                      s.tracks[i] = s.tracks[i].copy(
                                        lyrics: text,
                                      );
                                      s.changed();
                                    }
                                  }
                                },
                                icon: const Icon(Icons.file_open_outlined),
                                label: const Text('Import local lyrics'),
                              ),
                      )
                    : lines.isEmpty
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          t!.lyrics,
                          style: TextStyle(
                            fontSize: 23,
                            height: 1.8,
                            fontWeight: FontWeight.w600,
                            color: context.ink,
                          ),
                        ),
                      )
                    : ValueListenableBuilder<int>(
                        valueListenable: s.position,
                        builder: (context, position, _) {
                          var active = -1;
                          for (var i = 0; i < lines.length; i++) {
                            if (lines[i].milliseconds <= position) active = i;
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(28, 32, 28, 50),
                            itemCount: lines.length,
                            itemBuilder: (context, i) => InkWell(
                              onTap: () =>
                                  s.command('seek', lines[i].milliseconds),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: AnimatedDefaultTextStyle(
                                  duration: context.motion(200),
                                  style: TextStyle(
                                    fontFamily: 'Jakarta',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                    color: i == active
                                        ? context.ink
                                        : context.muted.withValues(alpha: .46),
                                  ),
                                  child: Text(lines[i].text),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Previous',
                      onPressed: () => s.command('previous'),
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                    TextButton.icon(
                      onPressed: s.togglePlayback,
                      icon: Icon(
                        s.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(s.playing ? 'Pause' : 'Play'),
                    ),
                    IconButton(
                      tooltip: 'Next',
                      onPressed: () => s.command('next'),
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
