import rss from '@astrojs/rss';
import sanitizeHtml from 'sanitize-html';
import MarkdownIt from 'markdown-it';
import {fetchApps} from '~/utils/apps.js';

const parser = new MarkdownIt({
	html: true,
	linkify: true,
	typographer: true,
});

export async function getStaticPaths() {
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

export async function GET(context) {
	const {app} = context.props;
	const {title: appTitle, releasesRepo} = app;

	const response = await fetch(`https://api.github.com/repos/sindresorhus/${releasesRepo}/releases`, {
		headers: {
			Accept: 'application/vnd.github.v3+json',
			...(import.meta.env.GITHUB_TOKEN ? {
				Authorization: `token ${import.meta.env.GITHUB_TOKEN}`,
			} : {}),
		},
	});

	let releases = await response.json();

	releases = releases.filter(release => release.tag_name !== 'v1.0.0' && !release.draft && !release.prerelease);

	return rss({
		title: `${appTitle} Release Notes`,
		description: `Latest releases of ${appTitle}`,
		site: context.site,
		items: releases.map(release => {
			const version = release.tag_name.replace(/^v/, '');

			return {
				title: version,
				pubDate: new Date(release.published_at),
				content: sanitizeHtml(parser.render(release.body), {
					allowedTags: sanitizeHtml.defaults.allowedTags,
				}),
				link: `${app.url}/release-notes#${version}`,
			};
		}),
	});
}
