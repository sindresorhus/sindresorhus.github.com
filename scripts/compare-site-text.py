from html.parser import HTMLParser
from pathlib import Path
import re
import sys

reference_root = Path(sys.argv[1])
candidate_root = Path(sys.argv[2])

def normalize(value):
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

class VisibleMainTextParser(HTMLParser):
	def __init__(self):
		super().__init__(convert_charrefs=True)
		self.main_depth = 0
		self.ignore_stack = []
		self.parts = []

	def handle_starttag(self, tag, attrs_list):
		attrs = dict(attrs_list)
		if tag == 'main':
			self.main_depth += 1

		if not self.main_depth:
			return

		classes = set((attrs.get('class') or '').split())
		should_ignore = (
			tag in {'script', 'style', 'select', 'svg', 'noscript'}
			or 'hidden' in attrs
			or 'hidden' in classes
			or attrs.get('aria-hidden') == 'true'
		)
		self.ignore_stack.append(should_ignore or any(self.ignore_stack))

	def handle_endtag(self, tag):
		if self.main_depth and self.ignore_stack:
			self.ignore_stack.pop()
		if tag == 'main' and self.main_depth:
			self.main_depth -= 1

	def handle_data(self, data):
		if self.main_depth and not any(self.ignore_stack):
			self.parts.append(data)

	def text(self):
		value = normalize(''.join(self.parts))
		# Related apps intentionally shuffle among the top candidates each build.
		return value.split('You Might Also Like', 1)[0].rstrip()

def visible_text(path):
	parser = VisibleMainTextParser()
	parser.feed(path.read_text())
	parser.close()
	return parser.text()

reference_routes = route_map(reference_root)
candidate_routes = route_map(candidate_root)
differences = []

for route in sorted(reference_routes.keys() & candidate_routes.keys()):
	reference = visible_text(reference_routes[route])
	candidate = visible_text(candidate_routes[route])
	if reference != candidate:
		differences.append((route, reference, candidate))

if differences:
	print(f'Visible-text parity failed for {len(differences)} route(s):')
	for route, reference, candidate in differences[:50]:
		print(f'  {route}:')
		print(f'    Astro: {reference[:500]!r}')
		print(f'    Swift: {candidate[:500]!r}')
	if len(differences) > 50:
		print(f'  ... and {len(differences) - 50} more')
	raise SystemExit(1)

print(f'Visible-text parity passed for {len(reference_routes)} routes.')
