import 'package:flutter/material.dart';

import 'application/music_store.dart';
import 'presentation/theme.dart';
import 'presentation/components.dart';
import 'presentation/screens.dart';

class AuraApp extends StatefulWidget {
  const AuraApp({super.key, required this.store});
  final MusicStore store;
  @override
  State<AuraApp> createState() => _AuraAppState();
}

class _AuraAppState extends State<AuraApp> with WidgetsBindingObserver {
  String _theme = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.store.addListener(_changed);
  }

  void _changed() {
    final s = widget.store;
    final key =
        '${s.initialized}|${s.appearance}|${s.reducedMotion}|${s.glass}|${s.reducedTransparency}';
    if (key != _theme) {
      _theme = key;
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      widget.store.save();
    }
    if (state == AppLifecycleState.resumed) widget.store.validate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.store.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StoreScope(
    store: widget.store,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aura Audio',
      theme: auraTheme(Brightness.light),
      darkTheme: auraTheme(Brightness.dark),
      themeMode: switch (widget.store.appearance) {
        'Light' => ThemeMode.light,
        'Dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      themeAnimationDuration: Duration(
        milliseconds:
            widget.store.reducedMotion ||
                WidgetsBinding
                    .instance
                    .platformDispatcher
                    .accessibilityFeatures
                    .disableAnimations
            ? 0
            : 260,
      ),
      home: widget.store.initialized
          ? const MainShell()
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: context.music,
    builder: (context, _) {
      final s = context.music;
      if (s.error.isNotEmpty) {
        final message = s.error;
        s.error = '';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 6),
              ),
            );
          }
        });
      }
      final content = s.welcomed
          ? Scaffold(
              body: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    if (s.glass && !s.reducedTransparency)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(-.7, -.7),
                                radius: 1.3,
                                colors: [
                                  context.accent.withValues(alpha: .085),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    IndexedStack(
                      index: tab,
                      children: [
                        HomeScreen(onLibrary: () => setState(() => tab = 1)),
                        const LibraryScreen(),
                        const SearchScreen(),
                        const EqualizerPage(),
                        const SettingsScreen(),
                      ],
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          MediaQuery.paddingOf(context).bottom + 10,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (s.current != null) ...[
                              const _MiniPlayer(),
                              const SizedBox(height: 8),
                            ],
                            _Dock(
                              tab: tab,
                              select: (value) => setState(() => tab = value),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const WelcomeScreen();
      return Stack(
        children: [
          content,
          if (s.scanning) ...[
            const ModalBarrier(dismissible: false, color: Colors.black54),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Material(
                  color: Colors.transparent,
                  child: Panel(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 22),
                        Text(
                          'Finding your rhythm',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${s.scanCount} tracks found',
                          style: TextStyle(color: context.accent),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.scanName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: context.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();
  @override
  Widget build(BuildContext context) {
    final s = context.music;
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < -100) {
          openPage(context, const NowPlayingPage());
        }
      },
      onTap: () => openPage(context, const NowPlayingPage()),
      child: Panel(
        blur: true,
        radius: 24,
        padding: const EdgeInsets.fromLTRB(9, 8, 6, 8),
        child: Row(
          children: [
            Artwork(track: s.current, size: 44, radius: 14, hero: true),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.current!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    s.current!.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: context.muted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: s.playing ? 'Pause mini player' : 'Play mini player',
              onPressed: s.togglePlayback,
              style: IconButton.styleFrom(
                backgroundColor: context.accent.withValues(alpha: .18),
              ),
              icon: Icon(
                s.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: context.accent,
              ),
            ),
            IconButton(
              tooltip: 'Next mini player',
              onPressed: () => s.command('next'),
              icon: const Icon(Icons.skip_next_rounded, size: 23),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({required this.tab, required this.select});
  final int tab;
  final ValueChanged<int> select;
  @override
  Widget build(BuildContext context) => Panel(
    blur: true,
    radius: 32,
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
    child: Row(
      children: List.generate(5, (i) {
        final selected = tab == i;
        final label = ['Home', 'Library', 'Search', 'EQ', 'Settings'][i];
        final icon = [
          Icons.home_outlined,
          Icons.library_music_outlined,
          Icons.search_rounded,
          Icons.equalizer_rounded,
          Icons.settings_outlined,
        ][i];
        return Expanded(
          child: Semantics(
            selected: selected,
            button: true,
            label: label,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: () => select(i),
              child: AnimatedContainer(
                duration: context.motion(200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? context.accent.withValues(alpha: .11)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 21,
                      color: selected ? context.accent : context.muted,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        color: selected ? context.accent : context.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
}
