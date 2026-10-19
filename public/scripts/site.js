// A greeting for the curious ones who open the developer tools. The source link is in the footer.
console.log(`%c
       \\
        \\
         >\\/7
     _.-(6'  \\
    (=___._/\` \\       Hello, curious one!
         )  \\ |
        /   / |       This site is generated with Swift.
       /    > /       Source: ${document.querySelector('[data-source-link]')?.href ?? ''}
      j    < _\\
  _.-' :      \`\`.
  \\ r=._\\        \`.
`, 'color: #ec4899; font-family: ui-monospace, monospace;');

// Opens the collapsible section that the URL fragment points to, and returns it. Browsers open a section for find-in-page and for a fragment inside it, but not for a fragment that is the section itself.
function openTargetedSection() {
	let id;

	try {
		id = decodeURIComponent(location.hash.slice(1));
	} catch {
		// A malformed fragment, like `#%E0`, points to nothing.
		return;
	}

	const target = id ? document.getElementById(id) : undefined;

	if (target instanceof HTMLDetailsElement) {
		target.open = true;
		return target;
	}
}

openTargetedSection();

window.addEventListener('hashchange', async () => {
	const {hash} = location;
	const section = openTargetedSection();

	if (!section) {
		return;
	}

	// Opening a section closes the open section of its group, like a question with a link to another question, which animates its height. When that section is above, the page above shrinks while the browser scrolls, so the section is scrolled to again after the animation. Chrome does not list the height transition of `::details-content`, so this waits for the rotation of the chevrons, which has the same duration (`.disclosure` in `ProseStyles+CollapsibleSections.swift`).
	await Promise.allSettled(document.getAnimations().filter(animation => animation instanceof CSSTransition).map(animation => animation.finished));

	// The visitor went somewhere else while it waited.
	if (location.hash !== hash) {
		return;
	}

	section.scrollIntoView();
});

// Copies the text, marks the element as copied for the styles, and says “Copied” to screen readers. Returns whether it worked. Without clipboard access, it does nothing, as the visitor can still select the text.
async function copy(text, element) {
	try {
		await navigator.clipboard.writeText(text);
	} catch {
		return false;
	}

	element.dataset.state = 'copied';
	// Older browsers, like Safari 26, have no `ariaNotify`. They say nothing, but the copied state still goes away.
	element.ariaNotify?.('Copied');

	return true;
}

// The pending timers that remove the copied state of section links, so a second click restarts the timer of its link.
const copiedStateTimers = new WeakMap();

// Copies the URL of a section when its link is clicked. The link still navigates, so the section becomes the `:target`. The styles show a checkmark for the copied state, and hide the link until the pointer leaves the section.
document.addEventListener('click', async event => {
	const link = event.target.closest?.('[data-copy-link]');

	// Without clipboard access, the link still navigates, so the URL is in the address bar.
	if (!link || !await copy(link.href, link)) {
		return;
	}

	clearTimeout(copiedStateTimers.get(link));
	copiedStateTimers.set(link, setTimeout(() => {
		// Only a pointer leaving the section shows the link again, so a keyboard copy, without a pointer on the section, shows it right away.
		if (!link.parentElement.matches(':hover')) {
			delete link.dataset.state;
			return;
		}

		link.dataset.state = 'hidden';

		// Only the hidden state, as a new copy before the pointer leaves shows its checkmark until its own timer ends.
		link.parentElement.addEventListener('mouseleave', () => {
			if (link.dataset.state === 'hidden') {
				delete link.dataset.state;
			}
		}, {once: true});
	}, 1500));
});

// A footnote or an inline note closes when the keyboard moves the focus out of it, like with Tab, as it would stay open over the text otherwise. Only the keyboard, as a click on the button or the link that opens the note moves the focus there in some browsers before it closes the note, and a click outside closes the note anyway.
document.addEventListener('focusin', ({target}) => {
	if (!target.matches(':focus-visible')) {
		return;
	}

	for (const note of document.querySelectorAll('[role="note"]:popover-open')) {
		// Shift+Tab from the note goes back to the button or the link that opened it, which keeps it open.
		const isOpener = target.getAttribute('popovertarget') === note.id || target.getAttribute('href') === `#${note.id}`;

		if (!note.contains(target) && !isOpener) {
			note.hidePopover();
		}
	}
});

// A unicorn gallops across the page after the Konami code: ↑ ↑ ↓ ↓ ← → ← → B A. The code is also a `konami` event on the document, for the surprises of a page, like the unicorn parade of the 1999 page.
{
	const code = ['ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight', 'b', 'a'];
	let position = 0;

	document.addEventListener('keydown', event => {
		// Chrome autofill sends `keydown` events without a key.
		const key = event.key?.length === 1 ? event.key.toLowerCase() : event.key;

		if (key === code[position]) {
			position++;
		} else if (key === code[0]) {
			// Extra presses of ↑ before ↓ still count.
			position = position === 2 ? 2 : 1;
		} else {
			position = 0;
		}

		if (position < code.length) {
			return;
		}

		position = 0;

		document.dispatchEvent(new Event('konami'));

		if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
			return;
		}

		const unicorn = document.querySelector('#unicorn-template').content.firstElementChild.cloneNode(true);
		unicorn.addEventListener('animationend', () => {
			unicorn.remove();
		}, {once: true});
		document.body.append(unicorn);
	});
}
