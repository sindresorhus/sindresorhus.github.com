import {cloneTemplate, isMac, parts} from '/scripts/dom.js';

/**
The configuration encoded by SiteSearch.Config in Swift. ScriptTypeTests checks the encoded values against this type.
@typedef {Readonly<{indexPath: string}>} SiteSearchConfig
*/

// The most results that a group shows at first, so the results of all the groups fit on about one screen. A group with more ends with a button that shows the others.
const maximumGroupCount = 5;

// How long the visitor does not type before a search without results is counted, so the words that the visitor is still typing are not counted.
const noResultsDelay = 2000;

/*
The function that finds the entries of the index that a query is about, in the groups of the index, with the word functions of `/scripts/words.js` and the closest name of `/scripts/edit-distance.js`. An entry matches when its title has the whole query at the start of a word, like “ai” for Ask AI, whose words are too short to be words of the index, or when each word of the query is a word of the entry, another form of it, or the start of it, as the visitor may still be typing it. The entries of one rank are in the order of the index, after the entries of the page that is open (`pagePath`), like the questions of the app on its page.

The entries of one rank whose titles are more about the query come first, like “Change the Default Browser on Mac” before “Change the Default Browser Automatically on Mac”. When the first result only matches by words, like an app by the words of its subtitle, the first title of the first later group that has the whole query in a title is first, as the top hit, so Return opens it, when the query covers more of its words than of the title of the first result, like “Menu Bar Apps” before Menu Bar Spacing for “menu bar apps”. When the first result only matches by words that it does not show, like a page by its headings, a title with all the words of the query counts too, like the question “How can I get a refund?” before the terms for “how do i get a refund”, and so does it for a query of more than one word when the first result does not have the words in its title, like the guide “Flush the DNS Cache on Mac” for “flush dns”, before the Supercharge app and a question with the whole query in a longer title. When nothing matches, the result is the app with the closest name, like Gifski for “gifksi”, with `isClosest`, and else, for a query of more than one word, like “screenshot location”, the entries with the most words of the query, with `isPartial`.

A word of the query of 5 or more letters that is not a word of the index, another form of one, or the start of one, is the closest word of the index, like “calendar” for “calender”, and the groups have the corrected query (`correctedQuery`) and the words that the search used (`queryWords`), for the marks in the titles. A word that starts with the closest word, like “photosh” with “photos”, is a longer word that the visitor is still typing, so it is not corrected. Spaces, hyphens, underscores, periods, and slashes are the same in the query and the titles, so “p limit” is the title of p-limit, and “ds store” the start of “DS_Store”, and a word of the query with a part of fewer than 3 letters, like “wi-fi” or “e-mail”, is one word, like the index has it (“wifi” or “email”), when a word of the index starts with it. Only a word that the query has as it is gets a correction, not a word without its apostrophe or a joined word. A question of the general FAQ, which is about all the apps, only needs the words of the query that are not the name of an app, so “supercharge refund” finds “How can I get a refund?”.
*/
function searchMatcher(index, {wordsIn, wordsMatch, closest, searchKey}) {
	const [appGroup] = index.groups;
	const indexWords = [...new Set(index.groups.flatMap(group => group.entries.flatMap(entry => entry.words)))];
	const loose = value => value.replaceAll(/[\s+\-_./]+/g, ' ').trim();
	const appNames = appGroup.entries.map(app => wordsIn(loose(app.title))).filter(nameWords => nameWords.length > 0);
	// The names of a title with a hyphen, and a word of two capital letters with the next word, as one word, like the index has them (`joinedWords(in:)` in Swift), so “wifi” finds “Wi-Fi” in a title like a plain word.
	const joinedTitle = title => title.replaceAll(/[A-Za-z\d]+(?:-[A-Za-z\d]+)+|\b[A-Z]{2}\s+[A-Za-z\d]+/g, name => name.replaceAll(/[^A-Za-z\d]/g, ''));
	const titleWordsIn = title => [...new Set([...wordsIn(loose(title)), ...wordsIn(joinedTitle(title))])];

	// A correction is kept only when the corrected query matches, so “remind me to drink water” does not show results for “drink later”, and else the query is searched as it is (`correctsWords` false).
	const search = (query, pagePath, correctsWords = true) => {
		const typedText = query.trim();
		const looseQuery = loose(typedText);

		if (!looseQuery) {
			return [];
		}

		// The words with a short part, like “wi-fi” and “e-mail”, as one word, like the index has them (“wifi” and “email”), in place of their parts, so “e-mail” also finds a title with only “email”. A joined word that does not start a word of the index, like “xaxis” for “x-axis”, keeps its parts.
		const hyphenatedWords = [...typedText.toLowerCase().matchAll(/[a-z\d]+(?:-[a-z\d]+)+/g)]
			.map(([word]) => word.split('-'))
			.filter(wordParts => wordParts.some(part => part.length < 3) && indexWords.some(indexWord => indexWord.startsWith(wordParts.join(''))));
		const joinedParts = new Set(hyphenatedWords.flat());
		const joinedWords = hyphenatedWords.map(wordParts => wordParts.join(''));

		// An underscore separates words here, though JavaScript's word boundary treats it as part of a word.
		const wholeWordIn = word => new RegExp(`(?<![a-z0-9])${RegExp.escape(word)}(?![a-z0-9])`, 'gi');
		const corrections = new Map();

		// Only a word that the typed text has as it is, so the text that the dialog shows has the correction, not a word without its apostrophe, like “doesnt” for “doesn't”.
		const correctedWord = word => {
			if (!correctsWords || word.length < 5 || !wholeWordIn(word).test(typedText) || indexWords.some(indexWord => indexWord.startsWith(word) || wordsMatch(word, indexWord))) {
				return word;
			}

			const correction = closest(word, indexWords);

			if (!correction || word.startsWith(correction)) {
				return word;
			}

			corrections.set(word, correction);
			return correction;
		};

		const queryWords = [...new Set([...wordsIn(looseQuery).filter(word => !joinedParts.has(word)), ...joinedWords].map(word => correctedWord(word)))];
		let text = typedText;

		for (const [word, correction] of corrections) {
			text = text.replaceAll(wholeWordIn(word), correction);
		}

		const wholeWordPattern = new RegExp(`\\b${RegExp.escape(loose(text))}\\b`, 'i');
		const wordStartPattern = new RegExp(`\\b${RegExp.escape(loose(text))}`, 'i');
		const hasWord = (words, queryWord) => words.some(word => word.startsWith(queryWord) || wordsMatch(queryWord, word));

		// The words of the query that are not the name of an app, for the questions of the general FAQ.
		const appNameWords = new Set(appNames.filter(nameWords => nameWords.every(word => queryWords.includes(word))).flat());
		const otherWords = queryWords.filter(queryWord => !appNameWords.has(queryWord));
		const isGeneralQuestion = entry => entry.url.startsWith('/apps/faq#');
		const hasWords = (words, neededWords) => neededWords.length > 0 && neededWords.every(queryWord => hasWord(words, queryWord));

		// Short acronyms like “AI” distinguish titles even though the word matcher skips words of fewer than three letters.
		const typedAcronyms = new Set(looseQuery.toUpperCase().match(/\b[A-Z]{2}\b/g) ?? []);

		// Prefer full words and their variants to prefixes in word-based title matches. For ties, prefer results from this page, then titles with fewer unrelated words.
		const titleMatch = ({entry, rank}) => {
			const titleWords = rank <= 4 ? titleWordsIn(entry.title) : [];
			const coverage = titleWords.filter(word => queryWords.some(queryWord => hasWord([word], queryWord))).length / Math.max(titleWords.length, 1);
			let fullWords = 0;

			if (rank === 4) {
				fullWords = queryWords.filter(queryWord => titleWords.some(word => wordsMatch(queryWord, word))).length;
				fullWords += (entry.title.match(/\b[A-Z]{2}\b/g) ?? []).filter(acronym => typedAcronyms.has(acronym)).length;
			}

			return {entry, rank, fullWords, coverage};
		};
		const isOnPage = entry => entry.url.split('#')[0] === pagePath;

		// The place of the entry in the order of the results, or `undefined` when it does not match: the query as whole words in the title, then as the start of a word, like “ai” for Aiko after Ask AI, each first at the start of the title, then the words of the query in the title, then in the title and the detail that the result shows, like the subtitle of an app, and then in the other words of the entry, like the headings of a page or the short answer of a guide.
		const rank = entry => {
			const neededWords = isGeneralQuestion(entry) && otherWords.length > 0 ? otherWords : queryWords;

			const titleRank = (pattern, firstRank) => {
				const titleIndex = [entry.title, joinedTitle(entry.title)].map(title => loose(title).search(pattern)).find(titleIndex => titleIndex >= 0) ?? -1;
				return titleIndex < 0 ? undefined : firstRank + (titleIndex > 0 ? 1 : 0);
			};

			const wordRank = () => {
				if (!hasWords(entry.words, neededWords)) {
					return undefined;
				}

				if (hasWords(titleWordsIn(entry.title), neededWords)) {
					return 4;
				}

				return hasWords(titleWordsIn(`${entry.title} ${entry.detail ?? ''}`), neededWords) ? 5 : 6;
			};

			return titleRank(wholeWordPattern, 0) ?? titleRank(wordStartPattern, 2) ?? wordRank();
		};

		const matchingGroups = rankOf => index.groups
			.map(group => ({
				title: group.title,
				symbol: group.symbol,
				matches: group.entries
					.map(entry => ({entry, rank: rankOf(entry)}))
					.filter(match => match.rank !== undefined)
					.map(titleMatch)
					// The stable sort keeps entries tied on rank, page, and title match in index order.
					.sort((first, second) => (first.rank - second.rank) || (second.fullWords - first.fullWords) || (isOnPage(second.entry) - isOnPage(first.entry)) || (second.coverage - first.coverage)),
			}))
			.filter(group => group.matches.length > 0);

		const correctedQuery = corrections.size > 0 ? text : undefined;

		const toResults = (groups, flags = {}) => groups
			.filter(group => group.matches.length > 0)
			.map(({title, symbol, matches}) => ({title, symbol, entries: matches.map(match => match.entry), correctedQuery, queryWords, ...flags}));

		const groups = matchingGroups(rank);

		if (groups.length === 0) {
			if (corrections.size > 0) {
				return search(query, pagePath, false);
			}

			const app = closest(searchKey(text), appGroup.entries, {key: entry => searchKey(entry.title)});

			if (app) {
				return [{title: 'App with the Closest Name', symbol: appGroup.symbol, entries: [app], isClosest: true}];
			}

			// The entries with the most words of the query, first the ones with these words in the title.
			const matchedWordCount = words => queryWords.filter(queryWord => hasWord(words, queryWord)).length;
			const mostWords = queryWords.length > 1 ? Math.max(...index.groups.flatMap(group => group.entries.map(entry => matchedWordCount(entry.words)))) : 0;

			if (mostWords > 0) {
				const partialRank = entry => {
					if (matchedWordCount(entry.words) < mostWords) {
						return undefined;
					}

					return matchedWordCount(wordsIn(entry.title)) === mostWords ? 0 : 1;
				};

				return toResults(matchingGroups(partialRank), {isPartial: true});
			}

			return [];
		}

		// The whole query in a title (rank 1 or better), or all the words of the query in a title (rank 4) when the first result only has them in words that it does not show (rank 6), or for a query of more than one word, not in its title (rank 5). For a query of one word that the first result shows, like Camera Preview, whose subtitle has “webcam”, only a title that starts with the query (rank 0).
		const firstRank = groups[0].matches[0].rank;
		const topHitRank = firstRank === 6 || (firstRank === 5 && queryWords.length > 1) ? 4 : (firstRank === 5 ? 0 : 1);
		const topHitGroup = firstRank >= 4 ? groups.slice(1).find(group => group.matches[0].rank <= topHitRank && group.matches[0].coverage > groups[0].matches[0].coverage) : undefined;

		if (topHitGroup) {
			groups.unshift({title: 'Top Hit', symbol: topHitGroup.symbol, matches: [topHitGroup.matches.shift()]});
		}

		return toResults(groups);
	};

	return search;
}

// The pattern of the parts of a title that the query matches, like “Calendar” in “Open Google Calendar from the Mac Menu Bar” for “calendar”: the whole query, or a word of the query, at the start of a word. The longest first, so a word does not cut the whole query in two. A hyphen is optional between the letters, like the joined words of the search, so “wifi” marks “Wi-Fi”, and “e-mail” marks “Email”.
function highlightPattern(query, queryWords) {
	const terms = [...new Set([query.trim(), ...queryWords].map(term => term.replaceAll('-', '')))]
		.filter(Boolean)
		.sort((first, second) => second.length - first.length)
		.map(term => [...term].map(character => RegExp.escape(character)).join('-?'));

	return terms.length > 0 ? new RegExp(`\\b(${terms.join('|')})`, 'i') : undefined;
}

// The text with the parts that the pattern matches in `<strong>`, as text, not as HTML, as the titles and details are content.
function highlightedText(text, highlight) {
	return (highlight ? text.split(highlight) : [text]).map((part, index) => {
		if (index % 2 === 0) {
			return part;
		}

		const strong = document.createElement('strong');
		strong.textContent = part;
		return strong;
	});
}

class SiteSearch extends HTMLElement {
	// The function that finds the results, and the groups before the visitor types, from the index, which loads when the dialog opens the first time, as it is large.
	#search;
	#start;
	#loading;

	// The links of the results and the buttons that show more of a group, in their order, for the arrow keys and Return.
	#links = [];

	// The groups whose other results the visitor showed, until the query changes.
	#expandedGroups = new Set();

	// The searches without results that were counted, so a search is counted once.
	#countedQueries = new Set();
	#noResultsTimer;

	connectedCallback() {
		const {button, dialog, field, results} = parts(this);
		// The same functions, so connecting the element again does not add second listeners.
		dialog.addEventListener('toggle', this.#toggle);
		results.addEventListener('click', this.#close);
		dialog.addEventListener('keydown', this.#moveFocus);
		field.addEventListener('input', this.#update);
		field.addEventListener('keydown', this.#openFirstResult);
		field.addEventListener('keydown', this.#closeWithEscape);
		document.addEventListener('keydown', this.#handleShortcut);
		document.addEventListener('click', this.#openFromButton);

		// The shortcut, so a visitor with a mouse learns it without more text in the header.
		button.title = isMac ? 'Search (⌘K)' : 'Search (Ctrl+K)';

		// A link with a query, like from the search of a browser (OpenSearch), opens the results. The query leaves the address, so a reload does not open the search again.
		const query = new URLSearchParams(location.search).get('q');

		if (query !== null) {
			const url = new URL(location.href);
			url.searchParams.delete('q');
			history.replaceState(history.state, '', url);
			this.#open(query);
		}

		// The button opens the dialog also before the script runs, and the open dialog sends no more events.
		if (dialog.matches(':popover-open')) {
			this.#toggle({newState: 'open'});
		}
	}

	disconnectedCallback() {
		clearTimeout(this.#noResultsTimer);
		document.removeEventListener('keydown', this.#handleShortcut);
		document.removeEventListener('click', this.#openFromButton);
	}

	// A result can be on the same page, like a question of the app page that is open, where the page does not load again, so the dialog closes, and the page can scroll to it. A result that opens in a new tab keeps the search open.
	#close = event => {
		if (!event.target.closest('a') || event.metaKey || event.ctrlKey || event.shiftKey) {
			return;
		}

		parts(this).dialog.hidePopover();
	};

	#toggle = event => {
		if (event.newState !== 'open') {
			clearTimeout(this.#noResultsTimer);
			return;
		}

		if (this.#search) {
			this.#render();
			return;
		}

		// A failed request is tried again at the next open.
		this.#loading ??= this.#loadIndex().catch(() => {
			this.#loading = undefined;
			parts(this).loadError.hidden = false;
		});
	};

	async #loadIndex() {
		parts(this).loadError.hidden = true;

		const {indexPath} = /** @type {SiteSearchConfig} */ (JSON.parse(this.dataset.config));

		const [{wordMatcher}, {closest, searchKey}, index] = await Promise.all([
			import('/scripts/words.js'),
			import('/scripts/edit-distance.js'),
			fetch(indexPath).then(response => {
				if (!response.ok) {
					throw new Error(`The search index did not load: ${response.status}`);
				}

				return response.json();
			}),
		]);

		this.#search = searchMatcher(index, {...wordMatcher(index), closest, searchKey});
		this.#start = index.start;

		// The visitor may have typed while the index loaded.
		this.#update();
	}

	// A new query shows the first results of each group again.
	#update = () => {
		this.#expandedGroups.clear();
		this.#render();
	};

	#render() {
		if (!this.#search) {
			return;
		}

		const {dialog, field, results, partialNote, correctionNote, correctedQuery, empty, emptyQuery, status} = parts(this);
		const query = field.value.trim();
		const groups = query ? this.#search(query, location.pathname) : this.#start;
		// The results of a corrected query have the words of the correction, not the typed words, and the words that the search used, like “email” for “e-mail”, not “mail”.
		const resultQuery = groups[0]?.correctedQuery ?? query;
		const highlight = query ? highlightPattern(resultQuery, groups[0]?.queryWords ?? []) : undefined;
		this.#links = [];
		results.replaceChildren(...groups.map(group => this.#groupElement(group, highlight)));

		const count = groups.flatMap(group => group.entries).length;
		const isPartial = query !== '' && groups[0]?.isPartial === true;
		const isClosest = groups[0]?.isClosest === true;
		empty.hidden = !query || count > 0;
		emptyQuery.textContent = query;
		partialNote.hidden = !isPartial;
		correctionNote.hidden = resultQuery === query || count === 0 || isClosest;
		correctedQuery.textContent = resultQuery;

		// Screen readers hear the number, not all the results again for each change, after the notes that the dialog shows.
		const countText = `${count === 0 ? 'No' : count} ${count === 1 ? 'result' : 'results'}`;
		const notes = [correctionNote, partialNote].filter(note => !note.hidden).map(note => note.textContent);
		status.textContent = !query ? '' : (isClosest ? 'No results. This is the app with the closest name.' : [...notes, countText].join(' '));

		clearTimeout(this.#noResultsTimer);
		if ((count === 0 || isClosest || isPartial) && /[\p{L}\p{N}]/u.test(query) && dialog.matches(':popover-open')) {
			this.#noResultsTimer = setTimeout(() => {
				if (dialog.matches(':popover-open')) {
					this.#countNoResults(query);
				}
			}, noResultsDelay);
		}
	}

	// The list of a group, with the first results, and a button that shows the others.
	#groupElement(group, highlight) {
		const {groupTemplate, resultTemplate, moreTemplate} = parts(this);
		const groupElement = cloneTemplate(groupTemplate);
		const {groupTitle, groupList} = parts(groupElement);
		groupTitle.textContent = group.title;
		groupList.ariaLabel = group.title;

		const entries = this.#expandedGroups.has(group.title) ? group.entries : group.entries.slice(0, maximumGroupCount);

		groupList.replaceChildren(...entries.map(entry => {
			const item = cloneTemplate(resultTemplate);
			const itemParts = parts(item);
			const {link, icon, title, detail} = itemParts;
			this.#links.push(link);
			link.href = entry.url;
			detail.replaceChildren(...highlightedText(entry.detail ?? '', highlight));
			detail.hidden = !entry.detail;
			title.replaceChildren(...highlightedText(entry.title, highlight));

			// An entry with an icon, like an app, shows it, and the others the symbol of the group in its place, like a question mark, so the titles line up.
			icon.hidden = !entry.icon;

			if (entry.icon) {
				icon.src = entry.icon;
			} else {
				itemParts[group.symbol].hidden = false;
			}

			return item;
		}));

		if (entries.length < group.entries.length) {
			const item = cloneTemplate(moreTemplate);
			const {moreButton, moreLabel} = parts(item);
			moreLabel.textContent = `Show ${group.entries.length - entries.length} More`;
			this.#links.push(moreButton);

			moreButton.addEventListener('click', () => {
				const index = this.#links.indexOf(moreButton);
				this.#expandedGroups.add(group.title);
				this.#render();
				// The first new result gets the focus, so the keyboard goes on from there.
				this.#links[index]?.focus();
			});

			groupList.append(item);
		}

		return groupElement;
	}

	// Counts a search without results with an event of GoatCounter, which counts the visits of the site, so the owner sees what visitors look for, like a guide that the site does not have. Only the query, short and in lowercase, once for each query.
	#countNoResults(query) {
		const normalizedQuery = query.toLowerCase().slice(0, 50);

		if (this.#countedQueries.has(normalizedQuery)) {
			return;
		}

		this.#countedQueries.add(normalizedQuery);
		window.goatcounter?.count({path: `search: ${normalizedQuery}`, title: 'No search results', event: true});
	}

	// The Down Arrow and Up Arrow keys move the focus from the field through the results and back, and Return opens the result with the focus, like any link.
	#moveFocus = event => {
		if ((event.key !== 'ArrowDown' && event.key !== 'ArrowUp') || event.isComposing || event.defaultPrevented || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) {
			return;
		}

		const items = [parts(this).field, ...this.#links];
		const next = items[items.indexOf(document.activeElement) + (event.key === 'ArrowDown' ? 1 : -1)];

		if (next) {
			event.preventDefault();
			next.focus();
		}
	};

	// Return in the field opens the first result, as it is the best one.
	#openFirstResult = event => {
		if (event.key !== 'Enter' || event.isComposing) {
			return;
		}

		const [firstResult] = this.#links;

		// The start groups are links too, but an empty field has no result to open.
		if (firstResult && parts(this).field.value.trim()) {
			event.preventDefault();
			firstResult.click();
		}
	};

	// Escape closes the dialog also with text in the field, where it would only clear the text of a search field first, as the hint says “Esc to close”. The text stays for the next open.
	#closeWithEscape = event => {
		if (event.key !== 'Escape' || event.isComposing) {
			return;
		}

		event.preventDefault();
		parts(this).dialog.hidePopover();
	};

	// Opens the dialog with the focus in the field. A query replaces the text of the field, with the caret at its end, so the visitor types the rest. Without one (or with an empty one, like the button of the footer), the text of the last search is selected, so typing replaces it.
	#open(query) {
		const {dialog, field} = parts(this);

		if (query) {
			field.value = query;
			this.#update();
		}

		if (!dialog.matches(':popover-open')) {
			dialog.showPopover();
		}

		field.focus();

		if (!query) {
			field.select();
		} else {
			field.setSelectionRange(query.length, query.length);
		}
	}

	// A button outside the header that opens the search, like in the footer, or with the name of an app below the FAQ heading of its page.
	#openFromButton = event => {
		const button = event.target.closest?.('[data-search-query]');

		if (!button) {
			return;
		}

		event.preventDefault();
		this.#open(button.dataset.searchQuery);
	};

	// Command+K and Control+K toggle the search, and `/` opens it. The platform shortcut also closes the search from its field, preserving Control+K as a text editing shortcut on a Mac.
	#handleShortcut = event => {
		const isCommandK = event.key?.toLowerCase() === 'k' && (event.metaKey || event.ctrlKey) && !event.altKey && !event.shiftKey;
		const isSlash = event.key === '/' && !event.metaKey && !event.ctrlKey && !event.altKey;

		if ((!isCommandK && !isSlash) || event.defaultPrevented || event.isComposing) {
			return;
		}

		const {dialog, field} = parts(this);
		const closesSearch = isCommandK && dialog.matches(':popover-open');
		const closesFromSearchField = closesSearch && event.target === field && (!isMac || event.metaKey);

		if (!closesFromSearchField && event.target.closest?.('input, textarea, select, [contenteditable]')) {
			return;
		}

		event.preventDefault();

		if (event.repeat) {
			return;
		}

		if (closesSearch) {
			dialog.hidePopover();
		} else {
			this.#open();
		}
	};
}

customElements.define('site-search', SiteSearch);
