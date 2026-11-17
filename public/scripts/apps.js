import {finePointer, prefersReducedMotion} from '/scripts/dom.js';

const excluded = new URLSearchParams(location.search).get('exclude');

if (excluded) {
	// Without hyphens, as the apps make “dsstore-inspector” of “DS_Store Inspector”, and its slug here is “ds-store-inspector”.
	const withoutHyphens = slug => slug.replaceAll('-', '');
	const slugs = new Set(excluded.split(',').map(slug => withoutHyphens(slug)));
	const cards = [...document.querySelectorAll('[data-slug]')];

	for (const card of cards) {
		card.hidden = slugs.has(withoutHyphens(card.dataset.slug));
	}

	const shownCount = cards.filter(card => !card.hidden).length;

	// It says what the list shows, not what it leaves out.
	if (shownCount < cards.length) {
		const notice = document.querySelector('#apps-filter-notice');
		document.querySelector('#apps-filter-count').textContent = `The ${shownCount} ${shownCount === 1 ? 'app' : 'apps'} that you do not have yet.`;
		notice.hidden = false;

		// The apps that are left are one grid without titles, as the list is about the apps that the visitor does not have, not about the featured apps of the day, and a hidden featured app would leave a hole in its row. The featured apps stay first.
		// A card outside a section has no group to hide.
		const sections = Map.groupBy(cards, card => card.closest('section')).keys().filter(Boolean).toArray();
		const lastSection = sections.at(-1);
		const grid = cards.at(-1).parentElement;
		grid.prepend(...cards.filter(card => !card.hidden && card.parentElement !== grid));

		for (const section of sections.slice(0, -1)) {
			section.hidden = true;
		}

		if (lastSection) {
			// The title of the other apps, “More Apps”, is only there below the featured apps.
			const title = lastSection.querySelector(':scope > h2');
			if (title) {
				title.hidden = true;
			}

			lastSection.hidden = shownCount === 0;
		}
	}
}

// A soft light follows the pointer over the title, like light on glass. The styles fade it in while the pointer is over the title, so this only moves it.
{
	const title = document.querySelector('#apps-title');
	let frame = 0;

	title.addEventListener('pointermove', event => {
		if (prefersReducedMotion || !finePointer.matches) {
			return;
		}

		cancelAnimationFrame(frame);
		frame = requestAnimationFrame(() => {
			// Each part of the title has its own background, so the light is placed in each of them.
			for (const part of title.children) {
				const rect = part.getBoundingClientRect();
				part.style.setProperty('--light-x', `${event.clientX - rect.left}px`);
				part.style.setProperty('--light-y', `${event.clientY - rect.top}px`);
			}
		});
	});
}
