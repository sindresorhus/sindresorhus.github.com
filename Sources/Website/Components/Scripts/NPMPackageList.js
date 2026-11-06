import {parts} from '/scripts/dom.js';
import {searchKey, closest} from '/scripts/edit-distance.js';

class NPMPackageList extends HTMLElement {
	// The same number as `NPMPackageList.pageSize` in Swift, whose styles show only the first batch before this script runs.
	static #pageSize = 20;

	#filter;
	#status;
	#rows;
	#showMore;
	#visibleCount = NPMPackageList.#pageSize;

	connectedCallback() {
		({filter: this.#filter, status: this.#status, showMore: this.#showMore} = parts(this));

		// The text of a row is the name and the description of its package, not its downloads. The name key is the name without a scope, like “slugify” for `@sindresorhus/slugify`, as that is what a visitor types.
		this.#rows = [...this.querySelectorAll('[data-part="row"]')].map(row => {
			const {text, link} = parts(row);
			return {row, key: searchKey(text.textContent), nameKey: searchKey(link.textContent.replace(/^@[^/]+\//, ''))};
		});

		// The same function, so connecting the element again does not add a second listener.
		this.#filter.addEventListener('input', this.#filterChanged);
		this.#filter.addEventListener('keydown', this.#openFirstPackage);
		this.#showMore.addEventListener('click', this.#showNextPage);

		// Firefox restores the text of the field when the visitor comes back to the page.
		this.#update();
	}

	#filterChanged = () => {
		this.#visibleCount = NPMPackageList.#pageSize;
		this.#update();
	};

	// Enter opens the package whose name is the text of the filter, like ora, which many packages with more downloads also match, or else the first package that shows, like a search, and like the app picker of the feedback page. Not while an input method composes a word, or without a filter.
	#openFirstPackage = event => {
		if (event.key === 'Enter' && !event.isComposing && this.#filter.value.trim()) {
			const query = searchKey(this.#filter.value);
			const firstRow = this.#rows.find(({nameKey}) => nameKey === query) ?? this.#rows.find(({row}) => !row.hidden);

			if (firstRow) {
				parts(firstRow.row).link.click();
			}
		}
	};

	#showNextPage = () => {
		const previousCount = this.#visibleCount;
		this.#visibleCount += NPMPackageList.#pageSize;
		this.#update();

		// Continue keyboard navigation at the first newly shown package.
		const firstNewRow = this.#rows.filter(({row}) => !row.hidden)[previousCount];
		parts(firstNewRow.row).link.focus();
	};

	/*
	A package matches when its name or its description has each word, like “promise limit” for p-limit, also without spaces or punctuation (`searchKey`).

	When no package matches, the package whose name is closest shows instead, like chalk for “chlak” (`closest`), like the app picker of the feedback page.
	*/
	#update = () => {
		const words = this.#filter.value.split(/\s+/).map(word => searchKey(word)).filter(Boolean);
		const matches = this.#rows.filter(({key}) => words.every(word => key.includes(word)));
		const closestRow = matches.length === 0 ? closest(words.join(''), this.#rows, {key: ({nameKey}) => nameKey}) : undefined;
		const shownRows = new Set(closestRow ? [closestRow] : matches.slice(0, this.#visibleCount));

		for (const entry of this.#rows) {
			entry.row.hidden = !shownRows.has(entry);
		}

		this.#status.textContent = closestRow ? 'No package matches. This is the package with the closest name.' : this.#statusText(words.length > 0, matches.length);
		this.#showMore.hidden = matches.length <= this.#visibleCount;
	};

	// The number of matching packages while the filter has text, like “49 packages”, so screen readers hear that the filter worked. Nothing without a filter, where the list has all the packages.
	#statusText(isFiltering, matchCount) {
		if (matchCount === 0) {
			return 'No package matches. Try another word.';
		}

		if (!isFiltering) {
			return '';
		}

		return `${matchCount} ${matchCount === 1 ? 'package' : 'packages'}`;
	}
}

customElements.define('npm-package-list', NPMPackageList);
