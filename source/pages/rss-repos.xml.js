import rss from '@astrojs/rss';
import {githubApi} from '~/utils/utils.js';

const fetchRepos = async () => {
	const repos = await githubApi('users/sindresorhus/repos?type=owner&sort=created&per_page=20');
	return repos.filter(repo => !repo.archived && !repo.fork);
};

export const GET = async context => {
	const repos = await fetchRepos();

	const items = repos.map(repo => ({
		title: repo.name,
		description: repo.description ?? '',
		link: repo.html_url,
		pubDate: repo.created_at,
	}));

	return rss({
		title: 'Sindre Sorhus — New Repos',
		description: 'Recently created GitHub repos by Sindre Sorhus',
		site: context.site,
		items,
		trailingSlash: false,
	});
};
