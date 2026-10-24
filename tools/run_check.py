"""Capture a native build/test process without PowerShell stderr altering its exit status."""
from pathlib import Path
import subprocess
import sys
sys.stdout.reconfigure(encoding='utf-8', errors='replace')
target = Path(sys.argv[1]); target.parent.mkdir(parents=True, exist_ok=True)
with target.open('w', encoding='utf-8') as log:
    result = subprocess.run(sys.argv[2:], stdout=log, stderr=subprocess.STDOUT)
lines = target.read_text(encoding='utf-8', errors='replace').splitlines()
print('\n'.join(lines[-12:]))
print('EXIT_STATUS=' + str(result.returncode))
raise SystemExit(result.returncode)
