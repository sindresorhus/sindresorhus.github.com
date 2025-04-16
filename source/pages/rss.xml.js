import rss from '@astrojs/rss';
import {SITE} from '~/config.mjs';
import {fetchPosts} from '~/utils/posts.js';
import {fetchApps} from '~/utils/apps.js';

export const GET = async context => {
	const getApps = async () => {
		const apps = await fetchApps();
		return apps.map(app => ({
			...app,
			title: `New App: ${app.title}`,
		}));
	};

	let items = await Promise.all([fetchPosts(), getApps()]);

	items = items
		.flat()
		.map(item => ({
			link: item.url,
			title: item.title,
			pubDate: item.pubDate,
			description: item.description ?? item.subtitle, // `apps` uses `subtitle`.
			// Use the original content URL as GUID instead of redirect URL.
			// This can prevent an edge case where both an "app" item and a blog post with redirect points to the same item.
			...(item.isRedirect && {
				customData: `<guid isPermaLink="false">${context.site}blog/${item.slug}</guid>`,
			}),
		}))
		.sort((a, b) => b.pubDate - a.pubDate);

	return rss({
		title: 'Sindre Sorhus — Blog',
		description: SITE.description,
		site: context.site,
		items,
		trailingSlash: false,
	});
};
