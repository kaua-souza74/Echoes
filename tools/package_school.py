"""Build and inspect the teacher's restricted lib/ + pubspec.yaml package."""
from hashlib import sha256
import json
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
app = root / 'flutter_app'
output = root / 'deliverables'
output.mkdir(exist_ok=True)
archive = output / 'ECHOES_V2.2_school.zip'
sources = sorted(path for path in (app / 'lib').rglob('*') if path.is_file())
sources.append(app / 'pubspec.yaml')
with ZipFile(archive, 'w', ZIP_DEFLATED) as bundle:
    for source in sources:
        bundle.write(source, source.relative_to(app).as_posix())
with ZipFile(archive) as bundle:
    names = bundle.namelist()
    assert names and bundle.testzip() is None
    assert all(name.startswith('lib/') or name == 'pubspec.yaml' for name in names)
    assert 'pubspec.yaml' in names and 'lib/main.dart' in names
report = {
    'archive': archive.name,
    'files': len(names),
    'bytes': archive.stat().st_size,
    'sha256': sha256(archive.read_bytes()).hexdigest(),
    'school_format_only': True,
    'standalone_runnable': False,
    'required_for_complete_project': ['assets/', 'pubspec.lock', 'platform runners', 'Supabase setup and public build configuration'],
    'contents': names,
}
(output / 'school_package_manifest.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(f'Verified {archive.name}: {len(names)} files, {archive.stat().st_size} bytes. Assets and local configuration are excluded.')
