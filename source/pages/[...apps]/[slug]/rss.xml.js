import rss from '@astrojs/rss';
import sanitizeHtml from 'sanitize-html';
import {fetchFilteredReleases, releaseNotesMarkdownParser as parser} from '~/utils/utils.js';

export {getReleaseNotesStaticPaths as getStaticPaths} from '~/utils/utils.js';

export async function GET(context) {
	const {app} = context.props;
	const {title: appTitle, releasesRepo} = app;

	const allReleases = await fetchFilteredReleases(releasesRepo);
	const releases = allReleases.filter(release => release.tag_name !== 'v1.0.0');

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
