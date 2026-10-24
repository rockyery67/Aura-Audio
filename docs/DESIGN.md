# Design audit and implementation

Reference directory: `stitch_liquid_glass_music_player/`. Inspected the exported HTML/CSS, Aura Resonance token board, Home, Liquid Glass Now Playing, both equalizer references, Appearance, and all supplied image assets before building. The three full-resolution album covers are bundled for onboarding and the same-song theme previews. Runtime library artwork comes from actual local audio metadata.

## Compact system board

| Foundation | Implemented token |
|---|---|
| Dark canvas / text | `#121318` / `#E9E5EF` |
| Light canvas / text | `#F5F3F9` / `#24212C` |
| Dark / light accent | `#D0BCFF` / `#7041BF` |
| Dark / light cyan | `#4CD7F6` / `#007C92` |
| Muted dark / light text | `#B9B2C6` / `#686173` |
| Display / heading / body | Bundled Jakarta headings, Inter body, 29 / 24 / 13 px |
| Technical labels | Bundled JetBrains Mono, 9–11 px |
| Margins and rhythm | 20 px side margins; 4, 8, 12, 16, 20, 24 px spacing |
| Shapes | 12–14 px thumbnails; 22–30 px album/panel corners; capsule dock |
| Glass surface | Elevated tint at 78% opacity, 9% highlight rim; localized 18 px backdrop blur |
| Classic surface | Opaque dark/light panels; subtle separators, same component geometry |
| Touch targets | Standard 44+ px icon actions; 52 px equalizer band columns |

Shared native Flutter components: `Panel`, `Artwork`, `BrandMark`, `PageHeader`, `TrackTile`, `SectionTitle`, `SeekControl`, `Transport`, `EmptyState`, mini-player, floating dock, and modal sheets.

Selected states use accent fill/rim and explicit icons. Pressed states use Material ink feedback. Bypassed EQ disables sliders while retaining values. Scanning uses an indeterminate progress panel with a live track count and filename. Empty library, search, playlists, history, queue, and lyrics have dedicated honest states. Missing files are visibly dimmed and marked unavailable. No screenshot is used as the interface, and there is no WebView.

## Reference comparison

The rendered screen set in `screenshots/` covers Home, Library, Now Playing, Equalizer, Queue, and Settings in Liquid Glass Dark/Light and Classic Dark/Light. Reference proportions, floating dock/mini-player, rounded artwork, violet/cyan/amber hierarchy, monospace audio labels, and restrained material surfaces are carried into the app. Welcome, detail, playlist, search, lyrics, and permission states extend those same components.

The reference's invented quality claims and device names were replaced with actual local file formats, current DSP configuration, and system output controls. The EQ response is the real native filter response, including automatic headroom. Its shape is therefore deliberately different from the reference's decorative curve.

Screenshot review exposed and fixed narrow-width text overflow, hidden ListTile ink, and stale reused mini-player/EQ views. State propagation now uses one `InheritedNotifier`; a regression test checks that reused widgets update when the current track and playback state change.

## Motion

Artwork uses a shared Hero between the mini-player and expanded player. Route, sheet, play/pause, dock, artwork, curve, and theme transitions use short ease-out changes. Audio position is always supplied by Media3. Reduced motion and system animation preferences shorten or remove motion; reduced transparency removes blur and ambient backgrounds. No continuously flashing visualizer or simulated audio analysis is used.

The emulator screenshots demonstrate rendering and interaction, not physical-device GPU performance. A device profile, battery/endurance run, and TalkBack acceptance remain follow-up checks; see `VERIFICATION.md`.
