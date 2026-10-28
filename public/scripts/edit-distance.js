/**
The number of single-character edits that turn one string into the other (optimal string alignment distance). An edit is an insertion, a deletion, a substitution, or a swap of two neighboring characters, as a swap is a common typo, like `daot` for `dato`. The 404 page, the email check of the feedback page, and `closest` use it.
*/
export function editDistance(first, second) {
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

/**
The text in the form that names are compared in: lowercase, and without accents, spaces, and punctuation, so `cafe` finds “Café”, `menubar` finds “Menu Bar”, and `dsstore` finds “DS_Store Inspector”.
*/
export const searchKey = text => text.normalize('NFD').replaceAll(/[\p{Diacritic}\s\p{P}]/gu, '').toLowerCase();

/**
The candidate whose key, like `searchKey(app.title)`, is closest to the query, or `undefined` when none is close: at most one edit for each 5 characters of the longer of the two (`maximumRatio`), so a short query needs an exact match. The query is already in the form of the keys, like `searchKey(text)`.
*/
export function closest(query, candidates, {key = candidate => candidate, maximumRatio = 0.2} = {}) {
	let closestCandidate;
	let closestRatio = Number.POSITIVE_INFINITY;

	for (const candidate of candidates) {
		const candidateKey = key(candidate);
		const ratio = editDistance(query, candidateKey) / Math.max(query.length, candidateKey.length, 1);

		if (ratio <= maximumRatio && ratio < closestRatio) {
			closestCandidate = candidate;
			closestRatio = ratio;
		}
	}

	return closestCandidate;
}
