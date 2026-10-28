---
title: 'DS_Store Inspector'
subtitle: 'Inspect .DS_Store files'
publicationDate: 2026-01-29
platforms: [
	'macOS'
]
appStoreID: 6758286374
# olderVersions: [
# 	{
# 		version: '1.0.0',
# 		macOS: '26',
# 		url: '',
# 	},
# ]
nonAppStoreVersion: {
	version: '1.0.2'
	macOS: 26
	url: 'https://www.dropbox.com/scl/fi/amjh96y5np88k35a29o91/DS_Store-Inspector-1.0.2-1770388348.zip?rlkey=laf8sa8yybe2v1i21oe9ps86d&raw=1'
}
---

A viewer for Finder metadata stored in [`.DS_Store`](https://en.wikipedia.org/wiki/.DS_Store) files. It shows the records, but it cannot change them.

`.DS_Store` (Desktop Services Store) files are hidden files macOS creates in every folder you open in Finder. They store folder-specific view preferences like icon positions, window size, and sorting options.

## Frequently Asked Questions {#faq}

### Why would I want to inspect a `.DS_Store` file? {#why-would-i-want-to-inspect-a-ds_store-file}

To understand and debug how Finder presents a folder: sorting, view mode, window size, icon positions, and other hidden state. This is especially useful when investigating odd Finder behavior, auditing metadata left behind in shared folders, repositories, ZIP archives, installers, and designed DMGs, where the `.DS_Store` controls the exact visual layout users see (icon placement, background, window geometry).

### Can I use this to clean or reset Finder settings? {#can-i-use-this-to-clean-or-reset-finder-settings}

Partly. The app cannot change the records, but “File › Delete .DS_Store” moves the `.DS_Store` file of the open folder to the Trash. Without the file, Finder uses its default view settings for that folder.

### Why does a .DS_Store file look empty or show little data? {#why-does-a-ds_store-file-look-empty-or-show-little-data}

Some folders barely have custom Finder settings, so there’s not much stored. Also, certain records only appear after you change view options (icon positions, sort order, window size, etc).

### Why are some record types cryptic? {#why-are-some-record-types-cryptic}

The format is undocumented. Many record types were reverse-engineered, and some Finder internals still use opaque identifiers. If you [send me](/feedback?product=DS_Store%20Inspector&referrer=Website-FAQ) the `.DS_Store` file, I will take a look. To get the file, choose “Help › Copy .DS_Store for Sharing” in the app.

### Why does it require macOS 26 or later? {#why-does-it-require-macos-26-or-later}

This is just a small, free project I built for fun. Supporting older macOS versions would mean extra testing, compatibility layers, and working around bugs Apple will never fix.

Keeping it macOS 26+ lets me keep the code simple and spend time building things I enjoy instead of maintaining legacy support.
