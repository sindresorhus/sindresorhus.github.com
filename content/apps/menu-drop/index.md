---
title: 'Menu Drop'
subtitle: 'Quick AirDrop sharing in your menu bar'
publicationDate: 2025-10-17
platforms: [
	'macOS'
]
isMenuBarApp: true
appStoreID: 6754022187
nonAppStoreVersion: {
	version: '1.0.1'
	macOS: 26
	url: 'https://www.dropbox.com/scl/fi/2f4gtf7nau0rhrthxwmpl/Menu-Drop-1.0.1-1760766251.zip?rlkey=wedsedjf0v97dpw034by2vtbw&raw=1'
}
sharedQuestions: [
	'menu-bar-icons'
]
olderVersions: [
	{
		version: '0.9.0'
		macOS: '15'
		url: 'https://www.dropbox.com/scl/fi/lpb25nc13acyvup0px1rz/Menu-Drop-0.9.0-macOS-15-1760766492.zip?rlkey=yavo3yew2387xmehp69m6wo3m&raw=1'
	}
]
# feedbackNote: '''
# 	[The app randomly disappears/quits](/apps/faq#randomly-quits)
# 	'''
pressQuotes: [
	{
		quote: 'Menu Drop targets users who regularly send files via AirDrop and want to avoid the detour through an extra Finder window and its sidebar. Instead, “Menu Drop” waits in the Mac menu bar for you to drag a file you want to send via AirDrop onto the app icon that appears there after installation.'
		source: 'ifun.de'
		translatedFrom: 'German'
		url: 'https://www.ifun.de/menu-drop-kuerzt-den-link-und-dateiversand-ueber-airdrop-ab-267375/'
		year: 2025
	}
]
---

AirDrop files, folders, links, and text simply by dragging them onto the app’s menu bar icon.

You can also share files or text directly from your clipboard or use the built-in file picker, both with customizable keyboard shortcuts.

Rich text content is converted to plain text. Rich-text files are sent as files.

*Requires macOS 26 or later*

## Tips

- You can drag and drop a URL directly from the Safari address bar to the menu bar icon.
- Select a URL and either drop it on the menu bar icon or copy it and use Share from Clipboard to open it on your iOS device.

### Privacy

The app is built without internet permissions (no network entitlement), so macOS prevents it from connecting to the internet even if it wanted to.

## Frequently Asked Questions {#faq}

### Dragging onto the menu bar icon opens Mission Control on macOS 27 {#dragging-onto-the-menu-bar-icon-opens-mission-control-on-macos-27}

macOS 27 opens Mission Control when you hold a dragged item near the top of the screen for a moment. Apps cannot prevent this.

Release the item as soon as the pointer reaches the menu bar icon. If Mission Control has already opened, release the item anyway and press Escape to close Mission Control. The AirDrop picker is behind it.

You can also choose “Files” or “Clipboard” below “Share From” in the menu instead.

### Can it send directly to a specific device without showing the picker? {#can-it-send-directly-to-a-specific-device-without-showing-the-picker}

No. Apple doesn’t expose any way to preselect an AirDrop target. You must choose a device in the AirDrop picker.

### Why doesn’t my iPhone/iPad/Mac show up as a target? {#why-doesnt-my-iphoneipadmac-show-up-as-a-target}

AirDrop device discovery is up to the system. Ensure AirDrop is enabled, both devices are unlocked/awake, and are on compatible settings (Contacts Only/Everyone for 10 Minutes).

### AirDrop is not working {#airdrop-is-not-working}

This just triggers the AirDrop picker with the dragged files. It has no control over how AirDrop works.

### Why use this instead of AirDrop in the Share popover? {#why-use-this-instead-of-airdrop-in-the-share-popover}

Speed. Drag straight to the menu bar.

### Can you add a menu item or keyboard shortcut to share the current Finder selection with AirDrop? {#can-you-add-a-menu-item-or-keyboard-shortcut-to-share-the-current-finder-selection-with-airdrop}

No. App Store limits (sandboxing) prevent the app from knowing what you’ve selected in Finder.

My [Supercharge](/supercharge) app has a [Finder context menu item](https://www.dropbox.com/scl/fi/gc760wtbraxtgtq3gsrd3/AirDrop-Finder-context-menu-item-Screen-Shot-2025-11-19-at-00.23.31-1763486630.png?rlkey=4qleot753u1cc8xzez26afj0x&raw=1) to send selected files directly to AirDrop.

<!-- My app also has a keyboard shortcut to send the selection to AirDrop -->
