import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/models.dart';
import 'theme.dart';

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.blur = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;
  @override
  Widget build(BuildContext context) {
    final glass = context.music.glass && !context.music.reducedTransparency;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.surface.withValues(alpha: glass ? .78 : 1),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: context.ink.withValues(alpha: glass ? .09 : .035),
        ),
        boxShadow: [
          if (glass)
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
    if (!glass || !blur) return content;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: content,
      ),
    );
  }
}

class Artwork extends StatelessWidget {
  const Artwork({
    super.key,
    this.track,
    this.path,
    this.size = 52,
    this.radius = 14,
    this.asset,
    this.hero = false,
  });
  final Track? track;
  final String? path, asset;
  final double size, radius;
  final bool hero;
  @override
  Widget build(BuildContext context) {
    final source = path ?? track?.artwork ?? '';
    final placeholder = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff40305d), Color(0xff172631), Color(0xff13141c)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.album_outlined,
          color: const Color(0xffd0bcff),
          size: size * .4,
        ),
      ),
    );
    final image = asset != null
        ? Image.asset(
            asset!,
            fit: BoxFit.cover,
            cacheWidth: (size * 2).round().clamp(100, 800),
          )
        : source.isNotEmpty
        ? Image.file(
            File(source),
            fit: BoxFit.cover,
            cacheWidth: (size * 2).round().clamp(100, 800),
            errorBuilder: (_, _, _) => placeholder,
          )
        : placeholder;
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: image),
    );
    return hero && track != null
        ? Hero(tag: 'art-${track!.id}', child: content)
        : content;
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 34});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: context.accent.withValues(alpha: .65)),
      boxShadow: [
        BoxShadow(color: context.accent.withValues(alpha: .12), blurRadius: 14),
      ],
    ),
    child: Icon(
      Icons.graphic_eq_rounded,
      size: size * .6,
      color: context.accent,
    ),
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontFamily: 'Mono',
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.3,
      color: color ?? context.accent,
    ),
  );
}

class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.trailing, this.back = false});
  final String title;
  final Widget? trailing;
  final bool back;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 16, 18),
    child: Row(
      children: [
        if (back)
          IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Go back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          )
        else
          const BrandMark(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('Aura Audio'),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action, this.onTap});
  final String text;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          TextButton(
            onPressed: onTap,
            child: Text(action!, style: const TextStyle(fontSize: 11)),
          ),
      ],
    ),
  );
}

class TrackTile extends StatelessWidget {
  const TrackTile(
    this.track, {
    super.key,
    required this.onTap,
    this.trailing,
    this.onMore,
    this.number,
  });
  final Track track;
  final VoidCallback onTap;
  final VoidCallback? onMore;
  final Widget? trailing;
  final int? number;
  @override
  Widget build(BuildContext context) {
    final active = context.music.current?.id == track.id;
    return Opacity(
      opacity: track.missing ? .48 : 1,
      child: Material(
        color: active
            ? context.accent.withValues(alpha: .07)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Row(
              children: [
                if (number != null)
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$number',
                      style: TextStyle(
                        fontFamily: 'Mono',
                        fontSize: 11,
                        color: context.muted,
                      ),
                    ),
                  ),
                Artwork(track: track, size: 46, radius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active ? context.accent : context.ink,
                        ),
                      ),
                      Text(
                        track.missing
                            ? 'File unavailable · rescan to reconnect'
                            : track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: context.muted),
                      ),
                    ],
                  ),
                ),
                if (active)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      context.music.playing
                          ? Icons.graphic_eq
                          : Icons.pause_rounded,
                      size: 17,
                      color: context.cyan,
                    ),
                  ),
                Text(
                  timeLabel(track.duration),
                  style: TextStyle(
                    fontFamily: 'Mono',
                    fontSize: 10,
                    color: context.muted,
                  ),
                ),
                trailing ??
                    IconButton(
                      tooltip: 'Track actions',
                      onPressed: onMore,
                      icon: const Icon(Icons.more_horiz, size: 20),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.title,
    this.subtitle, {
    super.key,
    this.icon = Icons.library_music_outlined,
    this.action,
  });
  final String title, subtitle;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.accent.withValues(alpha: .09),
          ),
          child: Icon(icon, size: 34, color: context.accent),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.muted, height: 1.6),
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

class SeekControl extends StatelessWidget {
  const SeekControl({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.music;
    return ValueListenableBuilder<int>(
      valueListenable: store.position,
      builder: (context, value, _) {
        final duration = store.duration > 0
            ? store.duration
            : store.current?.duration ?? 0;
        return Column(
          children: [
            Slider(
              value: value.toDouble().clamp(
                0,
                duration.toDouble().clamp(1, double.infinity),
              ),
              min: 0,
              max: duration.toDouble().clamp(1, double.infinity),
              label: timeLabel(value),
              onChanged: duration > 0
                  ? (v) => store.command('seek', v.round())
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    timeLabel(value),
                    style: TextStyle(
                      fontFamily: 'Mono',
                      fontSize: 11,
                      color: context.muted,
                    ),
                  ),
                  Text(
                    '-${timeLabel((duration - value).clamp(0, duration))}',
                    style: TextStyle(
                      fontFamily: 'Mono',
                      fontSize: 11,
                      color: context.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class Transport extends StatelessWidget {
  const Transport({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.music;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: 'Shuffle',
          isSelected: s.shuffle,
          onPressed: () => s.command('shuffle', !s.shuffle),
          icon: Icon(
            Icons.shuffle_rounded,
            color: s.shuffle ? context.accent : context.muted,
          ),
        ),
        IconButton(
          tooltip: 'Previous track',
          onPressed: () => s.command('previous'),
          icon: const Icon(Icons.skip_previous_rounded, size: 34),
        ),
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: s.glass
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xffd0bcff), Color(0xff8655dc)],
                  )
                : null,
            color: s.glass ? null : context.accent,
            border: Border.all(
              color: const Color(0xffe9ddff).withValues(alpha: .65),
              width: 2,
            ),
            boxShadow: [
              if (s.glass)
                BoxShadow(
                  color: context.accent.withValues(alpha: .28),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: IconButton(
            tooltip: s.playing ? 'Pause' : 'Play',
            onPressed: s.togglePlayback,
            color: s.glass
                ? Colors.white
                : Theme.of(context).colorScheme.onPrimary,
            icon: AnimatedSwitcher(
              duration: context.motion(180),
              child: Icon(
                s.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey(s.playing),
                size: 38,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next track',
          onPressed: () => s.command('next'),
          icon: const Icon(Icons.skip_next_rounded, size: 34),
        ),
        IconButton(
          tooltip: 'Repeat mode',
          onPressed: () => s.command('repeat', (s.repeat + 1) % 3),
          icon: Icon(
            s.repeat == 1 ? Icons.repeat_one_rounded : Icons.repeat_rounded,
            color: s.repeat > 0 ? context.accent : context.muted,
          ),
        ),
      ],
    );
  }
}

Future<String?> askName(
  BuildContext context,
  String title, {
  String initial = '',
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 60,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Give it a name'),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(context, controller.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  // Dialog route may still animate with its TextField after this future completes.
  Future<void>.delayed(const Duration(seconds: 1), controller.dispose);
  return result;
}
