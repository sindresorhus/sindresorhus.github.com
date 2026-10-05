# Codebase Notes

## Commits

Never commit the owner’s uncommitted changes, especially in `content/`. They are often about app features that are not released yet, like new actions in `content/apps/actions/index.md`. Before you commit, list the uncommitted changes that you did not make: run `git diff` and check `git stash list`, as the owner may have stashed them. When you and the owner changed the same file, stage only your hunks (for example with `git apply --cached` and a patch of your hunks), and check with `git diff` that only the owner’s changes stay uncommitted. Do not run git commands that change the index or the working tree while another agent stages a commit.

## Browsers

The site targets only modern browsers (the latest Safari, Chrome, and Firefox). Use the latest CSS, HTML, and JavaScript features and syntax freely, like relative colors (`oklch(from …)`) and `sibling-index()`, without fallbacks for older browsers.

## Modern APIs before speed

Prefer modern syntax and APIs to the fastest ones. For example, use Swift `Regex` and regex literals, not `NSRegularExpression`, even where `NSRegularExpression` is faster. The build is fast enough, so do not trade readable, modern code for performance unless something is too slow to use.

## Image formats

Do not use AVIF. The owner waits for JPEG XL instead. Keep PNG and JPEG until then.

## Motion

Keep motion to a minimum in the content. Small transitions that help to understand a change, like a hover color or a menu that fades in, are fine. Do not add scroll animations, elements that move into view, parallax, or animations of the content itself, like text or cards that move by themselves.

Subtle background animations are fine, like the nebula of the home page, the drifting blobs of the contact page, or a slow glassy background behind a page header. They must be calm and slow, stay behind the content, show a still frame when the visitor prefers reduced motion, and pause when they are off screen or the tab is hidden. The home page also keeps the animated gradient of the name and the rotating ring in dark mode, as it is the playful page of the site.

## Styles

A style that only one element has goes on the element itself, like a modifier in SwiftUI: `.style { $0.padding(.rootEm(1)) }`, or `.vstack(spacing:)` and `.hstack(…)` for a stack (`ElementStyle`). Its class is the name of the file and a hash, and the page collects its rule in the `elements` layer, after the components, so it wins over the styles of its component. Use a case in the `Styles` (a `StyleSet`) of the component for a look that more than one element has, for variants, and for a style that another selector refers to, like a parent that changes a child while it is hovered, as nothing can refer to a hashed class. A parent sets the space around a child component where it uses it, like `PressQuotes(…).style { $0.margin(.top, .rootEm(7)) }`, not with `.children(X.Styles.root.selector)`, so the child declares the tag of its root, like `var body: some HTML<HTMLTag.section>`. Never use inline styles or `<style>` in content. Before adding a style, reuse a component or a style that already exists, like `VisuallyHidden` for text that is only in the HTML, or a modifier like `.buttonStyle(.gradient)`.

When you simplify or remove duplicate code, do not remove style modifiers and other generally useful modifiers and utilities (in SiteKit or `Theme.swift`), even if nothing uses them now. They may be needed later. Only remove code that is specific to a feature that was removed.

Use full words in names, also for CSS units and keywords, like `.pixels(1)`, not `.px(1)`. Put the CSS keyword in the doc comment, like “(`px` in CSS)”.

## Block directives

Content files can use the block directives in `Sources/Website/Components/MarkdownOptions.swift`, like `@Feature(title: "…") { … }` and `@Tips { … }`. Prefer one of them to raw HTML in content, and use Markdown links, not raw `<a>` tags, as a link inside one would be a nested link. Each has a sample in the gallery (`GalleryPage`), and the styles of each are a style set. Markdown renders before the pages, so a document collects the styles that its directives use, and the page adds them when it shows the document. So show a document with `document.content` (or `Prose(markdown:)`), not with `HTMLRaw(document.html)`, which leaves its styles out. A test checks that every class on a page has a rule.

- `@Cards { - … }`: a list as cards that flow through two columns from tablets. The text of each item is the title of its card, and a nested list is smaller text below it. Like the lists of the about page.
- `@Steps { 1. … }`: a numbered list with large numbers in the accent of the page. A nested list is smaller text below its item.
- `@SocialLinks`: the social links of `Site.author` as chips with icons. The footer has the same links, as plain links. It has no content.
- `@Details(summary: "…") { … }`: a collapsible section with the look of the FAQ questions, for long details that most readers skip, like the steps for an older macOS version.
- `@QuickAnswer { … }`: the short answer at the top of a how-to post, in a box with a “Quick Answer” label, for readers who only want the answer.
- `@Tips { - … }`: a box of tips, with the look of a tip alert.

Inline, a platform badge marks a part that only works on some platforms: `^[macOS only](platform: "macOS")`.

A fenced code block in content renders as a `CodeBlock` (`Sources/Website/Components/CodeBlock.swift`), with its language and a copy button. The build highlights Swift code with the parser of Swift (`swiftCodeParts` in SiteKit), each line of a `console` block gets a `$ ` prompt, and the code of other languages is plain. Markdown without the options of the site, like release notes, has a plain `pre`.

No content uses `@Details`, `@QuickAnswer`, `@Tips`, or the platform badge yet. They are kept for content that needs them, so use them when they fit, instead of raw HTML or a new directive. Good places: platform badges on app pages where a feature works only on some platforms, like the Actions app (`content/apps/actions/index.md`), `@QuickAnswer` at the top of how-to posts, and `@Details` for long notes in an FAQ answer.

Do not indent the content of a directive that has a nested list. swift-markdown removes as many whitespace characters from each line as the first line has columns of indentation, so a tab-indented first line removes the tab of the nested items too, and the nested list becomes part of the outer list.

## Scripts of components

A component with behavior is a custom element (`ScriptedElement`), like `CopyButton`: Swift renders all its markup in the light DOM, and its script is the class of the element, so the script only works on its own element and finds no elements on the page by an ID or a selector. A small script, like the one of `CopyButton`, is inline in the Swift file (`ElementScript(inline:)`), and the page gets it once. A larger one is the `.js` file next to the Swift file (`ElementScript()`), which also goes in the `exclude` of the Website target in `Package.swift`. List every element in `Site.scriptedElements`, as the tests check the scripts there. An element that needs none of the helpers of the `ScriptedElement` base class extends `HTMLElement`, so the page does not load the base class. An element that only adds behavior to the element inside it, like a button, has `display: contents` as its root style. Another script changes an element through its attributes, like Appdle sets the `text` of its copy button, as an attribute also works before the element is defined.

Behavior of a whole page, like the nebula of the home page or the filter of the apps page, stays a page script in `public/scripts`.

## Script hooks

A page script, or a script that must find elements outside its component, finds them by hooks. A component declares the IDs and data attributes that its script uses as a nested `enum Hooks: String, ScriptHookSet`, next to its `Styles`, and uses them like `.id(Hooks.restart)`. Only data attributes that components in more than one file use as a generic state, like `data-state`, go in the shared `ScriptAttribute` in `ScriptHook.swift`. A hook of one component that another file needs is used from its `Hooks`, like `AppHero.Hooks.hero`. A test checks that every hook is used by a script, and that every hook a script uses is declared.

## Home page

The home page does not show apps, like the newest apps. It stays a calm introduction, and the “Apps” button leads to the apps.

## FAQ Suggestions on /feedback

The feedback page shows relevant FAQ links as the user types their message.

### Data sources

- **General FAQs**: the questions of `content/pages/apps/faq.md` that have `<!-- @faq.general -->`. The directive is only allowed on that page.
- **App-specific FAQs**: the `####` questions in the FAQ section (`## Frequently Asked Questions {#faq}`) of the selected app's markdown file (via the `?product=` URL param), without the questions in `###` subsections and without the added feedback question. See `App.faqHeadings` in `Sources/Website/Content/App+Links.swift`. The section is found by its ID, `App.faqSectionID`. It includes the common questions that the build adds.
- **Common questions**: the build adds the questions that many apps have to the FAQ section of each app from its facts: the menu bar question for menu bar apps (`isMenuBarApp`), the free question for free apps on the App Store that are not archived, and the localization question for all apps. See `CommonQuestion` in `Sources/Website/Components/MarkdownOptions.swift`. Do not write these questions in app files, unless the app needs a different answer: a question with the same text keeps its own answer and gets no added copy.

`FAQSuggestions` (`Sources/Website/Components/FAQSuggestions.swift`) embeds both in the page as JSON (its `questions` part), and its script (`Sources/Website/Components/Scripts/FAQSuggestions.js`) reads it. `public/scripts/feedback.js` sets the `app` attribute of the element to the title of the selected app.

### Heading metadata (`<!-- @namespace.attribute value -->`)

Any markdown heading with a `{#id}` can be annotated with directives on the lines immediately below:

```md
### The app does not show up in the menu bar {#app-not-showing-in-menu-bar}
<!-- @faq.keywords launching launch start open opening -->
<!-- @faq.platforms macOS -->
<!-- @faq.general -->
<!-- @faq.pinned 3 -->
```

- Each directive is a type that conforms to `HeadingDirective` (`Sources/SiteKit/Markdown/HeadingDirective.swift`), with its name and the type of its values. The FAQ directives are in `Sources/Website/Content/FAQDirectives.swift`, and the value is available as `heading[FAQDirectives.Keywords.self]`.
- The values are split on whitespace and decoded strictly as a list, like frontmatter. So an unknown platform is an error with its line. A directive without values is a flag (`HeadingDirectiveFlag`): check it with `heading.contains(FAQDirectives.General.self)`.
- A heading can have several directives, one per line, directly below it.
- The known directives are `FAQDirectives.all`, plus `FAQDirectives.General` on the general FAQ page (`Sources/Website/Components/MarkdownOptions.swift`). An unknown name, invalid values, or a directive that is not directly below a heading, is a content error with its line.
- The `@faq.` namespace is consumed by the feedback page. Add a type to `FAQDirectives` for a new directive.

**`@faq.keywords`**: extra words that make a FAQ matchable by queries that don't use the same words as the heading text.

**`@faq.platforms`**: restricts the FAQ to apps that support at least one of these platforms. FAQs without this annotation are shown for all apps. An unknown platform is a content error.

**`@faq.general`**: suggests a question of the general FAQ for every app. Only on `content/pages/apps/faq.md`.

**`@faq.pinned <rank>`**: suggests the question before all others, when it has enough matching words (like other questions). Lower ranks come first. The ranks are shared by the general FAQ and the app files. A pinned directive without one number is a content error.

### Matching

`SuggestedQuestion` (`Sources/Website/Content/SuggestedQuestion.swift`) prepares the words of each question at build time, so the script of `FAQSuggestions` only splits the message into words and scores the questions.

1. **Words**: lowercase, apostrophes removed, straight and typographic (“doesn't” and “doesn’t” are “doesnt”), words of 3 or more letters, digits, or underscores, and no stopwords (`SuggestedQuestion.stopwords`, also sent to the script). The stopwords include “app”, “apps”, “application”, “mac”, and “macos”: almost every question has them, and with prefix matching “app” would also match “apple” and “appearing”. Use `@faq.platforms` for questions about one platform.
2. **Question words**: the words of the question text (`questionWords`). The words of `@faq.keywords` and the synonyms of all these words are in `extraWords`. Together they are the words a message can match.
3. **Matching**: a message word matches a question word when one starts with the other, like “sync” and “syncing”.
4. **Score**: TF-IDF. Each matching message word adds `log((n+1)/(df+1))`, where `df` is the number of questions whose question words contain it. Rare words score higher.
5. **Minimum**: a question needs 2 matching words when the message has 2 or more known words (words that match any question), else 1. Pinned questions need the same number.
6. **Order**: pinned questions first, by rank. Between an app question and a general question, more matching words come first, then the app question. Otherwise, the higher score comes first.
7. **Deduplication**: general FAQs with 0.6 or more Jaccard similarity to an app-specific result are removed. The first 4 are shown.

The script also shows a request for a crash report when the message contains a word that starts with “crash”.

### Synonyms

**Synonyms** (e.g. `icloud` ↔ `sync`) live in `SuggestedQuestion.synonyms`. A group makes every word match the others, and a one-way synonym only matches in its direction (a question about a “broken” app matches a message about a “bug”, but not the other way around). They expand the words of the questions at build time.

Do **not** use `@faq.keywords` for synonyms: keywords are for *additional match terms specific to one FAQ*. Synonyms express a relationship between two concepts that applies across all FAQs mentioning either term.

### When a FAQ doesn't show as "related help" for a user's message

When asked to improve FAQ matching (e.g., "add to related help", "this FAQ didn't show up", "add keywords"), the fix is usually adding `@faq.keywords` to the relevant FAQ heading in the app's markdown file. Only add words that aren't already in the heading text. A general FAQ question also needs `@faq.general`.

Common causes for missing matches: (a) missing keywords/synonyms so the FAQ doesn't match enough query words, (b) weak app-specific FAQs crowd it out of the top 4 (app-specific FAQs rank above general ones at equal match count), (c) stopwords and short words are left out (e.g. "back up": "back" is a stopword, and "up" has fewer than 3 letters). Fix by adding `@faq.keywords` to the FAQ or synonyms to `SuggestedQuestion.synonyms`.
