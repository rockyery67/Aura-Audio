"""Verify a real media service survives the already-closed Flutter Activity."""
import json
import re
import subprocess
import time
from pathlib import Path
prefix = ['adb', '-s', 'emulator-5554', 'shell']
def adb(*args): return subprocess.check_output(prefix + list(args), text=True, encoding='utf-8', errors='replace')
def snapshot():
    dump = adb('dumpsys', 'media_session')
    state = re.search(r'state=PlaybackState \{state=(\w+)\(', dump)
    title = re.search(r'metadata: size=\d+, description=(.*)', dump)
    return {'state': state.group(1) if state else '', 'metadata': title.group(1) if title else ''}
activity = adb('dumpsys', 'activity', 'activities')
present = bool(re.search(r'ActivityRecord[^\n]*audio\.aura\.aura_audio', activity))
deadline = time.monotonic() + 5
while present and time.monotonic() < deadline:
    time.sleep(.2)
    activity = adb('dumpsys', 'activity', 'activities')
    present = bool(re.search(r'ActivityRecord[^\n]*audio\.aura\.aura_audio', activity))
assert not present, 'Close the root Flutter Activity with Android Back before this check.'
before = snapshot()
adb('cmd', 'media_session', 'dispatch', 'next')
after = snapshot()
deadline = time.monotonic() + 8
while after['state'] != 'PLAYING' and time.monotonic() < deadline:
    time.sleep(.2); after = snapshot()
assert after['state'] == 'PLAYING', after
assert after['metadata'] != before['metadata'], (before, after)
report = {'activity_present': present, 'before': before, 'background_after_next': after, 'airplane_mode': adb('settings', 'get', 'global', 'airplane_mode_on').strip(), 'wifi_on': adb('settings', 'get', 'global', 'wifi_on').strip()}
Path('docs/release-lifecycle.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report))
