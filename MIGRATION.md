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
- [ ] Port browser scripts verbatim to `public/scripts` and remove remaining Tailwind-oriented DOM class generation.
- [ ] Generate OG cards in Swift/resvg and verify PNG parity.
- [ ] Run SwiftPM compile/tests in CI and fix all type/build issues.
- [ ] Compare generated route set and representative HTML against Astro output.
- [ ] Remove Astro/Tailwind/npm files and replace deploy workflow.
- [ ] Final validation and merge-ready PR.
