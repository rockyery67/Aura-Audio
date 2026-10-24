part of '../../presentation/screens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.music;
    return ListView(
      padding: const EdgeInsets.only(bottom: 190),
      children: [
        const PageHeader('Settings'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('Make room for your sound'),
              const SizedBox(height: 6),
              Text(
                'A player that feels like you.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SectionTitle('Your library'),
              Panel(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.folder_open_outlined,
                        color: context.accent,
                      ),
                      title: const Text('Music folders'),
                      subtitle: Text(
                        '${s.sources.length} selected folders · ${s.tracks.length} tracks',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => foldersSheet(context),
                    ),
                    ListTile(
                      leading: Icon(Icons.sync_rounded, color: context.cyan),
                      title: const Text('Rescan local library'),
                      subtitle: const Text(
                        'Find new music and reconnect files',
                      ),
                      onTap: () => s.scan('scan'),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.playlist_play_rounded,
                        color: context.accent,
                      ),
                      title: const Text('Playlists & collections'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => openPage(context, const PlaylistsPage()),
                    ),
                  ],
                ),
              ),
              const SectionTitle('Listening & appearance'),
              Panel(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.palette_outlined,
                        color: context.accent,
                      ),
                      title: const Text('Appearance'),
                      subtitle: Text(
                        '${s.glass ? 'Liquid Glass' : 'Classic'} · ${s.appearance}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => openPage(context, const AppearancePage()),
                    ),
                    ListTile(
                      leading: Icon(Icons.tune_rounded, color: context.cyan),
                      title: const Text('Playback preferences'),
                      subtitle: const Text(
                        'Speed, repeat, output, and sleep timer',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => playbackExtras(context),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.equalizer_rounded,
                        color: context.accent,
                      ),
                      title: const Text('Equalizer presets'),
                      subtitle: Text(s.preset),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => presetSheet(context),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.accessibility_new_rounded,
                        color: context.accent,
                      ),
                      title: const Text('Accessibility'),
                      subtitle: const Text('Motion and transparency'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => openPage(context, const AppearancePage()),
                    ),
                  ],
                ),
              ),
              const SectionTitle('Good to know'),
              Panel(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.storage_outlined,
                        color: context.accent,
                      ),
                      title: const Text('Storage'),
                      subtitle: Text(
                        '${(s.tracks.fold<int>(0, (sum, t) => sum + t.size) / 1048576).toStringAsFixed(1)} MB indexed · Originals stay in place',
                      ),
                      onTap: () => sheet(
                        context,
                        (context) => const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your files stay yours',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aura stores local file references, resized embedded artwork, and your preferences in private app storage. Original audio is never uploaded, copied, moved, or deleted. Uninstalling Aura removes its settings, playlists, and artwork cache. Your music stays in its original folders.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.help_outline_rounded,
                        color: context.accent,
                      ),
                      title: const Text('Help & about'),
                      onTap: () => sheet(
                        context,
                        (context) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aura Audio',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            const Eyebrow('Version 1.0 · Android'),
                            const SizedBox(height: 18),
                            const Text(
                              'Choose a folder for durable access without whole-library permission, import individual audio files, or allow music access to scan device audio.\n\nSupported containers include MP3, M4A/AAC, FLAC, WAV, Ogg/Opus, 3GP, and AMR. Actual decoding depends on your Android device.\n\nMissing music? Reconnect your storage and rescan. For revoked permissions, select the folder again or use Scan device music.\n\nLyrics are read from matching .lrc/.txt files in selected folders, or imported manually. No lyrics are fetched online.\n\nAudio output uses Android’s system controls. Bluetooth and USB options depend on connected hardware.\n\nNative equalizer processing uses 10 peaking filters, smoothed changes, and automatic headroom. No spatial audio or lossless passthrough is claimed.',
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => showLicensePage(
                                context: context,
                                applicationName: 'Aura Audio',
                              ),
                              child: const Text('Open-source licenses'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Column(
                  children: [
                    const BrandMark(size: 28),
                    const SizedBox(height: 10),
                    Text(
                      'Always offline. Always yours.',
                      style: TextStyle(fontSize: 11, color: context.muted),
                    ),
                    const SizedBox(height: 4),
                    const Eyebrow('Aura Audio 1.0'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void foldersSheet(BuildContext context) => sheet(
  context,
  (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Your music lives here',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      if (context.music.sources.isEmpty)
        Text(
          'No folders selected yet. Device music and individual imports can still be in your library.',
          style: TextStyle(color: context.muted),
        ),
      ...context.music.sources.map(
        (uri) => ListTile(
          leading: const Icon(Icons.folder_open_rounded),
          title: Text(
            Uri.decodeFull(uri).split('/').last,
            style: const TextStyle(fontSize: 12),
          ),
          subtitle: const Text('Persisted local read access'),
        ),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () {
          Navigator.pop(context);
          context.music.scan('pickFolder');
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Choose music folder'),
      ),
      TextButton(
        onPressed: () {
          Navigator.pop(context);
          context.music.scan('scanDevice');
        },
        child: const Text('Scan device music'),
      ),
    ],
  ),
);

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: context.music,
    builder: (context, _) {
      final s = context.music;
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 36),
            children: [
              const PageHeader('Appearance', back: true),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(
                      'Your player. Your perspective.',
                      color: context.cyan,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find your atmosphere.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ThemePreview(
                            glass: true,
                            selected: s.glass,
                            onTap: () {
                              s.glass = true;
                              s.changed();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ThemePreview(
                            glass: false,
                            selected: !s.glass,
                            onTap: () {
                              s.glass = false;
                              s.changed();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SectionTitle('Color appearance'),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'System', label: Text('System')),
                          ButtonSegment(value: 'Light', label: Text('Light')),
                          ButtonSegment(value: 'Dark', label: Text('Dark')),
                        ],
                        selected: {s.appearance},
                        onSelectionChanged: (v) {
                          s.appearance = v.first;
                          s.changed();
                        },
                      ),
                    ),
                    const SectionTitle('A little more you'),
                    Panel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            secondary: Icon(
                              Icons.color_lens_outlined,
                              color: context.accent,
                            ),
                            title: const Text(
                              'Artwork accents',
                              style: TextStyle(fontSize: 14),
                            ),
                            subtitle: const Text(
                              'Use local artwork colors in Now Playing',
                              style: TextStyle(fontSize: 11),
                            ),
                            value: s.artworkAccent,
                            onChanged: (v) {
                              s.artworkAccent = v;
                              s.changed();
                            },
                          ),
                          SwitchListTile(
                            secondary: Icon(
                              Icons.blur_off_rounded,
                              color: context.accent,
                            ),
                            title: const Text(
                              'Reduced transparency',
                              style: TextStyle(fontSize: 14),
                            ),
                            subtitle: const Text(
                              'Opaque panels and fewer effects',
                              style: TextStyle(fontSize: 11),
                            ),
                            value: s.reducedTransparency,
                            onChanged: (v) {
                              s.reducedTransparency = v;
                              s.changed();
                            },
                          ),
                          SwitchListTile(
                            secondary: Icon(
                              Icons.animation_rounded,
                              color: context.accent,
                            ),
                            title: const Text(
                              'Reduced motion',
                              style: TextStyle(fontSize: 14),
                            ),
                            subtitle: const Text(
                              'Instant transitions, gentle feedback',
                              style: TextStyle(fontSize: 11),
                            ),
                            value: s.reducedMotion,
                            onChanged: (v) {
                              s.reducedMotion = v;
                              s.changed();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Both themes share the same layout and controls. Your music, queue, and sound settings keep going as you switch.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.7,
                        color: context.muted,
                      ),
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

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({
    required this.glass,
    required this.selected,
    required this.onTap,
  });
  final bool glass, selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: glass ? 'Liquid Glass theme' : 'Classic theme',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: context.motion(200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            width: 1.5,
            color: selected
                ? context.accent
                : context.ink.withValues(alpha: .06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 148,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: glass
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xff51426d),
                          Color(0xff2c505a),
                          Color(0xff23212f),
                        ],
                      )
                    : null,
                color: glass
                    ? null
                    : context.dark
                    ? const Color(0xff121318)
                    : const Color(0xffeeebf3),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Artwork(
                        asset: 'assets/art/ethereal.png',
                        size: 74,
                        radius: 13,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Cosmic Drift',
                        style: TextStyle(fontSize: 9, color: Color(0xffd0bcff)),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: 70,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: const Color(0xffd0bcff),
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        size: 20,
                        color: Color(0xffd0bcff),
                      ),
                    ],
                  ),
                  if (selected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: context.accent,
                        size: 21,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            Text(
              glass ? 'Liquid Glass' : 'Classic',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              glass
                  ? 'Luminous. Layered.\nA little extraordinary.'
                  : 'Clean. Calm.\nBeautifully familiar.',
              style: TextStyle(fontSize: 10, height: 1.6, color: context.muted),
            ),
          ],
        ),
      ),
    ),
  );
}
