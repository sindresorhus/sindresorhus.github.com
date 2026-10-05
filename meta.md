# Decisions

Short reasons for the main choices in the Swift version of the site. `plan.md` has the work log.

## Stack

- **Swift with Elementary for HTML.** Elementary is a small, fast HTML DSL with result builders and an environment, close to SwiftUI. Ignite and Publish bring their own HTML DSL and theme system. We only needed the HTML layer, and we wanted full control over the markup.
- **swift-markdown and SOML.** Apple’s Markdown parser gives a typed tree, so headings, alerts, footnotes, and keyboard shortcuts are handled on the tree, not with regexes. The frontmatter is [SOML](https://github.com/soml-lang/soml), not YAML: a value has the type its syntax gives it, so `version: 1.10` cannot silently become the number 1.1, and a day is a string (`'2026-02-23'`) that the `Day` type checks.
- **Social cards with Core Graphics.** The cards are drawn with Core Graphics and Core Text, with the Inter font bundled as a resource. A card looks the same on every machine, the build needs no Homebrew packages, and drawing is much faster than starting `rsvg-convert` for each card. The layout follows the old CSS design (line heights, margins, shadow), and long texts wrap.
- **No Node at build time.** The build is `swift run website build`. Browser scripts are plain JavaScript files in `public/scripts`.

## Package layout

- `RSS`: a general RSS 2.0 library (typed items, result builder, validation). It knows nothing about the site.
- `SiteKit`: the small toolkit the site needs: content loading, Markdown, routes, publishing, link validation, and the style system. Sized for this site, not a framework.
- `SiteKitMacros`: the `@Frontmatter` macro.
- `Website`: everything specific to sindresorhus.com.
- `WebsiteCLI`: `build`, `check`, `routes`, `serve`.

The split keeps site knowledge out of the generic parts, so each layer can be read and tested alone.

## Content

- **Strict frontmatter.** `@Frontmatter` generates decoding that rejects unknown keys and keeps default values. Synthesized `Decodable` silently ignores typos and drops defaults, which hid real content mistakes. This is the one macro that clearly pays for itself.
- **Validation in types.** `AbsoluteURL` fails while decoding, so the error names the real key path. There are no hand-written key strings to keep in sync.
- **Loading is on the type.** `BlogPost.load(from:)` instead of a collection wrapper type.

## Routes and publishing

- **Every output file is a `Route` value**, built with `@RouteBuilder` in `Site.routes`. Reading one function shows the whole site map. The sitemap is derived from the routes.
- **The publisher is defensive.** It checks for two routes writing the same file, and refuses an output directory that would delete the project.
- **The preview server is Swift** (`PreviewServer`, Network framework), not Python, so the build has no other runtime. It behaves like GitHub Pages (`/about` serves `about.html`), opens the default browser, and stops when its task is cancelled, which makes it testable.
- **Watch mode polls.** `serve` compares file dates every half second instead of using FSEvents. It is simple, and fast enough for the size of the project. Content changes rebuild in the same process. Source changes run `swift build` and replace the process with the new executable (`execv`), which is simpler than a separate supervisor process. Pages long-poll the server for its state: they reload when the files are written, before the link check, and show build errors and broken links on the page. Asking again after a failed request also works across a restart.
- **Incremental publishing.** The output directory is not deleted. Unchanged files are not written, and files that are no longer published are removed, so rebuilds are fast and the published files always match the routes.
- **Cached data for local builds.** App Store and GitHub responses are cached for an hour and revalidated with ETags. Local builds fall back to the cache when offline. CI always revalidates and never uses stale data.
- **Reproducible output.** Dates use a fixed locale and UTC. The related apps rotate daily with a seeded shuffle, so two builds on the same day give the same files, and diffs only show real changes.

## Styles

- **Typed modifier chains**, like SwiftUI view modifiers: `Style().padding(.rem(1)).hover { $0.background(.gray100) }`. Each modifier returns the same concrete type, so long chains type-check fast. Jetpack Compose and Kobweb (a Kotlin web framework built on Compose) use the same model for styling. Result builders fit structure (routes, page bodies) better than a list of properties.
- **Named styles as enum cases (`StyleSet`).** Each component has `enum Styles: StyleSet`, and the class name is generated from the component and the case (`app-card-title`). Markup applies `.style(Styles.title)`, so markup and CSS cannot drift, and a typo does not compile. `CaseIterable` registers every style, and the `switch` is exhaustive.
	- A macro was considered for naming `static let` styles. A macro cannot rewrite the initializer of a stored property, and `#function` gives the enclosing type name, not the property. Enum cases give names, registration, and exhaustiveness with plain language features.
- **Typed values.** `Color` (palette, `.opacity`), `Length`, `Shadow`, `FontWeight`, keyword enums, and a text scale where one call sets size and line height. `.declaration(_:_:)` is the escape hatch for rare properties.
- **Styles are found while rendering.** Applying a style registers it with the page, like SwiftUI preferences. Each page gets a `<style>` with only the component styles it applies (not the other cases of their style sets), and the shared `site.css` has the element defaults, the typography, and the components that Markdown output uses. No list of components has to be kept in sync, which removed a whole class of bugs (a new component without styles). Scripts work the same way with `ModuleScript`.
- **Cascade layers.** The stylesheet has three layers: element defaults, Markdown typography, and components. Components always win over the typography around them, whatever the specificity.
- **The palette is custom properties.** Each shade and each semantic color (like `.primaryText`, with light and dark values through `light-dark()`) is defined once on `:root`. Swift code uses typed values, like `.gray(900)`.
- **Native CSS nesting.** Nested selectors and conditions are written as nested CSS, which all current browsers support. The output is smaller and reads like the Swift.
- **Selector rules stay where components do not own the markup**: Markdown output (`.prose` typography), and elements that scripts create.
- **Scripts use IDs and `data-` attributes**, never style classes. Renaming a style cannot break a script.
- **Verification.** The style migration was checked by comparing the computed style of every element in Chrome (light and dark, desktop and mobile) before and after. Pixel screenshots were too noisy, because of image loading.

## Data flow

- **Pages get their data in their initializer**, in `Site.routes`: `AppPage(app:content:)`. The flow is explicit, and the compiler checks it.
- **No `@Environment` for page data.** Elementary’s environment only exists while rendering, but routes, paths, and metadata are computed before rendering. Page data in the environment would have to be optional, and the dependency would be hidden. The data passes through at most two layers, so explicit parameters are simpler.

## One owner for each fact

Facts that were decided in several places now have one owner. Examples: `App.releaseNotes` (page, feed, and repo; `nil` for archived apps), `App.downloadOptions`, the site feeds, the author in structured data, page titles, and asset paths.

## Structured data

- **JSON-LD only, no microdata.** The JSON-LD has the same facts as the old `itemprop` attributes, and search engines ignore microdata for site navigation. One format means one place to keep correct, and smaller HTML.
- **Keywords from property names.** Schema types have plain `type` and `context` properties, and the encoder writes them as `@type` and `@context`, so no type needs hand-written coding keys.

## CI and deploy

- **macOS runners.** The Linux build could not be tested locally, and an earlier Linux run failed on a Linux-only compile error. macOS runs the same toolchain as local builds.
- **Same triggers as before**: pushes to `main`, manual dispatch, and the nightly build (which picks up new App Store data and releases).

## Owner decisions

Do not change these, even when a review or a research round suggests it.

- **The overflow menu (“…”) is a native `<select>`.** Not a popover, not a custom menu, not `appearance: base-select`. It works with the keyboard and on touch devices, and it looks native.
- **No fade between pages.** Do not add a cross-document view transition that fades the page on navigation, or that morphs app icons into the next page.

## Known limitations

- Code blocks are not syntax highlighted. The old site used Shiki for about 70 blocks.
- The sitemap keeps the old two-file layout (`sitemap-index.xml` → `sitemap-0.xml`), so URLs that search engines already know keep working.
