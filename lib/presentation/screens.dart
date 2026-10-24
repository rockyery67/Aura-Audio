import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/models.dart';
import 'components.dart';
import 'theme.dart';

part '../features/library/library_screens.dart';
part '../features/player/player_screens.dart';
part '../features/playlists/playlist_screens.dart';
part '../features/equalizer/equalizer_screen.dart';
part '../features/settings/settings_screens.dart';

void openPage(BuildContext context, Widget page) {
  final reduced = context.reduceMotion;
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: Duration(milliseconds: reduced ? 0 : 320),
      reverseTransitionDuration: Duration(milliseconds: reduced ? 0 : 240),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .035), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        ),
      ),
    ),
  );
}

Future<void> sheet(
  BuildContext context,
  Widget Function(BuildContext) builder,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  sheetAnimationStyle: context.reduceMotion ? AnimationStyle.noAnimation : null,
  builder: (context) => AnimatedBuilder(
    animation: context.music,
    builder: (context, _) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .8,
        ),
        child: SingleChildScrollView(child: builder(context)),
      ),
    ),
  ),
);

void importSheet(BuildContext context) => sheet(
  context,
  (context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Bring your music home',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      Text(
        'Choose music stored on this device. Your files stay where they are, and your library stays private.',
        style: TextStyle(color: context.muted),
      ),
      const SizedBox(height: 16),
      ListTile(
        leading: Icon(Icons.folder_open_rounded, color: context.accent),
        title: const Text('Choose music folder'),
        subtitle: const Text('Keep access across app restarts'),
        onTap: () {
          Navigator.pop(context);
          context.music.scan('pickFolder');
        },
      ),
      ListTile(
        leading: Icon(Icons.audio_file_outlined, color: context.cyan),
        title: const Text('Import audio files'),
        subtitle: const Text('Select one or more local files'),
        onTap: () {
          Navigator.pop(context);
          context.music.scan('pickFiles');
        },
      ),
      ListTile(
        leading: Icon(Icons.manage_search_rounded, color: context.accent),
        title: const Text('Scan device music'),
        subtitle: const Text('Requires access to music and audio'),
        onTap: () {
          Navigator.pop(context);
          context.music.scan('scanDevice');
        },
      ),
    ],
  ),
);
