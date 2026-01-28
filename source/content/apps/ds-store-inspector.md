---
title: DS_Store Inspector
subtitle: Inspect .DS_Store files
pubDate: 2026-01-29
platforms:
  - macOS
appStoreId: 6758286374
forceHasIosAppIcon: true
# olderMacOSVersions:
#   - '26'
---

A read-only viewer for Finder metadata stored in [`.DS_Store`](https://en.wikipedia.org/wiki/.DS_Store) files.

`.DS_Store` (Desktop Services Store) files are hidden files macOS creates in every folder you open in Finder. They store folder-specific view preferences like icon positions, window size, and sorting options.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](/feedback?product=DS_Store%20Inspector&referrer=Website-FAQ)

#### Why would I want to inspect a `.DS_Store` file?

To understand and debug how Finder presents a folder: sorting, view mode, window size, icon positions, and other hidden state. This is especially useful when investigating odd Finder behavior, auditing metadata left behind in shared folders, repositories, ZIP archives, installers, and designed DMGs, where the `.DS_Store` controls the exact visual layout users see (icon placement, background, window geometry).

#### Can I use this to clean or reset Finder settings?

No. This app is an inspector, not a cleaner. Use it to understand what is stored, then decide separately how to handle it.

#### Why does a .DS_Store file look empty or show little data?

Some folders barely have custom Finder settings, so there’s not much stored. Also, certain records only appear after you change view options (icon positions, sort order, window size, etc).

#### Why are some record types cryptic?

The format is undocumented. Many record types were reverse-engineered, and some Finder internals still use opaque identifiers. If you [send me](/feedback?product=DS_Store%20Inspector&referrer=Website-FAQ) the `.DS_Store` file, I will take a look. Click the button in the “Help” menu in the app.

#### [More FAQs…](/apps/faq)

<!-- ## Older Versions

- [1.0.0]() for macOS 26+ -->

## Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/ludnvb99m7auzqccwu5wo/DS_Store-Inspector-1.0.1-1769714602.zip?rlkey=su74okznapj5u7m7taaq7zhwp&raw=1) *(1.0.1)*

*Requires macOS 26 or later*
