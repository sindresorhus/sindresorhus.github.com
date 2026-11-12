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
The candidate whose key, like `searchKey(app.title)`, is closest to the query, or `undefined` when none is close: at most one edit for each 4 characters of the longer of the two (`maximumRatio`), so a name of 4 letters, like Dato, accepts one typo, like `daot`, and a name of 3 letters needs an exact match. The query is already in the form of the keys, like `searchKey(text)`.
*/
export function closest(query, candidates, {key = candidate => candidate, maximumRatio = 0.25} = {}) {
	let closestCandidate;
	let closestRatio = Number.POSITIVE_INFINITY;

	for (const candidate of candidates) {
		const candidateKey = key(candidate);
		const longerLength = Math.max(query.length, candidateKey.length, 1);

		// The distance is at least the difference of the lengths, so a key with a very different length cannot be close, and the slow comparison is skipped, like for a long text that was pasted by mistake.
		if (Math.abs(query.length - candidateKey.length) / longerLength > maximumRatio) {
			continue;
		}

		const ratio = editDistance(query, candidateKey) / longerLength;

		if (ratio <= maximumRatio && ratio < closestRatio) {
			closestCandidate = candidate;
			closestRatio = ratio;
		}
	}

	return closestCandidate;
}

/**
The filter of a list, like the app picker of the feedback page and the npm list of the open source page. Each item has a `textKey`, like `searchKey()` of the name and the description, and a `nameKey`, like `searchKey()` of the name.

An item matches when its text has each word of the query, like “promise limit” for p-limit, also without spaces or punctuation (`searchKey`). The items whose name has the words come first, as visitors mostly type the name, like “menu bar” for Menu Bar Calendar before the apps that are about the menu bar. Else, the order of the items stays. Without words, all the items match, in their order.

When no item matches, `matches` is only the item whose name is closest to the query, like Gifski for “gifksi” (`closest`), and `isClosest` is `true`. When none is close either, `matches` is empty.
*/
export function filterByWords(query, items) {
	const words = query.split(/\s+/).map(word => searchKey(word)).filter(Boolean);
	const hasWords = key => words.every(word => key.includes(word));
	const matches = items.filter(({textKey}) => hasWords(textKey));

	if (matches.length === 0) {
		const closestItem = closest(words.join(''), items, {key: ({nameKey}) => nameKey});
		return {matches: closestItem ? [closestItem] : [], isClosest: Boolean(closestItem)};
	}

	return {
		matches: [...matches.filter(({nameKey}) => hasWords(nameKey)), ...matches.filter(({nameKey}) => !hasWords(nameKey))],
		isClosest: false,
	};
}
