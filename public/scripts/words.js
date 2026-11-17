// The word rules of `SuggestedQuestion` in Swift, for the scripts that match the words of a text with the words that the site generator prepared, like the related help of the feedback page (`FAQSuggestions`) and the site search (`SiteSearch`), so the two find the same answers. The data has the rules from Swift: the stopwords, the patterns that split a text into words, and the forms of a word.

// The functions that split a text into words like the site generator (`wordsIn`), and that tell whether two words are forms of one word (`wordsMatch`).
export function wordMatcher({stopwords, wordPatterns, wordForms}) {
	const stopwordSet = new Set(stopwords);
	// The patterns of the site generator, so a text is split like the questions.
	const apostrophePattern = new RegExp(wordPatterns.apostrophe, 'g');
	const menuBarPattern = new RegExp(wordPatterns.menuBar, 'g');
	const wordPattern = new RegExp(wordPatterns.word, 'g');
	// The rules of the site generator for the forms of a word, so the check of the keywords and the page agree: the endings of the forms of a word (with no ending, for the same word), the endings that a word without its last “e” takes, like “freezing” for “freeze”, and the steps from a word to its stem.
	const wordEndings = new Set(wordForms.endings);
	const vowelEndings = new Set(wordForms.vowelEndings);
	const stemSteps = wordForms.stemSteps.map(({pattern, replacement}) => [new RegExp(pattern), replacement]);

	// Apostrophes are removed first, as in the site generator, so “doesn't” becomes “doesnt”, and “menu bar” is one word, “menubar”, like in the questions.
	const wordsIn = text => (text.toLowerCase().replaceAll(apostrophePattern, '').replaceAll(menuBarPattern, 'menubar').match(wordPattern) ?? []).filter(word => !stopwordSet.has(word));

	// The stem of a word, without one ending, a doubled last letter, and a last “e”, so two forms of a word have the same stem, like “crashed” and “crashing”, “stops” and “stopped”, and “enabled” and “enabling”. A step that would leave fewer than 3 letters is skipped, so “ads” does not match “added”. Each word is compared with many words, so its stem is computed once.
	const wordStems = new Map();
	const stemOf = word => {
		if (!wordStems.has(word)) {
			let stem = word;

			for (const [pattern, replacement] of stemSteps) {
				const shorterStem = stem.replace(pattern, replacement);

				if (shorterStem.length >= 3) {
					stem = shorterStem;
				}
			}

			wordStems.set(word, stem);
		}

		return wordStems.get(word);
	};

	// Another form of the same word matches: the word with an ending, like “syncs”, “synced”, and “syncing” for “sync”, also with a doubled last letter, like “quitting” for “quit”, or without a last “e”, like “freezing” for “freeze”. Not a longer word with the same start, like “freezing” for “free”.
	const wordsMatch = (first, second) => {
		const [shorter, longer] = first.length <= second.length ? [first, second] : [second, first];
		// Without its last “e”, a word only takes an ending that starts with a vowel, so “one” does not match “only”.
		const stems = [[shorter, wordEndings], [shorter + shorter.at(-1), wordEndings], ...(shorter.endsWith('e') ? [[shorter.slice(0, -1), vowelEndings]] : [])];
		return stems.some(([stem, endings]) => longer.startsWith(stem) && endings.has(longer.slice(stem.length))) || stemOf(first) === stemOf(second);
	};

	return {wordsIn, wordsMatch};
}
