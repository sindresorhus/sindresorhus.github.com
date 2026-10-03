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

	if (hiddenCount > 0) {
		const notice = document.querySelector('#apps-filter-notice');
		notice.querySelector('span').textContent = `${hiddenCount} ${hiddenCount === 1 ? 'app' : 'apps'} filtered out.`;
		notice.hidden = false;
	}
}
