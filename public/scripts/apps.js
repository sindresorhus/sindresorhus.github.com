const excluded = new URLSearchParams(location.search).get('exclude');

if (excluded) {
	const slugs = new Set(excluded.split(','));
	let hiddenCount = 0;

	for (const card of document.querySelectorAll('[data-slug]')) {
		if (slugs.has(card.dataset.slug)) {
			card.hidden = true;
			hiddenCount++;
		}
	}

	// A section with all its apps hidden, like “Featured”, is hidden too, so its title is not above an empty grid.
	for (const [section, cards] of Map.groupBy(document.querySelectorAll('[data-slug]'), card => card.closest('section'))) {
		if (section && cards.every(card => card.hidden)) {
			section.hidden = true;
		}
	}

	if (hiddenCount > 0) {
		const notice = document.querySelector('#apps-filter-notice');
		document.querySelector('#apps-filter-count').textContent = `${hiddenCount} ${hiddenCount === 1 ? 'app' : 'apps'} filtered out.`;
		notice.hidden = false;
	}
}

// A soft light follows the pointer over the title, like light on glass. The styles fade it in while the pointer is over the title, so this only moves it.
{
	const title = document.querySelector('#apps-title');
	const query = matchMedia('(hover: hover) and (pointer: fine) and (prefers-reduced-motion: no-preference)');
	let frame = 0;

	title.addEventListener('pointermove', event => {
		if (!query.matches) {
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
