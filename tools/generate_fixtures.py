"""Generate original local validation audio; never bundled into the app."""
from pathlib import Path
import subprocess
import imageio_ffmpeg
from mutagen.id3 import ID3, TIT2, TPE1, TALB, TRCK, APIC

root = Path(__file__).resolve().parents[1]
destination = root / 'test_assets'
destination.mkdir(exist_ok=True)
samples = [
    ('cosmic_drift', 'Cosmic Drift', 'Neon Echoes', 'Ethereal Horizons', 'ethereal', 62),
    ('amber_horizon', 'Amber Horizon', 'Electron Project', 'Solaris Echoes', 'solaris', 220),
    ('monolith_reflections', 'Monolith Reflections', 'Obsidian Ensemble', 'Stillness in Motion', 'stillness', 330),
]
for index, (name, title, artist, album, artwork, frequency) in enumerate(samples):
    target = destination / f'{name}.mp3'
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), '-y', '-f', 'lavfi', '-i',
        f'aevalsrc=0.08*sin(2*PI*{frequency}*t)+0.04*sin(2*PI*1000*t)+0.02*sin(2*PI*8000*t):s=48000:d=90',
        '-ac', '2', '-codec:a', 'libmp3lame', '-b:a', '192k', str(target)], check=True, capture_output=True)
    tags = ID3(target)
    tags.add(TIT2(encoding=3, text=title)); tags.add(TPE1(encoding=3, text=artist))
    tags.add(TALB(encoding=3, text=album)); tags.add(TRCK(encoding=3, text=str(index + 1)))
    tags.add(APIC(encoding=3, mime='image/png', type=3, desc='Front cover', data=(root / 'assets' / 'art' / f'{artwork}.png').read_bytes()))
    tags.save(target)
(destination / 'cosmic_drift.lrc').write_text('[00:00.00]Local validation audio\n[00:05.00]A low tone, a mid tone, a high tone\n[00:15.00]Generated on this computer\n[00:30.00]Stored entirely on your device\n', encoding='utf-8')
print('Created three 90-second original multitone fixtures and one local LRC file.')
