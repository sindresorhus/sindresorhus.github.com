---
title: 'Any Text'
subtitle: 'Put text on your Lock Screen, Home Screen, and desktop'
description: 'Put a goal, a note, or a short list on your Lock Screen, Home Screen, Apple Watch, or Mac desktop with widgets. Syncs with iCloud.'
publicationDate: 2022-09-12
platforms: [
	'macOS'
	'iOS'
	'watchOS'
	'visionOS'
]
isPaid: true
appStoreID: 1643199620
redirectFrom: [
	'/lock-screen-one'
]
sharedQuestions: [
	'widget-missing'
	'lock-screen-widget-disappears'
	'lock-screen-centered'
	'lock-screen-text-color'
	'lock-screen-background-color'
	'lock-screen-update'
	'lock-screen-delayed-update'
	'lock-screen-after-restart'
	'widget-run-shortcut'
]
pressQuotes: [
	{
		quote: 'Any Text is a great example of an app that uses Shortcuts to its advantage to make what would otherwise be a static widget that you’d have to change manually or with Focus modes into one that is far more dynamic.'
		source: 'MacStories'
		url: 'https://www.macstories.net/reviews/lock-screen-one-text-widgets-for-your-ios-16-lock-screen-automated-with-shortcuts/'
		year: 2022
	}
	{
		quote: 'Although there are a few widget apps here and there that let you put your own text on the iPhone Lock Screen, none of them implement it as clearly, nicely, and well structured as […] AnyText.'
		source: 'iphone-ticker.de'
		translatedFrom: 'German'
		url: 'https://www.iphone-ticker.de/anytext-beliebige-texte-als-sperrbildschirm-widget-auf-dem-iphone-201106/'
		year: 2022
	}
]
feedbackNote: 'If you are having problems with sync, [read this](/any-text#troubleshoot-syncing).'
---

Write a goal, a note, or a short list, and see it every time you look at your Lock Screen, Home Screen, Apple Watch, or desktop.

The text is shown in widgets that you add where you want them.

For macOS, it’s only available for Apple silicon Macs running macOS 26 or later.

On iOS, you can also show the text in a Live Activity.

Syncs across your devices with iCloud.

> [!TIP]
> You may also like my [One Thing](/one-thing) app for macOS.

## Tips

### Markdown {#markdown}

You can style parts of the text bold, italic, or strikethrough using [Markdown](https://www.markdownguide.org/basic-syntax/).

For example:

- **Bold text** is created by wrapping text with double asterisks: `**bold**`
- *Italic text* is created by wrapping text with single asterisks: `*italic*`
- ~~Strikethrough text~~ is created by wrapping text with double tildes: `~~strikethrough~~`

With a keyboard on iPad or Mac, press ++Command+B++ to make the selected text bold, ++Command+I++ to make it italic, and ++Shift+Command+X++ to strike it through.

### Troubleshoot syncing {#troubleshoot-syncing}

- After enabling sync, try writing some more text on all the devices.
- [More iCloud sync troubleshooting…](/apps/faq#icloud-sync)

## Frequently Asked Questions {#faq}

### How do I add the widget? {#how-do-i-add-the-widget}

- [iOS](https://support.apple.com/118610)
- [macOS](https://support.apple.com/guide/mac-help/mchl52be5da5/mac)
- [watchOS](https://support.apple.com/guide/watch/see-widgets-in-the-smart-stack-apdecf142fb9/watchos)

### The widget is blank {#the-widget-is-blank}

If the text is missing only while the device is locked, enable “Force Show When Device Is Locked” in the “Advanced” section of the widget settings in the app. After a restart, the text shows only after you unlock the device once. This is a limit of iOS for all widgets.

If not, try this:
- Restart your device.
- Change the language of the device to something else and then back.
- Ensure Lock Screen widgets are allowed to show content while the device is locked at “Settings › Face ID & Passcode (or Touch ID & Passcode) › Allow Access When Locked › Lock Screen Widgets”.

### Can you support having multiple pieces of text that change during the day? {#can-you-support-having-multiple-pieces-of-text-that-change-during-the-day}

I would like to keep the app simple, so it’s not something I plan to support built-in. However, the app comes with a shortcut action to change the text, so you could use the [Shortcuts automations](https://support.apple.com/guide/shortcuts/apdfbdbd7123/7.0/ios/17.0) to change the text during the day.

You could also put multiple widgets in a [widget stack](https://support.apple.com/118610).

### Can you add support for user-installed fonts? {#can-you-add-support-for-user-installed-fonts}

This is unfortunately not possible as widgets cannot access user-installed fonts.

### The widget does not update when setting the text with the Shortcuts action {#the-widget-does-not-update-when-setting-the-text-with-the-shortcuts-action}

This is unfortunately an iOS bug. The app correctly tells iOS to update the widget, but iOS delays it for some reason. The text will update eventually.

If you work at Apple → [FB11522170](https://github.com/feedback-assistant/reports/issues/359)

### Can you make the widget bigger? {#can-you-make-the-widget-bigger}

The widget sizes are controlled by Apple. The provided size is the largest it allows. On iPad and Mac, there is also an extra large size.

### Can you make the widget background transparent? {#widget-transparent-background}

The app cannot make its widget transparent, but iOS can make all widgets and app icons see-through: touch and hold the Home Screen, tap “Edit” › “Customize”, and choose “Clear”.

### Can you remove the title shown below the widget? {#can-you-remove-the-title-shown-below-the-widget}

Apple does not allow removing the title. Some apps managed to do it early on, but these days, Apple rejects any attempt at doing that. However, you can hide the titles of all apps and widgets on the Home Screen: touch and hold the Home Screen, tap “Edit” › “Customize”, and choose “Large”.

### How can I remove the date prefix from the inline Lock Screen widget above the clock? {#how-can-i-remove-the-date-prefix-from-the-inline-lock-screen-widget-above-the-clock}

iOS forces the date to be shown. This is out of my control.

### The inline Lock Screen widget above the clock does not respect my font choice {#the-inline-lock-screen-widget-above-the-clock-does-not-respect-my-font-choice}

iOS forces the text to be the same style as the prefixed date. This is out of my control.

### Can it open a specific app instead when tapping the widget? {#can-it-open-a-specific-app-instead-when-tapping-the-widget}

Create a shortcut in the Shortcuts app that opens the app you want, then open “Any Text”, go to one of the widgets, open settings, and set the tap action to the shortcut you just made.

### Can I prevent my child from editing the text when tapping the widget? {#can-i-prevent-my-child-from-editing-the-text-when-tapping-the-widget}

You can set the “When Tapped” setting to “None” in the widget settings.

### Can I edit the text directly from the Home Screen or Lock Screen? {#can-i-edit-the-text-directly-from-the-home-screen-or-lock-screen}

No, widgets only support tapping interactions.

## Scripting

The text in the widgets can be changed using the Shortcuts app.

### Shortcuts app

- [Shortcuts usage guide](https://www.xda-developers.com/guide-shortcuts-macos/)
- [How to run shortcuts from the command-line on macOS](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac)

### Command-line on macOS

Shortcuts can be executed via the command-line, allowing you to set widget text programmatically.

For example, to set the text for widget 1, add the [“Set Widget 1 Text” shortcut](https://www.icloud.com/shortcuts/6873c23a3cbb4718b23135e367d6be1b), and then run this:

```sh
echo 'TEST' | shortcuts run 'Set Widget 1 Text'
```
