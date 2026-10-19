// The paths of the pages that the visitor may have meant.
const paths = JSON.parse(document.querySelector('#not-found-data').textContent);

/**
The number of single-character edits that turn one string into the other (optimal string alignment distance). An edit is an insertion, a deletion, a substitution, or a swap of two neighboring characters, as a swap is a common typo, like `daot` for `dato`.
*/
function editDistance(first, second) {
	let beforePrevious = [];
	let previous = Array.from({length: second.length + 1}, (_, index) => index);

	for (let firstIndex = 1; firstIndex <= first.length; firstIndex++) {
		const current = [firstIndex];

		for (let secondIndex = 1; secondIndex <= second.length; secondIndex++) {
			const substitution = previous[secondIndex - 1] + (first[firstIndex - 1] === second[secondIndex - 1] ? 0 : 1);
			current[secondIndex] = Math.min(previous[secondIndex] + 1, current[secondIndex - 1] + 1, substitution);

			if (first[firstIndex - 1] === second[secondIndex - 2] && first[firstIndex - 2] === second[secondIndex - 1]) {
				current[secondIndex] = Math.min(current[secondIndex], beforePrevious[secondIndex - 2] + 1);
			}
		}

		beforePrevious = previous;
		previous = current;
	}

	return previous[second.length];
}

function requestedPath() {
	let path = location.pathname;

	// A malformed escape, like `%E0`, stays as it is.
	try {
		path = decodeURIComponent(path);
	} catch {}

	return path.toLowerCase().replace(/\.html$/, '').replace(/\/+$/, '') || '/';
}

// Without the leading slash, which every path has, so it does not make short paths look closer than they are.
const path = requestedPath().slice(1);
// The last part alone too, so `/apps/dato` finds `/dato`.
const lastPart = path.split('/').at(-1);

let closest;
let closestRatio = Number.POSITIVE_INFINITY;

for (const candidate of paths) {
	const name = candidate.slice(1).toLowerCase();
	// The edits for each character of the longer string, so a short path needs a closer match than a long one, and `/apps/mac` finds `/apps/macos` (2 edits in 10 characters), not `/apps/faq` (2 in 8).
	const ratio = Math.min(...[path, lastPart].map(input => editDistance(input, name) / Math.max(input.length, name.length)));

	if (ratio < closestRatio) {
		closest = candidate;
		closestRatio = ratio;
	}
}

// Only close matches, like a typo or a missing letter: at most 3 edits in 10 characters. A name of 3 characters, like `now`, must match exactly, so `/how` and `/new` suggest nothing.
if (closest && closestRatio <= 0.3) {
	const link = document.querySelector('#closest-page-link');
	link.href = closest;
	link.textContent = `sindresorhus.com${closest}`;
	document.querySelector('#closest-page').hidden = false;
}
