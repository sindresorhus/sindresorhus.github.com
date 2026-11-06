// Small helpers for the page scripts and the scripts of the elements. Not in `scripted-element.js`, so an element that extends `HTMLElement` can use them without loading the base class, like `import {cloneTemplate} from '/scripts/dom.js';`.

// Whether the visitor prefers reduced motion. It is read once, when the page loads, so a change of the setting while the page is open does not change it (AGENTS.md).
export const prefersReducedMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

// A copy of the element of a template, like a row for a list. The template has one element, which is the whole copy.
export const cloneTemplate = template => template.content.firstElementChild.cloneNode(true);

// The element that owns a part: the root, or the custom element inside the root that the part is in, as the parts of an element inside belong to that element.
const ownerOfPart = (element, root) => {
	for (let ancestor = element.parentElement; ancestor; ancestor = ancestor.parentElement) {
		if (ancestor === root || ancestor.localName.includes('-')) {
			return ancestor;
		}
	}
};

// The elements with `.part(Parts.name)` in Swift inside the root, by name, like `const {panel, list} = parts(this);`, or `parts(item).link` for a copy of a template. The parts of an element inside the root belong to that element. A part that the root does not have throws, so a typo or a part that the markup lost fails at once, not later with `null`. The description names the root in the error.
export function parts(root, description = `<${root.localName}>`) {
	const found = {};

	for (const element of root.querySelectorAll('[data-part]')) {
		if (ownerOfPart(element, root) === root) {
			found[element.dataset.part] ??= element;
		}
	}

	return new Proxy(found, {
		// `then` and `toJSON` are what `await` and `JSON.stringify()` look for, so they are not parts.
		get(target, part) {
			if (
				typeof part === 'string'
				&& !Object.hasOwn(target, part)
				&& part !== 'then'
				&& part !== 'toJSON'
			) {
				throw new Error(`${description} has no part “${part}”.`);
			}

			return target[part];
		},
	});
}

// The speculation rules of the site can prerender the page. A script that must wait until the visitor opens the page, like to start a request or an animation, waits with `await prerendered;`. It is `undefined` when the page was not prerendered, so nothing waits.
export const prerendered = document.prerendering ? new Promise(resolve => {
	document.addEventListener('prerenderingchange', resolve, {once: true});
}) : undefined;

// The element that a URL fragment points to, like `location.hash` or the `hash` of a link, or `undefined`.
export function elementForFragment(hash) {
	try {
		return document.getElementById(decodeURIComponent(hash.slice(1))) ?? undefined;
	} catch {
		// A malformed fragment, like `#%E0`, points to nothing.
	}
}

// The data of a `JSONScript` in Swift, by its ID, like `const {apps} = scriptData('feedback-data');`. A missing script element throws, so a renamed ID fails at once.
export const scriptData = id => JSON.parse(document.getElementById(id).textContent);

// Copies the text, and says “Copied” to screen readers from the element, which must have a box, so not an element with `display: contents`. Returns whether it worked, so the caller shows its copied state. Without clipboard access, it does nothing, as the visitor can still select the text. On macOS, VoiceOver can drop the announcement when another event comes at the same time, like the focus moving. The copied state still shows. Safari 26 does not have `ariaNotify`, so there the copy works without the announcement.
export async function copy(text, element) {
	try {
		await navigator.clipboard.writeText(text);
	} catch {
		return false;
	}

	element.ariaNotify?.('Copied');
	return true;
}

// The page that an element shares, from its `share-title` and `share-url` attributes (`SharedPage` in Swift), like `{title, url}` for `share()`.
export const sharedPage = element => ({title: element.getAttribute('share-title'), url: element.getAttribute('share-url')});

// Shows the share sheet of the browser for a page, like `{title, url}`. Returns `false` when the browser refuses to share, so the caller can show another way to share. Safari on the Mac refuses when it does not count the event as an action of the visitor, like a choice in a `<select>` menu. Closing the share sheet is not an error.
export async function share(page) {
	try {
		await navigator.share(page);
	} catch (error) {
		if (error.name === 'NotAllowedError') {
			return false;
		}

		if (error.name !== 'AbortError') {
			console.error('Share failed:', error.message);
		}
	}

	return true;
}
