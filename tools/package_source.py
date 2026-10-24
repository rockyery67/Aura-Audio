"""Package reviewable Flutter sources, designs, tests, and evidence without SDK caches."""
import hashlib
import json
import os
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
destination = root / 'build' / 'deliverables'
destination.mkdir(parents=True, exist_ok=True)
archive = destination / 'AuraAudio-Flutter-Source.zip'
directories = ['lib', 'android', 'assets', 'docs', 'test', 'integration_test', 'test_driver', 'tools', 'stitch_liquid_glass_music_player']
skip_dirs = {'build', '.gradle', '.kotlin', '.cxx', '.idea', '__pycache__'}
skip_files = {'local.properties', 'GeneratedPluginRegistrant.java', 'current.png', 'lock-screen.png', 'ui.xml'}
with ZipFile(archive, 'w', ZIP_DEFLATED) as bundle:
    for name in ['pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'README.md', '.gitignore', '.metadata']:
        bundle.write(root / name, name)
    for name in directories:
        for parent, children, files in os.walk(root / name):
            children[:] = [child for child in children if child not in skip_dirs]
            for name in files:
                if name in skip_files: continue
                file = Path(parent) / name
                bundle.write(file, file.relative_to(root))
apk = root / 'build' / 'app' / 'outputs' / 'flutter-apk' / 'app-release.apk'
def record(path):
    return {'path': str(path.relative_to(root)), 'bytes': path.stat().st_size, 'sha256': hashlib.file_digest(path.open('rb'), 'sha256').hexdigest()}
manifest = {'application': 'Aura Audio', 'version': '1.0.0+1', 'platform': 'Android API 26+', 'apk': record(apk), 'source': record(archive)}
(destination / 'artifacts.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
print(json.dumps(manifest, indent=2))
