# Swift website migration

The migration keeps the existing Markdown content and public assets as source-of-truth while replacing Astro, Tailwind, and the Node build pipeline with Swift.

## Progress

- [x] Inventory current Astro routes, content schemas, Markdown transforms, metadata, feeds, assets, and browser behavior.
- [x] Add Swift package using Elementary, swift-markdown, and Yams.
- [x] Add typed app/blog/frontmatter models and media inspection.
- [x] Port Markdown processing: custom heading IDs, heading metadata, feedback FAQ injection, raw HTML, alerts, tables, and kbd normalization.
- [x] Add Swift style registry and generated stylesheet with no Tailwind dependency.
- [x] Port shared metadata, navigation, footer, icons, app/blog/static page rendering.
- [x] Port route generation, RSS, sitemap, redirects, and internal-link validation.
- [x] Port browser scripts to `public/scripts`, preserve existing behavior, replace runtime Tailwind class strings with semantic CSS hooks, and syntax-check them in CI.
- [ ] Generate OG cards in Swift/rsvg-convert and verify output parity.
- [ ] Keep the latest branch green in SwiftPM tests and full-site validation. Earlier Linux runs have passed; latest branch is still gated by OG/parity CI.
- [ ] Pass automated Astro-vs-Swift HTML/XML/OG route parity, then compare representative generated HTML/metadata.
- [ ] Remove Astro/Tailwind/npm files and replace deploy workflow.
- [ ] Final validation and merge-ready PR.

## Post-parity architecture passes

After functional and visual parity is green:

- [ ] Add a lightweight content-collection abstraction, inspired by Astro but simpler, so apps, blog posts, and future collections share loading, filtering, sorting, validation, routing, and rendering infrastructure.
- [ ] Add proper shared layouts so page chrome, simple content pages, blog pages, and app pages compose common layout primitives instead of repeating document structure.
- [ ] Extract reusable site components where the same UI or behavior appears in multiple places.
- [ ] Extract RSS generation into a proper general-purpose Swift subpackage with typed channels/items, namespaces, escaping, dates, validation, and reusable feed rendering.
- [ ] Make the public APIs more Swift-native: stronger types, better naming, result builders where they improve clarity, value semantics, protocol-based composition where useful, and fewer stringly-typed escape hatches.
- [ ] Do multiple dedicated refactoring passes after parity: generalize repeated patterns, simplify control flow and models, remove accidental abstractions, reduce duplication, and DRY up the implementation without sacrificing readability or direct access to HTML/CSS.
- [ ] As the final refinement step, explore Swift macros creatively to improve authoring syntax and reduce boilerplate where they provide a clear ergonomic win, especially for content collections, routes, layouts, components, metadata, and style declarations. Keep macros optional and justified by clarity rather than novelty.
