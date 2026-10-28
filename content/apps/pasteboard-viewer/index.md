---
title: 'Pasteboard Viewer'
subtitle: 'Inspect the system pasteboards'
publicationDate: 2020-02-18
platforms: [
	'macOS'
	'iOS'
	'visionOS'
]
appStoreID: 1499215709
repositoryURL: 'https://github.com/sindresorhus/Pasteboard-Viewer'
nonAppStoreVersion: {
	version: '2.12.0'
	macOS: 26
	url: 'https://www.dropbox.com/scl/fi/ofwrr7xwgkbh2gpyosdkl/Pasteboard-Viewer-2.12.0-1774843275.zip?rlkey=5xslv1f9me08bgwsn9yb2kpp8&raw=1'
}
olderVersions: [
	{
		version: '2.11.0'
		macOS: '15'
		url: 'https://github.com/sindresorhus/Pasteboard-Viewer/releases/download/v2.11.0/Pasteboard.Viewer.2.11.0.-.macOS.15.zip'
	}
	{
		version: '2.8.0'
		macOS: '14'
		url: 'https://github.com/sindresorhus/Pasteboard-Viewer/releases/download/v2.8.0/Pasteboard.Viewer.2.8.0.-.macOS.14.zip'
	}
	{
		version: '2.5.1'
		macOS: '13'
		url: 'https://github.com/sindresorhus/Pasteboard-Viewer/releases/download/v2.5.1/Pasteboard.Viewer.2.5.1.-.macOS.13.zip'
	}
	{
		version: '2.4.1'
		macOS: '12'
		url: 'https://github.com/sindresorhus/meta/files/13539167/Pasteboard-Viewer-2.4.1-macOS-12.zip'
	}
	{
		version: '2.2.2'
		macOS: '11'
		url: 'https://github.com/sindresorhus/Pasteboard-Viewer/releases/download/v2.2.2/Pasteboard.Viewer.2.2.2.-.macOS.11.zip'
	}
	{
		version: '1.5.2'
		macOS: '10.15'
		url: 'https://github.com/sindresorhus/Pasteboard-Viewer/releases/download/v1.5.1/Pasteboard.Viewer.1.5.2.-.macOS.10.15.zip'
	}
]
---

A developer utility that shows the contents of the system pasteboards live, with previews of text, RTF, images, and anything that has a Quick Look preview.

The sidebar lists the types of the current item, like `public.url`. Select a type to see its content. A `dyn.` type shows the type it stands for below its name.

Use it to check that your app puts the correct data on [`NSPasteboard`](https://developer.apple.com/documentation/appkit/nspasteboard) or [`UIPasteboard`](https://developer.apple.com/documentation/uikit/uipasteboard).

Note that this is not a clipboard manager. If you are not a developer, you probably don’t want this app. To only see the text or image on the clipboard, select “Edit › Show Clipboard” in Finder.

## Frequently Asked Questions {#faq}

### How do I stop the paste prompt? {#paste-prompt}

The system asks before an app can read the pasteboard. To always allow it:

**macOS:** Allow the app in “System Settings › Privacy & Security › Paste from Other Apps”.

**iOS:** Go to “Settings › Apps › Pasteboard Viewer › Paste from Other Apps” and choose “Allow”.
