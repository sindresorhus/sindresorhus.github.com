import {getCollection} from 'astro:content';

const normalizeApps = async app => {
	const {data, slug} = app;
	const pubDate = Date.parse(data.pubDate);
	const date30DaysAgo = new Date(new Date().setDate(new Date().getDate() - 30));

	const faqHeadingTitle = 'Frequently Asked Questions';

	const mainLinks = {
		...(data.repoUrl && {'Learn More': data.repoUrl}),
		...(data.redirectUrl && {'Learn More': data.redirectUrl}),
		...data.mainLinks,
	};

	let hasFaqSection = false;

	const {Content, headings} = await app.render();

	const headerLinks = headings
		.filter(header => header.depth === 3)
		.map(({text, slug}) => {
			if (text === faqHeadingTitle) {
				hasFaqSection = true;
				text = 'FAQ';
			}

			return [text, `#${slug}`];
		});

	const links = {
		...Object.fromEntries(headerLinks),
		...data.links,
		...(data.showSupportLink && !data.isArchived && {Support: `/feedback?product=${encodeURIComponent(data.title)}`}),
	};

	let screenshots = await import.meta.glob('~/../public/apps/*/screenshot*.{png,jpg}', {eager: false});

	screenshots = await Promise.all(
		Object.entries(screenshots)
			.filter(([key]) => key.startsWith(`/public/apps/${slug}/`))
			.map(([, value]) => value()),
	);

	screenshots = screenshots.map(screenshot => {
		const object = screenshot.default;
		object.src = object.src.replace(/^\/public/, '');
		return object;
	});

	return {
		...data,
		pubDate,
		slug: data.slug ?? slug,
		url: data.redirectUrl ?? `/${slug}`,
		isRedirect: data.redirectUrl !== undefined,
		iconUrl: `/apps/${slug}/icon.png`,
		// We can use `forceHasiOSAppIcon` for both true/false override.
		hasIOSAppIcon: data.forceHasIosAppIcon ?? ((data.platforms.includes('iOS') || data.platforms.includes('watchOS')) && !data.platforms.includes('macOS')),
		isNew: pubDate > date30DaysAgo,
		mainLinks,
		links,
		hasFaqSection,
		screenshots,
		Content,
		olderVersionsUrl: data.repoUrl ? `${data.repoUrl}#download` : `/${slug}#older-versions`,
		...(data.appStoreId && {appStoreUrl: `https://apps.apple.com/app/id${data.appStoreId}`}),
		...(data.setappId && {setappUrl: `https://go.setapp.com/stp181?refAppID=${data.setappId}&utm_medium=vendor_program&utm_content=button`}),
	};
};

const load = async ({includeArchived = false} = {}) => {
	const apps = await getCollection('apps', app => !app.data.draft);

	const normalizedApps = await Promise.all(
		apps.map(async app => normalizeApps(app)),
	);

	return normalizedApps
		.sort((a, b) => b.pubDate - a.pubDate)
		.filter(app => includeArchived || !app.isArchived);
};

let cachedApps;

export const fetchApps = async options => {
	if (options) {
		return load(options);
	}

	cachedApps ??= load();
	return cachedApps;
};

// TODO: Use `getEntryBySlug`
// export const fetchApp = async id => fetchApps().filter(app => app.id === id);

// `prose-code:before:hidden prose-code:after:hidden`: https://github.com/tailwindlabs/tailwindcss-typography/issues/18#issuecomment-1280797041
export const proseCSS = 'container mx-auto px-6 sm:px-6 max-w-3xl prose prose-lg lg:prose-xl dark:prose-invert dark:prose-headings:text-slate-300 prose-headings:font-heading prose-headings:leading-tighter prose-headings:tracking-tighter prose-headings:font-bold prose-img:rounded-md prose-img:shadow-lg mt-8 prose-a:text-black/75 dark:prose-a:text-white/90 prose-a:underline prose-a:underline-offset-4 prose-a:decoration-primary-500 hover:prose-a:decoration-primary-600 prose-a:decoration-2 hover:prose-a:decoration-4 hover:prose-a:text-black dark:hover:prose-a:text-white break-words tracking-normal prose-h4:tracking-normal prose-h5:tracking-normal prose-h6:tracking-normal prose-code:before:hidden prose-code:after:hidden';
