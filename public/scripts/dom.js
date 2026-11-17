// @ts-check
// Small helpers for the page scripts and the scripts of the elements. Not in `scripted-element.js`, so an element that extends `HTMLElement` can use them without loading the base class, like `import {cloneTemplate} from '/scripts/dom.js';`.

// Whether the visitor prefers reduced motion. It is read once, when the page loads, so a change of the setting while the page is open does not change it (AGENTS.md).
export const prefersReducedMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

// Whether the visitor has a precise pointer that can hover, like a mouse or a trackpad, so an effect that follows the pointer, or a preview that shows on hover, is not for touch screens. A media query list, so `.matches` is read when it is needed.
export const finePointer = matchMedia('(hover: hover) and (pointer: fine)');

// Whether the browser runs on a Mac, like for a link to System Settings or the steps of a file dialog of macOS. An iPad asks for desktop sites by default, so it says that it is a Mac too, but its main input is touch, even with a trackpad, while a Mac, also one with a touch screen, has a trackpad or a mouse as its main input. Read once, when the page loads.
export const isMac = /Mac/.test(navigator.platform) && !(navigator.maxTouchPoints > 1 && matchMedia('(pointer: coarse)').matches);

// A copy of the element of a template, like a row for a list. The template has one element, which is the whole copy.
/**
@param {HTMLTemplateElement} template
@returns {Element}
*/
export const cloneTemplate = template => {
	const element = /** @type {Element} */ (template.content.firstElementChild);
	return /** @type {Element} */ (element.cloneNode(true));
};

// The element that owns a part: the root, or the custom element inside the root that the part is in, as the parts of an element inside belong to that element.
/**
@param {Element} element
@param {Element} root
*/
const ownerOfPart = (element, root) => {
	for (let ancestor = element.parentElement; ancestor; ancestor = ancestor.parentElement) {
		if (ancestor === root || ancestor.localName.includes('-')) {
			return ancestor;
		}
	}
};

// The elements with `.part(Parts.name)` in Swift inside the root, by name, like `const {panel, list} = parts(this);`, or `parts(item).link` for a copy of a template. The parts of an element inside the root belong to that element. A part that the root does not have throws, so a typo or a part that the markup lost fails at once, not later with `null`. The description names the root in the error.
/**
@param {Element} root
@param {string} [description]
@returns {Partial<Record<string, Element>>}
*/
export function parts(root, description = `<${root.localName}>`) {
	/** @type {Partial<Record<string, Element>>} */
	const found = Object.create(null);

	for (const element of root.querySelectorAll('[data-part]')) {
		if (ownerOfPart(element, root) === root) {
			found[/** @type {string} */ (element.getAttribute('data-part'))] ??= element;
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

			return Reflect.get(target, part);
		},
	});
}

// All the elements of a part inside the root, in the order of the page, like `partList(this, 'row')` for the rows of a list, or `partList(this, 'share')[0]` for a part that can be missing. Like `parts()`, the parts of an element inside the root belong to that element.
/**
@param {Element} root
@param {string} name
@returns {Element[]}
*/
export const partList = (root, name) => [...root.querySelectorAll('[data-part]')].filter(element => element.getAttribute('data-part') === name && ownerOfPart(element, root) === root);

// The speculation rules of the site can prerender the page. A script that must wait until the visitor opens the page, like to start a request or an animation, waits with `await prerendered;`. It is `undefined` when the page was not prerendered, so nothing waits.
/** @type {Promise<Event> | undefined} */
export const prerendered = /** @type {Document & {prerendering?: boolean}} */ (document).prerendering ? new Promise(resolve => {
	document.addEventListener('prerenderingchange', resolve, {once: true});
}) : undefined;

// The element that a URL fragment points to, like `location.hash` or the `hash` of a link, or `undefined`.
/**
@param {string} hash
@returns {Element | undefined}
*/
export function elementForFragment(hash) {
	try {
		return document.getElementById(decodeURIComponent(hash.slice(1))) ?? undefined;
	} catch {
		// A malformed fragment, like `#%E0`, points to nothing.
	}
}

// The time of a date in the 24-hour format, like “04:12”, in a time zone, like `'UTC'`, or in the time zone of the visitor without one. The clocks of the site all have this format, like the awake status of the now page and the UTC Time card.
/**
@param {Date} date
@param {string} [timeZone]
*/
export const clockTime = (date, timeZone) => date.toLocaleTimeString('en-US', {timeZone, hour: '2-digit', minute: '2-digit', hourCycle: 'h23'});

// The milliseconds from a date to the start of the next minute, so a clock that updates each minute changes with the clock of the visitor, like `setTimeout(update, untilNextMinute(now))`.
/** @param {Date} date */
export const untilNextMinute = date => 60_000 - (date.getSeconds() * 1000) - date.getMilliseconds();

// The data of a `JSONScript` in Swift, by its ID, like `const {apps} = scriptData('feedback-data');`. A missing script element throws, so a renamed ID fails at once.
/**
@param {string} id
@returns {unknown}
*/
export const scriptData = id => JSON.parse(/** @type {HTMLScriptElement} */ (document.getElementById(id)).text);

// Copies the text, and says “Copied” to screen readers from the element, which must have a box, so not an element with `display: contents`. Returns whether it worked, so the caller shows its copied state. Without clipboard access, it does nothing, as the visitor can still select the text. On macOS, VoiceOver can drop the announcement when another event comes at the same time, like the focus moving. The copied state still shows. Safari 26 does not have `ariaNotify`, so there the copy works without the announcement.
/**
@param {string} text
@param {Element & {ariaNotify?: (announcement: string) => void}} element
*/
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
/** @param {Element} element */
export const sharedPage = element => ({
	title: /** @type {string} */ (element.getAttribute('share-title')),
	url: /** @type {string} */ (element.getAttribute('share-url')),
});

// Shows the share sheet of the browser for a page, like `{title, url}`. Returns `false` when the browser refuses to share, so the caller can show another way to share. Safari on the Mac refuses when it does not count the event as an action of the visitor, like a choice in a `<select>` menu. Closing the share sheet is not an error.
/** @param {ShareData} page */
export async function share(page) {
	try {
		await navigator.share(page);
	} catch (caught) {
		const error = /** @type {Error} */ (caught);
		if (error.name === 'NotAllowedError') {
			return false;
		}

		if (error.name !== 'AbortError') {
			console.error('Share failed:', error.message);
		}
	}

	return true;
}
