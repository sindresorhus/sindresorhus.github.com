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
		const notice = document.createElement('p');
		notice.className = 'apps-filter-notice';
		const link = document.createElement('a');
		link.href = location.pathname;
		link.textContent = 'Show all';
		notice.append(`${hiddenCount} ${hiddenCount === 1 ? 'app' : 'apps'} filtered out. `, link);
		document.querySelector('#apps-grid')?.before(notice);
	}
}
