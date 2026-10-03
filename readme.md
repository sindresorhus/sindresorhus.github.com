# [sindresorhus.com](https://sindresorhus.com)

> Personal website of Sindre Sorhus

*The website targets the latest version of Chrome, Safari, and Firefox.*

## Development

The site is generated with Swift. Content is Markdown in `content/`, and static files are in `public/`.

```sh
swift run website build # Writes the site to `dist`
swift run website serve # Serves the site, and rebuilds and reloads it on changes
swift test
```

The preview server also has a gallery of every component at `/_gallery`.

Set `GITHUB_TOKEN` to avoid the GitHub API rate limit. Local builds cache the App Store and GitHub responses for an hour in `.cache`, so they are fast and work offline.

## Deploy

Pushes to `main`, manual runs, and the nightly run build, test, and publish the site to GitHub Pages in one workflow (`ci.yml`). A deploy is skipped when the site did not change.

Cloudflare can cache the HTML too, with a cache rule for `sindresorhus.com/*` (“Cache everything”). The workflow purges the cache after each deploy when the `CLOUDFLARE_API_TOKEN` (with the “Cache Purge” permission) and `CLOUDFLARE_ZONE_ID` secrets are set.
