import MarkdownIt from 'markdown-it';
import {fetchApps} from '~/utils/apps.js';

export const releaseNotesMarkdownParser = new MarkdownIt({
	html: true,
	linkify: true,
	typographer: true,
});

export async function getReleaseNotesStaticPaths() {
	const apps = await fetchApps({includeUnlisted: true});

	return apps
		.filter(app => app.releasesRepo)
		.map(app => ({
			params: {
				slug: app.slug,
			},
			props: {
				app,
			},
		}));
}

export const iconLinkCSS = 'text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 focus:outline-hidden focus:ring-4 focus:ring-gray-200 dark:focus:ring-gray-700 rounded-lg text-sm p-2.5 inline-flex items-center';

/**
Clean up `Astro.url.pathname` by stripping the leading `/` and the `.html` extension added by `build.format: 'file'`.
*/
export function cleanPathname(pathname) {
	return pathname.slice(1).replace(/\.\w+$/, '');
}

export async function githubApi(path) {
	const response = await fetch(`https://api.github.com/${path}`, {
		headers: {
			Accept: 'application/vnd.github.v3+json',
			...(import.meta.env.GITHUB_TOKEN ? {
				Authorization: `token ${import.meta.env.GITHUB_TOKEN}`,
			} : {}),
		},
	});

	if (!response.ok) {
		const data = await response.json().catch(() => ({}));
		const message = data.message ?? response.statusText;
		throw new Error(`GitHub API error (${response.status}): ${message}`);
	}

	return response.json();
}

export async function fetchGitHubReleases(repo) {
	return githubApi(`repos/sindresorhus/${repo}/releases`);
}

export async function fetchFilteredReleases(repo) {
	const releases = await fetchGitHubReleases(repo);
	return releases.filter(release => !release.draft && !release.prerelease);
}

// Fisher-Yates shuffle.
export const shufflingArray = array => {
	const result = [...array];

	for (let index = result.length - 1; index > 0; index--) {
		const randomIndex = Math.floor(Math.random() * (index + 1));
		[result[index], result[randomIndex]] = [result[randomIndex], result[index]];
	}

	return result;
};

export const getFormattedDate = date =>
	date
		? new Date(date).toLocaleDateString('en-us', {
			year: 'numeric',
			month: 'long',
		})
		: '';
