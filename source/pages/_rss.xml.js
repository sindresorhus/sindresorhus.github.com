import rss from '@astrojs/rss';
import {SITE} from '~/config.mjs';
import {fetchPosts} from '~/utils/posts.js';
import {fetchApps} from '~/utils/apps.js';

export const get = async context => {
	const posts = await Promise.all([fetchPosts(), fetchApps()]);

	const items = posts.flat().map(post => ({
		link: post.url,
		title: post.title,
		pubDate: post.pubDate,
		description: post.description ?? post.subtitle, // `apps` uses `subtitle`.
	}));

	return rss({
		title: 'Sindre Sorhus\' blog',
		description: SITE.description,
		site: context.site,
		items,
		trailingSlash: false,
	});
};
