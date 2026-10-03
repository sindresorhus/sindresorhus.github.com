const data = JSON.parse(document.querySelector('#random-app-data')?.textContent ?? '{"slugs":[]}');
const referrerApp = document.referrer ? new URL(document.referrer).pathname.split('/')[1] : undefined;
const candidates = data.slugs.filter(slug => slug !== referrerApp);

// The redirect happens before the page shows, so there is nothing to transition from.
addEventListener('pageswap', event => {
	if (event.viewTransition) {
		event.viewTransition.ready.catch(() => {});
		event.viewTransition.finished.catch(() => {});
		event.viewTransition.skipTransition();
	}
});

if (candidates.length > 0) {
	const slug = candidates[Math.floor(Math.random() * candidates.length)];
	// `#another-random-app` shows the “Another Random App” button.
	location.replace(`/${slug}#another-random-app`);
}
