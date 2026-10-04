from html.parser import HTMLParser
from pathlib import Path
import json
import re
import sys

reference_root = Path(sys.argv[1])
candidate_root = Path(sys.argv[2])

meta_keys = {
	'description', 'robots', 'apple-itunes-app',
	'twitter:card', 'twitter:site', 'twitter:creator', 'twitter:description',
	'fediverse:creator', 'og:title', 'og:type', 'og:url', 'og:image',
	'og:image:width', 'og:image:height', 'og:image:alt', 'og:description',
	'og:locale', 'og:site_name', 'article:published_time', 'article:author',
	'article:tag',
}

def normalize_text(value):
	return re.sub(r'\s+', ' ', value).strip()

def route_map(root):
	result = {}
	for path in root.rglob('*.html'):
		relative = path.relative_to(root).as_posix()[:-5]
		route = '/' + relative
		if route == '/index':
			route = '/'
		elif route.endswith('/index'):
			route = route[:-6] or '/'
		result[route] = path
	return result

def normalize_meta(key, value):
	if key == 'article:published_time':
		return re.sub(r'\.000Z$', 'Z', value)
	return value

def normalize_screenshot(value):
	filename = value.rsplit('/', 1)[-1]
	match = re.match(r'^(screenshot\d*)(?:\.[^.]+)?\.(png|jpe?g)
	if not match:
		return filename
	extension = match.group(2).lower().replace('jpeg', 'jpg')
	return f'{match.group(1).lower()}.{extension}'

def normalize_json(value):
	if isinstance(value, dict):
		result = {}
		for key, item in value.items():
			if key == 'screenshot':
				if isinstance(item, list):
					result[key] = [normalize_screenshot(str(entry)) for entry in item]
				else:
					result[key] = normalize_screenshot(str(item))
			else:
				result[key] = normalize_json(item)
		return result
	if isinstance(value, list):
		return [normalize_json(item) for item in value]
	return value

class Parser(HTMLParser):
	def __init__(self):
		super().__init__(convert_charrefs=True)
		self.title = []
		self.in_title = False
		self.heading_stack = []
		self.ignore_heading_depth = 0
		self.headings = []
		self.meta = {}
		self.canonical = None
		self.rss = set()
		self.refresh = None
		self.in_json = False
		self.json_buffer = []
		self.json_ld = []

	def handle_starttag(self, tag, attrs_list):
		attrs = dict(attrs_list)
		if tag == 'title':
			self.in_title = True
		if tag in {'h1', 'h2', 'h3', 'h4'}:
			self.heading_stack.append((tag, []))
		if self.heading_stack and tag in {'select', 'script', 'style'}:
			self.ignore_heading_depth += 1
		if tag == 'meta':
			key = attrs.get('name') or attrs.get('property')
			value = attrs.get('content')
			if key in meta_keys and value is not None:
				self.meta.setdefault(key, []).append(value)
			if (attrs.get('http-equiv') or '').lower() == 'refresh':
				self.refresh = value
		if tag == 'link':
			rel = set((attrs.get('rel') or '').split())
			if 'canonical' in rel:
				self.canonical = attrs.get('href')
			if 'alternate' in rel and attrs.get('type') == 'application/rss+xml' and attrs.get('href'):
				self.rss.add((attrs.get('title') or '', attrs['href']))
		if tag == 'script' and attrs.get('type') == 'application/ld+json':
			self.in_json = True
			self.json_buffer = []

	def handle_endtag(self, tag):
		if tag == 'title':
			self.in_title = False
		if self.heading_stack and tag in {'select', 'script', 'style'} and self.ignore_heading_depth:
			self.ignore_heading_depth -= 1
		if tag in {'h1', 'h2', 'h3', 'h4'} and self.heading_stack:
			heading_tag, parts = self.heading_stack.pop()
			value = normalize_text(''.join(parts))
			if value:
				self.headings.append((heading_tag, value))
		if tag == 'script' and self.in_json:
			raw = ''.join(self.json_buffer).strip()
			if raw:
				self.json_ld.append(json.loads(raw))
			self.in_json = False
			self.json_buffer = []

	def handle_data(self, data):
		if self.in_title:
			self.title.append(data)
		if self.heading_stack and not self.ignore_heading_depth:
			self.heading_stack[-1][1].append(data)
		if self.in_json:
			self.json_buffer.append(data)

	def snapshot(self):
		return {
			'title': normalize_text(''.join(self.title)),
			'meta': {key: sorted(normalize_meta(key, value) for value in values) for key, values in self.meta.items()},
			'canonical': self.canonical,
			'rss': sorted(self.rss),
			'refresh': self.refresh,
			'headings': self.headings,
			'json_ld': [normalize_json(value) for value in self.json_ld],
		}

def parse(path):
	parser = Parser()
	parser.feed(path.read_text())
	parser.close()
	return parser.snapshot()

reference_routes = route_map(reference_root)
candidate_routes = route_map(candidate_root)
differences = []

for route in sorted(reference_routes.keys() & candidate_routes.keys()):
	reference = parse(reference_routes[route])
	candidate = parse(candidate_routes[route])
	for key, expected in reference['meta'].items():
		if candidate['meta'].get(key) != expected:
			differences.append(f'{route}: meta {key}: Astro={expected!r}, Swift={candidate["meta"].get(key)!r}')
	for key in ('title', 'canonical', 'rss', 'refresh', 'headings', 'json_ld'):
		if candidate[key] != reference[key]:
			differences.append(f'{route}: {key}: Astro={reference[key]!r}, Swift={candidate[key]!r}')

if differences:
	print(f'Semantic parity failed with {len(differences)} difference(s):')
	for difference in differences[:200]:
		print('  ' + difference)
	if len(differences) > 200:
		print(f'  ... and {len(differences) - 200} more')
	sys.exit(1)

print(f'Semantic HTML parity passed for {len(reference_routes)} routes.')
, filename, re.I)
	if not match:
		return filename
	extension = match.group(2).lower().replace('jpeg', 'jpg')
	return f'{match.group(1).lower()}.{extension}'

def normalize_json(value):
	if isinstance(value, dict):
		result = {}
		for key, item in value.items():
			if key == 'screenshot':
				if isinstance(item, list):
					result[key] = [normalize_screenshot(str(entry)) for entry in item]
				else:
					result[key] = normalize_screenshot(str(item))
			else:
				result[key] = normalize_json(item)
		return result
	if isinstance(value, list):
		return [normalize_json(item) for item in value]
	return value

class Parser(HTMLParser):
	def __init__(self):
		super().__init__(convert_charrefs=True)
		self.title = []
		self.in_title = False
		self.heading_stack = []
		self.ignore_heading_depth = 0
		self.headings = []
		self.meta = {}
		self.canonical = None
		self.rss = set()
		self.refresh = None
		self.in_json = False
		self.json_buffer = []
		self.json_ld = []

	def handle_starttag(self, tag, attrs_list):
		attrs = dict(attrs_list)
		if tag == 'title':
			self.in_title = True
		if tag in {'h1', 'h2', 'h3', 'h4'}:
			self.heading_stack.append((tag, []))
		if self.heading_stack and tag in {'select', 'script', 'style'}:
			self.ignore_heading_depth += 1
		if tag == 'meta':
			key = attrs.get('name') or attrs.get('property')
			value = attrs.get('content')
			if key in meta_keys and value is not None:
				self.meta.setdefault(key, []).append(value)
			if (attrs.get('http-equiv') or '').lower() == 'refresh':
				self.refresh = value
		if tag == 'link':
			rel = set((attrs.get('rel') or '').split())
			if 'canonical' in rel:
				self.canonical = attrs.get('href')
			if 'alternate' in rel and attrs.get('type') == 'application/rss+xml' and attrs.get('href'):
				self.rss.add((attrs.get('title') or '', attrs['href']))
		if tag == 'script' and attrs.get('type') == 'application/ld+json':
			self.in_json = True
			self.json_buffer = []

	def handle_endtag(self, tag):
		if tag == 'title':
			self.in_title = False
		if self.heading_stack and tag in {'select', 'script', 'style'} and self.ignore_heading_depth:
			self.ignore_heading_depth -= 1
		if tag in {'h1', 'h2', 'h3', 'h4'} and self.heading_stack:
			heading_tag, parts = self.heading_stack.pop()
			value = normalize_text(''.join(parts))
			if value:
				self.headings.append((heading_tag, value))
		if tag == 'script' and self.in_json:
			raw = ''.join(self.json_buffer).strip()
			if raw:
				self.json_ld.append(json.loads(raw))
			self.in_json = False
			self.json_buffer = []

	def handle_data(self, data):
		if self.in_title:
			self.title.append(data)
		if self.heading_stack and not self.ignore_heading_depth:
			self.heading_stack[-1][1].append(data)
		if self.in_json:
			self.json_buffer.append(data)

	def snapshot(self):
		return {
			'title': normalize_text(''.join(self.title)),
			'meta': {key: sorted(normalize_meta(key, value) for value in values) for key, values in self.meta.items()},
			'canonical': self.canonical,
			'rss': sorted(self.rss),
			'refresh': self.refresh,
			'headings': self.headings,
			'json_ld': [normalize_json(value) for value in self.json_ld],
		}

def parse(path):
	parser = Parser()
	parser.feed(path.read_text())
	parser.close()
	return parser.snapshot()

reference_routes = route_map(reference_root)
candidate_routes = route_map(candidate_root)
differences = []

for route in sorted(reference_routes.keys() & candidate_routes.keys()):
	reference = parse(reference_routes[route])
	candidate = parse(candidate_routes[route])
	for key, expected in reference['meta'].items():
		if candidate['meta'].get(key) != expected:
			differences.append(f'{route}: meta {key}: Astro={expected!r}, Swift={candidate["meta"].get(key)!r}')
	for key in ('title', 'canonical', 'rss', 'refresh', 'headings', 'json_ld'):
		if candidate[key] != reference[key]:
			differences.append(f'{route}: {key}: Astro={reference[key]!r}, Swift={candidate[key]!r}')

if differences:
	print(f'Semantic parity failed with {len(differences)} difference(s):')
	for difference in differences[:200]:
		print('  ' + difference)
	if len(differences) > 200:
		print(f'  ... and {len(differences) - 200} more')
	sys.exit(1)

print(f'Semantic HTML parity passed for {len(reference_routes)} routes.')
