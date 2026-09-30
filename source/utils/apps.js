import process from 'node:process';
import fs from 'node:fs';
import path from 'node:path';
import {markdown} from '@astropub/md';
import {getCollection, render} from 'astro:content';

const date30DaysAgo = new Date(new Date().setDate(new Date().getDate() - 30));

/*
Reads the video size from the track header (`tkhd`) box of an MP4 file.

Ignores rotation metadata.
*/
const getVideoSize = filePath => {
	const buffer = fs.readFileSync(filePath);

	const childBoxes = function * ({start, end}, type) {
		let offset = start;
		while (offset + 8 <= end) {
			let size = buffer.readUInt32BE(offset);
			let headerSize = 8;
			if (size === 1) {
				size = Number(buffer.readBigUInt64BE(offset + 8));
				headerSize = 16;
			} else if (size === 0) {
				size = end - offset;
			}

			if (size < headerSize) {
				return;
			}

			if (buffer.toString('latin1', offset + 4, offset + 8) === type) {
				yield {start: offset + headerSize, end: offset + size};
			}

			offset += size;
		}
	};

	for (const movie of childBoxes({start: 0, end: buffer.length}, 'moov')) {
		for (const track of childBoxes(movie, 'trak')) {
			for (const trackHeader of childBoxes(track, 'tkhd')) {
				// The size is 16.16 fixed-point and comes after fields that are larger in version 1.
				const sizeOffset = trackHeader.start + (buffer[trackHeader.start] === 1 ? 88 : 76);
				const width = Math.round(buffer.readUInt32BE(sizeOffset) / 65_536);
				const height = Math.round(buffer.readUInt32BE(sizeOffset + 4) / 65_536);

				// Audio tracks have zero size.
				if (width > 0 && height > 0) {
					return {width, height};
				}
			}
		}
	}

	throw new Error(`Could not read the video size of ${filePath}`);
};

const normalizeApp = async app => {
	const {data, id: slug} = app;
	const pubDate = Date.parse(data.pubDate);

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
			.map(async ([key, value]) => {
				const {default: url} = await value();
				return {
					src: url.replace(/^\/public/, ''),
					...getVideoSize(path.join(process.cwd(), key)),
				};
			}),
	);

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
		slug,
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

let cachedApps;

const loadAll = async () => {
	const apps = await getCollection('apps', app => !app.data.draft);

	const normalizedApps = await Promise.all(
		apps.map(app => normalizeApp(app)),
	);

	return normalizedApps.sort((a, b) => b.pubDate - a.pubDate);
};

export const fetchApps = async ({includeArchived = false, includeUnlisted = false} = {}) => {
	cachedApps ??= loadAll();
	const apps = await cachedApps;

	return apps.filter(app =>
		(includeArchived || !app.isArchived)
		&& (includeUnlisted || !app.isUnlisted),
	);
};

export const tagCSS = 'text-[10px] inline-flex items-center font-bold leading-sm px-1.5 text-black/70 dark:text-black rounded-lg';

// `prose-code:before:hidden prose-code:after:hidden`: https://github.com/tailwindlabs/tailwindcss-typography/issues/18#issuecomment-1280797041
const baseProseCSS = 'mx-auto px-6 sm:px-6 prose prose-lg lg:prose-xl dark:prose-invert dark:prose-headings:text-slate-300 prose-headings:font-heading prose-headings:leading-tighter prose-headings:tracking-tighter prose-headings:font-bold prose-img:rounded-md prose-img:shadow-lg mt-8 prose-a:text-black/75 dark:prose-a:text-white/90 prose-a:underline prose-a:underline-offset-4 prose-a:decoration-primary-500 prose-a:decoration-2 prose-a:hover:text-black dark:prose-a:hover:text-white prose-code:before:hidden prose-code:after:hidden';

// We add extra spacing between main section using: prose-h2:mt-24
export const proseCSS = `container ${baseProseCSS} max-w-4xl dark:prose-a:decoration-primary-400 prose-a:hover:decoration-primary-700 dark:prose-a:hover:decoration-primary-300 break-words tracking-normal prose-h4:tracking-normal prose-h5:tracking-normal prose-h6:tracking-normal prose-h2:mt-24`;

export const blogProseCSS = `${baseProseCSS} pt-0 pb-20 max-w-3xl prose-md prose-a:text-primary-600 dark:prose-a:text-primary-400 prose-a:hover:decoration-primary-600 prose-a:hover:decoration-4`;
