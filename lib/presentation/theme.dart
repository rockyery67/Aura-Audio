import 'package:flutter/material.dart';

import '../application/music_store.dart';

class StoreScope extends InheritedNotifier<MusicStore> {
  const StoreScope({super.key, required MusicStore store, required super.child})
    : super(notifier: store);
  MusicStore get store => notifier!;
  static MusicStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.store;
}

extension AuraContext on BuildContext {
  MusicStore get music => StoreScope.of(this);
  bool get reduceMotion =>
      music.reducedMotion || MediaQuery.disableAnimationsOf(this);
  Duration motion(int milliseconds) =>
      Duration(milliseconds: reduceMotion ? 0 : milliseconds);
  bool get dark => Theme.of(this).brightness == Brightness.dark;
  Color get ink => dark ? const Color(0xffe9e5ef) : const Color(0xff24212c);
  Color get muted => dark ? const Color(0xffb9b2c6) : const Color(0xff686173);
  Color get accent => dark ? const Color(0xffd0bcff) : const Color(0xff7041bf);
  Color get cyan => dark ? const Color(0xff4cd7f6) : const Color(0xff007c92);
  Color get surface => dark ? const Color(0xff202127) : const Color(0xffffffff);
}

ThemeData auraTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xffa078ff),
        brightness: brightness,
      ).copyWith(
        surface: dark ? const Color(0xff121318) : const Color(0xfff5f3f9),
        primary: dark ? const Color(0xffd0bcff) : const Color(0xff7041bf),
      );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'Inter',
    splashFactory: InkSparkle.splashFactory,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Jakarta',
        fontSize: 29,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Jakarta',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -.8,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Jakarta',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -.5,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Jakarta',
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(fontSize: 13, height: 1.5),
      bodySmall: TextStyle(fontSize: 11, height: 1.5),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 4,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 18),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xff24242c) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? const Color(0xff1e1f26) : const Color(0xfffaf8ff),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      showDragHandle: true,
    ),
    dividerColor: dark ? Colors.white10 : Colors.black12,
  );
}
