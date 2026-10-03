const {paths} = JSON.parse(document.querySelector('#not-found-data').textContent);

/**
The number of single-character edits that turn one string into the other (Levenshtein distance).
*/
function editDistance(first, second) {
	let previous = Array.from({length: second.length + 1}, (_, index) => index);

	for (let firstIndex = 1; firstIndex <= first.length; firstIndex++) {
		const current = [firstIndex];

		for (let secondIndex = 1; secondIndex <= second.length; secondIndex++) {
			const substitution = previous[secondIndex - 1] + (first[firstIndex - 1] === second[secondIndex - 1] ? 0 : 1);
			current[secondIndex] = Math.min(previous[secondIndex] + 1, current[secondIndex - 1] + 1, substitution);
		}

		previous = current;
	}

	return previous[second.length];
}

function requestedPath() {
	try {
		return decodeURIComponent(location.pathname).toLowerCase().replace(/\.html$/, '').replace(/\/+$/, '') || '/';
	} catch {
		return location.pathname.toLowerCase();
	}
}

const path = requestedPath();
// The last part alone too, so `/apps/dato` finds `/dato`.
const lastPart = `/${path.split('/').at(-1)}`;

let closest;
let closestDistance = Number.POSITIVE_INFINITY;

for (const candidate of paths) {
	const distance = Math.min(editDistance(path, candidate.toLowerCase()), editDistance(lastPart, candidate.toLowerCase()));

	if (distance < closestDistance) {
		closest = candidate;
		closestDistance = distance;
	}
}

// Only close matches, like a typo or a missing letter.
if (closest && closestDistance <= Math.max(2, Math.floor(lastPart.length / 4))) {
	const link = document.querySelector('#closest-page-link');
	link.href = closest;
	link.textContent = `sindresorhus.com${closest}`;
	document.querySelector('#closest-page').hidden = false;
}
