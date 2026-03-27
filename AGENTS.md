# Codebase Notes

## FAQ Suggestions on /feedback

The feedback page shows relevant FAQ links as the user types their message.

### Data sources

- **General FAQs** — a curated subset of `source/pages/apps/faq.md` headings, filtered by slug via `feedbackFaqSlugs` in `feedback.astro`.
- **App-specific FAQs** — all FAQ headings from the selected app's markdown file (via `?product=` URL param), passed through `faqHeadings` in `apps.js`.

### Heading metadata (`<!-- @namespace.attribute value -->`)

Any markdown heading with a `{#id}` can be annotated with directives on the lines immediately below:

```md
### The app does not show up in the menu bar {#app-not-showing-in-menu-bar}
<!-- @faq.keywords launching launch start open opening -->
<!-- @faq.platforms macOS -->
```

- Parsed by the `remarkHeadingMeta` plugin (`source/utils/remark-heading-meta.js`), which runs after `remarkCustomHeaderId` so heading IDs are already set.
- Injected into `file.data.astro.frontmatter.headingMeta` and accessed in `feedback.astro` as `faqMd.frontmatter.headingMeta`.
- Values are always arrays (split on whitespace).
- Multiple directives per heading work by looking back past consecutive `<!-- @... -->` nodes to find the owning heading.
- The `@faq.` namespace is consumed by the feedback page. Other namespaces can be added for future uses.

**`@faq.keywords`** — extra words that make a FAQ matchable by queries that don't use the same words as the heading text.

**`@faq.platforms`** — restricts the FAQ to apps that support at least one of these platforms. FAQs without this annotation are shown for all apps.

### Matching algorithm (`feedback.astro`, second `<script>` block)

1. **Tokenize** — lowercase, strip apostrophes, extract words ≥4 chars, filter stopwords.
2. **Score** — TF-IDF: each query word that matches a FAQ word (exact or prefix) adds `log((n+1)/(df+1))` to the FAQ's score. Rare words score higher.
3. **FAQ words** include the question text + `@faq.keywords`, expanded with synonyms.
4. **minMatches** — requires ≥2 query words to match when ≥2 meaningful ("known") query words exist, preventing single generic terms from matching everything. Pinned FAQs bypass this and only need 1 match.
5. **Pinned FAQs** (`pinnedUrls`) always sort to the top when matched.
6. **App-specific FAQs** sort above general FAQs.
7. **Deduplication** — general FAQs with ≥0.6 Jaccard similarity to an app-specific result are removed.

### Synonyms

**General synonyms** (e.g. `icloud` ↔ `sync`) live in the `SYNONYMS` map in `feedback.astro`. They expand FAQ words so cross-term matches work both ways.

Do **not** use `@faq.keywords` for synonyms — keywords are for *additional match terms specific to one FAQ*. Synonyms express a relationship between two concepts that applies across all FAQs mentioning either term.

### Why a FAQ didn't show for a given email

Common causes: (a) missing keywords/synonyms so the FAQ doesn't match enough query words, (b) weak app-specific FAQs crowd it out of the top-4 (app-specific FAQs rank above general ones at equal matchCount), (c) stopwords eat key terms (e.g. "back up" → "back" is a stopword, "up" is <4 chars). Fix by adding `@faq.keywords` to the FAQ or synonyms to the `SYNONYMS` map.
