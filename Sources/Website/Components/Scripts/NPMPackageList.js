import {partList, parts} from '/scripts/dom.js';
import {searchKey, filterByWords} from '/scripts/edit-distance.js';

class NPMPackageList extends HTMLElement {
	#filter;
	#status;
	#npmSearch;
	#npmSearchQuery;
	#list;
	#rows;
	#shownRows;
	#showMore;
	#visibleCount;

	// The number of packages in the first batch (`NPMPackageList.pageSize` in Swift), whose styles show only this many rows before this script runs.
	get #pageSize() {
		return Number(this.getAttribute('page-size'));
	}

	connectedCallback() {
		({filter: this.#filter, status: this.#status, npmSearch: this.#npmSearch, list: this.#list, showMore: this.#showMore} = parts(this));
		// The maintainer of the search on npm, which `#update` adds the words of the filter to.
		this.#npmSearchQuery = new URL(this.#npmSearch.href).searchParams.get('q');

		// The text of a row is the name and the description of its package, not its downloads. The name key is the name without a scope, like “slugify” for `@sindresorhus/slugify`, as that is what a visitor types.
		this.#rows = partList(this, 'row').map(row => {
			const {text, link} = parts(row);
			return {row, textKey: searchKey(text.textContent), nameKey: searchKey(link.textContent.replace(/^@[^/]+\//, ''))};
		});

		// The history entry keeps the number of rows that “Show more” showed, so a reload shows them again, and the browser can scroll back to the package that the visitor read, like the order of the Wall of Love.
		this.#visibleCount = history.state?.npmVisibleCount ?? this.#pageSize;

		// The same function, so connecting the element again does not add a second listener.
		this.#filter.addEventListener('input', this.#filterChanged);
		this.#filter.addEventListener('keydown', this.#openFirstPackage);
		this.#showMore.addEventListener('click', this.#showNextPage);

		// Firefox restores the text of the field when the visitor comes back to the page.
		this.#update();
	}

	#filterChanged = () => {
		this.#visibleCount = this.#pageSize;
		this.#update();
	};

	// Enter opens the package whose name is the text of the filter, like ora, which many packages with more downloads also match, or else the first package that shows, like a search, and like the app picker of the feedback page. Not while an input method composes a word, or without a filter.
	#openFirstPackage = event => {
		if (event.key === 'Enter' && !event.isComposing && this.#filter.value.trim()) {
			const query = searchKey(this.#filter.value);
			const firstRow = this.#rows.find(({nameKey}) => nameKey === query) ?? this.#shownRows[0];

			if (firstRow) {
				parts(firstRow.row).link.click();
			}
		}
	};

	#showNextPage = () => {
		const previousCount = this.#visibleCount;
		// Each batch is as large as all the rows before it (20, 40, 80, …), so a visitor who reads on gets to the end of the list with a few clicks.
		this.#visibleCount *= 2;
		// Not for each change of the filter, as Safari limits the calls of `replaceState()`. Limitation: after a change of the filter and a reload, the list shows the number of rows of before the change.
		history.replaceState({...history.state, npmVisibleCount: this.#visibleCount}, '');
		this.#update();

		// Continue keyboard navigation at the first newly shown package.
		parts(this.#shownRows[previousCount].row).link.focus();
	};

	/*
	A package matches when its name or its description has each word, like “promise limit” for p-limit, also without spaces or punctuation, and the packages whose name has the words come first, like delay before debounce for “delay” (`filterByWords`). Else, the packages with more downloads come first.

	When no package matches, the package whose name is closest shows instead, like chalk for “chlak”, like the app picker of the feedback page.

	A matching package after the batch is hidden “until found”, so find in page and a link to a text of the page also find it, and the browser shows it. Limitation: the next update of the list, like “Show more”, hides it again when it is after the batch.
	*/
	#update = () => {
		// The matches in their order, or the closest row.
		const {matches, isClosest} = filterByWords(this.#filter.value, this.#rows);
		this.#shownRows = matches.slice(0, this.#visibleCount);
		const shownRows = new Set(this.#shownRows);
		const matchingRows = new Set(matches);

		for (const entry of this.#rows) {
			if (shownRows.has(entry)) {
				entry.row.hidden = false;
			} else {
				entry.row.hidden = matchingRows.has(entry) ? 'until-found' : true;
			}
		}

		// The rows in the order of the matches, and the other rows after them, so screen readers and the keyboard follow the order too, like the app picker of the feedback page. A set keeps the first place of each row.
		const orderedRows = new Set([...matches, ...this.#rows]);
		this.#list.append(...Array.from(orderedRows, ({row}) => row));

		this.#status.textContent = isClosest ? 'No package matches. This is the package with the closest name.' : this.#statusText(searchKey(this.#filter.value) !== '', matches.length);
		this.#updateNPMSearch(isClosest || matches.length === 0);
		this.#showMore.hidden = matches.length <= this.#visibleCount;
		// Each batch is as large as all the rows before it, so the next click shows as many rows as show now, or the rest.
		this.#showMore.textContent = `Show ${Math.min(this.#visibleCount, matches.length - this.#visibleCount)} more`;

		this.#markWords(isClosest);
	};

	/*
	Marks the words of the filter in the names and the descriptions of the shown rows, so the visitor sees why each package matches, like “promise” in the description of p-limit. It is a highlight of the text (`npm-filter-match`, styled in Swift), so the text, find in page, and screen readers stay the same. Nothing is marked without a filter, or when the row is only the closest name.

	Limitation: a word that matches only without the spaces, the punctuation, or the accents of the text, like “promiselimit”, is not marked.
	*/
	#markWords(isClosest) {
		const patterns = isClosest ? [] : this.#filter.value.split(/\s+/).filter(Boolean).map(word => new RegExp(RegExp.escape(word), 'giu'));
		const ranges = [];

		for (const {row} of this.#shownRows) {
			const walker = document.createTreeWalker(parts(row).text, NodeFilter.SHOW_TEXT);

			while (walker.nextNode()) {
				const node = walker.currentNode;

				for (const pattern of patterns) {
					// Match the original text, as case conversion can change its length, like “İ” to “i̇”.
					for (const match of node.data.matchAll(pattern)) {
						const range = new Range();
						range.setStart(node, match.index);
						range.setEnd(node, match.index + match[0].length);
						ranges.push(range);
					}
				}
			}
		}

		CSS.highlights.set('npm-filter-match', new Highlight(...ranges));
	}

	// When no package of the list matches, a link to a search of all my packages on npm with the words of the filter, as the list only has the packages with a repository.
	#updateNPMSearch(isShown) {
		this.#npmSearch.hidden = !isShown;

		if (isShown) {
			const url = new URL(this.#npmSearch.href);
			url.searchParams.set('q', `${this.#npmSearchQuery} ${this.#filter.value.trim()}`);
			this.#npmSearch.href = url.href;
		}
	}

	// The number of matching packages while the filter has text, like “49 packages”, so screen readers hear that the filter worked. Nothing without a filter, where the list has all the packages.
	#statusText(isFiltering, matchCount) {
		if (matchCount === 0) {
			return 'No package of the list matches.';
		}

		if (!isFiltering) {
			return '';
		}

		return `${matchCount} ${matchCount === 1 ? 'package' : 'packages'}`;
	}
}

customElements.define('npm-package-list', NPMPackageList);
