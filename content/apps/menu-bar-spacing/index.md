---
title: 'Menu Bar Spacing'
subtitle: 'Customize the gap between menu bar items'
publicationDate: '2024-07-09'
platforms: [
	'macOS'
]
mainLinks: {
	Download: 'https://github.com/sindresorhus/menu-bar-spacing-meta/releases/latest/download/Menu.Bar.Spacing.zip'
}
requirement: 'Free · Requires macOS 26 or later'
olderVersions: [
	{
		version: '1.1.0'
		macOS: '15'
		url: 'https://www.dropbox.com/scl/fi/oicszj1rvnivv0wzqtsi0/Menu-Bar-Spacing-1.1.0-macOS-15-1771443121.zip?rlkey=5v0diy5fwpiut9lysc65ij333&raw=1'
	}
	{
		version: '1.0.1'
		macOS: '14'
		url: 'https://github.com/user-attachments/files/18203513/Menu.Bar.Spacing.1.0.1.zip'
	}
]
feedbackNote: 'This no longer works on macOS 27 as Apple rewrote the menu bar and did not include the requires hidden settings to adjust spacing. There is nothing I can do about this, unfortunately.'
---

Fit more items in your MacBook’s menu bar by making the gap between them smaller. On a large display, you can make the gap larger instead.

With a single run, the app applies changes permanently, allowing you to fit more apps into the menu bar. Reverting the changes is just as simple, done within the app.

> [!WARNING]
> This no longer works on macOS 27 as Apple rewrote the menu bar and did not include the requires hidden settings to adjust spacing. There is nothing I can do about this, unfortunately.

> [!WARNING]
> Because of a [macOS 26 bug](https://github.com/feedback-assistant/reports/issues/679), third-party menu bar apps need to be relaunched before they show the correct spacing.

The app includes a Shortcuts action, enabling automated spacing adjustments for various scenarios.

**The app only needs to be run once to set the spacing and can then be uninstalled. The settings persist.**

This app can potentially replace Bartender/Ice for some users. It also lets you fit more of my [menu bar apps](/apps/menu-bar) in your menu bar.

![Download count](https://img.shields.io/github/downloads/sindresorhus/menu-bar-spacing-meta/total?color=3e65d0)

<br>

> [!TIP]
> You may also like my [Spaced](/spaced) app for grouping menu bar items.

## Frequently Asked Questions {#faq}

### I can already do this from the command-line, why should I use this app?

This app makes it simpler and it also makes it possible to see the changes without having to restart your computer first.

### Is it dangerous?

No. The changes are easily reversible in the app.

### Do I need to keep the app running?

No. You only need to run the app once to apply the changes.

### Is this a replacement for Bartender or Ice?

It depends on your needs. If you primarily use those apps to fit more items in the menu bar, this app is a good alternative.

### Can it change the spacing of the left side of the menu bar?

No, this is not possible.

### iStat Menus disappeared when I moved the slider

Menu Bar Spacing needs to relaunch all menu bar items for changes to take effect. iStat Menus may take a while to relaunch. If it doesn’t reappear, try moving the slider again. Restarting your computer will definitely fix it.

### Can you add more features?

No. This app is intentionally simple and focused.

### Can it have per-app configurations?

No. It applies globally only.

### Can I have different spacing for when I’m using the built-in display and when using a connected larger display?

No, not in the app. However, the app comes with an action for Shortcuts, so you could automate it. Create a shortcut for each display that uses the “Set Menu Bar Spacing” action. Then use Shortcuts automations to run them when a display connects.

> [!NOTE]
> The setting is global. Changing it will interrupt any ongoing screen recording or sharing, as it restarts some system processes to apply changes immediately.

### Why is this not on the App Store?

The app works by changing hidden system settings, which is not allowed on the App Store.
