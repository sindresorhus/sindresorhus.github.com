---
title: 'Battery Indicator'
subtitle: 'Remaining battery time in your menu bar'
publicationDate: 2017-02-18
platforms: [
	'macOS'
]
isPaid: true
isMenuBarApp: true
appStoreID: 1206020918
hasSentry: true
sharedQuestions: [
	'blurry-secondary-display'
]
olderVersions: [
	{
		version: '2.19.0'
		macOS: '15'
		url: 'https://www.dropbox.com/scl/fi/14amy0g1r6sjyhg48cjns/Battery-Indicator-2.19.0-macOS-15-1772299240.zip?rlkey=e647a9azxyif2mnyuqot8jya7&raw=1'
	}
	{
		version: '2.18.0'
		macOS: '14'
		url: 'https://github.com/user-attachments/files/19015442/Battery.Indicator.2.18.0.-.macOS.14.zip'
	}
	{
		version: '2.16.1'
		macOS: '13'
		url: 'https://github.com/sindresorhus/meta/files/13942534/Battery.Indicator.2.16.1.-.macOS.13.zip'
	}
	{
		version: '2.14.2'
		macOS: '12'
		url: 'https://github.com/sindresorhus/meta/files/10759031/Battery.Indicator.2.14.2.-.macOS.12.zip'
	}
	{
		version: '2.12.3'
		macOS: '11'
		url: 'https://github.com/sindresorhus/meta/files/8759816/Battery.Indicator.2.12.3.-.macOS.11.zip'
	}
	{
		version: '2.7.1'
		macOS: '10.15'
		url: 'https://github.com/sindresorhus/meta/files/6565005/Battery.Indicator.2.7.1.-.macOS.10.15.zip'
	}
	{
		version: '2.1.0'
		macOS: '10.14'
		url: 'https://github.com/sindresorhus/meta/files/4127047/Battery-Indicator-2.1.0-Mojave.zip'
	}
]
---

See how long your battery will last, right in your menu bar, without clicking anything. You can show the percentage instead.

**Features**

- Show the time remaining or the percentage, as an icon or as text
- Hover over the menu bar item to see the other one (percentage or time remaining)
- Notify when the battery is fully charged or at the percentages you choose, on battery or while charging
- Hide the menu bar item while on power or while fully charged on power
- See the battery condition, health, and cycle count (press ++Option++ while the menu is open)
- Get battery details, like health and power draw, in Shortcuts

## Frequently Asked Questions {#faq}

### The app does not show up in the menu bar {#the-app-does-not-show-up-in-the-menu-bar}

[Try the steps in the general FAQ](/apps/faq#app-not-showing-in-menu-bar)

You may also have set the “Hide menu bar item” setting, which hides the menu bar icon while the power adapter is connected, or while the battery is fully charged on power. Launch the app again to reveal the menu bar item for 5 seconds or disconnect the power adapter.

### The estimated time left is incorrect {#the-estimated-time-left-is-incorrect}

The number comes from macOS and the app has no control over it.

### Why does it say “Charging On Hold” while plugged in? {#charging-on-hold}
<!-- @faq.keywords stuck limit -->

macOS holds the charge, for example with Optimized Battery Charging or a charge limit, to make the battery last longer. Battery Indicator reads the same charge holds as macOS. “Not Charging” means that the battery does not charge for another reason, like heat. There is no time remaining while it does not charge.

### Why does the menu bar icon show `…` when I unplug the power adapter? {#why-does-the-menu-bar-icon-show--when-i-unplug-the-power-adapter}

The system needs some time to accurately calculate the time remaining estimate.

### Can macOS do this without an app? {#built-in}

Partly. The battery item of macOS can show the percentage: go to “[System Settings › Menu Bar](x-apple.systempreferences:com.apple.ControlCenter-Settings.extension)”, open the options of “Battery”, and enable “Show Percentage”. It cannot show the time remaining in the menu bar.

Battery Indicator shows the time remaining or the percentage, notifies you at the percentages you choose, and can hide itself while on power.

### How do I remove the system battery menu bar item? {#how-do-i-remove-the-system-battery-menu-bar-item}

Drag it out of the menu bar while pressing ++Command++.

### Can it show “apps using significant energy” like the built-in battery indicator? {#can-it-show-apps-using-significant-energy-like-the-built-in-battery-indicator}

It can unfortunately not show this because of restrictions ([sandboxing](/apps/faq#macos-sandbox)) imposed on apps on the App Store. However, you could change the menu bar item type to text instead of the icon and use this app in combination with the system battery indicator.

### Can it have a “charge to full now” button? {#can-it-have-a-charge-to-full-now-button}

This is not possible for the same reason as mentioned above.

### Can it play a sound when the battery is charged a certain percentage? {#notification-sound}

Yes. In the settings, click “Choose…” next to “Notify at percentages”, and select the percentages, on battery or while charging. The notification plays a sound.

If you want a different sound, you can disable the default notification sound in the “Notification Settings” and then follow the below steps.

This is a perfect use case for the built-in Shortcuts app. You can use the `Play Sound` action to play the sound you want. To run the shortcut when the battery is at a certain percentage, use Shortcuts automations.

You can find sound effects on [Pixabay](https://pixabay.com/sound-effects/search/interface/).

### Can the battery icon hide when the battery is charged a certain percentage? {#can-the-battery-icon-hide-when-the-battery-is-charged-a-certain-percentage}

To hide it when the battery is full, set “Hide menu bar item” to “while fully charged on power” in the settings.

For other percentages, use the built-in Shortcuts app. Create a shortcut that quits the app and one that launches it. To run the shortcut when the battery is at a certain percentage, use Shortcuts automations.
