const data = JSON.parse(document.querySelector('#random-app-data')?.textContent ?? '{"slugs":[]}');
const referrerApp = document.referrer ? new URL(document.referrer).pathname.split('/')[1] : undefined;
const candidates = data.slugs.filter(slug => slug !== referrerApp);

if (candidates.length > 0) {
	const slug = candidates[Math.floor(Math.random() * candidates.length)];
	location.replace(`/${slug}`);
}
