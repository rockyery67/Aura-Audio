"""Small adb helpers for reproducible emulator UI checks; no product backdoors."""
import re
import subprocess
import sys
from pathlib import Path
from xml.etree import ElementTree
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

prefix = ['adb', '-s', 'emulator-5554']
def adb(*args):
    return subprocess.check_output(prefix + list(args), text=True, encoding='utf-8', errors='replace')
def nodes():
    status = adb('shell', 'uiautomator', 'dump', '/sdcard/aura-ui.xml')
    if 'dumped to' not in status: raise SystemExit('Could not inspect a fresh UI tree; pause playback and retry.')
    xml = adb('shell', 'cat', '/sdcard/aura-ui.xml')
    return list(ElementTree.fromstring(xml).iter('node'))
def tap(text):
    matches = [n for n in nodes() if (n.get('text') or n.get('content-desc') or '').split('\n')[0] == text]
    if not matches:
        raise SystemExit('No visible control matches: ' + text)
    bounds = [int(v) for v in re.findall(r'\d+', matches[-1].get('bounds', ''))]
    adb('shell', 'input', 'tap', str((bounds[0]+bounds[2])//2), str((bounds[1]+bounds[3])//2))
if __name__ == '__main__':
    if sys.argv[1] == 'list':
        for n in nodes():
            text = n.get('text') or n.get('content-desc')
            if text: print(text.replace('\n', ' / '), n.get('bounds'))
    elif sys.argv[1] == 'tap': tap(sys.argv[2])
    elif sys.argv[1] == 'shot':
        dest = Path(sys.argv[2]); dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(subprocess.check_output(prefix + ['exec-out', 'screencap', '-p']))
