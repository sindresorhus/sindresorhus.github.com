import {markdown} from '@astropub/md';
import {getCollection, render} from 'astro:content';

const normalizeApps = async app => {
	const {data, id: slug} = app;
	const pubDate = Date.parse(data.pubDate);
	const date30DaysAgo = new Date(new Date().setDate(new Date().getDate() - 30));

	const faqHeadingTitle = 'Frequently Asked Questions';

	const mainLinks = {
		...(data.repoUrl && {'Learn More': data.repoUrl}),
		...(data.redirectUrl && {'Learn More': data.redirectUrl}),
		...data.mainLinks,
	};

	let hasFaqSection = false;

	const {Content, headings, remarkPluginFrontmatter} = await render(app);
	const headingMeta = remarkPluginFrontmatter?.headingMeta ?? {};

	const NON_APP_STORE_VERSION = 'Non-App Store Version';

	const headerLinks = headings
		.filter(header => header.depth === 2 && header.text !== 'Footnotes')
		.map(({text, slug}) => {
			if (text === faqHeadingTitle) {
				hasFaqSection = true;
				text = 'FAQ';
			}

			return [text, `#${slug}`];
		});

	const faqHeadings = [];
	if (hasFaqSection) {
		let inFaqSection = false;
		let inFaqSubsection = false;
		for (const heading of headings) {
			if (heading.depth === 2 && heading.text === faqHeadingTitle) {
				inFaqSection = true;
				inFaqSubsection = false;
				continue;
			}

			if (inFaqSection && heading.depth === 2) {
				break;
			}

			if (!inFaqSection) {
				continue;
			}

			if (heading.depth === 3) {
				inFaqSubsection = true;
				continue;
			}

			if (
				heading.depth === 4
				&& !inFaqSubsection
				&& heading.slug !== 'feedback'
			) {
				faqHeadings.push({text: heading.text, slug: heading.slug, ...headingMeta[heading.slug]?.faq});
			}
		}
	}

	const {[NON_APP_STORE_VERSION]: nonAppStoreLink, ...regularLinks} = Object.fromEntries(headerLinks);

	const links = {
		...regularLinks,
		...data.links,
		...(data.showSupportLink && !data.isArchived && {Support: `/feedback?product=${encodeURIComponent(data.title)}`}),
	};

	const overflowLinks = {
		...data.overflowLinks,
		...(nonAppStoreLink && {[NON_APP_STORE_VERSION]: nonAppStoreLink}),
	};

	let videos = await import.meta.glob('~/../public/apps/*/video*.mp4', {eager: false});

	videos = await Promise.all(
		Object.entries(videos)
			.filter(([key]) => key.startsWith(`/public/apps/${slug}/`))
			.map(([, value]) => value()),
	);

	videos = videos.map(video => video.default.replace(/^\/public/, ''));

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

	const feedbackNote = await markdown(data.feedbackNote);

	return {
		...data,
		pubDate,
		slug: data.slug ?? slug,
		url: data.redirectUrl ?? `/${slug}`,
		isRedirect: data.redirectUrl !== undefined,
		iconUrl: `/apps/${slug}/icon.png`,
		isNew: pubDate > date30DaysAgo,
		mainLinks,
		links,
		overflowLinks,
		hasFaqSection,
		faqHeadings,
		videos,
		screenshots,
		Content,
		olderVersionsUrl: data.repoUrl ? `${data.repoUrl}#download` : `/${slug}#older-versions`,
		...(data.appStoreId && {appStoreUrl: `https://apps.apple.com/app/id${data.appStoreId}`}),
		...(data.setappId && {setappUrl: `https://go.setapp.com/stp181?refAppID=${data.setappId}&utm_medium=vendor_program&utm_content=button`}),
		feedbackNote,
	};
};

const load = async ({
	includeArchived = false,
	includeUnlisted = false,
} = {}) => {
	const apps = await getCollection('apps', app => !app.data.draft);

	const normalizedApps = await Promise.all(
		apps.map(app => normalizeApps(app)),
	);

	return normalizedApps
		.sort((a, b) => b.pubDate - a.pubDate)
		.filter(app =>
			(includeArchived || !app.isArchived)
			&& (includeUnlisted || !app.isUnlisted),
		);
};

let cachedApps;

export const fetchApps = async options => {
	if (options) {
		return load(options);
	}

	cachedApps ??= load();
	return cachedApps;
};

// TODO: Use `getEntry`
// export const fetchApp = async id => fetchApps().filter(app => app.id === id);

export const tagCSS = 'text-[10px] inline-flex items-center font-bold leading-sm px-1.5 text-black/70 dark:text-black rounded-lg';

// `prose-code:before:hidden prose-code:after:hidden`: https://github.com/tailwindlabs/tailwindcss-typography/issues/18#issuecomment-1280797041
const baseProseCSS = 'mx-auto px-6 sm:px-6 prose prose-lg lg:prose-xl dark:prose-invert dark:prose-headings:text-slate-300 prose-headings:font-heading prose-headings:leading-tighter prose-headings:tracking-tighter prose-headings:font-bold prose-img:rounded-md prose-img:shadow-lg mt-8 prose-a:text-black/75 dark:prose-a:text-white/90 prose-a:underline prose-a:underline-offset-4 prose-a:decoration-primary-500 prose-a:decoration-2 prose-a:hover:text-black dark:prose-a:hover:text-white prose-code:before:hidden prose-code:after:hidden';

// We add extra spacing between main section using: prose-h2:mt-24
export const proseCSS = `container ${baseProseCSS} max-w-4xl dark:prose-a:decoration-primary-400 prose-a:hover:decoration-primary-700 dark:prose-a:hover:decoration-primary-300 break-words tracking-normal prose-h4:tracking-normal prose-h5:tracking-normal prose-h6:tracking-normal prose-h2:mt-24`;

export const blogProseCSS = `${baseProseCSS} pt-0 pb-20 max-w-3xl prose-md prose-a:text-primary-600 dark:prose-a:text-primary-400 prose-a:hover:decoration-primary-600 prose-a:hover:decoration-4`;
