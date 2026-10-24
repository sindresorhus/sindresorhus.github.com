# Codebase Notes

## Commits

Never commit the owner’s uncommitted changes, especially in `content/`. They are often about app features that are not released yet, like new actions in `content/apps/actions/index.md`. Before you commit, list the uncommitted changes that you did not make: run `git diff` and check `git stash list`, as the owner may have stashed them. When you and the owner changed the same file, stage only your hunks (for example with `git apply --cached` and a patch of your hunks), and check with `git diff` that only the owner’s changes stay uncommitted. Do not run git commands that change the index or the working tree while another agent stages a commit.

## Browsers

The site targets only modern browsers (the latest Safari, Chrome, and Firefox). Use the latest CSS, HTML, and JavaScript features and syntax freely, like relative colors (`oklch(from …)`) and `sibling-index()`, without fallbacks for older browsers.

## Modern APIs before speed

Prefer modern syntax and APIs to the fastest ones. For example, use Swift `Regex` and regex literals, not `NSRegularExpression`, even where `NSRegularExpression` is faster. The build is fast enough, so do not trade readable, modern code for performance unless something is too slow to use.

Swift makes the `Regex` of a literal again, and compiles its program again, each time the code runs, so a regex that runs often, like in a loop or for each page, is stored in a `static let` or a file-level `let`. A stored regex is `nonisolated(unsafe)`: `Regex` is not `Sendable`, but it is immutable and compiles its program once, thread-safely.

## Image formats

Do not use AVIF. The owner waits for JPEG XL instead. Keep PNG and JPEG until then.

## Assets

A page is a Markdown file, or a directory with an `index.md` (a page bundle) when it has files of its own, like images. The files of a page bundle are published next to its page: `content/apps/dato/icon.png` at `/dato/icon.png`, `content/blog/post/image.png` at `/blog/post/image.png`, and `content/pages/about/lego.jpg` at `/about/lego.jpg` (`Project.site(root:)`), but only when the site publishes the page, so a draft (`isDraft: true`) does not publish its files. Only the files directly next to the `index.md` are published, not the files in its subdirectories. An app's icon, screenshots (`screenshot*.png/jpg`), and videos (`video*.mp4`) are files of its page bundle.

Link to them relatively in the Markdown, like `[photo](lego.jpg)`. A relative link with a file extension to a file that does not exist is a build error. Files that many pages use, or that other sites link to, like the logos in `public/assets/thanks`, go in `public/`, as their URLs must not change.

## Motion

Keep motion to a minimum in the content. Small transitions that help to understand a change, like a hover color or a menu that fades in, are fine. Do not add scroll animations, elements that move into view, parallax, or animations of the content itself, like text or cards that move by themselves.

Subtle background animations are fine, like the nebula of the home page, the drifting blobs of the contact page, or a slow glassy background behind a page header. They must be calm and slow, stay behind the content, show a still frame when the visitor prefers reduced motion, and pause when they are off screen or the tab is hidden. The galaxy of the home page is the exception: with reduced motion, it is not loaded, and the page shows its plain background. The home page also keeps the animated gradient of the name and the rotating ring in dark mode, as it is the playful page of the site.

The `animation()` style modifier does this by default: it writes the animation in `@media (prefers-reduced-motion: no-preference)`, so with reduced motion the element shows its style without the animation. Make that style the still frame, like the end of a fade in, and do not wrap the animation in `.media(.allowsMotion)` or stop it with `.reducedMotion { $0.noAnimation() }`. Hide a decoration that only makes sense while it moves, with `.reducedMotion { $0.hidden() }`. Only an animation that carries meaning and hardly moves runs with reduced motion too (`isEssential: true`), like the highlight of the section that a link points to. Scroll-driven animations (`animation(_:timeline:range:)`) follow the scrolling of the visitor, so they also run. Transitions and animations in scripts (`element.animate()`) are not covered: guard them yourself where they move things.

Read the reduced motion setting once, when the page loads. Do not handle a change of the setting while the page is open.

## Styles

A style that only one element has goes on the element itself, like a modifier in SwiftUI: `.style { $0.padding(.rootEm(1)) }`, or `.vstack(spacing:)` and `.hstack(…)` for a stack (`ElementStyle`). Its class is the name of the file and a hash, and the page collects its rule in the `elements` layer, after the components, so it wins over the styles of its component. Use a case in the `Styles` (a `StyleSet`) of the component for a look that more than one element has, for variants, and for a style that another selector refers to, like a parent that changes a child while it is hovered, as nothing can refer to a hashed class. A parent sets the space around a child component where it uses it, like `PressQuotes(…).style { $0.margin(.top, .rootEm(7)) }`, not with `.children(X.Styles.root.selector)`, so the child declares the tag of its root, like `var body: some HTML<HTMLTag.section>`. Never use inline styles or `<style>` in content. A value of the build, like the accent of an app or the size of a screenshot, is a custom property in a style of the element, like `.tint(color)` or `.style { $0.setting(Color.accent, to: color) }`, so no page has a `style` attribute (a test checks it). Before adding a style, reuse a component or a style that already exists, like `VisuallyHidden` for text that is only in the HTML, or a modifier like `.buttonStyle(.gradient)`.

When you simplify or remove duplicate code, do not remove style modifiers and other generally useful modifiers and utilities (in SiteKit or `Theme.swift`), even if nothing uses them now. They may be needed later. Only remove code that is specific to a feature that was removed.

Use full words in names, also for CSS units and keywords, like `.pixels(1)`, not `.px(1)`. Put the CSS keyword in the doc comment, like “(`px` in CSS)”. A length always has a unit, like `.padding(.pixels(1))` or `.gap(.rootEm(0.5))`: a `Length` accepts only `0` as an integer literal, as `.padding(1)` writes the invalid `padding: 1`.

The “More Posts” list below a blog post is faded (`opacity(0.8)`) on purpose, so it does not draw attention from the post. Keep the fade, even though it gives its gray text less contrast, and do not replace it with another quiet look, like smaller post titles.

## Keyboard focus

The site has no focus rings, not even the ones of the browser (`SiteLayout`). Every focusable element must still show keyboard focus, often with the same look as under the pointer (`.hoverOrFocusVisible { … }`), never with an outline: a fill or a border for a control, a pill, or a card (`hoverFill(_:color:)` in `Theme.swift`), and a color or an underline for a link in text, like the links of the footer (`hoverColor(_:)`) and of the prose. A link or a button whose color cannot change, like the site name, which already has the strongest text color, or the dots of `AppMedia`, gets a round card fill on focus (`focusFill()` in `Theme.swift`). A current item (`aria-current`) already has a fill, so it shows focus with a thin edge instead: `.current { $0.focusVisible { $0.shadow(.edge(.secondaryText)) } }`, which `currentFill(_:)` in `Theme.swift` does, like for `navigationPill()`. A text field shows focus on its border, with a `focusRing` that covers the border (`FormField`): the only outline outside the 1999 page.

## Block directives

Content files can use the block directives in `Sources/Website/Components/MarkdownOptions.swift`, like `@Feature(title: "…") { … }` and `@Tips { … }`. Prefer one of them to raw HTML in content, and use Markdown links, not raw `<a>` tags, as a link inside one would be a nested link. Each has a sample in the gallery (`GalleryPage`), and the styles of each are a style set. Markdown renders before the pages, so a document collects the styles that its directives use, and the page adds them when it shows the document. So show a document with `document.content` (or `Prose(markdown:)`), not with `HTMLRaw(document.html)`, which leaves its styles out. A test checks that every class on a page has a rule.

- `@Cards { - … }`: a list as cards that flow through two columns from tablets. The text of each item is the title of its card, and a nested list is smaller text below it. Like the lists of the about page.
- `@Steps { 1. … }`: a numbered list as steps, with each number in a circle in the accent of the page and a line to the next. A nested list is smaller text below its item.
- `@Changelog { - 2014 }`: a list of years, each with a nested list of changes, like the release notes of an app. A change can start with its kind, like `Added: Awesome`, which becomes a badge: Added, Changed, Fixed, and Removed in their colors, or Deprecated in gray. Another kind is a content error. Like the life changelog of the about page.
- `@Feature(title: "…") { … }`: a main feature of an app, as a section with a numbered title, like “01”, so a few main features stand out from the rest of the page.
- `@Trial(url: "…") { … }`: the trial of an app, as a card with the text and a download button. `title` changes the text of the button, like “Try on TestFlight”. It goes below the “Trial” heading, which the “Free Trial” button of the app links to.
- `@Sponsors`: the sponsors of the `sponsorTiers` frontmatter of the page, on a line of its own, like on the supporters page. A page with `sponsorTiers` must have it. It has no content.
- `@SocialLinks`: the social links of `Site.author` as chips with icons. The footer has the same links, as plain links. It has no content.
- `@Details(summary: "…") { … }`: a collapsible section with the look of the FAQ questions, for long details that most readers skip, like the steps for an older macOS version.
- `@QuickAnswer { … }`: the short answer at the top of a how-to post, in a box with a “Quick Answer” label, for readers who only want the answer.
- `@Tips { - … }`: a box of tips, with the look of a tip alert.
- `@TinyApp(title: "…", icon: "/apps/…/icon.png", download: "…", source: "…", requirement: "…") { … }`: a small app without a page of its own, as a card with its icon, the text, a download button, and the requirement, like on the tiny apps page. Only `title` and `download` are required. Without an icon, it shows the placeholder icon. The icons are in `public/apps/<slug>/`.

A paragraph that only has bold text, like `**Highlights**` or `**More features**`, is a label for the list or text below it. The renderer gives it the `boldLabel` class (`ProseStyles.boldLabelStyle`), which adds slightly more space above than between paragraphs, so it reads as the start of a new group. This is intentional. A paragraph that has other text after the bold text, like `**macOS:** Click …`, is not a label and keeps the normal space.

Inline, a platform badge marks a part that only works on some platforms: `^[macOS only](platform: "macOS")`.

An inline note shows more about a text in a popover when the text is clicked: `^[Spotlight](note: "The *search* of macOS. See [the FAQ](faq.md).")`. The text is an `InlineNote`, a link that wraps like the text around it, and the note is a popover at the end of the document. The note is Markdown, and its links are resolved and checked like other links. Write `"` in a note as `\"`, and a new paragraph as `\n\n`. A note cannot have headings, footnotes, or other notes (a content error), and it does not work in a short text that is shown inline, like a frontmatter field. The script of `InlineNote` finds its note by the ID in the link, as the note is at the end of the document, not in the element. Use a note, not a footnote (`[^id]`): the site shows both in a popover, but a note does not need a definition in another place.

Write a keyboard shortcut as `++Shift+Command+N++`, which becomes one `<kbd>` per key. Spell out the modifier keys (`Command`, `Option`, `Control`, `Shift`), and do not write shortcuts as plain text like “Command-N”.

A fenced code block in content renders as a `CodeBlock` (`Sources/Website/Components/CodeBlock.swift`), with its language and a copy button. The build highlights Swift code with the parser of Swift (`swiftCodeParts` in SiteKit) and SOML code with the lexer of SOML (`somlCodeParts`), each line of a `console` block gets a `$ ` prompt, and the code of other languages is plain. Markdown without the options of the site, like release notes, has a plain `pre`.

No content uses `@QuickAnswer`, `@Tips`, or the platform badge yet. They are kept for content that needs them, so use them when they fit, instead of raw HTML or a new directive. Good places: platform badges on app pages where a feature works only on some platforms, like the Actions app (`content/apps/actions/index.md`), `@QuickAnswer` at the top of how-to posts, and `@Details` for long notes in an FAQ answer.

Do not indent the content of a directive that has a nested list. swift-markdown removes as many whitespace characters from each line as the first line has columns of indentation, so a tab-indented first line removes the tab of the nested items too, and the nested list becomes part of the outer list.

## Scripts of components

A component with behavior is a custom element (`ScriptedElement`), like `CopyButton`: Swift renders all its markup in the light DOM, and its script is the class of the element, so the script only works on its own element and finds no elements on the page by an ID or a selector. A small script, like the one of `CopyButton`, is inline in the Swift file (`ElementScript(inline:)`), extends `HTMLElement`, and the page gets it once. A larger one is the `.js` file in the `Scripts` folder next to the Swift file (`ElementScript()`). A new `Scripts` folder also goes in the `exclude` of the Website target in `Package.swift`. The build publishes it unchanged, so the file defines its element itself: `class GeoCitiesLego extends GeoCitiesElement {` with the name of the Swift type, and `customElements.define('geo-cities-lego', GeoCitiesLego);` at the end, with the tag name of the element. It imports its base class and other scripts without a hash, like `import GeoCitiesElement from '/scripts/geocities-element.js';`, as the import map of the page adds the hash. To copy the element of a template part, use `clone()` of the base class, which gives the copy and its parts, like `const {element: row, parts} = this.clone('rowTemplate'); parts.name.textContent = name;` (or `napster.clone('resultTemplate')` in a setup function that gets the element). The elements in a template that the script fills are parts too, with `.part(Parts.name)` in the same `Parts` enum, so the script finds them by name, not by a tag or a position, like `querySelector('span')` or `children[1]`. `this.parts` does not have them, as the content of a template is not in the element, and a test checks that a script reads them only in a copy. For a template that is one element, like a `<span>`, `cloneTemplate(template)` is enough, which `/scripts/scripted-element.js` and `/scripts/geocities-element.js` export, like `import GeoCitiesElement, {cloneTemplate} from '/scripts/geocities-element.js';`. There is no list of the elements: the build finds the scripts in the `Scripts` folders, and the tests check the scripts against the elements that the pages show, so show a new element in the gallery (`GalleryPage`) when the pages only show it with data. An element that needs none of the helpers of the `ScriptedElement` base class extends `HTMLElement`, so the page does not load the base class. An element that only adds behavior to the element inside it, like a button, has `display: contents` as its root style. Another script changes an element through its attributes, like Appdle sets the `text` of its copy button, as an attribute also works before the element is defined.

Behavior of a whole page, like the nebula of the home page or the filter of the apps page, stays a page script in `public/scripts`.

## Script hooks

A page script, or a script that must find elements outside its component, finds them by hooks. A component declares the IDs and data attributes that its script uses as a nested `enum Hooks: String, ScriptHookSet`, next to its `Styles`, and uses them like `.id(Hooks.restart)`. A hook that starts with `data-` is a data attribute (`.hook(_:)`, `.when(_:)`), and every other hook is an ID (`.id(_:)`, and `Hooks.restart.id` for a reference to it, like `.for(_:)` or an inline script). Using one as the other kind stops the build at the first render. A hook of one component that another file needs is used from its `Hooks`, like `AppHero.Hooks.hero`. A test checks that every hook is used by a script, and that every hook a script uses is declared.

## States

A script shows a state of an element to the styles with `data-state`, like `button.dataset.state = 'copied'`. The component declares its states as a nested `enum States: String, ElementStateSet` (SiteKit), next to its `Parts`, and the name of a case is the state, like `case copied`, or a state with a hyphen has a raw value, like `case signingOn = "signing-on"`. Its styles use them like `.when(States.copied) { … }`, or `.when(ancestorHas: States.copied) { … }` for an element inside, and Swift renders a first state with `.state(States.copied)`. A component that is not a custom element, but that a page script sets states on, declares its states the same way, like the 1999 page for `geocities.js`. Tests check that every state that the script of an element sets is one of its states, that each state is set and styled, and that the page scripts only set states that some component declares (a page script is not tied to one component).

Do not copy an ARIA state or the state of a form control to `data-state`. Style it directly, so the look always matches what screen readers say: `.pressed { … }` for a toggle button (`aria-pressed="true"`), `.expanded { … }` for a button that opens a menu (`aria-expanded="true"`), and `.current { … }` for the current item of a set (`aria-current`). For the element around it, use `.descendantPressed { … }`, like a box around a toggle button, or `.descendantChecked { … }`, like the label of a hidden radio button, and for an element inside it, `.ancestorPressed { … }` or `.ancestorCurrent { … }`. The script only sets the ARIA attribute (a form control needs no script), and Swift renders the first value, like `.ariaPressed(index == 0)` or `.attributes(.checked, when: …)`.

## Home page

The home page does not show apps, like the newest apps. It stays a calm introduction, and the “Apps” button leads to the apps.

## FAQ Suggestions on /feedback

The feedback page shows relevant FAQ links as the user types their message.

### Data sources

- **General FAQs**: the questions of `content/pages/apps/faq.md` that have `<!-- @faq.general -->`. The directive is only allowed on that page.
- **App-specific FAQs**: the `###` questions in the FAQ section (`## Frequently Asked Questions {#faq}`) of the selected app's markdown file (via the `?product=` URL param), without deeper headings and without the added feedback question. See `App.faqHeadings` in `Sources/Website/Content/App+Links.swift`. The section is found by its ID, `App.faqSectionID`. It includes the common questions that the build adds, except the menu bar question (`App.addedMenuBarQuestionID`), as its answer only links to the general question, which is suggested instead.
- **Common questions**: the build adds the questions that many apps have to the FAQ section of each app from its facts: the menu bar question for menu bar apps (`isMenuBarApp`), the free question for free apps on the App Store that are not archived, and the localization question for all apps. An app can also pick questions that only some apps have from `content/shared-questions.md` by the IDs of their headings, like `sharedQuestions: ['suggested-filenames']` for apps that save files (`App.SharedQuestions`). Each shared question is a level 3 heading with a short ID and its answer in Markdown, and its directives, like `@faq.keywords`, work as in an app file. The shared questions go after the questions of the app, but a question about a problem has `<!-- @faq.first -->` (`App.SharedQuestions.First`), so it goes before them, like the menu bar question. Only the shared questions can have it. The links of the shared answers are site paths, like `/apps/faq#refund`, not relative links, as the answer is shown on the app pages. See `CommonQuestion` in `Sources/Website/Content/App.swift`. Do not write these questions in app files, unless the app needs a different answer: a question with the same text keeps its own answer and gets no added copy.

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
- The known directives are `FAQDirectives.all`, plus `FAQDirectives.General` on the general FAQ page (`Sources/Website/Components/MarkdownOptions.swift`), and `App.SharedQuestions.First` in the shared questions (`Sources/Website/Content/App.swift`). An unknown name, invalid values, a directive given twice on one heading, or a directive that is not directly below a heading, is a content error with its line.
- The `@faq.` namespace is consumed by the feedback page, except `@faq.first`, which places a shared question on the app page. Add a type to `FAQDirectives` for a new directive.

**`@faq.keywords`**: extra words that make a FAQ matchable by queries that don't use the same words as the heading text. Only add a keyword that a user would likely type and that is not already matched: not a word of the heading, not a word that prefix matching covers (“sort” covers “sorted”), not a stopword, and not a synonym. When a word pair is useful for many FAQs, add it to `SuggestedQuestion.synonyms` instead.

**`@faq.platforms`**: restricts the FAQ to apps that support at least one of these platforms. FAQs without this annotation are shown for all apps. An unknown platform is a content error.

**`@faq.general`**: suggests a question of the general FAQ for every app. Only on `content/pages/apps/faq.md`.

**`@faq.pinned <rank>`**: suggests the question before all others, when it has enough matching words (like other questions). Lower ranks come first. The ranks are shared by the general FAQ and the app files. A pinned directive without one number is a content error.

**`@faq.first`**: puts a shared question before the questions of the app, instead of after them, like a question about a problem. Only `content/shared-questions.md` can have it (`App.SharedQuestions.First`). The app page knows it too, as the picked questions have it, but a question of an app file with it is a content error.

### Matching

`SuggestedQuestion` (`Sources/Website/Content/SuggestedQuestion.swift`) prepares the words of each question at build time, so the script of `FAQSuggestions` only splits the message into words and scores the questions.

1. **Words**: lowercase, apostrophes removed, straight and typographic (“doesn't” and “doesn’t” are “doesnt”), words of 3 or more letters, digits, or underscores, and no stopwords (`SuggestedQuestion.stopwords`, also sent to the script). The stopwords include “app”, “apps”, “application”, “mac”, and “macos”: almost every question has them, and with prefix matching “app” would also match “apple” and “appearing”. Use `@faq.platforms` for questions about one platform.
2. **Question words**: the words of the question text (`questionWords`). The words of `@faq.keywords` and the synonyms of all these words are in `extraWords`. Together they are the words a message can match.
3. **Matching**: a message word matches a question word when one starts with the other, like “sync” and “syncing”.
4. **Score**: TF-IDF. Each matching message word adds `log((n+1)/(df+1))`, where `df` is the number of questions whose question words contain it. Rare words score higher.
5. **Minimum**: a question needs 2 matching words when the message has 2 or more known words (words that match any question), else 1. Pinned questions need the same number.
6. **Order**: pinned questions first, by rank. Then more matching words come first, then app questions before general questions, then the higher score.
7. **Deduplication**: general FAQs with 0.6 or more Jaccard similarity to an app-specific result are removed. The first 4 are shown.

The script also shows a request for a crash report when the message contains a word that starts with “crash”.

### Synonyms

**Synonyms** (e.g. `icloud` ↔ `sync`) live in `SuggestedQuestion.synonyms`. A group makes every word match the others, and a one-way synonym only matches in its direction (a question about a “broken” app matches a message about a “bug”, but not the other way around). They expand the words of the questions at build time.

Do **not** use `@faq.keywords` for synonyms: keywords are for *additional match terms specific to one FAQ*. Synonyms express a relationship between two concepts that applies across all FAQs mentioning either term.

### When a FAQ doesn't show as "related help" for a user's message

When asked to improve FAQ matching (e.g., "add to related help", "this FAQ didn't show up", "add keywords"), the fix is usually adding `@faq.keywords` to the relevant FAQ heading in the app's markdown file. Only add words that aren't already in the heading text. A general FAQ question also needs `@faq.general`.

Common causes for missing matches: (a) missing keywords/synonyms so the FAQ doesn't match enough query words, (b) weak app-specific FAQs crowd it out of the top 4 (app-specific FAQs rank above general ones at equal match count), (c) stopwords and short words are left out (e.g. "back up": "back" is a stopword, and "up" has fewer than 3 letters). Fix by adding `@faq.keywords` to the FAQ or synonyms to `SuggestedQuestion.synonyms`.
