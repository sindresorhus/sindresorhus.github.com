from __future__ import annotations

from html.parser import HTMLParser
from pathlib import Path
import json
import re
import sys


REFERENCE = Path(sys.argv[1])
CANDIDATE = Path(sys.argv[2])

META_KEYS = {
    'description',
    'robots',
    'apple-itunes-app',
    'twitter:card',
    'twitter:site',
    'twitter:creator',
    'twitter:description',
    'fediverse:creator',
    'og:title',
    'og:type',
    'og:url',
    'og:image',
    'og:image:width',
    'og:image:height',
    'og:image:alt',
    'og:description',
    'og:locale',
    'og:site_name',
    'article:published_time',
    'article:author',
    'article:tag',
}


def normalize_text(value: str) -> str:
    return re.sub(r'\s+', ' ', value).strip()


def route_map(root: Path) -> dict[str, Path]:
    result: dict[str, Path] = {}
    for path in root.rglob('*.html'):
        relative = path.relative_to(root).as_posix()
        route = '/' + relative[:-5]
        if route == '/index':
            route = '/'
        elif route.endswith('/index'):
            route = route[:-6] or '/'
        result[route] = path
    return result


class SemanticHTMLParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.title_parts: list[str] = []
        self.in_title = False
        self.heading_stack: list[tuple[str, list[str]]] = []
        self.headings: list[tuple[str, str]] = []
        self.meta: dict[str, list[str]] = {}
        self.canonical: str | None = None
        self.rss_links: set[tuple[str, str]] = set()
        self.refresh: str | None = None
        self.in_json_ld = False
        self.json_ld_buffer: list[str] = []
        self.json_ld: list[object] = []
        self.heading_ignored_depth = 0

    def handle_starttag(self, tag: str, attrs_list: list[tuple[str, str | None]]) -> None:
        attrs = dict(attrs_list)

        if tag == 'title':
            self.in_title = True

        if tag in {'h1', 'h2', 'h3', 'h4'}:
            self.heading_stack.append((tag, []))

        if self.heading_stack and tag in {'select', 'script', 'style'}:
            self.heading_ignored_depth += 1

        if tag == 'meta':
            key = attrs.get('name') or attrs.get('property')
            content = attrs.get('content')
            if key in META_KEYS and content is not None:
                self.meta.setdefault(key, []).append(content)

            if (attrs.get('http-equiv') or '').lower() == 'refresh':
                self.refresh = content

        if tag == 'link':
            rel = set((attrs.get('rel') or '').split())
            if 'canonical' in rel:
                self.canonical = attrs.get('href')

            if (
                'alternate' in rel
                and attrs.get('type') == 'application/rss+xml'
                and attrs.get('href')
            ):
                self.rss_links.add((attrs.get('title') or '', attrs['href']))

        if tag == 'script' and attrs.get('type') == 'application/ld+json':
            self.in_json_ld = True
            self.json_ld_buffer = []

    def handle_endtag(self, tag: str) -> None:
        if tag == 'title':
            self.in_title = False

        if self.heading_stack and tag in {'select', 'script', 'style'} and self.heading_ignored_depth > 0:
            self.heading_ignored_depth -= 1

        if tag in {'h1', 'h2', 'h3', 'h4'} and self.heading_stack:
            heading_tag, parts = self.heading_stack.pop()
            text = normalize_text(''.join(parts))
            if text:
                self.headings.append((heading_tag, text))

        if tag == 'script' and self.in_json_ld:
            raw = ''.join(self.json_ld_buffer).strip()
            if raw:
                try:
                    self.json_ld.append(json.loads(raw))
                except json.JSONDecodeError as error:
                    raise AssertionError(f'Invalid JSON-LD: {error}: {raw[:160]}') from error
            self.in_json_ld = False
            self.json_ld_buffer = []

    def handle_data(self, data: str) -> None:
        if self.in_title:
            self.title_parts.append(data)

        if self.heading_stack and self.heading_ignored_depth == 0:
            self.heading_stack[-1][1].append(data)

        if self.in_json_ld:
            self.json_ld_buffer.append(data)

    def snapshot(self) -> dict[str, object]:
        return {
            'title': normalize_text(''.join(self.title_parts)),
            'meta': {
                key: sorted(normalize_meta_value(key, value) for value in values)
                for key, values in sorted(self.meta.items())
            },
            'canonical': self.canonical,
            'rss': sorted(self.rss_links),
            'refresh': self.refresh,
            'headings': self.headings,
            'json_ld': [normalize_json_ld(value) for value in self.json_ld],
        }


def normalize_meta_value(key: str, value: str) -> str:
    if key == 'article:published_time':
        return re.sub(r'\.000Z
    parser = SemanticHTMLParser()
    parser.feed(path.read_text())
    parser.close()
    return parser.snapshot()


reference_routes = route_map(REFERENCE)
candidate_routes = route_map(CANDIDATE)
common_routes = sorted(reference_routes.keys() & candidate_routes.keys())

failures: list[str] = []

for route in common_routes:
    reference = parse(reference_routes[route])
    candidate = parse(candidate_routes[route])

    # Candidate may intentionally add harmless metadata, but every stable field
    # emitted by Astro must still exist with the same values.
    reference_meta = reference['meta']
    candidate_meta = candidate['meta']

    for key, value in reference_meta.items():
        if candidate_meta.get(key) != value:
            failures.append(
                f'{route}: meta {key!r}: Astro={value!r}, Swift={candidate_meta.get(key)!r}'
            )

    for key in ('title', 'canonical', 'rss', 'refresh', 'headings', 'json_ld'):
        if candidate[key] != reference[key]:
            failures.append(
                f'{route}: {key}: Astro={reference[key]!r}, Swift={candidate[key]!r}'
            )

if failures:
    print(f'Semantic parity failed with {len(failures)} difference(s):')
    for failure in failures[:200]:
        print('  ' + failure)
    if len(failures) > 200:
        print(f'  ... and {len(failures) - 200} more')
    raise SystemExit(1)

print(f'Semantic HTML parity passed for {len(common_routes)} routes.')
, 'Z', value)
    return value


def normalize_screenshot_url(value: str) -> str:
    filename = value.rsplit('/', 1)[-1]
    match = re.match(r'^(screenshot\d+)(?:\.[^.]+)?\.(png|jpe?g)
    parser = SemanticHTMLParser()
    parser.feed(path.read_text())
    parser.close()
    return parser.snapshot()


reference_routes = route_map(REFERENCE)
candidate_routes = route_map(CANDIDATE)
common_routes = sorted(reference_routes.keys() & candidate_routes.keys())

failures: list[str] = []

for route in common_routes:
    reference = parse(reference_routes[route])
    candidate = parse(candidate_routes[route])

    # Candidate may intentionally add harmless metadata, but every stable field
    # emitted by Astro must still exist with the same values.
    reference_meta = reference['meta']
    candidate_meta = candidate['meta']

    for key, value in reference_meta.items():
        if candidate_meta.get(key) != value:
            failures.append(
                f'{route}: meta {key!r}: Astro={value!r}, Swift={candidate_meta.get(key)!r}'
            )

    for key in ('title', 'canonical', 'rss', 'refresh', 'headings', 'json_ld'):
        if candidate[key] != reference[key]:
            failures.append(
                f'{route}: {key}: Astro={reference[key]!r}, Swift={candidate[key]!r}'
            )

if failures:
    print(f'Semantic parity failed with {len(failures)} difference(s):')
    for failure in failures[:200]:
        print('  ' + failure)
    if len(failures) > 200:
        print(f'  ... and {len(failures) - 200} more')
    raise SystemExit(1)

print(f'Semantic HTML parity passed for {len(common_routes)} routes.')
, filename, re.I)
    if match:
        return f'{match.group(1).lower()}.{match.group(2).lower().replace("jpeg", "jpg")}'
    return filename


def normalize_json_ld(value: object) -> object:
    if isinstance(value, dict):
        result = {}
        for key, item in value.items():
            if key == 'screenshot':
                if isinstance(item, list):
                    result[key] = [normalize_screenshot_url(str(entry)) for entry in item]
                else:
                    result[key] = normalize_screenshot_url(str(item))
            else:
                result[key] = normalize_json_ld(item)
        return result

    if isinstance(value, list):
        return [normalize_json_ld(item) for item in value]

    return value


def parse(path: Path) -> dict[str, object]:
    parser = SemanticHTMLParser()
    parser.feed(path.read_text())
    parser.close()
    return parser.snapshot()


reference_routes = route_map(REFERENCE)
candidate_routes = route_map(CANDIDATE)
common_routes = sorted(reference_routes.keys() & candidate_routes.keys())

failures: list[str] = []

for route in common_routes:
    reference = parse(reference_routes[route])
    candidate = parse(candidate_routes[route])

    # Candidate may intentionally add harmless metadata, but every stable field
    # emitted by Astro must still exist with the same values.
    reference_meta = reference['meta']
    candidate_meta = candidate['meta']

    for key, value in reference_meta.items():
        if candidate_meta.get(key) != value:
            failures.append(
                f'{route}: meta {key!r}: Astro={value!r}, Swift={candidate_meta.get(key)!r}'
            )

    for key in ('title', 'canonical', 'rss', 'refresh', 'headings', 'json_ld'):
        if candidate[key] != reference[key]:
            failures.append(
                f'{route}: {key}: Astro={reference[key]!r}, Swift={candidate[key]!r}'
            )

if failures:
    print(f'Semantic parity failed with {len(failures)} difference(s):')
    for failure in failures[:200]:
        print('  ' + failure)
    if len(failures) > 200:
        print(f'  ... and {len(failures) - 200} more')
    raise SystemExit(1)

print(f'Semantic HTML parity passed for {len(common_routes)} routes.')
