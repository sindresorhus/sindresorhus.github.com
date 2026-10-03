from pathlib import Path
import sys
import xml.etree.ElementTree as ET

reference_root = Path(sys.argv[1])
candidate_root = Path(sys.argv[2])

content_encoded = '{http://purl.org/rss/1.0/modules/content/}encoded'
sitemap_ns = {'s': 'http://www.sitemaps.org/schemas/sitemap/0.9'}

def text(element, name):
	child = element.find(name)
	return '' if child is None or child.text is None else child.text.strip()

def rss_snapshot(path):
	root = ET.parse(path).getroot()
	channel = root.find('channel')
	if channel is None:
		raise ValueError(f'No RSS channel in {path}')

	items = []
	for item in channel.findall('item'):
		guid = item.find('guid')
		content = item.find(content_encoded)
		items.append({
			'title': text(item, 'title'),
			'link': text(item, 'link'),
			'guid': '' if guid is None or guid.text is None else guid.text.strip(),
			'guidPermaLink': None if guid is None else guid.attrib.get('isPermaLink'),
			'pubDate': text(item, 'pubDate'),
			'description': text(item, 'description'),
			'content': '' if content is None or content.text is None else content.text.strip(),
		})

	return {
		'title': text(channel, 'title'),
		'link': text(channel, 'link'),
		'description': text(channel, 'description'),
		'items': items,
	}

def sitemap_snapshot(path):
	root = ET.parse(path).getroot()
	if root.tag.endswith('sitemapindex'):
		return sorted(
			element.text.strip()
			for element in root.findall('s:sitemap/s:loc', sitemap_ns)
			if element.text
		)
	if root.tag.endswith('urlset'):
		return sorted(
			element.text.strip()
			for element in root.findall('s:url/s:loc', sitemap_ns)
			if element.text
		)
	raise ValueError(f'Unknown sitemap root in {path}: {root.tag}')

differences = []

reference_rss = sorted(
	path.relative_to(reference_root)
	for path in reference_root.rglob('*.xml')
	if path.name.startswith('rss') or path.name == 'rss.xml'
)
candidate_rss = sorted(
	path.relative_to(candidate_root)
	for path in candidate_root.rglob('*.xml')
	if path.name.startswith('rss') or path.name == 'rss.xml'
)

if reference_rss != candidate_rss:
	differences.append(f'RSS path set differs: Astro={reference_rss!r}, Swift={candidate_rss!r}')

for relative in sorted(set(reference_rss) & set(candidate_rss)):
	reference = rss_snapshot(reference_root / relative)
	candidate = rss_snapshot(candidate_root / relative)
	if reference != candidate:
		differences.append(f'RSS {relative}: Astro={reference!r}, Swift={candidate!r}')

for relative in [Path('sitemap-index.xml'), Path('sitemap-0.xml')]:
	reference_path = reference_root / relative
	candidate_path = candidate_root / relative
	if not reference_path.exists() or not candidate_path.exists():
		continue
	reference = sitemap_snapshot(reference_path)
	candidate = sitemap_snapshot(candidate_path)
	if reference != candidate:
		differences.append(f'Sitemap {relative}: Astro={reference!r}, Swift={candidate!r}')

if differences:
	print(f'XML parity failed with {len(differences)} difference(s):')
	for difference in differences[:50]:
		print('  ' + difference)
	if len(differences) > 50:
		print(f'  ... and {len(differences) - 50} more')
	sys.exit(1)

print(f'RSS/sitemap semantic parity passed for {len(reference_rss)} RSS feeds.')
