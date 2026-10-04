from pathlib import Path
from PIL import Image, ImageChops
import math
import sys

reference_root = Path(sys.argv[1]) / 'og'
candidate_root = Path(sys.argv[2]) / 'og'
maximum_rmse = 40.0

reference = {path.name: path for path in reference_root.glob('*.png')}
candidate = {path.name: path for path in candidate_root.glob('*.png')}

if reference.keys() != candidate.keys():
	missing = sorted(reference.keys() - candidate.keys())
	extra = sorted(candidate.keys() - reference.keys())
	if missing:
		print('Missing Swift OG images:', ', '.join(missing))
	if extra:
		print('Extra Swift OG images:', ', '.join(extra))
	raise SystemExit(1)

failures = []
scores = []

for name in sorted(reference):
	expected = Image.open(reference[name]).convert('RGB')
	actual = Image.open(candidate[name]).convert('RGB')

	if expected.size != (1200, 630) or actual.size != (1200, 630):
		failures.append(f'{name}: dimensions Astro={expected.size}, Swift={actual.size}')
		continue

	difference = ImageChops.difference(expected, actual)
	histogram = difference.histogram()
	squared_error = sum(
		count * ((index % 256) ** 2)
		for index, count in enumerate(histogram)
	)
	rmse = math.sqrt(squared_error / (expected.width * expected.height * 3))
	scores.append((rmse, name))

	if rmse > maximum_rmse:
		failures.append(f'{name}: RMSE {rmse:.2f} > {maximum_rmse:.2f}')

if failures:
	print(f'OG visual parity failed with {len(failures)} difference(s):')
	for failure in failures:
		print('  ' + failure)
	raise SystemExit(1)

scores.sort(reverse=True)
worst_rmse, worst_name = scores[0]
average_rmse = sum(score for score, _ in scores) / len(scores)
print(
	f'OG visual parity passed for {len(scores)} images '
	f'(average RMSE {average_rmse:.2f}, worst {worst_rmse:.2f} in {worst_name}).'
)
