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
