// A greeting for the curious ones who open the developer tools.
console.log(`%c
       \\
        \\
         >\\/7
     _.-(6'  \\
    (=___._/\` \\       Hello, curious one!
         )  \\ |
        /   / |       This site is generated with Swift.
       /    > /       Source: https://github.com/sindresorhus/sindresorhus.github.com
      j    < _\\
  _.-' :      \`\`.
  \\ r=._\\        \`.
`, 'color: #ec4899; font-family: ui-monospace, monospace;');

// Opens the collapsible section that the URL fragment points to. Browsers open a section for find-in-page and for a fragment inside it, but not for a fragment that is the section itself.
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
	}
}

openTargetedSection();
window.addEventListener('hashchange', openTargetedSection);

// The mobile menu covers the page, so it closes when keyboard focus moves out of it, like to a link behind it.
{
	const menu = document.querySelector('#menu');

	menu?.addEventListener('focusout', event => {
		const isLeaving = event.relatedTarget && !menu.contains(event.relatedTarget) && !event.relatedTarget.matches('[popovertarget="menu"]');

		if (isLeaving && menu.matches(':popover-open')) {
			menu.hidePopover();
		}
	});
}

// Copies the code of a code block. The styles show “Copied” for a moment.
document.addEventListener('click', async event => {
	const button = event.target.closest?.('[data-copy-code]');

	if (!button) {
		return;
	}

	try {
		await navigator.clipboard.writeText(button.closest('[data-code-block]').querySelector('code').textContent);
	} catch {
		// Without clipboard access, the visitor can still select the code.
		return;
	}

	button.dataset.state = 'copied';

	setTimeout(() => {
		delete button.dataset.state;
	}, 1500);
});

// Copies the URL of a section when its link is clicked. The link still navigates, so the section becomes the `:target`. The styles show a checkmark for the copied state, and hide the link until the pointer leaves the section.
document.addEventListener('click', async event => {
	const link = event.target.closest?.('[data-copy-link]');

	if (!link) {
		return;
	}

	try {
		await navigator.clipboard.writeText(link.href);
	} catch {
		// The link still navigates, so the URL is in the address bar.
		return;
	}

	link.dataset.state = 'copied';

	setTimeout(() => {
		link.dataset.state = 'hidden';

		link.parentElement.addEventListener('mouseleave', () => {
			delete link.dataset.state;
		}, {once: true});
	}, 1500);
});

// A unicorn gallops across the page after the Konami code: ↑ ↑ ↓ ↓ ← → ← → B A.
{
	const code = ['ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight', 'b', 'a'];
	let position = 0;

	document.addEventListener('keydown', event => {
		const key = event.key.length === 1 ? event.key.toLowerCase() : event.key;

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
