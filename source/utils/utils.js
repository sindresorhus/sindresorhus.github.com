import process from 'node:process';
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
Clean up `Astro.url.pathname` by stripping the leading `/`, the `.html` extension added by `build.format: 'file'`, and a trailing `index`, so the home page becomes an empty string.

@param {string} pathname - The `Astro.url.pathname` value.
*/
export function cleanPathname(pathname) {
	return pathname.slice(1).replace(/\.\w+$/v, '').replace(/(?:^|\/)index$/v, '');
}

export async function githubApi(path) {
	const response = await fetch(`https://api.github.com/${path}`, {
		headers: {
			Accept: 'application/vnd.github.v3+json',
			...(process.env.GITHUB_TOKEN && {
				Authorization: `token ${process.env.GITHUB_TOKEN}`,
			}),
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
	return githubApi(`repos/sindresorhus/${repo}/releases?per_page=100`);
}

// Both the release notes page and the RSS feed of an app need the releases, so only fetch them once per build.
const filteredReleasesCache = new Map();

export async function fetchFilteredReleases(repo) {
	if (!filteredReleasesCache.has(repo)) {
		filteredReleasesCache.set(repo, fetchGitHubReleases(repo).then(releases => releases.filter(release => !release.draft && !release.prerelease)));
	}

	return filteredReleasesCache.get(repo);
}

/**
Get the App Store info of apps, like the price, rating, and version, with one request.

The info is from the US App Store. Mac App Store apps always have a rating count of 0.

@param {number[]} appStoreIds - The App Store IDs of the apps.
@returns {Promise<Map<number, object>>} The info for each App Store ID. Apps that are not on the App Store are not included.
*/
export async function fetchAppStoreInfo(appStoreIds) {
	try {
		const response = await fetch(`https://itunes.apple.com/lookup?id=${appStoreIds.join(',')}`);

		if (!response.ok) {
			return new Map();
		}

		const {results} = await response.json();
		return new Map(results.map(result => [result.trackId, result]));
	} catch {
		return new Map();
	}
}

// Fisher-Yates shuffle.
export const shufflingArray = array => {
	const result = [...array];

	for (let index = result.length - 1; index > 0; index--) {
		const randomIndex = Math.floor(Math.random() * (index + 1));
		const value = result[index];
		result[index] = result[randomIndex];
		result[randomIndex] = value;
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
