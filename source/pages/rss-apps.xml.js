import rss from '@astrojs/rss';
import {fetchApps} from '~/utils/apps.js';

export const GET = async context => {
	let items = await fetchApps();

	items = items
		.filter(item => !item.unlisted)
		.map(item => ({
			link: item.url,
			title: item.title,
			pubDate: item.pubDate,
			description: item.subtitle,
		}));

	return rss({
		title: 'Sindre Sorhus — Apps',
		description: 'Quality crafted apps',
		site: context.site,
		items,
		trailingSlash: false,
	});
};
