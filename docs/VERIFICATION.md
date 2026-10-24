# Verification report

Date: 2026-10-22. Primary target: Android. Test surface: Pixel 7 / Android 15 (API 35), x86_64 emulator. No physical phone or headphones were connected.

## Host checks

| Check | Evidence |
|---|---|
| Flutter formatting and analysis | PASS; `docs/analyze.log` shows no issues; formatting unchanged |
| Dart application / layout tests | `docs/flutter-tests.log`; eight tests cover persistence, queue coordination, missing-file selection, preset ownership, LRC parsing, bounded continuous EQ updates, reused widget updates, theme continuity, 390×844 layout, and 320 px / 1.4× text |
| Native DSP tests | `docs/native-tests.log`; six tests cover flat/bypass, real frequency balance, real preamp gain, measured-vs-graphed response, headroom/finite transitions, and unsupported high bands at low sample rates |
| Real native engine integration | `docs/offline-integration.log`; uses Media3, device files, and the actual native processor, not the fake gateway used by unit tests |
| Release build | `docs/build-release.log`; development-signed installable release APK |

## Airplane-mode observations

Airplane mode was explicitly enabled with `adb shell cmd connectivity airplane-mode enable`; `airplane_mode_on` returned `1`, and `wifi_on` returned `0`. The test music consists of three original 90-second multitone MP3 fixtures generated locally by `tools/generate_fixtures.py`. They contain actual title/artist/album/track tags and embedded covers. They are not bundled or silently inserted into the installed app's library.

Observed on the emulator:

- MediaStore scanning found all three tracks with correct metadata, durations, and locally cached embedded artwork.
- The Android folder picker granted access to `Music/AuraValidation`. Rescanning retained three deduplicated entries, preferred durable SAF references, and discovered the matching local LRC file.
- Revoking `READ_MEDIA_AUDIO`, force-stopping, and reopening the app kept the selected folder readable: all three SAF-backed files remained available, and native playback worked. Broad permission is not required for already granted folder access.
- Temporarily moving a fixture out of the scanned collection marked its reference unavailable while retaining all three playlist entries. Restoring the fixture and rescanning recovered it.
- Play/pause, seek to 30 seconds, skip/jump, shuffle, repeat, speed, queue reorder/remove/append, favorites, and playlist/preset persistence were exercised through the real platform gateway.
- Native processor diagnostics confirmed nonzero processed PCM frames and the applied Bass Boost gains on the same ExoPlayer session. Bypass changed that processor's enabled configuration, and the response became flat. Separate numerical tests measured the filter effect and matched the response curve to actual processed samples.
- Theme switching while playing preserved current track, playback position, queue, and native session. Twenty-four screenshots cover six core screens in Liquid Glass and Classic, both Dark and Light.
- Local timed lyrics displayed real sidecar content with timestamped lines. Missing lyrics have an honest unavailable/import state.
- The output action opened Android's actual system audio panel, showing “Play Aura Audio on → This phone” on the available emulator hardware (`system-output.png`). No Bluetooth or USB hardware was connected.
- Android's local media notification displayed the actual song, artist, embedded artwork, seek position, output indicator, and transport controls. `docs/media-notification.png` captures this. Android media commands paused and resumed playback while the app was backgrounded; session dumps showed PAUSED → PLAYING with accurate metadata.
- Force-stop/reopen restored the library, playlist order, theme, EQ preset, queue, and a paused playback state. `docs/restart-home.png` records the restored app. Queue position checkpoints can be up to five seconds old after abrupt process termination.

The final release APK was installed and checked separately. Its manifest has **no INTERNET permission** (`release-permissions.txt`). With no Flutter Activity present, the media service stayed PLAYING and accepted Next, changing from Monolith Reflections to Cosmic Drift. On recreating the Activity, Cosmic Drift was first in listening history (`release-lifecycle.json`, `release-history-ui.txt`, `background-history.png`). Thus background history was checked after the UI engine was actually destroyed, not merely covered by another window.

A temporary secure emulator keyguard was enabled. While keyguard reported `showing=true`, `secure=true`, Android media commands changed PAUSED to PLAYING with correct metadata (`release-keyguard.txt`). Visual lock-screen acceptance remains limited: the emulator captured a blank lock-screen surface. The temporary credential was cleared. A subsequent emulator reboot recovered the normal interface and preserved all three library tracks, favorites, playlist, theme, EQ, and a paused restored queue. Airplane mode remained `1` and Wi-Fi remained `0` after reboot (`release-after-reboot.txt`).

## Profile-mode comparison

Ran the dedicated EQ scrolling sequence in Flutter profile mode using `integration_test/performance_test.dart`, with `--no-dds` so the on-device timeline connection remained local and reachable. Both configurations passed. Raw timings are in `performance.json`; `profile-attempt.log` records the successful final run.

| Emulator profile | Frames | Average build | Average raster | Raster p90 |
|---|---:|---:|---:|---:|
| Liquid Glass | 224 | 1.83 ms | 13.24 ms | 17.16 ms |
| Reduced transparency | 220 | 2.01 ms | 8.37 ms | 16.23 ms |

The lower-effects option reduced average raster cost in this particular run. These are emulator observations, not a guarantee of sustained frame rate, battery efficiency, or physical-device GPU behavior.

## Visual review

Compared the supplied Stitch exports with actual emulator renders. Corrected narrow-screen overflow, panel ink feedback, stale shared-state subscriptions, and response-axis label collisions. The sample audio and file formats are genuine. Decorative reference quality claims, fabricated device names, spatial-audio claims, and invented lyrics were not copied into the product.

The EQ curve includes real automatic headroom, so it intentionally differs from the reference's decorative shape. On smaller viewports the extended player and EQ are scrollable, and all ten EQ bands are reachable horizontally. `docs/DESIGN.md` records the visual tokens and component/state board.

## Unverified and bounded claims

- No physical listening test: audible quality, perceptual click-free transitions on hardware, DAC behavior, Bluetooth/USB routing, wired-headphone disconnection, and real phone-call/audio-focus interruptions remain unverified. Their native handling is implemented; emulator/session and DSP evidence do not establish hardware acceptance.
- Only the supplied generated MP3 fixtures were exercised end to end. All advertised containers and device-specific codecs need a wider real-world media corpus. DRM and DSD are unsupported.
- The local folder path and automatic sidecar lyrics were exercised. Multi-file import, manual lyric import, and custom playlist-artwork picker paths are implemented but have not all received separate end-to-end acceptance runs.
- Sleep timer configuration is implemented in the native service. A full screen-off expiry/endurance test, repeated process-kill stress run, battery assessment, very large library benchmark, and physical GPU profiling remain pending. A process death cancels a sleep timer and stops playback.
- Debug screenshot capture produced emulator frame stalls and Flutter accessibility bridge diagnostics. Those captures are rendering evidence, not smoothness or TalkBack acceptance. Reduced transparency is available; physical-device performance and accessibility acceptance are still required.
- iOS is not implemented. There is a replaceable Flutter platform boundary, but no delivered iOS audio/EQ backend.

All these limits are explicit. No streaming, online API, login, analytics, advertisements, cloud database, push notification, or runtime font download is part of the app.
