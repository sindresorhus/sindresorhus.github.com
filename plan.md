# Swift site plan

Tracks the migration of sindresorhus.com from Astro/Tailwind/Node to Swift. `MIGRATION.md` is the historical log. This file is the working plan.

Rules:
- Do not push. Run every CI gate locally (`scripts/parity.sh`).
- Good architecture for this site, not a general framework. No speculative options.
- Astro is removed from the repo. The parity scripts compare against a local Astro build (`git worktree` at `97e8770`), outside the repo.

## Architecture

`meta.md` has the reasons for the main decisions.

```
Package.swift
├─ RSS            General-purpose RSS 2.0 library: typed items, GUIDs, enclosures, a result builder, RFC 822 dates, validation. No site knowledge.
├─ SiteKit        Small static-site toolkit, sized for this site.
│  ├─ Content     `ContentEntry.load(from:)`: Markdown files with strict typed frontmatter (`@Frontmatter`, `AbsoluteURL`), drafts left out, sorted.
│  ├─ Markdown    `MarkdownDocument` (swift-markdown): headings with GitHub slugs and `{#id}`, directives, introduction, footnotes, alerts, kbd. Styles `.extended` and `.releaseNotes`.
│  ├─ Routing     `Route` values (page, redirect, file) built with `@RouteBuilder`.
│  ├─ Publishing  `Publisher` (collision and output checks, sitemap), `LinkValidator`, `PreviewServer`.
│  ├─ Styles      `Style` modifier chains with typed values, `StyleSet` (named styles with generated class names), `Stylesheet` for selector rules, media queries, and keyframes.
│  └─ HTML        Attributes, `JSONScript`, the feed HTML sanitizer.
├─ SiteKitMacros  `@Frontmatter` and `@Key`.
├─ Website        sindresorhus.com: content types, external data, `Site.routes`, layout, components and pages (one per file, each with its `Styles`), theme, feeds, OG cards.
└─ WebsiteCLI     `website build | routes | serve`.
```

Data flow: `SiteContent.load()` (content + App Store and GitHub data, concurrent) → `Site.routes` (pure) → `Publisher.publish` → `LinkValidator`.

## Phase 0: Restore the oracle

- [x] Fix `SiteOptions` visibility compile error.
- [x] Resolve `rsvg-convert` from `PATH`.
- [x] Fix symlinked-root route bug in Markdown page loading.
- [x] Repair `compare-site-semantics.py` (truncated regex, duplicated tail, heading parts index).
- [x] Build Astro reference locally (Little Snitch blocks Node → `api.github.com`; use a local curl-backed fetch shim, never committed).
- [x] Add `scripts/parity.sh` that runs every gate.
- [x] Make visible-text comparison insensitive to whitespace at block boundaries (both sides).
- [x] Triage remaining diffs (fix during Phase 2, after the redesign):
	- Semantic: 3 heading slugs (`_`, `ⓘ`, emoji variation selector). Rule: keep alphabetic, marks, decimal digits, connector punctuation, space, hyphen.
	- XML: RSS channel link has trailing slash; sitemap homepage URL lacks slash; redirects listed in sitemap.
	- Text: “Another Random App” must be `hidden` until JS reveals it; apps stats must be separate spans with separators hidden on mobile (also a visual diff).
- [x] Add `scripts/compare-screenshots.py` (headless Chrome screenshots, light/dark, desktop/mobile). Chrome headless currently hangs; revisit in Phase 2.

Architecture comes first. Parity is a gate after the redesign, not a driver of it.

## Phase 1: New architecture (port everything, old Swift output as the baseline)

Baseline: current Swift output (`dist-baseline`) plus Astro. New output must match both gates.

- [x] Package layout: `RSS`, `SiteKit`, `Website`, `WebsiteCLI` (`website` product). `SiteCore` removed.
- [x] RSS library + tests.
- [x] SiteKit Content: frontmatter splitting, strict YAML decoding, `ContentCollection`, `OrderedMapping`.
- [x] SiteKit Markdown: AST-based headings, GitHub slugger (fixes `_`, `ⓘ`, emoji variation selector), directives, introduction, footnotes, alerts, loose lists, kbd, release-note options. Tests ported and extended.
- [x] SiteKit Routing/Publishing/Sitemap/LinkValidator (everything published is a `Route`).
- [x] SiteKit Styles DSL (`Rule(selector, [property: value]) { nested }`). Legacy CSS converted into component-owned styles with a migration script; cascade check: 0 value differences, remaining order flips verified as non-overlapping.
- [x] Website content types: `App`, `BlogPost`, `MarkdownPage`, app extras.
- [x] Website external data: `AppStoreInfo.lookup`, `GitHub`, `SiteContent.load` (concurrent; App Store failures are tolerated, GitHub failures fail the build, like Astro).
- [x] Website layout + components.
- [x] Website pages.
- [x] Website routes declared with `@RouteBuilder`. Feeds via RSS library.
- [x] OG card generation on the new structure.
- [x] CLI on the new `Website` target (`build`, `routes`, `serve`).
- [x] Delete `SiteCore`.

## Phase 2: Parity green on new architecture

- [x] Route parity.
- [x] XML (RSS + sitemap) parity.
- [x] Semantic HTML parity.
- [x] Visible-text parity.
- [x] OG visual parity.
- [x] Visual port of every page to hand-written CSS that mirrors the old DOM. Screenshot differences are under 5% except noise (random related apps, lazy images). Legacy CSS variables removed.
- [x] Browser JS audit: feedback form, FAQ suggestions, random app, contact, home canvas, media carousel, share button, overflow menus, secondary app nav. (Every page loads without script errors or failed requests at two widths, in light and dark mode, checked with a headless Chrome script. The interactive parts were tested with real clicks and keys: feedback form, FAQ suggestions (the same results as before for 210 messages), random app, contact, galaxy, media carousel and videos, overflow menus, mobile menu, secondary navigation, footnotes, code copy buttons, and the unicorn. The random app redirect no longer throws a view transition error.)

## Phase 3: Refinement passes

- [x] Pass 1: types and naming (no stringly IDs/URLs where a type helps, no `[String: Any]`, no tuples for links). (Typed `href` for site paths everywhere, the unused page `stylesheet` hook removed, and the googly eyes script cleaned up. No `[String: Any]`, and the remaining tuples are local return values.)
- [x] Pass 2: duplication and component boundaries. (With a review agent: the page width, icon and screenshot URLs, absolute URLs, ISO days, and typed paths each have one owner now.)
- [x] Pass 3: simplify control flow, remove accidental abstractions. (With review agents for SiteKit and the scripts. Alerts render in one renderer, footnote definitions share the document options, and dead script code is gone.)
- [x] Review with subagents, fix core/contract bugs. Repeat until clean. (Ten review passes with agents: code, accessibility, CSS, Markdown, publishing and the preview server, content validation, visual regressions, size, tests, and a final review of the branch. The last round found no core bugs.)

## Phase 4: Macros (last)

- [x] `@Frontmatter` macro replacing hand-written `CodingKeys`/`init(from:)` boilerplate (defaults, renames with `@Key`, strict keys, conformance). Expansion tests in `SiteKitMacrosTests`.
- [x] Evaluate other candidates (routes, metadata). Only keep with a clear win. (None kept: routes already use the `@RouteBuilder` result builder, and page metadata is a plain struct with defaults, so a macro would add build time and an Xcode trust prompt without removing boilerplate.)

## Phase 5: Remove Astro/Tailwind/Node

- [x] Move content to `content/` (`apps`, `blog`, `pages`, `apps-extra.json`). Drop the Astro `layout:` key.
- [x] Delete Astro pages/components/layouts/config, Tailwind, npm files, remark/rehype plugins, `styles/global.css`, xo config, tsconfig.
- [x] Replace `deploy.yml` with Swift build on a macOS runner (main, manual dispatch, nightly, `GITHUB_TOKEN`, Pages artifact, deploy-pages). macOS, because the Linux build cannot be tested locally.
- [x] `swift-site.yml` → `ci.yml`: tests, build (with link validation), JS syntax check with `node --check`, no npm.

## Phase 5b: Architecture (requested 2026-10-04)

- [x] Improve the architecture. Proposal below, agreed on 2026-10-04 with modifier chains for styles.
- [x] Make it more strongly typed (`AbsoluteURL`, `App.releaseNotes`, `DownloadOption`, typed style values, `RoutePath` for paths, `StyleSet` instead of class strings).
- [x] Simplify and DRY up (one owner for each fact, one type per file, smaller SiteKit, palette and brand gradient).
- [x] Make it more SwiftUI-like (style modifiers, `hstack`/`vstack`/`frame`, conditions as modifiers).
- [x] Macros: kept to `@Frontmatter`. Named styles use enum cases, which give names, registration, and exhaustiveness without a macro (see `meta.md`).
- [x] Less plain CSS: every style is a typed modifier chain; about 100 `.declaration` calls remain for rare properties.

Input: the two audits from 2026-10-04 (SiteKit and Website), summarized in the proposal.

### Proposal (agreed)

Problems today:
- Class names are strings written twice: `.class("feed-card")` in markup and `Rule(".feed-card", …)` in the style. A typo or a removed rule fails silently (the audit found 3 such bugs).
- Most CSS values are strings (`"1px solid"`, `"0 10px 15px -3px rgb(0 0 0 / 10%)"`, `"1.4286"`), and `fontSize` + `lineHeight` pairs repeat everywhere.
- Pages get their data through initializers (`AppsPage(content: content)`), so `content` is threaded through every page and component.
- The same facts are decided in several places: release-notes availability (4), download providers (2), site feeds (3), structured data for apps (2), feedback URL (2).
- Files mix many types (`AppPageSections.swift` has 8 components). Some models live in page files (`AppCategory`).
- SiteKit has more API than the site uses (`ContentCollection`, 55 unused CSS properties, builder wrapper types).

1. Typed, colocated styles (the main change). A component declares named styles next to its markup and applies them with `.style(_:)`. Styles are written as modifier chains, like SwiftUI view modifiers. Class names are generated from the type and property name (`feed-card-title`), so markup and CSS cannot drift:

	```swift
	struct FeedCard: HTML {
		var body: some HTML {
			a(.href(feed.path)) {
				span { feed.title }
					.style(Styles.title)
			}
			.style(Styles.card)
		}

		@Styles
		enum Styles {
			static let card = Style()
				.border(.slate200.opacity(0.8))
				.cornerRadius(.rem(0.5))
				.background(.white.opacity(0.8))
				.shadow(.small)
				.hover {
					$0.background(.primary50.opacity(0.5))
				}
				.dark {
					$0.border(.white.opacity(0.1))
				}
				.breakpoint(.sm) {
					$0.padding(.rem(1.5))
				}

			static let title = Style()
				.font(.base, weight: .bold)
		}
	}
	```

	- `Style` is a value type. Each modifier returns a new `Style`, and a later modifier wins (like CSS). Condition modifiers (`hover`, `focusVisible`, `dark`, `breakpoint`, `reducedMotion`, `child(_:)` for a nested selector) take a closure that gets an empty `Style`, so conditions nest: `.dark { $0.hover { … } }`.
	- Reuse works like custom view modifiers: `extension Style { func focusRing() -> Style { … } }`.
	- Values are typed: `Color` (palette, `.opacity`), `Length`, `Shadow`, `Font(.lg)` (size and line height from one scale), `Transition`. A raw `.declaration("hanging-punctuation", "first")` is the escape hatch.
	- `@Styles` (macro) generates the class names and the list of styles. `SiteStylesheet` lists the types (`FeedCard.Styles.self`) in cascade order, like today.
	- State and script hooks (`hidden`, `leaving`, IDs) stay strings, because JavaScript uses them. A style that a script selects can set a fixed class name.
	- Prose (Markdown output) keeps selector-based rules, because Markdown produces that HTML, not components.

	Why modifier chains: it is how SwiftUI and Jetpack Compose style views, and Kobweb (Kotlin web framework built on Compose) uses the same model for CSS: named styles, `Modifier` chains for declarations, blocks for `hover` and breakpoints. Each modifier returns the same concrete type, so long chains type-check fast. Result builders are better for structure (a list of routes, a page body) than for a list of properties.

2. Environment instead of threading data. `@Environment(\.content)` and `@Environment(\.currentPath)` (Elementary supports `@Environment` with `TaskLocal`). `SiteLayout` sets them. Pages and components read what they need.

3. One owner for each fact (strong types, DRY):
	- `App.downloadOptions: [DownloadOption]` (enum: App Store, Setapp, link), already filtered for archived apps.
	- `App.releaseNotes: ReleaseNotes?` (page path + feed path, `nil` when archived).
	- `Feed.blog/.newApps/.newRepositories` statics used by routes, `FeedsPage`, and `<head>`.
	- `Schema.SoftwareApplication(app:)`, `Schema.Person.author`.
	- `AppCategory` in `Content/` with raw values and `path`.
	- `AbsoluteURL` frontmatter type (validated while decoding, so errors show the real key path).
	- `RoutePath` for every internal path. Asset paths as constants.

4. Smaller SiteKit:
	- `ContentEntry.load(from:)` instead of `ContentCollection`.
	- CSS builder: one `StyleContent` protocol instead of 5 wrapper types and 6 `buildExpression` overloads. Prune unused properties and values.
	- One name for the sitemap flag (`isInSitemap`). Use Elementary’s `.rel`.

5. Files: one component or page per file, with its styles. Models in `Content/`.

6. Tests: a test that renders every page and checks that every class in the HTML has a style or a script use (catches the remaining string classes).

Order: 3 and 4 (no visual change, safe), 5, then 1 (styles, page by page with screenshots), then 2. Each step builds, passes tests, and keeps the HTML output the same except for the class names.

## Phase 7: Next improvements (agreed 2026-10-05, not started)

- [x] Watch mode for `website serve`: watch `content/`, `public/`, and `Sources/`, rebuild on change, and reload the open browser tab with a small script that only `serve` injects.
- [x] Cache the App Store and GitHub responses for local work, so rebuilds are fast and work offline. Deploy builds still fetch fresh data.
- [x] Make the untyped style declarations typed where a modifier reads clearly better. Leave rare properties as `.declaration`.
- [x] Make the feed sanitizer drop control characters (like `&#0;`) that are not allowed in XML, so feeds are always valid. Remove the limitation from `meta.md`.
- [x] Social cards for blog posts, with the same renderer as the app cards.
- [x] Sitemap `lastmod` from publication dates (or git dates).
- [x] Smarter 404 page: suggest the closest existing page, like for a mistyped app name.

## Phase 8: Ideas (agreed 2026-10-05, not started)

Suggested order: `light-dark()` with semantic colors, then `@layer`, then the content cleanup that removes the global utilities, then CI caching.

### Less global CSS, more local components

- [x] Rewrite the raw HTML in content that uses Tailwind leftovers (`pl-2`, `text-xs`, `sm:block`, `dark:text-black`, `whitespace-nowrap`) as Markdown or semantic HTML, and delete those global utilities.
- [x] Turn utility classes into components: `GradientText`, `VisuallyHidden` (for `.sr-only`), and a size parameter on `Icon` instead of the global `.icon` rule.
- [x] Render the FAQ collapsible sections and the heading anchors in Swift at build time (Markdown renderer) instead of in `site.js`, so they get local styles and need less JavaScript.
- [x] Render the markup that `feedback.js` builds as HTML strings (success message, attachment chips) as `<template>` elements with normal `Styles`. The script only clones them.
- [x] Make the Markdown typography one local style with nested element rules.

### Modern CSS

- [x] `light-dark()` for colors, like `.color(.gray900, dark: .slate300)`, to remove most `.dark { … }` blocks.
- [x] `@layer` (base, prose, components) for the cascade order, so it no longer depends on the order of the list in `SiteStylesheet`.
- [x] Native CSS nesting in the output: simpler renderer, smaller CSS.
- [x] The palette as CSS custom properties, defined once.
- [x] `field-sizing: content` for the feedback textarea instead of the resize script.
- [x] `<details name>` for FAQ sections that open one at a time, without a script.
- [x] Container queries for components like the app card. (Not a fit: the card is edge to edge on phones and boxed from `sm`, which depends on the screen, not on the width of the card. At 639px the card is about 40rem wide and edge to edge, and at `sm` about 36rem and boxed.)
- [x] `@view-transition` for page transitions, and `content-visibility: auto` for long pages like the FAQ. (`@view-transition` is done, for visitors who allow motion. `content-visibility` is left out: the closed FAQ sections are small and their heights vary from 56px to 120px on phones, so a size estimate would move the question a link jumps to, for little gain.)

### Performance and caching

- [x] Cache `.build` and the package checkouts in CI, keyed by `Package.resolved`.
- [x] Parse the Markdown files in parallel with a task group.
- [x] Write only changed files (compare a hash), and copy `public/` incrementally in watch mode. Every publish does this (bytes compared, public files by size and date), and stale files are removed.
- [x] Timing per build phase with `--verbose`.

### More SwiftUI-like and Swifty

- [x] Adaptive semantic colors (`.primaryText`, `.secondaryText`, `.separator`) with light and dark values, used with `light-dark()`.
- [x] Layout components (`VStack`, `HStack`, `Spacer`) for pure layout, to remove layout-only `Styles` cases. (Not done: only a few style cases are layout alone, like `Style().vstack()`, so layout components would need a new mechanism for parameterized styles for little gain. A named case also says what the element is.)
- [x] Typed links and routes: `RoutePath.randomApp` instead of `"/apps/random"`, and a typed destination in `LabeledLink`.
- [x] Typed script hooks: an `enum ScriptHook` for the IDs and `data-` attributes that scripts use.
- [x] Typed throws for content and publishing errors.

### Other

- [x] Validate the feeds against the W3C rules (add `atom:link rel="self"`).

## Phase 9: More ideas (agreed 2026-10-05, not started)

Suggested first: the component gallery, per-page CSS, scripts declared by components, and the shared `Button`.

### General

- [x] Generate `robots.txt` in Swift, with the sitemap path from `Sitemap.indexPath`.
- [x] Redirects in frontmatter (`redirectFrom: [/old-name]`) instead of code in `Site.routes`.
- [x] A weekly scheduled CI job that checks external links.
- [x] A component gallery at `/_gallery` (only in `serve`): every component in each state, light and dark. It is also the page for the computed-style regression tool. (Only published by `serve`. Dark mode follows the system appearance, as many styles use `prefers-color-scheme`, which a part of a page cannot switch. The page tests render it too.)

### Less global CSS, more local components

- [x] Per-page CSS: record which `Styles` a page uses while rendering, and give each page only those rules plus the base.
- [x] Keyframes owned by the component, with generated names (no global `reveal`, `drift-a`, `ring-rotate`).
- [x] Move the document styles (`html`, `body`) into `SiteLayout`. (Moved next to `SiteLayout` as `Stylesheet.document`, in the base layer of the shared stylesheet. `HTMLDocument` renders `html` and `body` itself, so they stay element rules.)
- [x] Use only the `hidden` attribute (`element.hidden` in scripts), and remove the `.hidden` class.
- [x] Replace `.class("prose")` and `not-prose` with the `Prose` component around only the text (`AppsPage`, `FeedbackPage`, `FeedsPage`).
- [x] A shared `Button` component with variants (`.primary`, `.glass`, `.download`) for the separately styled buttons. (Fills `.primary`, `.dark`, and `.gradient`, and sizes `.small`, `.regular`, and `.large` (the download look). Used for the “Get” button, download links, the 404 page, and the random app link. The glass buttons stay on the home page, the only page with them, and the submit button keeps its own style for its two labels.)

### Modern CSS

- [x] Relative colors (`oklch(from …)`) for hover shades, like `.primary600.lighter(0.05)`. (`Color.lighter(_:)`, used for the hover of the filled download and “Get” buttons.)
- [x] Feedback form: `accent-color` and `color-scheme` for native controls, and `:user-invalid` for validation without JavaScript. (The root already sets `color-scheme`.)
- [x] `@media (scripting: none)` instead of `<noscript>` blocks.
- [x] `@property` to animate the home page gradient instead of the `background-position` trick.
- [x] `aspect-ratio` for app media instead of the `--width` and `--max-width` variables. (The width and height attributes already give the aspect ratio and the natural width, so `--width` is gone. `--max-width` stays for the 640px height limit on wider screens, as CSS cannot read the attributes.)
- [x] `scrollbar-gutter: stable`.
- [x] Later, when Safari supports them: CSS carousels (`::scroll-button`, `::scroll-marker`) instead of the carousel script, and `appearance: base-select` for the overflow menu. (The popover menu replaced `base-select`. A TODO comment in `app.js` marks the carousel.)

### Performance

- [x] Compute app data once when an app loads (`links`, `downloadOptions`, `faqHeadings`), and use dictionaries instead of `first { $0.slug == … }` lookups.
- [x] Conditional GitHub requests with ETags (`If-None-Match`).
- [x] Draw OG cards with Core Graphics instead of `rsvg-convert` (text rendering changes slightly).
- [x] Check links in parallel, one task per file.
- [x] Faster navigation: the Speculation Rules API (prefetch on hover), and `fetchpriority="high"` on the app icon.
- [x] `-warn-long-expression-type-checking` in CI.

### More SwiftUI-like and Swifty

- [x] Components declare the scripts they need (like SwiftUI preferences), and the layout adds each script once. JSON-LD could work the same way. Done for scripts with `ModuleScript`. JSON-LD stays where the page renders it, as each page has at most one.
- [x] Reusable style modifiers (`extension Style { func cardSurface() -> Style }`) for the shared card look.
- [x] Let custom components accept `.style(…)` from their parent through a small wrapper. (No wrapper needed: Elementary forwards `.style()` and `.attributes()` to the root element of a component whose body names its tag, like `some HTML<HTMLTag.img>`. `AppIcon`, `DateText`, `Link`, `Section`, `LinkRow`, and `ProsePage` do.)
- [x] `@Environment` for presentation only, like the current path for navigation highlighting.

## Phase 10: Even more ideas (agreed 2026-10-05, not started)

Suggested first: classes from the Markdown renderer, the `popover` menu, the content column modifier, one build date, and `/apps.json`.

### Less global CSS, more local components

- [x] The Markdown renderer gets a theme that maps elements to `Styles` (like `h2` → `Prose.Styles.heading2`), so Markdown output has local classes, and the `.prose :where(…)` selectors and `not-prose` go away. Done as: a `MarkdownTheme` gives classes to the markup the renderer creates (alerts, footnotes, keys, collapsible sections, anchors), and standard elements keep zero-specificity nested rules in `ProseStyles.root`, so raw HTML in content is styled too. Cascade layers and `@scope` made the `:where(…):not(…)` construction unnecessary.
- [x] Delete the `SiteStylesheet` list once per-page CSS and `@layer` exist.
- [x] Style states from semantics (`aria-expanded`, `aria-current`, `data-state`) instead of state classes. (Runtime states use attributes: `aria-current`, `data-state`, `data-leaving`, `data-rainbow`, `:disabled`, and `:not([href])` for the hidden pagination link. The remaining conditional classes are variants.)

### Modern CSS

- [x] The `popover` attribute for the mobile menu instead of the hidden checkbox.
- [x] `@scope (.prose) to (.not-prose)` instead of the `:where(…):not(:where(.not-prose …))` construction, if prose stays selector-based.
- [x] Fluid type with `clamp()` instead of font size jumps at breakpoints. (`Style.fluidFontSize(fromRem:toRem:between:and:)` for the big titles: app, home, blog post, and 404. Each grows from the breakpoint before to the one where it jumped, so the sizes outside that range are the same.)
- [x] `:has()` for parent states, like a form field with an invalid input.
- [x] `prefers-contrast` and `forced-colors` support (visible borders and focus rings). (Done: more contrast redefines the semantic colors in one place. Focus rings already draw a transparent outline that forced colors mode shows, and borders get system colors there.)

### Performance

- [x] An SVG sprite (`<symbol>` + `<use href>`) for the icons repeated on every page. (`/assets/icons.svg`, generated from `Icon`. Each page is about 1.4 KB smaller, and the icons look the same.)
- [x] Check that CI uses the prebuilt swift-syntax instead of compiling it. Local builds use it (`.build/prebuilts/swift-syntax/604.0.0`), as `Package.resolved` pins an exact release. CI caches `.build`, which includes the prebuilts.
- [x] Stream page rendering to the output file, only if profiling shows it matters. (Not needed: a full release build takes about 1.1 seconds and 260 MB of memory.)

### More SwiftUI-like and Swifty

- [x] Page metadata as modifiers on the body, like `.navigationTitle`: `body.title("Apps").description("…")`. (Not done: the `metadata` property is typed, required, and known before rendering, which the feeds, the sitemap, and the Open Graph cards need. Modifiers would make it known only after rendering the body.)
- [x] `ForEach(items, separator:)` for lists with separators (apps page stats, footer link rows). (Done with CSS instead: the stats get a `::before` dot with empty alternative text, so there are no separator elements. The footer rows have no separators.)
- [x] Arithmetic on `Length` (`.rem(1) * 2`, `.rem(1) + .px(2)`), rendered as `calc()`.
- [x] A typed palette: `.primary(600)` instead of separate static colors.

### Simplify and DRY up

- [x] A `.contentColumn()` style modifier for the repeated `frame(maxWidth: .rem(48)).margin(.horizontal, .auto).padding(.horizontal, .rem(1.5))`.
- [x] A `.pagePadding()` modifier for the repeated "2rem, 4rem at `sm`, 5rem at `lg`" pattern. (Used by the app and privacy pages. The blog index has its own padding.)
- [x] `OverflowMenu.appPage(app)` for the menu that `AppLinks` and `AppSecondaryNavigation` both build.
- [x] One `MarkdownAlert` enum for the alert kinds (renderer icons in SiteKit, colors in a site extension).
- [x] Remove the Astro parity scripts (`scripts/compare-*`) and the local Astro worktree.

### Architecture

- [x] One build date in `SiteContent` instead of `Date.now` in several places (build time, "new" badge, related-apps rotation, "years of craft").
- [x] Report all content errors at once, not only the first.
- [x] App categories in frontmatter (`categories: [shortcuts]`) instead of slug lists in `AppCategory`.

### Creative

- [x] `/apps.json`: a public JSON list of the apps (name, subtitle, icon, platforms, App Store ID), for example for the "More apps" menus in the apps.
- [x] `llms.txt`: a generated plain-text summary of the site and every app, for AI assistants.
- [x] QR codes on app pages (SVG at build time) to open the App Store page on an iPhone. (For iPhone, Apple Watch, and Vision Pro apps on the App Store, below the download badge, on larger screens with a mouse. Core Image makes the code, and a test reads it back.)
- [x] An app timeline page: every app by year. (At `/apps/timeline`, linked from the “More” menu of the apps page. The icons morph into the app page.)
- [x] A unicorn easter egg, like a Konami code that makes a unicorn run across the page.

## Phase 11: Creative ideas (agreed 2026-10-05, not started)

- [x] Price from the App Store data on app pages (like “Free” or “$4.99, one-time”), so it never goes out of date.
- [x] Footnotes as popovers (native `popover` attribute): read the note in place instead of jumping to the bottom.
- [x] Autoplay videos play only while visible, to save battery and CPU on long app pages.
- [x] A greeting in the browser console for developers, with an ASCII unicorn and a link to the site's source.
- [x] A random app (“while you're here”) on the 404 page, below the closest-page suggestion.
- [x] Copy buttons on code blocks.
- [x] App icons in the “New Apps” feed (an image per item, with the RSS library's enclosure support).
- [x] A channel image for the feeds (the photo or the unicorn).
- [x] Screenshots in the sitemap (`image:image`).
- [x] A small “Built with Swift” link in the footer to the site's source.
- [x] App icons in the release notes feeds too.
- [x] `llms-full.txt`: all page content in one file, next to `llms.txt`.
- [x] A language label on code blocks (`sh`, `swift`), next to the copy button.
- [x] A `generator` meta tag naming the Swift build.
- [x] An AI crawler policy in `robots.txt`, generated from Swift: AI crawlers are allowed.

## Phase 12: Ideas, round 6 (agreed 2026-10-05, not started)

Suggested first: reading only media headers, frontmatter errors with line numbers, the guardrail test, and `AppIcon`.

### Less global CSS, more local components

- [x] Component variables as typed parameters: a component exposes CSS custom properties (like `Badge.background`), and a parent sets them with `.styleVariable(Badge.background, .teal100)`. No extra cases for variants, no nested selectors in parents. (`StyleVariable` in SiteKit, with `.setting(_:to:)`. Used for `Badge.fontSize` and `OverflowMenu.color`, which replaced the two nested selectors of parents into other components.)
- [x] A guardrail test that fails when a selector-based `Rule` is added outside an allowlist (Markdown typography, script-created elements).

### Modern CSS

- [x] `overscroll-behavior: contain` on the screenshot carousel, so a horizontal trackpad swipe does not trigger back navigation.
- [x] Logical properties: `.padding(.horizontal, x)` renders one `padding-inline`.
- [x] `prefers-reduced-transparency`: turn off the glass effects (backdrop blur in the header and on home page buttons).
- [x] `text-box: trim-both cap alphabetic` for badges and buttons. (`Style.trimmedText(verticalPadding:)` keeps the size. Used for badges, which are now `inline-block`, as `text-box` does not trim the text of a flex container, like the buttons.)
- [x] `@media (pointer: coarse)` for larger tap targets (icon links, overflow menus).

### Performance

- [x] Read only file headers for media sizes, instead of whole files with `Data(contentsOf:)` (videos are many megabytes).
- [x] Start slow routes first: OG cards before the fast HTML pages.
- [x] No copying in `serve`: serve from `dist` with `public/` as a fallback. Done differently: every publish only copies public files that changed (APFS clones them), so a fallback directory is not needed, and the link validator still sees every file.

### More SwiftUI-like and Swifty

- [x] Accessibility modifiers with SwiftUI names: `.accessibilityLabel("…")`, `.accessibilityHidden()`, and `.hidden(when:)`.
- [x] A `Link("Title", destination:)` component that adds `rel="noopener"` for external links that open in a new tab.
- [x] A `Label("Apps", icon: .appStore)` component for icon-and-text pairs.

### Simplify and DRY up

- [x] An `AppIcon(app, size:)` component for the icon `img` that repeats in five places.
- [x] A `DateText(date, format:)` component that renders `<time datetime="…">` with the formatted date.
- [x] `NonEmptyString` and `SafeInteger` frontmatter types, like `AbsoluteURL`, to remove most `validate()` code.
- [x] A shared test helper for temporary project folders.

### Architecture

- [x] Routes grouped by section: `appRoutes`, `blogRoutes`, and `feedRoutes` as `@RouteBuilder` properties composed in `routes`.
- [x] Frontmatter errors with line numbers (map the key path to the YAML line with Yams positions), like `dato.md:12`.

### Creative

- [x] Recent five-star reviews on app pages, from the public App Store reviews feed. (Up to three recent five-star reviews of a readable length, from the US App Store feed, cached like the other App Store data. A failed request leaves out the reviews of that app.)

## Phase 13: Ideas, round 7 (agreed 2026-10-05, not started)

Suggested first: `FormField`, `:target` highlight, and loading `home.js` only when needed.

### Less global CSS, more local components

- [x] Split `Prose.swift` by topic: typography, alerts, FAQ, keyboard keys, and tables in separate files.
- [x] A `FormField` component for the feedback form: label, input, and hint, with local styles.

### Modern CSS

- [x] Highlight the target of a link with `:target`, like the FAQ question you arrive at from the feedback page.
- [x] `transition-behavior: allow-discrete` to animate elements that switch to `display: none`, like the FAQ suggestions box.
- [x] `::selection` in the brand colors.

### Performance

- [x] Load `home.js` only in dark mode and only when the visitor allows motion (dynamic import). (`home.js` is now a small loader, and the galaxy is `nebula.js`, imported in dark mode for visitors who allow motion, also after switching to dark mode.)
- [x] Build the FAQ matching index in Swift (tokens, stopwords, synonyms, weights) and write it as JSON, so `feedback.js` only scores. Test the Swift part. (Done: the words of each question, with synonyms, the stopwords, and the pinned ranks come from Swift. How often each word occurs is still counted in the browser, as it depends on the selected app.)
- [x] `decoding="async"` on screenshots.

### More SwiftUI-like and Swifty

- [x] A `Video` component with typed options (`.autoplay`, `.loop`, `.muted`, `.playsInline`) instead of `.custom(name: "autoplay")` attributes. (Done as typed attributes on `video` in SiteKit (`.loop`, `.muted`, `.playsInline`, `.preload`). `app.js` starts the videos, so there is no `autoplay`, and one use did not need a component.)
- [x] A `Section(title:)` component for titled groups (apps page groups, older versions page, FAQ).

## Phase 14: Ideas, round 8 (agreed 2026-10-05, not started)

Suggested first: scripts stop writing inline styles, and the scroll spy with `IntersectionObserver`.

### Less global CSS, more local components

- [x] Scripts stop writing inline styles (`style.display`, `style.opacity`, `style.pointerEvents` for the share button, random app link, carousel buttons, and secondary navigation). They set a state attribute like `data-visible`, and the look is defined in the component's `Styles`.

### Modern CSS

- [x] Reveal the secondary navigation with a scroll-driven animation (`animation-timeline: view()` on the app header) instead of the `IntersectionObserver` script.
- [x] Later, when browsers support it: CSS scroll spy (`:target-current`, `scroll-target-group`) instead of the scroll-spy script. A TODO comment marks the place in `app.js`. (The TODO comment is in `app.js`.)

### Performance

- [x] Scroll spy with an `IntersectionObserver` instead of measuring all headings on every scroll event.
- [x] Contact page: wait for `document.fonts.ready` and use a `ResizeObserver` instead of `setTimeout(cachePositions, 1000)`.

### More SwiftUI-like and Swifty

- [x] Typed transitions with Swift `Duration`, like `.transition(.colors, duration: .milliseconds(150))`, instead of strings like `"color .15s"`.
- [x] Remove `Comparable` conformances that exist only for sorting (`LinkValidator.BrokenLink`, maybe `RoutePath`), and use comparators.

### Simplify and DRY up

- [x] Clean up the scripts: fix the indentation in `app.js`, and remove comments that still mention Tailwind.

### Creative

- [x] A share button on every app page. Apps without an App Store link share the page URL.

## Phase 15: Research results (agreed 2026-10-05, not started)

From five research agents (CSS, Swift design, performance with measurements, code audit, macros). Suggested first: the two bugs, the regex fix, the JSON-LD encoder setting, and the icon view transition.

### Bugs

- [x] Glass buttons on the home page have no blur in Chrome and Firefox: they set only `-webkit-backdrop-filter`. Use `backdrop-filter`. Also remove the unneeded `::-webkit-scrollbar` (`AppMedia`) and `-webkit-background-clip` (`.gradient-text`).
- [x] Carousel buttons are invisible to keyboard users (shown only on hover). Add `:focus-within` to the same rule in `AppMedia.Styles.root`.

### Performance (measured: site build 4.0–4.8 s in release)

- [x] Stop compiling regexes again on each use in the Markdown code: cheap checks before each regex (`linkingBareURLs`, `Footnotes.extractDefinitions`, `replaceReferences`), and keep the other regexes as static values. Prototyped: 2.75–2.97 s, byte-identical output. Same pattern in `HTMLSanitizer` and `LinkValidator`.
- [x] Make `isLoose` linear: compute it once per list in the renderer, not twice per list item (about 0.4 s).
- [x] Deploy in debug, like CI: release costs 8–10 s more compile time on CI and saves about 1 s at run time, and one configuration shares one build cache. Add a comment in `deploy.yml` that explains this, so it is not changed back to release.
- [x] One workflow for `main`: the deploy job publishes the output of the tested build, instead of CI and deploy each building.
- [x] Skip deploys that change nothing: remove the `x-build-time` tag, compare a hash of `dist`, and skip upload and deploy when it is the same. Decide if the daily related-apps rotation should still change pages. Decision: the daily related-apps rotation stays, so nightly builds change the app pages once a day. Other builds deploy only real changes.
- [x] Let Cloudflare cache the HTML (a cache rule, and a purge call in the deploy job). The purge step runs when the secrets are set. The cache rule is set in the Cloudflare dashboard, as the readme describes.
- [x] Faster Homebrew in CI: `HOMEBREW_NO_AUTO_UPDATE=1`, `HOMEBREW_NO_INSTALL_CLEANUP=1`, `HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1`. Not needed anymore: the build has no Homebrew packages since the social cards use Core Graphics and a bundled font.
- [x] Faster local builds with the native build system, and run `.build/debug/website` directly instead of `swift run` (watch mode). Swift 6.4 already defaults to the Swift Build engine (`native` is deprecated), and watch mode restarts `.build/debug/website` directly.
- [x] Icon tilt in `app.js`: measure the icon on `mouseenter` and on resize, not on every `mousemove`.

### Less global CSS, more local components

- [x] `ProsePage` gets its own `Styles` instead of the `prose-page` and `prose-page-spacious` string classes and global rules.
- [x] One `Prose(html:, variant: .article)` owns the blog post typography (now in `.prose-blog`, the `#post-container` rules, and a raw class).
- [x] Put style cases on elements the component owns, instead of the ~43 descendant selectors (`.nested("img")`, `.nested("span")`). The blog list marks external posts with `.style(Styles.external, when: post.isRedirect)` instead of an `a[href^="https://"]` selector. (The remaining descendant rules style raw HTML that components do not own, like the Markdown of an announcement and the star SVG, and the title that `ProsePage` renders.)
- [x] The “Get” button becomes a plain `<a href="#app-hero">`, with no script.
- [x] Render the apps filter notice in Swift as a hidden `<p>` with `Styles`, and let `apps.js` only fill in the text.

### Modern CSS

- [x] Cross-document view transition that morphs the app icon from the apps list (and related apps) into the app page (`view-transition-name` per app, one `view-transition-class`).
- [x] Contact page: letter colors and delays with `sibling-index()` and `sibling-count()`, instead of script math and inline `--delay` styles. Sparkles with `@starting-style` instead of a forced reflow.
- [x] Gradients interpolated in OKLCH (`in oklch`), via a parameter on `CSSValue.linearGradient`. Check with screenshots.
- [x] `dvh` and `svh` instead of `vh` (mobile menu, feedback page, prose, 404, home canvas), with `Length.dvh` and `Length.svh`.
- [x] Show the header border only after scrolling (scroll-driven animation on `SiteHeader`).
- [x] `text-wrap: balance` on all headings and `pretty` on all prose paragraphs.
- [x] `:open` for `details`, and for the overflow menu's `select` while its menu is open. (`[open]` already works in all browsers for `details`, while `:open` is not in Safari yet. The overflow menu is a popover now, so its button shows the open state with `:has(:popover-open)`.)
- [x] Anchor positioning for the planned footnote popovers.
- [x] Center the odd last press quote with pure CSS (`:nth-child`), and use `:has(> :nth-child(2))` for two columns, instead of index math in Swift.
- [x] Later: interest invokers for icon-link tooltips, and `corner-shape: squircle` for cards and buttons. (TODO comments in `IconLink` and `Style.cardSurface()`.)

### More Swifty, simpler, DRY

- [x] Write the JSON-LD `@type` and `@context` keys with one key encoding strategy, and delete the seven `CodingKeys` enums and `Schema.Document.encode`.
- [x] A test that renders every page offline (real content, empty App Store and GitHub data), one test case per route: one `<h1>`, a unique `<title>`, and a description of 160 characters or fewer.
- [x] Warnings fail the build: `.treatAllWarnings(as: .error)` for our targets (SE-0480).
- [x] Remove the microdata (`itemprop`, `itemtype`), because the JSON-LD has the same facts and Google ignores the navigation microdata. Add the decision to `meta.md`.
- [x] One `.style(Styles.root, kind)` call for styles from different enums (parameter packs), instead of chained `.style().style()`.
- [x] One `SiteFeed: CaseIterable` enum (path, title, short title, subtitle, icon, feed builder) for the site feeds, used by the routes and `FeedsPage`.
- [x] One shared function for GitHub Pages path resolution, used by `PreviewServer` and `LinkValidator` (and the inverse of `RoutePath.outputFile`).
- [x] Parse release notes once (when content loads), and let the feed use `releaseNotes.feed.title`.
- [x] Two style duplicates: the menu toggle reuses the `IconLink` style, and a `Style.currentPageUnderline()` replaces the copied `aria-current` underline. (The menu toggle reuses the `IconLink.look` style value, not its class, as the order of rules from different style sets on a page is not defined.)
- [x] `margin(top:horizontal:bottom:)` with optional parameters, for the ~25 chains of three margin calls.
- [x] `@Frontmatter` on `LinkGroup` and `LabeledLink` (`content/apps-extra.json`), so the last content file also rejects unknown keys.
- [x] Exit tests for the crash paths (`RoutePath` preconditions).
- [x] Typed selectors for nesting patterns used three or more times (like `.children("li")`). (Done for the most used one, `Icon.selector`, and fixed icon sizes moved to `Icon.size(_:)`. The element selectors are the next item.)

### Creative

- [x] A static `/.well-known/webfinger` file, so `@sindre@sindresorhus.com` finds the Mastodon account (any name at the domain resolves to it).
- [x] `humans.txt` with a unicorn, generated in Swift.

## Phase 16: Markdown syntax for list subtitles and descriptions (agreed 2026-10-05, not started)

- [x] In list items (only in the `.extended` Markdown style), a continuation line that starts with `: ` renders as `<span class="list-subtitle">`, and one that starts with `:: ` renders as `<span class="list-description">`. Inline Markdown works inside both.

	```markdown
	- Calculate Bearing
		:: Get the compass direction between two coordinates.

	- Get Active Browser Tab
		: Gets the URL and title of the active browser tab
		:: Supports Safari, Chrome, and any Chromium-based browser.
	```

- [x] A `::` line right after a `:` line gets the smaller size automatically (today's `list-description text-xs`), so the output looks exactly like today. The CSS part is done: a description right after a subtitle is smaller (`.list-subtitle + .list-description`), which also restores the small size of the existing `text-xs` descriptions.
- [x] Add tests, and add the two classes to the classes the renderer documents.
- [x] Do NOT convert the content yet: the existing `<span class="list-subtitle">` and `<span class="list-description">` in `content/` stay as they are, and content files must not be touched for this. Both forms must keep working.

Why `:`: it comes from definition lists (Pandoc, kramdown, PHP Markdown Extra), reads well raw, and shows as plain text on GitHub. Two markers instead of a position rule, because one-line subtitles (`shortcutie.md`) and one-line descriptions (`actions.md`, `supercharge.md`) look different today.

## Phase 17: Research results, round 2 (agreed 2026-10-05, not started)

From five more research agents (less JavaScript, Markdown pipeline, SiteKit internals, components and style API, new kinds of ideas). Suggested first: the bugs, then the popover overflow menu, strict directives, the `hover` default, `.hidden(below:)`, and campaign tokens.

New Markdown syntax in this phase must keep the old forms working. Do not convert content files.

### Bugs (all confirmed by running them)

- [x] A route with a dot in its last part (like `/blog/macos-13.1`) publishes without `.html` and downloads instead of showing. Let the route kind decide (pages and redirects are always HTML), and remove the guess from `RoutePath`.
- [x] Missing folders pass silently: a missing `content/blog` loads zero posts, and a wrong output path makes link validation check nothing (also `Publisher.publicFiles()`). Throw instead.
- [x] Nested links: a bare URL inside a raw `<a>` or inside emphasis within a link becomes a link inside a link. Track link depth in the renderer.
- [x] `<kbd>Cmd++</kbd>` renders an empty key.
- [x] URL detection cuts a needed `)` (like `…/Swift_(programming_language)`): cut it only when unbalanced. Also, `icon@2x.png` becomes a `mailto:` link.
- [x] Preview server: `/` can try a file outside the output folder (`../dist.html`), and `/blog/` works in `serve` but the link validator reports it as broken. Check the chosen file, and fold this into the planned shared resolver.
- [x] `--output` is resolved against `--root` instead of the current folder.
- [x] `serve` opens `localhost` but listens on `127.0.0.1`: open and print `http://127.0.0.1:<port>`.
- [x] Frontmatter with a BOM or trailing spaces after `---` is read as body text: remove the BOM and trailing whitespace before comparing fence lines.
- [x] Incorrect ARIA in the feedback form: `aria-expanded` is not allowed on a textarea.
- [x] 96 HTML comments reach the published pages (commented-out drafts, `@faq` directives): skip comments in the renderer.
- [x] The Astro attribute `is:inline` ships from two content files as an invalid attribute. Add a guard test against raw `<script>`, `<style>`, `style=`, and `is:` in content, with the current files on an allowlist (do not edit the content now).
- [x] Hover effects stick on touch screens: `Style.hover` always applies only under `(hover: hover)`, and `canHover` goes away.

### Less JavaScript

- [x] The overflow menu becomes a popover (`popovertarget` and anchor positioning) with real links. It works without JavaScript, crawlers follow the links, and `AppFooterLinks` can go. Replaces the planned “later `base-select`” item.
- [x] Let browsers open `<details>` for fragment links and find-in-page (about 35 lines in `site.js`). Check ID fragments in Safari first. Chrome, Firefox 139, and Safari 26.2 open sections for find-in-page and for fragments inside them. A fragment that is the `<details>` itself does not open it, so five lines of `site.js` remain.
- [x] Remove the custom keyboard handling for FAQ suggestions (about 40 lines, fixes the ARIA bug), and give the panel `role="status"`.
- [x] The contact page rainbow in CSS with `@property`, and remove the dead branches in `contact.js`.
- [x] Render the secondary navigation inside `SiteHeader` in Swift (`SiteHeader.Variant.app(App)`), instead of moving it with a script.
- [x] “Another Random App” with `:target` (`/dato#random`) instead of checking the referrer.
- [x] Heading anchors stop calling `preventDefault` and `history.pushState`, so `:target` works.

### Markdown and content

- [x] Strict heading directives: unknown names (like `@faq.keyword`) and directives not under a heading fail the build with file and line.
- [x] Footnote references handled on the Markdown tree (`visitText`) instead of a regex over source lines, which removes the inline-code limitation.
- [x] The feedback FAQ question added on the Markdown tree instead of by editing raw lines.
- [x] `++Option+◀++` syntax for keyboard shortcuts (renders the same `<kbd>` markup). The old `<kbd>` form keeps working.
- [x] Platform badges with swift-markdown's inline attributes: `^[macOS-only](platform: "macOS")`, checked against `Platform`, with a local style.
- [x] Typed block directives with swift-markdown's DocC syntax (`@Details`, `@Tips`), with unknown names failing the build. After the content cleanup removes the inline `<style>` in `supporters.md`.
- [x] Link errors at the Markdown source line (like `aiko.md:12: /apps/faq#universal-purchas`), and support for `[Dato](dato.md)` links.
- [x] A typed `Announcement.url` (absolute URL or `/path`), validated while decoding.
- [x] Alt text required for Markdown images, and width and height added at build time for local images.

### Style API and components

- [x] `.hidden(below:)` and `.hidden(from:)` for the “display none, then display flex at a breakpoint” pattern (about 13 styles).
- [x] Use the modifiers that already exist: `grid(columns:)`, `underline(…)`, and `Shadow` instead of raw strings.
- [x] Delete dead code: the unused `CSSValue` palette copy in `Theme.swift` and the unused enum cases.
- [x] Typed effects with SwiftUI names (`.scaleEffect`, `.offset(y:)`, `.rotationEffect`, `.brightness`, `.blur(radius:)`), rendered as the separate CSS properties.
- [x] SwiftUI names where SwiftUI has a clear one: `.bold()`, `.textCase`, `.fontWidth(.expanded)`, `.textSelection(.disabled)`, `.allowsHitTesting(false)`, and `.leading`/`.trailing` text alignment.
- [x] `.cornerRadius(.capsule)` and `.cornerRadius(.circle)` instead of `9999px` and `50%`.
- [x] Stack parameters: `.hstack(alignment:justification:spacing:)`, with an inline option.
- [x] An `AppHero` component split out of `AppPage`, and `App.availabilityText` on the model.
- [x] `ProsePage(title:backTo:)` for the pages that start with a back link and a title.
- [x] One component for “link — description” rows (app list, older versions page, apps page extras). (The descriptions are now in the secondary text color everywhere, with an em dash.)
- [x] `focusRing(_:)` for the outline-plus-ring pattern.
- [ ] Semantic text styles (`.largeTitle`, `.caption`). A design decision, because pages would look slightly different. (Left for you to decide: the text sizes vary by component, and the most common size and color pair appears twice, so semantic styles would change how pages look.)

### SiteKit improvements

- [x] Check `og:image` and `og:url` (`content="…"` URLs) in the link validator.
- [x] A duplicate-ID check in the link validator.
- [x] The port as `UInt16` (ArgumentParser checks the range), and remove the dead `PreviewServerError` validation.
- [x] A simpler task group in `Publisher` (one loop, type inference).
- [x] Whole-component path matching for the current-page link (`RoutePath.starts(with:)`).
- [x] A test that the generated class names are unique.
- [x] RSS validation errors that name the item, and a check for an empty channel description.

### New kinds of ideas

- [x] App Store campaign tokens (`pt=…&ct=web-<placement>`) on App Store links and in the `apple-itunes-app` meta tag. The provider ID is not public, so set `Site.appStoreProviderToken` (App Store Connect → App Analytics → Campaigns) to turn the tokens on. Until then, the links stay as they are.
- [x] Demo videos follow reduced motion and can be paused (WCAG 2.2.2): no `autoplay` in the HTML, `app.js` plays them only when motion is allowed, and a tap pauses or plays.

## Phase 18: Research results, round 3 (agreed 2026-10-05, not started)

From six research agents (local CSS, modern CSS, performance with measurements, Swift design, simplify and architecture, creative), and the owner's feedback. Suggested first: the bugs and the feedback items, then the cheaper social cards and the class coverage test.

### Feedback from the owner

- [ ] The overflow menu (“…”) is a native `<select>` again, like before `2abe99b` (`git show 2abe99b^:Sources/Website/Components/OverflowMenu.swift`), with `site.js` opening the chosen link. Bring back `AppFooterLinks` too, so crawlers find the links. This replaces the popover menu from Phase 17. `meta.md` records this decision.
- [ ] The app icons on the timeline page animate in strangely. Remove the entry animation.
- [ ] Remove the fade between pages (the cross-document view transition of the root). `meta.md` records this decision.
- [ ] Remove the icon transition from the apps page (and related apps and the timeline) to the app page: the `view-transition-name` per app and the `view-transition-class`.
- [ ] Bug: a click on “Another Random App” shows the “Random App” header for a second before the redirect.
- [ ] The price (“Free”, or the price) on an app page goes together with the “Available on macOS” text, not apart from it.
- [ ] The recent reviews on app pages use a style like the press quotes. Titles with long words overflow (see `/googly-eyes`): force them to break (`overflow-wrap: anywhere`).
- [ ] The QR code is an option in the “…” menu, and shows in a popover when chosen, not always on the page.

### Bugs

- [ ] Old CSS, JS, and sprite after a deploy. Cloudflare keeps static files for 8 days (`max-age=691200`), and our file names never change. Astro used hashed names, so this was safe before. Now new HTML can load an old `site.css`, an old script, or an old sprite for up to 8 days. Fix: add a content hash to the URL at publish time, then add a 1-year `immutable` cache rule.
- [ ] Social cards are 7 times larger than before (48 MB for all cards, which is 40% of `dist`). Fix: draw the gradient and the icon shadow once into a shared image, and save the cards as JPEG. The agent built a prototype: the Dato card is 60 KB, rendering takes about 300 ms instead of about 800 ms, and the whole build takes about 0.75 s instead of 1.2 s. It looks the same in crops.
- [ ] Renaming a general FAQ ID stops `serve` (the `precondition` at `FeedbackPage.swift:336`). Report it as a content error instead. The FAQ curation item below removes the check completely.
- [ ] Blog posts do not check `@faq.platforms`. Fix: give posts `headingDirectives: []`.
- [ ] Anchor targets go under the header on screens 1536 px and wider. There the root font size is 20px, so the header is about 90px tall, but `scroll-padding-top` is a fixed `80px` (`SiteLayout.swift:181`). The same fact is also written as `100` in `app.js` and `69px` in `SiteHeader`. Fix: one `SiteHeader.height` value in rem. Measure it in a browser first.
- [ ] The scrollbar on code blocks is light in light mode. Fix: add `color-scheme: dark` to `pre`.

### Less global CSS, more local components

- [ ] A test that every class in the HTML has a rule, and every content rule has a user. This is item 6 of the Phase 5b proposal, and it was never done. It would find these now:
	- 39 dead `text-xs` classes
	- the unused `.not-prose` in the `@scope`
	- probably the `twitterwidget` rule
- [ ] `ProsePage` owns the style of its title. `PrivacyPolicyPage` and `ReleaseNotesPage` style its `h1` with the same values.
- [ ] Sponsors as frontmatter data with a `SponsorList` component, and `<picture>` for the dark logos. This removes 9 inline `style=` hacks, 4 content rules, and one guard allowlist entry. Also delete the 33 unused logo files.
- [ ] A static quote instead of the embedded tweet on the supporters page. This removes the `widgets.js` script.
- [ ] The about page JSON-LD comes from `Schema.Person`. Today it is written by hand, and its facts are different from the Swift copy.
- [ ] The icon tilt sets CSS variables, not `style.transform` and `style.filter`. It is the last script that writes inline styles.
- [ ] Needs your go: convert the 275 `list-subtitle` and `list-description` spans to the `:` and `::` syntax. Then delete the fixed class names and the nested selectors.

### Modern CSS

- [ ] Finish the `light-dark()` work. The pages still have 874 `prefers-color-scheme` blocks, mostly hover colors in `.dark { $0.hover {…} }`.
- [ ] Show a play icon on paused demo videos with `:has(> video:paused)`. Today a visitor with reduced motion sees a video that looks like a screenshot. Supported in Safari 15.4, Firefox 150, and Chrome 152.
- [ ] Speculation rules: `prerender` with `moderate` eagerness, but not for `/apps/random` or `/feedback`. GoatCounter does not count prerendered pages that nobody opens.
- [ ] `loading="lazy"` on videos. It works in Chrome 148, and the other browsers ignore it.
- [ ] `@view-transition { navigation: none }` on the random app page, so the `pageswap` handler can go. (If the feedback items above remove all view transitions, delete the handler instead.)
- [ ] A simpler unicorn animation: two keyframe sets with two steps each, instead of 13 steps (about 1.3 KB).
- [ ] CSS output cleanups:
	- one range syntax for media queries (`width >= x`)
	- remove the dead `font-size` before the `clamp()` value
	- merge sibling `@media` blocks that have the same condition
	- `rgb(0 0 0 / 10%)` instead of `color-mix` for black and white
	- `clip-path: inset(50%)` instead of the deprecated `clip`
- [ ] `:open` instead of `[open]`. Safari supports it since 26.5, so the plan note is out of date.
- Not ready yet: typed `attr()`, `grid-lanes`, `random()`, `if()`, `@function`, `reading-flow`.

### Performance

- [ ] Run `git log` once, not once per content type (3 processes today).
- [ ] Try in CI: `--disable-index-store` (17% faster, from one local sample).

### More SwiftUI-like and Swifty

- [ ] Typed `StyleVariable<Value>` and `RegisteredProperty<Value>`, like `EnvironmentKey.Value`. Then typed modifiers can take variables, and about 21 `CSSValue(...)` wraps, 6 raw `--` declarations, and `Length.variable(String)` go away.
- [ ] `LinkDestination` everywhere (`Link`, `Button`, `LinkRow`, `IconLink`, `App.url`, `BlogPost.url`), with `.href(_: LinkDestination)`. This fixes the `RoutePath` that holds `?product=…`. Build query URLs with `appending(queryItems:)`.
- [ ] Turn on the Swift 7 upcoming features: `ExistentialAny`, `MemberImportVisibility`, `NonisolatedNonsendingByDefault`, `InferIsolatedConformances`, and maybe `InternalImportsByDefault`.
- [ ] Elementary elements instead of HTML strings. This applies to the platform badge, `JSONScript`, the QR code, and the star SVG, plus a typed `.popoverTarget` and `JSONScript(hook:)`.
- [ ] Swift Testing: `@Test(arguments:)` for each route, so each page is its own test case, with the HTML or PNG attached when a test fails.
- [ ] A `.temporaryDirectory` test trait (`TestScoping`) that deletes the folder. Today 10 call sites leave folders behind.
- [ ] Make the `Length` type a value and a unit (plus an expression case), so arithmetic does not parse strings with a regex.
- [ ] Small cleanups:
	- `"\(x, default: "")"` (SE-0477)
	- `@HTMLBuilder` becomes `@ContentBuilder`
	- `Site.routePath(ofContentFile:)` becomes `RoutePath(contentFile:)`
- [ ] Maybe: `static var preview` in each component file, and the gallery only lists them.

### Simplify and DRY up

- [ ] `Stylesheet` records its own style sets, so `sharedStyleSets` is no longer a list kept in sync by hand.
- [ ] `@Details` and `@Tips` use the markup builders of the renderer, instead of copying the HTML of collapsible sections and alerts.
- [ ] One parser and one walk for heading directives, instead of three parsers and three walks (about 30 lines).
- [ ] Image sizes with `CGImageSource` instead of the hand-written PNG and JPEG readers (about 55 lines). Keep the MP4 reader.
- [ ] `App`, `BlogPost`, and `MarkdownPage` stop copying `lastCommitDate`, `slug`, and `url`.
- [ ] One local function for the three repeated `do`/`catch` blocks in `SiteContent.load`.
- [ ] Use the typed paths that already exist (about 8 string paths left), plus `Site.sourceURL` in `humans.txt` and `site.js`.
- [ ] Make `Button.Fill` and `Button.Size` `CaseIterable`, so the gallery shows new variants by itself.
- [ ] Small cleanups:
	- remove the dead `FoundationNetworking` import
	- merge the two copy handlers in `site.js`

### Architecture

- [ ] FAQ curation in the content, with `@faq.general` and `@faq.pinned` directives instead of `generalFAQSlugs` and `pinnedURLs` in Swift. This also fixes the crash bug.
- [ ] `Site.build(project:output:)` in `Website`. Today the CLI runs load, routes, publish, and validate itself. With this change, a test can run the whole pipeline offline, and about 220 `public` modifiers can go.
- [ ] One `ExternalData` value (`fetch` and `.none`). Then `SiteContent.load` has fewer parameters, and the tests use the real loader. The 4 `print("Warning…")` calls become values that the CLI prints.
- [ ] The derived app data as one `let`, set in `init`, instead of 6 `internal(set) var`s and `computeDerivedData()`.
- [ ] Each content type owns its path rule, so `[Dato](dato.md)` links cannot drift from the real paths.
- [ ] Build the “Categories” menu from `AppCategory` and delete `apps-extra.json`. This reverses an earlier step (Phase 15 decoded it strictly).

### Creative

- [ ] An automatic `/now` page, from data the build already has: the latest app, the latest releases, the latest blog post, and the new GitHub repositories.

## Phase 19: Research results, round 4 (agreed 2026-10-05, not started)

From ten research agents (local CSS, modern CSS, performance with measurements, Swift design, simplify and architecture, creative, a visual review with screenshots, the pages folder, and code that could move to SiteKit or `Utilities.swift`). Suggested first: the bugs, then delete `ContentStyles.swift`, then the release notes and app page spacing.

### Notes for Phase 18 items (no new items)

- “Another Random App” header flash. It has two causes:
	- The page always renders the “Random App” `h1`. Only the “JavaScript is required” note is hidden (`RandomAppPage.swift:21-23`).
	- The redirect script is a module script, so it runs only after the page is drawn.

	Fix both: give the whole page the “no JavaScript only” style, and put a small classic script in `<head>`.
- The price next to “Available on…”. Move the availability line into `AppHero` and pass `AppStoreInfo` to it. Then the −6rem and +8rem margin chain goes away, which today leaves about 128 px of empty space above the screenshots.
- Reviews like the press quotes. Make one `StarRating` component with a sprite star for both. This also fixes the ARIA bug below and the `#ff9500` that is written twice.
- Header height. When it is one rem value, `contact.js` can also stop measuring the header (6 lines).

### Bugs

- [ ] Release notes: about 170 px of empty space above each version. The `h2` keeps the prose margins inside a flex row (`ReleaseNotesPage.swift:78`).
- [ ] App pages without media (Blear, Services Debug) have about 208 px of empty space and an empty “App media” landmark. Render `AppMedia` only when the app has media.
- [ ] The share button is 16 × 60 px, so it is a thin focus ring and a very small tap target (`DownloadOptions.swift:97-102`). Make it a square button of at least 2.75rem.
- [ ] The carousel letterboxes 16:9 videos next to 16:10 screenshots, and the next screenshot sticks out above and below the video (`/googly-eyes`).
- [ ] Small gray text has less than 4.5:1 contrast in dark mode: “Available on macOS” (4.17:1) and the stats on the apps page (4.23:1).
- [ ] Screen readers can skip the label of the press quote stars. The `aria-label` is on a `div` with no role (`PressQuotes.swift:17`).
- [ ] VoiceOver reads the app name twice in `FeedsPage` and `RelatedApps`, because the icon is not marked as decorative.
- [ ] Problems in `feedbackNote` are lost: only the first problem is thrown, without a line (`App.swift:99-101`).
- [ ] Release notes stop at 100 per repo, with no warning (`per_page=100`, no next page). `supercharge-meta` has 53 today.
- [ ] `AGENTS.md` describes code that is gone: the `SYNONYMS` map and `pinnedUrls` in JS, and the 4-letter minimum.
- [ ] 4 error tests use `#expect(throws: (any Error).self)`, so they pass for any error, also a YAML typo in the test string.
- [ ] The preview server tests pick a random port and fail if it is in use. Support port 0 (the system picks a free port), which also makes `serve --port 0` work.

### Less global CSS, more local components

- [ ] Delete `ContentStyles.swift` and the `content` CSS layer. The rules move as follows:
	- `.page-photo` becomes a `photo` frontmatter key that `ProsePage` renders.
	- `.title-emoji` becomes a plain space in the title.
	- The sponsor rules go into the `SponsorList` item, and the tweet rule goes with the tweet item. Both items are in Phase 18.
	- The table rule for keys moves to `ProseStyles+Tables.swift`.
- [ ] `Prose` wraps only text. `ProsePage` renders `BackLink` and the title outside `Prose`, so `BackLink` gets its own look, and `ProseStyles.excluded` and the lower bound of the `@scope` go away.
- [ ] `Section` styles its own `h2`, and a small `LinkList` styles its own list. Then `AppsPage` stops borrowing prose styles, and the gallery stops styling into `section > h2`.
- [ ] Components have no outer margins, and the parent sets the spacing (10 root styles today, including a `-2rem` hack in `AnnouncementBanner`). Check with screenshots.
- [ ] The announcement text as plain text, not Markdown. None of the 3 announcements uses Markdown, so 7 nested rules go away.
- [ ] Split `FeedbackPage` (810 lines):
	- Move the search model (`FeedbackData`, `SuggestedQuestion`, stopwords, synonyms) to `Content/`, about 200 lines.
	- Make `FAQSuggestions`, `AttachmentPicker`, and `FeedbackSuccess` components, each with its own `Styles`.
- [ ] Scripts stop finding elements by markup structure: `article h2[id]`, `body > footer`, `:scope > span > span`, and `querySelector('span')`.
- [ ] A complete gallery. Add the 7 missing components, plus Markdown samples for collapsible sections, `@Details`, `@Tips`, badges, and list subtitles. Add long words that cannot break, which would have shown the review title overflow.
- [ ] `.trimmingChildMargins()` and `.flowSpacing(_:)` modifiers for the repeated first and last child margin rules and the `* + *` rules.
- [ ] About 29 literal colors outside the palette, for example `"#6b7280"` and the 5 hex colors of `kbd`.

### Modern CSS

- [ ] Remove `transform: translateZ(0)` from every heading anchor (89 GPU layers on `dato.html`), and the permanent `will-change` on the hero icon, which is the LCP image.
- [ ] Remove `!important` where layers already decide (feedback font size, nebula). Rewrite the 12 `!important` rules on `kbd` in the prose layer: `!important` reverses the layer order, so these rules beat every component.
- [ ] `Transition` with SwiftUI effect names (`.scaleEffect`, `.offset`, `.rotationEffect`), so a transition lists only the property that changes. Today all 13 uses write four properties.
- [ ] Header glass from one value: `.pageBackground.opacity(0.9)` replaces the dark block and one fallback.
- [ ] More output cleanups:
	- three duplicate `text-wrap: pretty`
	- `border-inline-start`
	- `quotes: auto`
	- `font-variant-numeric: oldstyle-nums` instead of `font-feature-settings`
- [ ] The brand colors as Tailwind v4 OKLCH values, which use the P3 color range, and the 9 hand-written `rgb(…)` palette colors on the home page as palette values. (Agreed.)
- [ ] The root font size jumps to 20px at 1536px. Make it fluid, or remove the jump. (Agreed. Compare both with screenshots, then choose.)

### Visual and UX

- [ ] Two columns on the apps page from `md`, not `lg`. At 768 px the page is taller than on phones.
- [ ] The mobile menu shows an “×” while it is open (CSS only), and its links line up with the header text.
- [ ] FAQ questions line up with the page text on phones (x=16 today, x=24 for the text around them).
- [ ] Less hyphenation in blog posts: only below `sm`, or remove it.
- [ ] A non-breaking hyphen in “Open‑Sourcerer” on the home page, so it does not break at the hyphen on phones.

### Performance

- [ ] Cache the class names and the rules of each style set. Prototyped: rendering 30% faster, byte-identical output.
- [ ] One shared `CIContext` for QR codes. Together with the item above, HTML rendering takes 39% less time.
- [ ] Watch mode: reload before the link check, and long-poll the version. Edit to reload goes from about 1.4 s to about 0.85 s.
- [ ] Load the first 4 icons on `/apps` and the category pages eagerly (`isAboveFold` already exists).
- [ ] CI runs `.build/debug/website` directly and uses `swift test --disable-xctest` (2 to 8 s each run).
- [ ] The link validator resolves links against the file set it already has, not with disk checks (about 45 ms).
- [ ] Scripts: no forced layout on each `mousemove` in `contact.js`, and no icon measure on each scroll in `app.js`.
- [ ] `width` and `height` on the download badges.
- [ ] Watch mode builds the same targets as `swift build`. Switching between them costs 4 to 5 s.

### More SwiftUI-like and Swifty

- [ ] `Button` becomes `Link(…).buttonStyle(.primary, size: .large)`. The generic `Button<Content>` goes away.
- [ ] One accessibility API: only `.accessibilityLabel` and `.accessibilityHidden` (21 uses of `.ariaLabel` and `.ariaHidden` today).
- [ ] `IconLink(label, icon:, destination:)` with a typed body, plus `.help(_:)` for `title`. Two stored properties go away.
- [ ] `AppIcon(decorative: app, size:)`, like `Image(decorative:)`, instead of `isNamedNearby`.
- [ ] The layout adds “ — Sindre Sorhus” to the title, so `PageMetadata.titled` goes away, and no page can forget it.
- [ ] An `Animation` value like SwiftUI (`.easeInOut(duration:).repeatForever(autoreverses:)`, `.timingCurve`, `.spring(duration:bounce:)`). This affects 44 calls.
- [ ] `@RouteBuilder` accepts anything that has a route, so the 5 hand-written `.route` uses and the `+` with a ternary go away.
- [ ] Small cleanups:
	- remove 12 unneeded `: Sendable`
	- `.hidden()` instead of `.display(.none)`
	- `[String] = []` instead of an optional array
	- `inlineHTML` as a property
	- `AppStoreInfo.id`
	- `Person.photoPath` as a `RoutePath`
- [ ] Maybe: frontmatter property wrappers (`@NonEmpty var title: String`) instead of about 25 `.value` unwraps.

### Simplify and DRY up

- [ ] One owner for the FAQ section: `App.faqSectionID`. The title is compared 5 times and the `"faq"` ID is written 4 times today, also in JS.
- [ ] Typed heading directives, checked by the renderer. `checkPlatformDirectives` goes away, and every problem gets a line. This also closes the blog post gap in Phase 18 without a special case.
- [ ] Body checks throw `ContentError(line:)`. `Heading` records its source line.
- [ ] Repeated regexes: the custom ID pattern 3 times, and the alert kinds 2 times.
- [ ] Footnote IDs on `Footnote`.
- [ ] Link reporting: the CLI stops cutting `description` apart, there is no second inverse of `outputFile`, and the output folder is walked once.
- [ ] One `Schema.SoftwareApplication(app:info:)`. Today `AppPage` and `AppsPage` each build it.
- [ ] Facts written twice: `og:image` 1200 × 630, `theme-color`, and the 3 switches in `SemanticColor`.
- [ ] One type per file: `ExternalData.swift` (6 types), `Person` in `Site.swift`, and the misplaced tests.
- [ ] Pages:
	- `lastModified` and `showsAppStoreBanner` on the model
	- `AppCategory.footer` and `isGroupedByPlatform`, so the `switch` goes (63 to about 35 lines)
	- `ProsePage(title:)` on the 4 pages that write their own `h1`
	- `PageHeader(title:intro:)` for the timeline and the gallery
	- `.contentColumn(.wide)` for the 48rem and 64rem widths
	- one copy of the “no JavaScript only” style
	- a `.visuallyHidden()` modifier
- [ ] Small cleanups: a separated doc comment, an indentation mistake, a raw `Media(…)`, and a shadowed `theme`.
- [ ] Release notes titles get the site name too (40+ titles change). (Agreed.)

### Code that moves

- [ ] To `Website/Utilities.swift`:
	- the generic `Schema` types and `JSONScript.init(schema:)`
	- `JSONDecoder.json5` and `CGColor.hex`
- [ ] Elsewhere in Website:
	- `Schema.Person.author`, `authorName`, and `authorProfile` go next to `Site`.
	- `App.schemaCategory` and `operatingSystems` go on `App`.
- [ ] To SiteKit. Only code that SiteKit uses or that is about building the site moves there, because a move makes everything `public` and needs hand-written `public init`s:
	- `ResponseCache`, with `String.stableHash` and `Duration.timeInterval`
	- `URL.mediaSize`, together with the `CGImageSource` item
	- the duplicate class name check, into `PageResources`
	- `RoutePath.current`
- [ ] A doc comment on `MarkdownTheme` that names the `data-copy-code` and footnote script hooks.
- Not worth moving: `Link`, `Section`, `Icon`, `PageMetadata`, `TextFiles`, and the theme tokens. SiteKit has no site knowledge.

### Architecture

- [ ] A page declares its social card (`Page.socialCard`), so the card route and `og:image` come from one place.
- [ ] The Markdown theme maps elements to a `Style` directly. Today a new Markdown element touches 7 places, and this removes about 120 lines of mirrored switches. Needs a prototype.
- [ ] Typed cascade layers. `Stylesheet` writes the `@layer` order from its blocks. A typo in a layer name today makes a layer that silently wins over all others.
- [ ] One `ContentDocument` protocol and `content.documents` for apps, posts, and pages. Then posts get `redirectFrom` too.
- [ ] The weekly link workflow reuses the CI build, instead of compiling from nothing without a cache.

### Creative

- [ ] Older versions as frontmatter data, with direct downloads by macOS version. Today 52 files write 190 zip links by hand.
- [ ] `website check`: content warnings, like icon weight, mixed screenshot sizes, an OS requirement that does not agree, expired announcements, and unused public files.

## Phase 20: Research results, round 5 (agreed 2026-10-05, not started)

From seven research agents (local CSS with every rule tested against every page, modern CSS and HTML, performance with measurements, Swift design, simplify and architecture, creative, and audits with axe, Lighthouse, html-validate, a JSON-LD check, a feed check, and keyboard tabbing). Suggested first: the accessibility bugs (FAQ headings, contrast, landmarks), the iPhone video bug, the rating in the JSON-LD, then the dead features.

### Owner direction (applies to all phases)

- Reduce global state and scripts. Move them into components and pages whenever possible, and find ways to do more in Swift at build time or in CSS.
- More readable, Swifty names everywhere, for example instead of `.sm` for breakpoints.

### Notes for Phase 18 and 19 items (no new items)

- The play icon on paused videos (Phase 18): on iPhones the video is a blank box today, because iOS draws no first frame with `preload="metadata"`. Add `#t=0.001` to the `src`, or make a `poster` at build time with `AVAssetImageGenerator`.
- Reviews like the press quotes (Phase 19): put the press quote source outside the `blockquote`, as the spec requires. Use the `figure`, `blockquote`, and `figcaption` structure of `AppReviews`, and add `cite`.
- Small gray text contrast (Phase 19): axe finds more failures:
	- the footer “Built with Swift” link (all pages)
	- the tip and important alert titles (1.86 and 2.59)
	- the press quote source
	- the release notes date in dark mode (2.66)
	- the blog post meta
	- the contact page notes
	- the primary glass button
	- `list-description`
- `website check` (Phase 19): add these checks:
	- the OS requirement against `minimumOsVersion`. The agent found 7 apps where the text disagrees, for example `second-clock.md` says macOS 15 but the App Store needs 26.0.
	- apps missing from the lookup, `isPaid` against `price`, and `platforms` against `supportedDevices`
	- notes about OS versions older than the App Store minimum
	- spelling with `NSSpellChecker`, with an allowlist. A prototype found “shorcut” and “the this” in `aiko.md`, and “gadzillion” in `today.md`.
	- skipped heading levels, and vague link texts (“here”, 57 links)
	- remote images without a size, and 16-bit PNGs
- `LinkDestination` everywhere (Phase 18): also one `Route.redirect(_:to: LinkDestination)`, `ModuleScript(RoutePath)`, `Project.publicFile(RoutePath)`, and `App.iconPath` and `MediaAsset.path` as `RoutePath`. Absolute URLs come only from `absoluteURL`, which today is built in 3 ways.
- `JSONDecoder.json5` (Phase 19): it does not move to `Utilities.swift` if the typed directive arguments item below is done, because that item puts the decoding in SiteKit.

### Bugs

- [ ] FAQ questions are not headings. `/apps/faq` has only one heading for 58 questions, and the site has 920 sections like this. The “Copy link” `<a>` is also inside `<summary>`, which is invalid. Fix: `<summary><h3>…</h3></summary>`, with the anchor outside `summary` (`HTMLRenderer.swift:127-135`).
- [ ] 19 app pages send `aggregateRating` in the JSON-LD, but the page shows no rating, which Google does not allow. Show the rating in `AppHero`, like “4.6 ★ · 563 ratings”. (Agreed.)
- [ ] The 404 page has `index, follow`. Set `isIndexed: false`. Then the `isInSitemap` requirement of `Page` goes away (see the sitemap item).
- [ ] Two unnamed `aside` landmarks on app pages. The press quotes become a `section`, and the related apps get `aria-labelledby`.
- [ ] App pages have five `nav` landmarks. The download badges are not navigation, so use a `div`.
- [ ] The attachment input has its name read twice (`aria-describedby` points to its own label).
- [ ] Scrolling tables cannot be reached with the keyboard on phones. Use a wrapper with `tabindex="0"` and a label.
- [ ] A focused heading anchor on phones is at x=−4, where it is cut off and covers the first letter.
- [ ] The feedback icon is an `<img>` with no `src`, so it leaves an empty 128 px box without a product. Render it `hidden`, and let the script show it.
- [ ] A social card error repeats its message (“Could not render /og/dato.png: Could not render the social card /og/dato.png: …”), and the font error uses a fake path.
- [ ] A failed tool restart in `serve` prints the usage text, because it throws `ValidationError`.
- [ ] `git log` blocks a cooperative thread (about 44 ms, 3 times per build). Do this with the Phase 18 “run `git log` once” item.

### Less global CSS, more local components

- [ ] Needs your decision: delete the blog pagination. There are 6 posts and 10 per page, so it never renders (about 45 lines). Document that one page lists all posts.
- [ ] Typed script states: `data-state`, `data-rainbow`, and `data-leaving` are strings in the styles and are not in `ScriptHook`. Add them, with a `Style.when(_ hook:)` modifier. (Agreed. Also reduce global state and scripts, see the owner direction above.)
- [ ] Typed state modifiers:
	- Use `.focusWithin` and `.disabled`, which exist but are written as strings.
	- Add `.firstChild`, `.lastChild`, `.userInvalid`, and `.popoverOpen` (about 12 string selectors).
- [ ] Two style cases that copy each other: `BlogPostPage.titleWithDescription`, and the two attachment cases in `FeedbackPage`.
- [ ] The `table` base rule moves to `ProseStyles+Tables.swift`.

### Modern CSS and HTML

- [ ] `<meta name="color-scheme" content="light dark">`, so dark mode visitors do not see a white flash before `site.css` loads.
- [ ] Remove head tags that do nothing on all 254 pages:
	- `twitter:title`, `twitter:description`, and `twitter:image`, because X falls back to the Open Graph tags
	- `robots` with `index, follow`
	- `<link rel="sitemap">`
- [ ] `<p>` elements instead of `<br>` for spacing (6 places).
- [ ] `dir="auto"` on the feedback message.
- [ ] `Intl.NumberFormat` for file sizes in `feedback.js`.
- [ ] Needs your decision: `autofocus` on the feedback message. Today focus and screen readers skip the notices above it, and on phones the keyboard can cover the intro. Options: only with `?product=`, or never.

### Performance

- [ ] Two 16-bit PNG icons (`short-run` 825 KB, `folder-peek` 773 KB) become 8-bit (about 210 KB each). On `/apps`, `short-run` sets the page load time.
- [ ] Try `fetchpriority="low"` on the carousel screenshots. Today they compete with the LCP icon on phones. Check on a real phone, because DevTools throttling cannot show the effect.
- [ ] Needs your decision: `--build-system native` only for the watch-mode rebuild. A rebuild with no change takes 0.8 s instead of 3 to 4 s, and one changed file takes 2 s instead of 4.5 s. It is deprecated, and Phase 15 closed this without a measurement.

### More SwiftUI-like and Swifty

- [ ] One optional `SitemapEntry` instead of `isInSitemap`, `lastModified`, and `images` on `Route` and `Page`. File routes then cannot have a `lastModified`. Two agents found this.
- [ ] Typed filters (`.backdropFilter(.blur(radius:), .saturation(1.8))`, `.filter(.none)`), 9 places.
- [ ] Typed values for the last string modifiers: `ViewTimeline`, `.timeline: .scroll`, `.supports(.anchorPositioning)` (5 distinct strings), and `.transition(.discrete(.contentVisibility))`.
- [ ] One breakpoint name pair, `.from(_:)` and `.below(_:)`, also in `MediaQuery`. This renames about 103 call sites. (Agreed. Also use more readable names than `.sm` for the breakpoints, and make naming more Swifty everywhere.)
- [ ] `MarkdownDocument(parsing: file)` throws and maps the lines, so no content type can forget `file.validate`.
- [ ] Typed arguments for directives and inline attributes, decoded strictly like frontmatter (`@Frontmatter struct PlatformAttribute`). About 25 lines of guards go away.
- [ ] One `ValidatedValue` protocol for `AbsoluteURL`, `NonEmptyString`, `SafeInteger`, and `RoutePath` decoding.
- [ ] Simpler task groups (6 places). Maybe use the `concurrentMap`, `concurrentCompactMap`, and `concurrentForEach` sequence extensions from SSKit (`/Users/sindresorhus/dev/apps/SSKit/SSKit/SSKit.swift`, around line 88700) in `Utilities.swift` instead. Copy only the ones the code uses. Otherwise, `withTaskGroup { }` without `of:` (SE-0442).
- [ ] `.underline(false)` and `.textWrap(.nowrap)` instead of `noUnderline()` and `noWrap()`. Add a doc comment that `.hidden()` is `display: none`, unlike SwiftUI.
- [ ] Tests: `@Test(arguments:)` for the 3 outputs, `#require` instead of `URL(string:)!`, and one shared `get` helper.
- [ ] `AppStoreInfo.price` as `Decimal`, formatted with `.currency`.

### Simplify and DRY up

- [ ] Update the stale doc comments in `Style.swift`, `StyleSet.swift`, `Frontmatter.swift`, `Route.swift`, and `Publisher.swift`. They show colors and APIs that no longer exist.
- [ ] `DownloadOption` gets a `badge` property, so `DownloadOptions` renders one branch.
- [ ] SiteKit cleanups:
	- a `Set` instead of `[ObjectIdentifier: Int]` in `PageResources`
	- `StyleVariable` uses `CSSValue.variable`
- [ ] Rename the private `Label` struct in `ExternalData.swift`, because it has the same name as the component.
- [ ] `Label` writes its defaults once.
- [ ] `BlogPost.isListed`, like `App`.
- [ ] `BrokenLink.page` as a `RoutePath`.
- [ ] `MediaAsset` stores its kind instead of guessing from the file extension.

### Architecture

- [ ] A `FeedLink` type in `Content/`, so `App.ReleaseNotes` does not depend on `PageMetadata.Feed`. Today the code has three types named “Feed”.
- [ ] Move `MarkdownOptions.swift` next to `Prose.swift`. It is presentation, and it is the only place where Content depends on components.
- [ ] One error rule: content mistakes become `ContentError` with a file and line, and only build failures keep their own type. Today there are 9 error types, and 4 of them only wrap a string.
- [ ] Watch mode as a loop over two kinds of events, with a small `ToolRestarter`. Do this after `Site.build` in Phase 18.

### Creative

- [ ] Needs your decision: general FAQ questions from facts. Menu bar apps get the menu bar question, free apps get the free question, and all apps get the localization question. A file that writes the question itself keeps its own text. This removes about 60 hand-written copies, and 3 menu bar apps are missing the question today.
- [ ] Errors in the browser during `serve`: the version endpoint returns the last error, and the reload script shows it.
- [ ] `--include-fragments` in the weekly lychee run (40 external links with fragments). Check GitHub's `user-content-` prefix first.
- [ ] Blog posts get `BlogPosting` structured data.
- [ ] Free direct downloads get an `Offer` with price 0, and app pages get `review` from the shown App Store reviews. Then more pages qualify for rich results.
- [ ] Feeds get `language` and `lastBuildDate` (from the newest item, so builds stay reproducible).
- [ ] Make the RSS library high quality and ready to publish as a package, with many useful tests. Also, the error that names an item by its index should name it by title, like the other errors. Do not publish it yet.

## Phase 6: Final validation

- [x] `swift test`, release build, full generation with link validation, JS syntax check, and parity gates (routes, feeds, sitemap, semantic HTML, text, OG) against the Astro build.
- [x] Update `MIGRATION.md`.
- [x] Draft PR text (do not push or open without asking). (In the scratchpad as `pull-request.md`. Nothing is pushed or opened.)

## Open decisions

- Code blocks: Astro highlighted 72 code blocks with Shiki (mostly `sh`, `js`). The Swift site renders them plain. Options: accept, or a small highlighter for the few languages used.
- ~~`serve` uses Python's server~~: replaced by `PreviewServer` (Network framework), like GitHub Pages.

## Log

- 2026-10-04: Took over at `c766a91`. Restored local oracle. Gates: route ✅ (241), OG ✅ (65), semantic 3 diffs, XML 4 diffs, text 75 routes (mostly block whitespace).
- 2026-10-04: Ported the whole site to the new architecture. Quick check against Astro: semantic HTML ✅ (166 routes), route ✅, text diffs only in release-note dates (timezone of the local Astro build), XML diffs only in release-feed channel links (fixed).
- 2026-10-04: Visual port done. Removed Astro/Tailwind/npm. Deploy and CI build with Swift on macOS. Next: architecture refinement passes.
- 2026-10-05: Architecture phase done: StyleSets everywhere (verified with a computed-style comparison of every element), smaller SiteKit, one owner per fact, Swift preview server, palette pass.


--


when done with everything. do 10 deep bug fix and review passes. fix issues, etc.

Done, 2026-10-05. Ten passes, each with review agents and fixes, in the commits after “Tick the refinement passes”:

1. Code: duplication, SiteKit control flow, and the browser scripts. Escaping with combining marks, alert and footnote links, redirect escaping, `..` in paths, script bugs.
2. Accessibility: focus on section links, the mobile menu, the feedback headings and form, reduced motion, landmarks and labels.
3. CSS: transitions that did not add up, reduced transparency, closing animations, forced colors.
4. Markdown edge cases: undefined and unused footnotes are reported.
5. Publishing and the preview server: case-only renames, atomic writes, link case, watching during the first build, stale cache on errors.
6. Content validation: redirect posts and apps, impossible days, feedback note links, FAQ IDs and platforms.
7. Visual regressions: screenshots before and after, light and dark, wide and narrow. No unintended changes.
8. Size and speed: the FAQ search data no longer repeats words. A full build takes about a second.
9. Tests: new tests for the fixed bugs, and expectations that could not fail now can.
10. Final review of the branch: no core bugs. Release notes keep their images, and footnotes render once.
