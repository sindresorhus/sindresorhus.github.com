# [sindresorhus.com](https://sindresorhus.com)

> Personal website of Sindre Sorhus

*The website targets the latest version of Chrome, Safari, and Firefox.*

## Development

The site is generated with Swift. Content is Markdown in `content/`, and static files are in `public/`. A page with files of its own, like images, is a directory with an `index.md`, and its files are published next to the page, like `/dato/icon.png` for `content/apps/dato/icon.png`.

```sh
swift run website build # Writes the site to `dist`
swift run website serve # Serves the site, and rebuilds and reloads it on changes
swift run website check # Builds the site, and prints possible mistakes, like spelling mistakes (`content/spelling-allowlist.txt` has the known words)
swift test
```

The preview server also has a gallery of every component at `/_gallery`.

To run the tests before each push, like CI, enable the hook in `.githooks` once with `git config core.hooksPath .githooks`.

Set `GITHUB_TOKEN` to avoid the GitHub API rate limit. Local builds cache the responses, like from the App Store and GitHub, for an hour in `.cache`, so they are fast and work offline after a build with the network.

## Architecture

- **Packages:** `SiteKit` is the generic toolkit (content loading, Markdown, routes, publishing, styles), `Website` is everything specific to this site, `WebsiteCLI` is the `website` command, and `RSS` writes the feeds.
- **Routes:** Every output file is a `Route`, listed in `Site.routes`. The publisher renders them in parallel, writes only changed files, and removes files that are no longer published. The sitemap comes from the routes.
- **Content and data:** The Markdown and its frontmatter are loaded into typed models, and the App Store, GitHub, and npm data is fetched at build time.
- **Components:** HTML is written in Swift with [Elementary](https://github.com/elementary-swift/elementary). Styles are typed Swift values. A page collects the styles that its components use while it renders, and gets them in a `<style>` element, so no list of components is kept.
- **Behavior:** A component with behavior is a light DOM custom element (`ScriptedElement`). Its script is a `.js` file in the `Scripts` folder next to its Swift file, which defines the element, or a short script inline in the Swift file. The build finds the script files by folder and publishes them unchanged. An import map in each page adds the content hash to imports.
- **Tests:** The tests render every page and check what the compiler cannot, like that every custom element on a page is defined, every class has a rule, and every link works.

The reasons for the main choices are in [`meta.md`](meta.md).

## Deploy

Pushes to `main`, manual runs, and the nightly run build, test, and publish the site to GitHub Pages in one workflow (`ci.yml`). A deploy is skipped when the site did not change.

After a deploy, the workflow sends the URLs in the sitemap to [IndexNow](https://www.indexnow.org) (Bing and other search engines), with the key in `public/indexnow.txt`.

Cloudflare can cache the HTML too, with a cache rule for `sindresorhus.com/*` (“Cache everything”). The workflow purges the cache after each deploy when the `CLOUDFLARE_API_TOKEN` (with the “Cache Purge” permission) and `CLOUDFLARE_ZONE_ID` secrets are set.

The stylesheet, the icons, and the scripts have a hash of their content in the URL, like `/assets/site.css?v=1a2b3c4d`, so they can be cached for a year. In Cloudflare, a cache rule for requests where `starts_with(http.request.uri.query, "v=")` sets the edge TTL to a year, and a response header transform rule for the same requests sets `Cache-Control: public, max-age=31536000, immutable`. Other files keep the default cache time, as their URLs do not change with their content.
