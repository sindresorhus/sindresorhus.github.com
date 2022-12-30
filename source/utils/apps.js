const normalizeApps = async app => {
	const {frontmatter, compiledContent, file} = app;
	const id = file.split('/').pop().split('.').shift();
	const date = Date.parse(frontmatter.date);
	const date30DaysAgo = new Date(new Date().setDate(new Date().getDate() - 30));

	// TODO: Validate that there are no missing props.

	const faqHeadingTitle = 'Frequently Asked Questions';

	const mainLinks = {
		...(frontmatter.repoUrl && {'Learn More': frontmatter.repoUrl}),
		...frontmatter.mainLinks,
	};

	let hasFaqSection = false;

	const headerLinks = app.getHeadings()
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
		...frontmatter.links,
		// TODO
		...(frontmatter.showSupportLink !== false && {Support: `/feedback?product=${encodeURIComponent(frontmatter.title)}`}),
	};

	let screenshots = await import.meta.glob('~/../public/apps/*/screenshot*.{png,jpg}', {eager: false});

	screenshots = await Promise.all(
		Object.entries(screenshots)
			.filter(([key]) => key.startsWith(`/public/apps/${id}/`))
			.map(([, value]) => value()),
	);

	screenshots = screenshots.map(screenshot => {
		const object = screenshot.default;
		object.src = object.src.replace(/^\/public/, '');
		return object;
	});

	return {
		...frontmatter,
		id,
		date,
		slug: frontmatter.slug ?? id,
		url: `/${id}`,
		iconUrl: `/apps/${id}/icon.png`,
		body: compiledContent(),
		hasIOSAppIcon: frontmatter.platforms.includes('iOS') && !frontmatter.platforms.includes('macOS'),
		isNew: date > date30DaysAgo,
		mainLinks,
		links,
		hasFaqSection,
		screenshots,
	};
};

const load = async () => {
	const apps = import.meta.glob('~/../data/apps/**/*.md', {eager: true});

	const normalizedApps = await Promise.all(
		Object.values(apps).map(async app => normalizeApps(await app)),
	);

	return normalizedApps
		.filter(app => !app.draft)
		.sort((a, b) => b.date - a.date);
};

let cachedApps;

export const fetchApps = async () => {
	cachedApps = cachedApps ?? load();
	return cachedApps;
};

export const fetchApp = async id => fetchApps().filter(app => app.id === id);

export const proseCSS = 'container mx-auto px-6 sm:px-6 max-w-3xl prose prose-lg lg:prose-xl dark:prose-invert dark:prose-headings:text-slate-300 prose-headings:font-heading prose-headings:leading-tighter prose-headings:tracking-tighter prose-headings:font-bold prose-img:rounded-md prose-img:shadow-lg mt-8 prose-a:text-black/75 dark:prose-a:text-white/90 prose-a:underline prose-a:underline-offset-4 prose-a:decoration-primary-500 hover:prose-a:decoration-primary-600 prose-a:decoration-2 hover:prose-a:decoration-4 hover:prose-a:text-black dark:hover:prose-a:text-white break-words tracking-normal prose-h4:tracking-normal prose-h5:tracking-normal prose-h6:tracking-normal';
