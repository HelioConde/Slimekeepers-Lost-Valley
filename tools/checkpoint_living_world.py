"""Preserve the working v2 project before Mundo Vivo 3.0; never overwrite a snapshot."""
from pathlib import Path
from datetime import datetime
import json, zipfile, hashlib

root = Path(__file__).resolve().parent.parent
dest = root / 'docs/backups' / ('before_mundo_vivo_v3_' + datetime.now().strftime('%Y%m%d_%H%M%S') + '.zip')
dest.parent.mkdir(parents=True, exist_ok=True)
excluded = {'.godot', '.git', 'backups', '__pycache__'}
files = sorted(p for p in root.rglob('*') if p.is_file() and not any(x in excluded for x in p.relative_to(root).parts))
with zipfile.ZipFile(dest, 'x', zipfile.ZIP_DEFLATED, compresslevel=3) as z:
    for path in files:
        z.write(path, path.relative_to(root).as_posix())
with zipfile.ZipFile(dest) as z:
    assert z.testzip() is None
report = {'archive': str(dest), 'entries': len(files), 'bytes': dest.stat().st_size,
          'sha256': hashlib.sha256(dest.read_bytes()).hexdigest(), 'integrity': 'all entries verified'}
evidence = root / 'docs/world/living_v3'
evidence.mkdir(parents=True, exist_ok=True)
(evidence / 'checkpoint.json').write_text(json.dumps(report, indent=2), encoding='utf8')
print(json.dumps(report))
