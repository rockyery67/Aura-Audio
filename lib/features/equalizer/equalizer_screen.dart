part of '../../presentation/screens.dart';

class EqualizerPage extends StatelessWidget {
  const EqualizerPage({super.key, this.standalone = false});
  final bool standalone;
  @override
  Widget build(BuildContext context) {
    Widget body() {
      final s = context.music;
      return ListView(
        key: const PageStorageKey('equalizer'),
        padding: EdgeInsets.only(bottom: standalone ? 30 : 190),
        children: [
          PageHeader(
            'Equalizer',
            back: standalone,
            trailing: IconButton(
              tooltip: 'Reset equalizer',
              onPressed: () => s.selectPreset('Flat'),
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (s.current != null)
                  Panel(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Artwork(track: s.current, size: 42),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Eyebrow('●  Tuning target', color: context.cyan),
                              Text(
                                s.current!.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                s.current!.artist,
                                style: TextStyle(
                                  color: context.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Eyebrow('Native DSP'),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('DSP studio engine'),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Acoustic Sculptor EQ',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Switch(
                            value: s.eqEnabled,
                            onChanged: (v) {
                              s.eqEnabled = v;
                              s.eqChanged();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Eyebrow(
                        s.eqEnabled
                            ? '●  Active · ${frequencyValues.where((f) => f < s.sampleRate / 2).length} native peaking filters'
                            : 'Bypassed · Original audio',
                        color: s.eqEnabled ? context.cyan : context.muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('Frequency response · actual filters'),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 170,
                        width: double.infinity,
                        child: TweenAnimationBuilder<List<double>>(
                          tween: ResponseTween(end: s.response),
                          duration: context.motion(160),
                          builder: (context, values, _) => CustomPaint(
                            painter: ResponsePainter(
                              values,
                              context.accent,
                              context.cyan,
                              context.muted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FrequencyAxis(sampleRate: s.sampleRate),
                      const SizedBox(height: 10),
                      Text(
                        'Includes preamp and ${s.headroom.toStringAsFixed(1)} dB automatic headroom.',
                        style: TextStyle(color: context.muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Panel(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 19,
                            color: context.accent,
                          ),
                          const SizedBox(width: 9),
                          const Expanded(
                            child: Text(
                              'Preamp level',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${s.preamp >= 0 ? '+' : ''}${s.preamp.toStringAsFixed(1)} dB',
                            style: TextStyle(
                              fontFamily: 'Mono',
                              fontSize: 11,
                              color: context.accent,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: s.preamp,
                        min: -12,
                        max: 12,
                        divisions: 48,
                        label: '${s.preamp.toStringAsFixed(1)} dB',
                        onChanged: s.eqEnabled
                            ? (v) {
                                s.preamp = v;
                                s.preset = 'Custom';
                                s.eqChanged();
                              }
                            : null,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '−12 dB',
                            style: TextStyle(
                              fontFamily: 'Mono',
                              fontSize: 9,
                              color: context.muted,
                            ),
                          ),
                          Text(
                            '0 dB · Unity',
                            style: TextStyle(
                              fontFamily: 'Mono',
                              fontSize: 9,
                              color: context.muted,
                            ),
                          ),
                          Text(
                            '+12 dB',
                            style: TextStyle(
                              fontFamily: 'Mono',
                              fontSize: 9,
                              color: context.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SectionTitle(
                  'Acoustic presets',
                  action: 'MANAGE',
                  onTap: () => presetSheet(context),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [...builtInPresets.keys, ...s.customPresets.keys]
                        .map(
                          (name) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(name),
                              selected: s.preset == name,
                              onSelected: (_) => s.selectPreset(name),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 18),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '10-Band Graphic Console',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Q 1.4 · ±12 dB · Scroll to reach every band',
                        style: TextStyle(fontSize: 10, color: context.muted),
                      ),
                      if (s.sampleRate <= 32000)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Bands above the audio’s Nyquist frequency are unavailable (${s.sampleRate} Hz audio).',
                            style: TextStyle(
                              fontSize: 10,
                              color: context.muted,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(
                            10,
                            (i) => SizedBox(
                              width: 52,
                              child: Column(
                                children: [
                                  Text(
                                    '${s.gains[i] >= 0 ? '+' : ''}${s.gains[i].toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontFamily: 'Mono',
                                      fontSize: 10,
                                      color: context.accent,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Semantics(
                                    label:
                                        '${frequencies[i]} hertz equalizer gain',
                                    child: SizedBox(
                                      height: 190,
                                      width: 48,
                                      child: RotatedBox(
                                        quarterTurns: 3,
                                        child: Slider(
                                          value: s.gains[i],
                                          min: -12,
                                          max: 12,
                                          divisions: 48,
                                          label:
                                              '${frequencies[i]} Hz: ${s.gains[i]} dB',
                                          onChanged:
                                              s.eqEnabled &&
                                                  frequencyValues[i] <
                                                      s.sampleRate / 2
                                              ? (v) {
                                                  s.gains[i] = v;
                                                  s.preset = 'Custom';
                                                  s.eqChanged();
                                                }
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${frequencies[i]}${i < 5 ? ' Hz' : 'Hz'}${frequencyValues[i] >= s.sampleRate / 2 ? '\nN/A' : ''}',
                                    style: TextStyle(
                                      fontFamily: 'Mono',
                                      fontSize: 9,
                                      color: context.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          final name = await askName(
                            context,
                            'Save custom preset',
                          );
                          if (name != null) {
                            s.savePreset(name);
                          }
                        },
                        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                        label: const Text('Save preset'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          s.eqEnabled = !s.eqEnabled;
                          s.eqChanged();
                        },
                        icon: const Icon(
                          Icons.power_settings_new_rounded,
                          size: 18,
                        ),
                        label: Text(s.eqEnabled ? 'Bypass EQ' : 'Enable EQ'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Native processing stays active during navigation, background listening, and theme changes. No decorative audio visualizer is used.',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.muted,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return standalone
        ? AnimatedBuilder(
            animation: context.music,
            builder: (context, _) => Scaffold(body: SafeArea(child: body())),
          )
        : body();
  }
}

class FrequencyAxis extends StatelessWidget {
  const FrequencyAxis({super.key, required this.sampleRate});
  final int sampleRate;
  @override
  Widget build(BuildContext context) {
    final max = math.min(20000.0, sampleRate * .495);
    final values = [20.0, 100.0, 1000.0, max];
    return LayoutBuilder(
      builder: (context, bounds) => SizedBox(
        height: 16,
        child: Stack(
          children: values
              .map(
                (f) => Positioned(
                  left:
                      (math.log(f / 20) / math.log(max / 20) * bounds.maxWidth -
                              15)
                          .clamp(0, bounds.maxWidth - 34),
                  width: 34,
                  child: Text(
                    f >= 1000
                        ? '${(f / 1000).toStringAsFixed(f % 1000 == 0 ? 0 : 1)}k'
                        : '${f.toInt()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Mono',
                      fontSize: 9,
                      color: context.muted,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class ResponseTween extends Tween<List<double>> {
  ResponseTween({super.begin, super.end});
  @override
  List<double> lerp(double t) {
    final a = begin ?? end!;
    final b = end!;
    return List.generate(b.length, (i) => a[i] + (b[i] - a[i]) * t);
  }
}

class ResponsePainter extends CustomPainter {
  ResponsePainter(this.values, this.accent, this.cyan, this.muted);
  final List<double> values;
  final Color accent, cyan, muted;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = muted.withValues(alpha: .15)
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = i * size.height / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (var i = 0; i < 7; i++) {
      final x = i * size.width / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    final minDb = math.min(
      -12.0,
      values.isEmpty ? -12.0 : values.reduce(math.min) - 3,
    );
    double y(double db) => (12 - db) / (12 - minDb) * size.height;
    for (final db in [12.0, 0.0, minDb]) {
      final label = TextPainter(
        text: TextSpan(
          text: '${db.toStringAsFixed(0)} dB',
          style: TextStyle(fontFamily: 'Mono', fontSize: 9, color: muted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(4, y(db).clamp(0, size.height - 12)));
    }
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final point = Offset(
        i / (values.length - 1) * size.width,
        y(values[i]).clamp(0, size.height),
      );
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: .22), cyan.withValues(alpha: .01)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [const Color(0xffffb95f), accent, cyan],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(ResponsePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.accent != accent;
}

void presetSheet(BuildContext context) => sheet(
  context,
  (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Find your sound',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      ...[...builtInPresets.keys, ...context.music.customPresets.keys].map(
        (name) => ListTile(
          leading: Icon(
            context.music.preset == name
                ? Icons.check_circle_rounded
                : Icons.equalizer_rounded,
            color: context.accent,
          ),
          title: Text(name),
          subtitle: Text(
            builtInPresets.containsKey(name)
                ? 'Built-in preset'
                : 'Saved on this device',
          ),
          onTap: () => context.music.selectPreset(name),
          trailing: builtInPresets.containsKey(name)
              ? null
              : PopupMenuButton<String>(
                  onSelected: (action) async {
                    final s = context.music;
                    if (action == 'Delete') {
                      s.deletePreset(name);
                    } else {
                      final next = await askName(
                        context,
                        'Rename preset',
                        initial: name,
                      );
                      if (next != null) {
                        s.renamePreset(name, next);
                      }
                    }
                  },
                  itemBuilder: (_) => ['Rename', 'Delete']
                      .map((v) => PopupMenuItem(value: v, child: Text(v)))
                      .toList(),
                ),
        ),
      ),
    ],
  ),
);
