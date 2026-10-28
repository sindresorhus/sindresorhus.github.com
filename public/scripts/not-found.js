import {editDistance} from '/scripts/edit-distance.js';

// The paths of the pages that the visitor may have meant, the feedback form, and the help of each app by its slug (`NotFoundPage.ScriptData`).
const {paths, feedback, apps} = JSON.parse(document.querySelector('#not-found-data').textContent);

function requestedPath() {
	let path = location.pathname;

	// A malformed escape, like `%E0`, stays as it is.
	try {
		path = decodeURIComponent(path);
	} catch {}

	// The file of a page can be at `/index.html` of its folder, so `/velja/index.html` finds `/velja`.
	return path.toLowerCase().replace(/\.html$/, '').replace(/\/index$/, '').replace(/\/+$/, '') || '/';
}

// Without the leading slash, which every path has, so it does not make short paths look closer than they are.
const path = requestedPath().slice(1);
// The last part alone too, so `/apps/dato` finds `/dato`.
const lastPart = path.split('/').at(-1);
const parent = path.slice(0, -lastPart.length);

/**
Whether a page in the same folder has a last part that is a whole word of the requested last part, or the other way around, which the edit distance misses when a word is added or left out, like `/blog/buffer` for `/blog/goodbye-nodejs-buffer`, `/dato/privacy` for `/dato/privacy-policy`, and `/about-me` for `/about`. Not a word of fewer than 3 characters, so `/x` does not find `/command-x`.
*/
function sharesWord(name) {
	const nameLastPart = name.split('/').at(-1);

	if (name.slice(0, -nameLastPart.length) !== parent) {
		return false;
	}

	const [shorter, longer] = [lastPart, nameLastPart].toSorted((first, second) => first.length - second.length);
	return shorter.length >= 3 && longer.split('-').includes(shorter);
}

// Words that visitors put in a path to find help, like `/support` or `/dato/help`, as the App Store calls the help link of each app “Support”.
const helpWords = new Set(['support', 'help', 'feedback', 'contact']);

/**
The help for a path with a help word, like the feedback form for `/support`, the form of the app for `/dato/support`, and the FAQ of the app for `/dato/faq`, or `undefined`. It comes before the closest path, which would be the page of the people who give money (`/supporters`), the opposite of what the visitor wants.
*/
function helpPath() {
	if (helpWords.has(path)) {
		return feedback;
	}

	const [slug, word, ...rest] = path.split('/');

	if (rest.length > 0) {
		return;
	}

	// The general form for an unknown app, like a misspelled one in `/datoo/support`.
	if (helpWords.has(word)) {
		return Object.hasOwn(apps, slug) ? apps[slug].feedback : feedback;
	}

	if (word === 'faq' && Object.hasOwn(apps, slug)) {
		return apps[slug].faq;
	}
}

// The edits for each character of the longer string, so a short path needs a closer match than a long one, and `/apps/mac` finds `/apps/macos` (2 edits in 10 characters), not `/apps/faq` (2 in 8). The requested path or its last part, whichever is closer.
const ratio = name => Math.min(...[path, lastPart].map(input => editDistance(input, name) / Math.max(input.length, name.length)));

// The last parts that several pages have, like `release-notes` of `/shortcutie/release-notes` and `/supercharge/release-notes`. They do not say which page the visitor meant.
const sharedLastParts = new Set(Object.entries(Object.groupBy(paths, candidate => candidate.split('/').at(-1).toLowerCase())).filter(([, group]) => group.length > 1).map(([part]) => part));

const candidates = paths.map(candidate => {
	const name = candidate.slice(1).toLowerCase();
	const nameLastPart = name.split('/').at(-1);

	return {
		path: candidate,
		sharesWord: sharesWord(name),
		ratio: ratio(name),
		// The last part of the page alone too, so `/faq` finds `/apps/faq`, but not a last part of several pages, so `/dato/release-notes` does not find `/shortcutie/release-notes`.
		lastPartRatio: sharedLastParts.has(nameLastPart) ? Number.POSITIVE_INFINITY : ratio(nameLastPart),
	};
});

// The path of the candidate with the lowest ratio, the first of them when several have it.
const lowest = (entries, ratioOf) => entries.toSorted((first, second) => ratioOf(first) - ratioOf(second)).at(0)?.path;

/*
Only close matches, like a typo or a missing letter: at most 3 edits in 10 characters, or a page that shares a word. A name of 3 characters, like `now`, must match exactly, so `/how` and `/new` suggest nothing.

A page that shares a word comes first, and of those, the closest, so `/privacy-policy` finds `/privacy`, not `/aiko/privacy-policy`. Then a page whose whole path is close, and then a page whose last part is close, so `/apps/dato` finds `/dato`, not `/apps/macos`.
*/
const suggestion = helpPath()
	?? lowest(candidates.filter(candidate => candidate.sharesWord), candidate => candidate.ratio)
	?? lowest(candidates.filter(candidate => candidate.ratio <= 0.3), candidate => candidate.ratio)
	?? lowest(candidates.filter(candidate => candidate.lastPartRatio <= 0.3), candidate => candidate.lastPartRatio)
	// A page in the folder of a page that does not exist, like `/dato/release-notes`, finds the page, also of an archived app.
	?? paths.find(candidate => candidate === `/${path.split('/')[0]}`);

if (suggestion) {
	const link = document.querySelector('#closest-page-link');
	link.href = suggestion;
	// Only the path, without the query for the form or the fragment for the section, so the address is short and the “?” of the sentence is the only one.
	link.textContent = `sindresorhus.com${suggestion.split(/[?#]/)[0]}`;
	document.querySelector('#closest-page').hidden = false;
}
