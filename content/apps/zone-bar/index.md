---
title: 'Zone Bar'
subtitle: 'World clocks in your menu bar'
publicationDate: 2025-11-20
platforms: [
	'macOS'
]
isPaid: true
isMenuBarApp: true
appStoreID: 6755328989
sharedQuestions: [
	'blurry-secondary-display'
	'menu-bar-icons'
	'sync'
	'backup-settings'
]
# olderVersions: [
# 	{
# 		version: '',
# 		macOS: '26',
# 		url: '',
# 	},
# ]
pressQuotes: [
	{
		quote: 'The app called Zone Bar, available on the Mac App Store, presents itself as a feature extension for the menu bar and lets you show several world clocks side by side there. “Zone Bar” lets you display up to eight time zones in the Mac menu bar at the same time.'
		source: 'ifun.de'
		translatedFrom: 'German'
		url: 'https://www.ifun.de/mac-apps-zone-bar-neu-und-update-fuer-folder-quick-look-269849/'
		year: 2025
	}
]
---

Know what time it is for your team, friends, and family with a glance at your menu bar.

Add clocks for any time zone, give them custom names and emoji, and see them at a glance. The time travel slider lets you check what time it will be hours from now across all clocks. Useful for planning meetings or checking if friends abroad are awake.

Simple by design. No sync, no widgets, no iOS version. Just your clocks, always there when you need them.

**Features**

- **Menu Bar Display**\
  Show up to 10 clocks directly in your menu bar
- **Time Travel**\
  Slide to see what time it will be hours from now across all time zones
- **Custom Labels**\
  Name each clock (“Tokyo Office”, “Mom”) and add emoji icons
- **Keyboard Shortcut**\
  Toggle the window with a global shortcut
- **Adjustable Text Size**\
  Make it comfortable to read

#### Privacy

Your clocks never leave your device. The app is built without internet permissions (no network entitlement), so macOS prevents it from connecting to the internet even if it wanted to. The time zone search uses Apple Maps through macOS.

## Tips

- Right-click a time zone to see more info and copy.
- The +1/−1 indicator shows when a time zone is in a different day.
- Press ++Command+Plus++ when the time zone window is open to quickly add a new time zone.

## Frequently Asked Questions {#faq}

### Some world clocks are missing from the menu bar {#some-world-clocks-are-missing-from-the-menu-bar}

See [how to make the app show up in the menu bar](/apps/faq#app-not-showing-in-menu-bar). Each clock is its own menu bar item, so the same fixes apply to a clock that is missing.

### Can it show seconds? {#can-it-show-seconds}

No. This is a glanceable menu bar app. Seconds clutter the UI and have real performance costs in menu bar updates.

### Can it show the UTC offset (e.g. UTC+8)? {#can-it-show-the-utc-offset-eg-utc8}

No. I want to keep it minimal. The focus is on name and time. You can right-click a time zone to see it.

### Does it work offline? {#does-it-work-offline}

Yes. Everything runs locally, except the time zone search.

### Does it handle summer / winter time (DST) correctly? {#does-it-handle-summer--winter-time-dst-correctly}

Yes. It follows macOS time zone rules, including daylight saving, so times update automatically. Unless you pick a fixed time zone like UTC+2.

### I only see Chinese cities when adding a time zone. Where are London, San Francisco, etc.? {#i-only-see-chinese-cities-when-adding-a-time-zone-where-are-london-san-francisco-etc}

This is a [macOS bug](https://github.com/feedback-assistant/reports/issues/462) when searching from China. You will have to pick a time zone manually using the `…` button.

### Can you add half hour steps to the Time Travel slider? {#can-you-add-half-hour-steps-to-the-time-travel-slider}

No. It’s meant for quick, rough shifts. Smaller steps slow it down. If you need an exact offset, just adjust the minutes yourself.

### Does the app use CPU constantly to keep the time updated? {#cpu}

No. It updates once per minute. Negligible.

### Does it show AM/PM or 24-hour time? {#does-it-show-ampm-or-24-hour-time}

It follows your macOS system time format. You can change it in “System Settings › General › Date & Time”.

### Can it show analog clocks? {#can-it-show-analog-clocks}

No. Digital only.

### Can you reduce the space between menu bar clocks? {#can-you-reduce-the-space-between-menu-bar-clocks}

The spacing is controlled by the system. To make the clocks narrower, turn off “Show minutes in menu bar clocks” in the settings. On macOS 26, you can also use [Menu Bar Spacing](/menu-bar-spacing) to change the spacing for all items. It does not work on macOS 27.

### Can you add widgets? {#can-you-add-widgets}

No. This is a simple menu bar app.

### Can you support iOS? {#can-you-support-ios}

No.

### I already own Dato. Does this offer any benefits over its similar feature? {#dato}

Compared to the similar feature in [Dato](/dato):

- More minimal
- Flag or emoji icons
- Custom text size
