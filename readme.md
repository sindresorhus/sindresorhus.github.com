# [sindresorhus.com](https://sindresorhus.com)

> Personal website of Sindre Sorhus

*The website targets the latest version of Chrome, Safari, and Firefox.*

## Development

The site is generated with Swift. Content is Markdown in `content/`, and static files are in `public/`.

```sh
swift run website build # Writes the site to `dist`
swift run website serve # Serves the site, and rebuilds and reloads it on changes
swift run website check # Builds the site, and prints possible mistakes, like spelling mistakes (`content/spelling-allowlist.txt` has the known words)
swift test
```

The preview server also has a gallery of every component at `/_gallery`.

Set `GITHUB_TOKEN` to avoid the GitHub API rate limit. Local builds cache the responses, like from the App Store and GitHub, for an hour in `.cache`, so they are fast and work offline after a build with the network.

## Deploy

Pushes to `main`, manual runs, and the nightly run build, test, and publish the site to GitHub Pages in one workflow (`ci.yml`). A deploy is skipped when the site did not change.

After a deploy, the workflow sends the URLs in the sitemap to [IndexNow](https://www.indexnow.org) (Bing and other search engines), with the key in `public/indexnow.txt`.

Cloudflare can cache the HTML too, with a cache rule for `sindresorhus.com/*` (“Cache everything”). The workflow purges the cache after each deploy when the `CLOUDFLARE_API_TOKEN` (with the “Cache Purge” permission) and `CLOUDFLARE_ZONE_ID` secrets are set.

The stylesheet, the icons, and the scripts have a hash of their content in the URL, like `/assets/site.css?v=1a2b3c4d`, so they can be cached for a year. In Cloudflare, a cache rule for requests where `starts_with(http.request.uri.query, "v=")` sets the edge TTL to a year, and a response header transform rule for the same requests sets `Cache-Control: public, max-age=31536000, immutable`. Other files keep the default cache time, as their URLs do not change with their content.
