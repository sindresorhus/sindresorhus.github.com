import {cloneTemplate, copy, elementForFragment, parts, prefersReducedMotion} from '/scripts/dom.js';

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

// Opens the collapsible section that the URL fragment points to, and scrolls to it. Browsers open a section for find-in-page and for a fragment inside it, but not for a fragment that is the section itself.
async function openTargetedSection() {
	const {hash} = location;
	const section = elementForFragment(hash);

	if (!(section instanceof HTMLDetailsElement)) {
		return;
	}

	section.open = true;

	// The section animates its height while it opens, and scroll anchoring moves the page while it grows, so the visitor would see the end of the section or the next one. So the section is scrolled to again after the animation. Chrome does not list the height transition of `::details-content`, so this waits for the rotation of the chevrons, which has the same duration (`.disclosure` in `ProseStyles+CollapsibleSections.swift`).
	await Promise.allSettled(document.getAnimations().filter(animation => animation instanceof CSSTransition).map(animation => animation.finished));

	// The visitor went somewhere else while it waited.
	if (location.hash !== hash) {
		return;
	}

	section.scrollIntoView();
}

openTargetedSection();
window.addEventListener('hashchange', openTargetedSection);

// The pending timers that remove the copied state of section links, so a second click restarts the timer of its link.
const copiedStateTimers = new WeakMap();

// Copies the URL of a section when its link is clicked. With a pointer, the link still navigates, so the section becomes the `:target`. The styles show a checkmark for the copied state, and hide the link until the pointer leaves the section.
document.addEventListener('click', async event => {
	const link = event.target.closest?.('[data-copy-link]');

	if (!link) {
		return;
	}

	// On touch screens, the link is at the end of the open section, so it does not navigate, which would scroll back to the start of the section.
	const cannotHover = matchMedia('(hover: none)').matches;

	if (cannotHover) {
		event.preventDefault();
	}

	// Without clipboard access, the link navigates, so the URL is in the address bar.
	if (!await copy(link.href, link)) {
		if (cannotHover) {
			location.hash = link.hash;
		}

		return;
	}

	link.dataset.state = 'copied';
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

let audioPlayer;

// A link to an audio clip, like how to say my name, plays it in place, instead of leaving the page for a bare player. Without the script, or with a modifier key, like to open it in a new tab, the link opens the file.
document.addEventListener('click', event => {
	const link = event.target.closest?.('a[href$=".m4a"]');

	if (!link || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
		return;
	}

	event.preventDefault();

	// One player, so a second click starts the clip again instead of playing it twice at once.
	audioPlayer ??= new Audio();
	audioPlayer.src = link.href;
	// A browser that does not let the script play the clip, like one with autoplay off for the site, opens it instead, as without the script.
	audioPlayer.play().catch(error => {
		// Restarting a clip aborts its pending playback, which is no failure.
		if (error.name === 'AbortError') {
			return;
		}

		location.href = link.href;
	});
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

// The open popovers close when the visitor leaves the page, like the menu on a phone after a tap on one of its links. Otherwise, the back/forward cache shows the page again with the popover still open over it. The page is not shown at this time, so nothing visibly closes.
window.addEventListener('pagehide', () => {
	for (const popover of document.querySelectorAll(':popover-open')) {
		popover.hidePopover();
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

		if (prefersReducedMotion) {
			return;
		}

		const unicorn = cloneTemplate(document.querySelector('#unicorn-template'));
		unicorn.addEventListener('animationend', () => {
			unicorn.remove();
		}, {once: true});
		document.body.append(unicorn);
	});
}

// A section link scrolls smoothly only to a section within two screens, so a link to the other end of a long page, like the “Get” button, jumps at once. The attribute stays until the next click, and the page has none when it opens at a section, so that jump is instant too.
document.addEventListener('click', event => {
	const link = event.target.closest?.('a[href*="#"]');

	if (!link || link.origin !== location.origin || link.pathname !== location.pathname) {
		return;
	}

	const target = elementForFragment(link.hash);
	const isClose = Boolean(target) && Math.abs(target.getBoundingClientRect().top) < innerHeight * 2;
	document.documentElement.toggleAttribute('data-smooth-scrolling', isClose);
}, {capture: true});

// A link in text, like prose, shows a preview of what it goes to when the pointer rests on it: an app, the answer of a question, or a shared shortcut (`LinkPreview` in Swift). Only with a precise pointer that can hover, as on a touch screen, a tap opens the page at once.
if (matchMedia('(hover: hover) and (pointer: fine)').matches) {
	// What the previews show, by their link, loaded at the first hover. Without them, links show no preview.
	let contentsByLink;
	let preview;
	let showTimer;
	let previewRequest;

	const contentForLink = async link => {
		contentsByLink ??= fetch('/link-previews.json')
			.then(response => response.json())
			.then(contents => new Map(Object.entries(contents)))
			// A failed request is not kept, so the next hover tries again, like after a short loss of the network.
			.catch(() => {
				contentsByLink = undefined;
			});

		const contents = await contentsByLink;

		// A shared shortcut is on another site.
		if (link.origin !== location.origin) {
			return contents?.get(link.href);
		}

		// A link to a section shows the section, like a question, also on the page itself. Any other link to another page shows the page, like an app. A link to the page itself needs no preview.
		return contents?.get(link.pathname + link.hash) ?? (link.pathname === location.pathname ? undefined : contents?.get(link.pathname));
	};

	const show = async (link, request) => {
		const content = await contentForLink(link);

		// The pointer left the link, or Escape dismissed it, while the previews loaded.
		if (!content || previewRequest !== request || !link.matches(':hover')) {
			return;
		}

		if (!preview) {
			preview = cloneTemplate(document.querySelector('#link-preview-template'));
			document.body.append(preview);
		}

		const {icon, name, subtitle, facts} = parts(preview, 'the link preview');
		name.textContent = content.name;
		subtitle.textContent = content.subtitle ?? '';
		facts.textContent = content.facts;

		// A question has no icon.
		icon.hidden = !content.icon;

		if (content.icon) {
			icon.src = content.icon;

			// Wait for the icon, so the preview does not show the icon of the last link while the new one loads. A failed icon still shows the preview.
			await icon.decode().catch(() => {});
		}

		// The pointer left the link, or Escape dismissed it, while the icon loaded.
		if (previewRequest !== request || !link.matches(':hover')) {
			return;
		}

		if (preview.matches(':popover-open')) {
			preview.hidePopover();
		}

		// The link is the source, so the preview is placed next to it.
		preview.showPopover({source: link});
	};

	document.addEventListener('pointerover', event => {
		const link = event.target.closest?.('[data-link-previews] a[href]');

		// A link in a box that already shows the app has no preview, a card of a shortcut has none, and the link of a section, which copies its URL, has none, as it is next to the section itself. Only a mouse, as a touch screen of a laptop also taps links.
		if (!link || event.pointerType !== 'mouse' || link.contains(event.relatedTarget) || link.closest('[data-no-link-preview]') || link.matches('[data-copy-link]')) {
			return;
		}

		clearTimeout(showTimer);
		const request = {};
		previewRequest = request;
		showTimer = setTimeout(() => {
			show(link, request);
		}, 400);
	});

	const hide = () => {
		clearTimeout(showTimer);
		previewRequest = undefined;

		if (preview?.matches(':popover-open')) {
			preview.hidePopover();
		}
	};

	document.addEventListener('pointerout', event => {
		const link = event.target.closest?.('a[href]');

		if (!link || link.contains(event.relatedTarget)) {
			return;
		}

		hide();
	});

	// The preview covers the text below the link, and it is a manual popover, which the browser does not close with Escape, so the visitor can close it without moving the pointer. It shows again when the pointer enters the link again.
	document.addEventListener('keydown', event => {
		if (event.key === 'Escape') {
			hide();
		}
	});
}
