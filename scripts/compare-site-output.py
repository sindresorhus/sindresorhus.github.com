from pathlib import Path
import sys

REFERENCE = Path(sys.argv[1])
CANDIDATE = Path(sys.argv[2])


def routes(root: Path):
    result = set()
    for path in root.rglob('*'):
        if not path.is_file():
            continue

        relative = path.relative_to(root).as_posix()
        if path.suffix == '.html':
            route = '/' + relative[:-5]
            if route == '/index':
                route = '/'
            elif route.endswith('/index'):
                route = route[:-6] or '/'
            result.add(('html', route))
        elif path.suffix == '.xml':
            result.add(('xml', '/' + relative))
        elif relative.startswith('og/') and path.suffix == '.png':
            result.add(('og', '/' + relative))

    return result


reference = routes(REFERENCE)
candidate = routes(CANDIDATE)
missing = sorted(reference - candidate)
extra = sorted(candidate - reference)

if missing:
    print('Missing from Swift output:')
    for kind, route in missing:
        print(f'  {kind}: {route}')

if extra:
    print('Extra in Swift output:')
    for kind, route in extra:
        print(f'  {kind}: {route}')

if missing or extra:
    raise SystemExit(1)

print(f'Route parity passed: {len(candidate)} HTML/XML/OG outputs.')
