import {scriptData} from '/scripts/dom.js';
import {editDistance} from '/scripts/edit-distance.js';

// The pages that the visitor may have meant, with the text of their buttons, the feedback form, the help of each app by its slug, and the pages of the platforms by their other names (`NotFoundPage.ScriptData`).
const {pages, feedback, apps, platformPaths} = scriptData('not-found-data');
// The text of the button of each page by its path, in the order of the pages.
const labels = new Map(pages.map(page => [page.path, page.label]));
const paths = [...labels.keys()];

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
Whether a page in the same folder has a last part with each word of the requested last part, or the other way around, which the edit distance misses when words are added or left out, like `/blog/buffer` for `/blog/goodbye-nodejs-buffer`, `/guides/flush-dns` for `/guides/flush-dns-cache-mac`, `/dato/privacy` for `/dato/privacy-policy`, and `/about-me` for `/about`. Not the words of fewer than 3 characters, so `/x` does not find `/command-x`.
*/
function sharesWord(name) {
	const nameLastPart = name.split('/').at(-1);

	if (name.slice(0, -nameLastPart.length) !== parent) {
		return false;
	}

	const [shorter, longer] = [lastPart, nameLastPart].toSorted((first, second) => first.length - second.length);
	const longerWords = new Set(longer.split('-'));
	const shorterWords = shorter.split('-').filter(word => word.length >= 3);
	return shorterWords.length > 0 && shorterWords.every(word => longerWords.has(word));
}

// Words that visitors put in a path to find help, like `/support` or `/dato/help`, as the App Store calls the help link of each app “Support”.
const helpWords = new Set(['support', 'help', 'feedback', 'contact']);

// A help word next to an app slug, also with one typo in a longer word, like `/dato/suport`. Not in `help`, as one edit gives other words, like `hell` and `held`. A help word alone must be exact, as a typo of it can be another page, like `/contacts` for `/contact`.
const isHelpWordOfApp = part => helpWords.values().some(word => part === word || (word.length > 4 && editDistance(part, word) <= 1));

/**
The help for a path with a help word, like the feedback form for `/support`, the form of the app for `/dato/support`, and the FAQ of the app for `/dato/faq`, or `undefined`. The word and the slug can be in any order, and an `apps` part is left out, so `/feedback/dato` and `/apps/dato/feedback` find the form of the app too. It comes before the closest path, which would be the page of the people who give money (`/supporters`), the opposite of what the visitor wants.
*/
function helpPath() {
	const parts = path.split('/').filter(part => part !== 'apps');

	if (parts.length === 1) {
		return helpWords.has(parts[0]) ? feedback : undefined;
	}

	if (parts.length !== 2) {
		return;
	}

	const pairs = [parts, parts.toReversed()];

	// The general form for an unknown app, like a misspelled one in `/datoo/support`.
	const helpPair = pairs.find(([word]) => isHelpWordOfApp(word));
	if (helpPair) {
		const [, slug] = helpPair;
		return Object.hasOwn(apps, slug) ? apps[slug].feedback : feedback;
	}

	const faqPair = pairs.find(([word, slug]) => word === 'faq' && Object.hasOwn(apps, slug));
	if (faqPair) {
		const [, slug] = faqPair;
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

For a request of one part, the page with that last part comes first, so `/shortcuts` finds `/apps/shortcuts`, not `/shortcutie`, which is only close. Not for more parts, so `/dato/privacy` finds `/dato/privacy-policy`, not `/privacy`. Then a page that shares a word, and of those, the closest, so `/privacy-policy` finds `/privacy`, not `/aiko/privacy-policy`. Then a page whose whole path is close, and then a page whose last part is close, so `/apps/dato` finds `/dato`, not `/apps/macos`.
*/
const suggestion = helpPath()
	// A name of a device, like `/apps/ipad` or `/mac`, finds the page of its platform, not a path that is only close, like `/apps/paid`.
	?? (Object.hasOwn(platformPaths, path) ? platformPaths[path] : undefined)
	?? (parent === '' ? candidates.find(candidate => candidate.lastPartRatio === 0)?.path : undefined)
	?? lowest(candidates.filter(candidate => candidate.sharesWord), candidate => candidate.ratio)
	?? lowest(candidates.filter(candidate => candidate.ratio <= 0.3), candidate => candidate.ratio)
	?? lowest(candidates.filter(candidate => candidate.lastPartRatio <= 0.3), candidate => candidate.lastPartRatio)
	// A page in the folder of a page that does not exist, like `/dato/release-notes`, finds the page, also of an archived app.
	?? paths.find(candidate => candidate === `/${path.split('/')[0]}`);

if (suggestion) {
	// With the query and the fragment of the request, when the suggestion has none, so `/velja/#browser-profiles` leads to the section, and the help of an app, like `/feedback?product=Dato`, keeps its own query.
	const url = new URL(suggestion, location.href);
	url.search ||= location.search;
	url.hash ||= location.hash;

	const link = document.querySelector('#closest-page-link');
	link.href = url.pathname + url.search + url.hash;
	// The name of the page, not its path, which is for machines. Without the query for the form or the fragment for the section, so the button is short.
	link.textContent = labels.get(url.pathname) ?? `Go to ${url.pathname}`;
	link.hidden = false;
	document.querySelector('#home-link').hidden = true;
}
