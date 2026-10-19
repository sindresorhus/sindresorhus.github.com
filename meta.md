# Decisions

Short reasons for the main choices in the Swift version of the site.

## Stack

- **Swift with Elementary for HTML.** Elementary is a small, fast HTML DSL with result builders and an environment, close to SwiftUI. Ignite and Publish bring their own HTML DSL and theme system. We only needed the HTML layer, and we wanted full control over the markup.
- **swift-markdown and SOML.** Apple’s Markdown parser gives a typed tree, so headings, alerts, footnotes, and keyboard shortcuts are handled on the tree, not with regexes. The frontmatter is [SOML](https://github.com/soml-lang/soml), not YAML: a value has the type its syntax gives it, so `version: 1.10` cannot silently become the number 1.1, and a day is a string (`'2026-02-23'`) that the `Day` type checks.
- **Social cards with Core Graphics.** The cards are drawn with Core Graphics and Core Text, with the Inter font bundled as a resource. A card looks the same on every machine, the build needs no Homebrew packages, and drawing is much faster than starting `rsvg-convert` for each card. The layout follows the old CSS design (line heights, margins, shadow), and long texts wrap.
- **No Node at build time.** The build is `swift run website build`. Browser scripts are plain JavaScript files, in `public/scripts` and in the `Scripts` folders next to the Swift files of their elements.

## Package layout

- `RSS`: a general RSS 2.0 library (typed items, result builder, validation). It knows nothing about the site.
- `SiteKit`: the small toolkit the site needs: content loading, Markdown, routes, publishing, link validation, and the style system. Sized for this site, not a framework.
- `SiteKitMacros`: the `@Frontmatter` macro.
- `Website`: everything specific to sindresorhus.com.
- `WebsiteCLI`: `build`, `check`, `routes`, `serve`.

The split keeps site knowledge out of the generic parts, so each layer can be read and tested alone.

## Content

- **Strict frontmatter.** `@Frontmatter` generates decoding that rejects unknown keys and keeps default values. Synthesized `Decodable` silently ignores typos and drops defaults, which hid real content mistakes. This is the one macro that clearly pays for itself.
- **Validation in types.** `AbsoluteURL` fails while decoding, so the error names the real key path. There are no hand-written key strings to keep in sync. The line of a mistake about a frontmatter value comes from the coding key too (`MarkdownFile.line(of:)`), so a renamed key cannot report the line of another key.
- **Loading is on the type.** `BlogPost.load(from:)` instead of a collection wrapper type.

## Routes and publishing

- **Every output file is a `Route` value**, built with `@RouteBuilder` in `Site.routes`. Reading one function shows the whole site map. The sitemap is derived from the routes.
- **The publisher is defensive.** It checks for two routes writing the same file, and for a public file at the path of a page, which a static host may serve instead. It refuses an output directory that would delete the project or write into the public or content directory, and a git checkout, as it removes the files that are not part of the site.
- **The preview server is Swift** (`PreviewServer`, Network framework), not Python, so the build has no other runtime. It behaves like GitHub Pages (`/about` serves `about.html`), opens the default browser, and stops when its task is cancelled, which makes it testable.
- **Watch mode polls.** `serve` compares file dates every half second instead of using FSEvents. It is simple, and fast enough for the size of the project. Content changes, and changes of the scripts of elements, rebuild in the same process. Other source changes run `swift build` and replace the process with the new executable (`execv`), which is simpler than a separate supervisor process. Pages long-poll the server for its state: they reload when the files are written, before the link check, and show build errors and broken links on the page. Asking again after a failed request also works across a restart.
- **Incremental publishing.** The output directory is not deleted. Unchanged files are not written, and files that are no longer published are removed, so rebuilds are fast and the published files always match the routes.
- **Cached data for local builds.** The responses, like from the App Store and GitHub, are cached for an hour and revalidated with ETags. CI revalidates each response, except the GitHub contributions of past years, which do not change. When a request fails, every build uses the cached response with a warning, so a local build works offline, and one failed request does not fail a deploy.
- **Reproducible output.** Dates use a fixed locale and UTC. The related apps rotate daily with a seeded shuffle, so two builds on the same day give the same files, and diffs only show real changes.
- **No HTML minification.** The markup is already output without whitespace between tags. Only the indentation of the CSS is left, and removing it saves about 1.5% after brotli (measured October 2026), which Cloudflare already applies. A Node minifier also needs Node at build time, and `html-minifier-terser` (clean-css) drops nested CSS rules.

## Styles

- **Typed modifier chains**, like SwiftUI view modifiers: `Style().padding(.rootEm(1)).hover { $0.background(.gray(100)) }`. Each modifier returns the same concrete type, so long chains type-check fast. Jetpack Compose and Kobweb (a Kotlin web framework built on Compose) use the same model for styling. Result builders fit structure (routes, page bodies) better than a list of properties.
- **Named styles as enum cases (`StyleSet`).** Each component has `enum Styles: StyleSet`, and the class name is generated from the component and the case (`app-card-title`). Markup applies `.style(Styles.title)`, so markup and CSS cannot drift, and a typo does not compile. `CaseIterable` registers every style, and the `switch` is exhaustive.
	- A macro was considered for naming `static let` styles. A macro cannot rewrite the initializer of a stored property, and `#function` gives the enclosing type name, not the property. Enum cases give names, registration, and exhaustiveness with plain language features.
- **Typed values.** `Color` (palette, `.opacity`), `Length`, `Shadow`, `FontWeight`, keyword enums, and a text scale where one call sets size and line height. A selector is a `CSSSelector`, a literal or an interpolation of other selectors: a class name without its dot cannot be interpolated, and other text is written with `raw:`. A registered property takes a `PropertySyntax`, so a misspelled type does not compile: the browser drops a registration with a type it does not know, without a message. `.declaration(_:_:)` is the escape hatch for rare properties.
- **Styles are found while rendering.** Applying a style registers it with the page, like SwiftUI preferences. Each page gets a `<style>` with only the component styles it applies (not the other cases of their style sets), and the shared `site.css` has the element defaults, the typography, and the components that most pages use, like buttons, the header, and the footer. No list of components has to be kept in sync, which removed a whole class of bugs (a new component without styles). Scripts work the same way with `ModuleScript`.
- **Cascade layers.** The styles have four layers: element defaults, Markdown typography, components, and the styles of single elements (`ElementStyle`). Components always win over the typography around them, and a style on an element wins over its component, whatever the specificity.
- **The palette is custom properties.** Each shade and each semantic color (like `.primaryText`, with light and dark values through `light-dark()`) is defined once on `:root`. Swift code uses typed values, like `.gray(900)`.
- **Native CSS nesting.** Nested selectors and conditions are written as nested CSS, which all current browsers support. The output is smaller and reads like the Swift.
- **Selector rules stay where components do not own the markup**: Markdown output (`.prose` typography), and elements that scripts create.
- **Scripts use IDs and `data-` attributes**, never style classes. Renaming a style cannot break a script.
- **Element scripts are found by folder, not listed.** Swift cannot list the types that conform to a protocol (`@section` records in Swift 6.3 have no API to read them), so a script file defines its own element with its tag written by hand, and the build publishes every `Scripts/*.js` file unchanged. For an element with a short inline script (`ElementScript(inline:)`), the build writes the definition. Tests check that each element on a rendered page is defined, once. One import map per page adds the hashes to imports, as Firefox only uses one.
- **Verification.** The style migration was checked by comparing the computed style of every element in Chrome (light and dark, desktop and mobile) before and after. Pixel screenshots were too noisy, because of image loading.

## Data flow

- **Pages get their data in their initializer**, in `Site.routes`: `AppPage(app:content:)`. The flow is explicit, and the compiler checks it.
- **No `@Environment` for page data.** Elementary’s environment only exists while rendering, but routes, paths, and metadata are computed before rendering. Page data in the environment would have to be optional, and the dependency would be hidden. The data passes through at most two layers, so explicit parameters are simpler.

## One owner for each fact

Facts that were decided in several places now have one owner. Examples: `App.releaseNotes` (page, feed, and repo; `nil` for archived apps), `App.shareURL` (the hero and the overflow menu; `nil` for archived apps), the sitemap entry of a page that search engines may not index (`Page.route` leaves it out), `App.downloadOptions`, the site feeds, the author in structured data, page titles, asset paths, the location in a message (`URL.location(ofLine:)`, for content errors, warnings, and broken links), and a GitHub repo name (`GitHubRepositoryName`, which ignores case).

## Structured data

- **JSON-LD only, no microdata.** The JSON-LD has the same facts as the old `itemprop` attributes, and search engines ignore microdata for site navigation. One format means one place to keep correct, and smaller HTML.
- **Keywords from property names.** Schema types have plain `type` and `context` properties, and the encoder writes them as `@type` and `@context`, so no type needs hand-written coding keys.

## CI and deploy

- **macOS runners.** The Linux build could not be tested locally, and an earlier Linux run failed on a Linux-only compile error. macOS runs the same toolchain as local builds.
- **Deploys have the same triggers as before**: pushes to `main`, manual dispatch, and the nightly build (which picks up new App Store data and releases).
- **Debug builds.** CI builds in debug, like the tests, so one build serves both. A release build takes 8 to 10 s longer to compile on CI and saves only about 1 s of the site build.
- **Sources dated by their last commit.** A checkout gives each file the current date, so the build that CI restores from its cache would compile every target again (80 to 110 s). A step first sets the date of each source file to its last commit (`git log --diff-merges=first-parent`, so a merge commit dates the files it changes against its first parent), and only what changed since the cached build compiles. The external links workflow does the same, so it also checks out the full history.
- **The site build is `--verbose` on CI**, so the log has the time of each step.
- **Git from the `PATH`.** The build and the tests run `git` through `/usr/bin/env`, not `/usr/bin/git`. On a fresh runner, `/usr/bin/git` asks `xcodebuild` where the git of Xcode is, about 4 s for each call.

## Owner decisions

Do not change these, even when a review or a research round suggests it.

- **The overflow menu (“…”) is a native `<select>`.** Not a popover, not a custom menu, not `appearance: base-select`. It works with the keyboard and on touch devices, and it looks native.
- **No fade between pages.** Do not add a cross-document view transition that fades the page on navigation, or that morphs app icons into the next page.
- **No TypeScript check of the scripts.** We tried it (2026-10): a test made a `.d.ts` of the parts, templates, and config of each element from the pages, and ran `tsc --checkJs` on the scripts that opt in. It found typos of parts and config keys, but the Swift tests already find most of them. And a script that opts in must have no type errors at all, which for the larger toys means many casts and JSDoc for code that works (the VCR had 37 errors). It also adds Node and TypeScript to the tests.

## Known limitations

- Only Swift and SOML code blocks are syntax highlighted (`CodeToken`). The old site used Shiki for every language.
- The sitemap keeps the old two-file layout (`sitemap-index.xml` → `sitemap-0.xml`), so URLs that search engines already know keep working.
- In a file with block directives, the definition of a footnote must be in the same part as its reference, before the next block directive, as the parser reads the text between them on its own.
- Footnotes and inline notes are popovers, which are not printed.
- A style set in a generic type gives each specialization the same class names, so a page that uses two specializations fails. Declare the styles of a generic component outside it, like `FormFieldStyles` for `FormField<Content>`.
- Two styles on one element (`.style { … }`) must not set the same property, as the order of their rules is the order in which the page first used them.
- The link check reads the attributes of a page with one regex. Text in HTML has its quotes unescaped, so a `="` in text without a closing quote, like inline code of `x="`, hides the attributes up to the next quote from the check.
- A file of a page bundle with a space or `%` in its name only works as a link with the space as it is, like `![Screenshot](<Screenshot 1.png>)`, and as an image it has no `width` and `height`, as a path from content must not have those characters. Give such files names without them.
- CI compiles a source file again only when its date changes, so a file that two commits changed in the same second could stay stale in the cached build.
- `validate()` runs after decoding, and only for the top value, like the frontmatter of a file, the arguments of a directive, or the attributes of an inline element, not for a value nested in another `@Frontmatter` type, so the type that contains the value checks it.
