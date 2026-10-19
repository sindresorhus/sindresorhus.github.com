---
title: 'Any Text'
subtitle: 'Put text on your Lock Screen, Home Screen, and desktop'
description: 'Put a goal, a note, or a short list on your Lock Screen, Home Screen, Apple Watch, or Mac desktop with widgets. Syncs with iCloud.'
redirectFrom: [
	'/lock-screen-one'
]
publicationDate: '2022-09-12'
platforms: [
	'macOS'
	'iOS'
	'watchOS'
	'visionOS'
]
isPaid: true
appStoreID: 1643199620
sharedQuestions: [
	'widget-missing'
	'lock-screen-widget-disappears'
	'lock-screen-centered'
	'lock-screen-text-color'
	'lock-screen-background-color'
	'lock-screen-update'
	'lock-screen-delayed-update'
	'widget-transparent-background'
	'lock-screen-after-restart'
	'widget-run-shortcut'
]
feedbackNote: 'If you are having problems with sync, [read this](/any-text#troubleshoot-syncing).'
pressQuotes: [
	{
		quote: 'Any Text is a great example of an app that uses Shortcuts to its advantage to make what would otherwise be a static widget that you’d have to change manually or with Focus modes into one that is far more dynamic.'
		source: 'MacStories'
		url: 'https://www.macstories.net/reviews/lock-screen-one-text-widgets-for-your-ios-16-lock-screen-automated-with-shortcuts/'
	}
]
---

Write a goal, a note, or a short list, and see it every time you look at your Lock Screen, Home Screen, Apple Watch, or desktop.

The text is shown in widgets that you add where you want them.

For macOS, it’s only available for Apple silicon Macs running macOS 26 or later.

On iOS, you can also show the text in a Live Activity.

Syncs across your devices with iCloud.

<br>

> [!TIP]
> You may also like my [One Thing](/one-thing) app for macOS.

## Tips

### Markdown {#markdown}

You can style parts of the text bold, italic, or strikethrough using [Markdown](https://www.markdownguide.org/basic-syntax/).

For example:

- **Bold text** is created by wrapping text with double asterisks: `**bold**`
- *Italic text* is created by wrapping text with single asterisks: `*italic*`
- ~~Strikethrough text~~ is created by wrapping text with double tildes: `~~strikethrough~~`

### Troubleshoot syncing {#troubleshoot-syncing}

- After enabling sync, try writing some more text on all the devices.
- [More…](/apps/faq#icloud-sync)

## Frequently Asked Questions {#faq}

### How do I add the widget?

- [iOS](https://support.apple.com/HT207122)
- [macOS](https://support.apple.com/guide/mac-help/mchl52be5da5/mac)
- [watchOS](https://support.apple.com/guide/watch/see-widgets-in-the-smart-stack-apdecf142fb9/watchos)

### The widget is blank

Try this:
- Restart your device.
- Change the language of the device to something else and then back.
- Ensure Lock Screen widgets are allowed to show content while the device is locked at “Settings › Face ID & Passcode › Allow Access When Locked › Lock Screen Widgets”.

### Can you support having multiple pieces of text that change during the day?

I would like to keep the app simple, so it’s not something I plan to support built-in. However, the app comes with a shortcut action to change the text, so you could use the [Shortcuts automations](https://support.apple.com/guide/shortcuts/apdfbdbd7123/7.0/ios/17.0) to change the text during the day.

You could also put multiple widgets in a [widget stack](https://support.apple.com/118610).

### Can you add support for user-installed fonts?

This is unfortunately not possible as widgets cannot access user-installed fonts.

### The widget does not update when setting the text with the Shortcuts action

This is unfortunately an iOS bug. The app correctly tells iOS to update the widget, but iOS delays it for some reason. The text will update eventually.

If you work at Apple → [FB11522170](https://github.com/feedback-assistant/reports/issues/359)

### Can you make the widget bigger?

The widget sizes are controlled by Apple. The provided size is the largest it allows.

### Can you remove the title shown below the widget?

Apple does not allow removing the title. Some apps managed to do it early on, but these days, Apple rejects any attempt at doing that. However, in iOS 18 you can hide the title for all apps and widgets.

### How can I remove the date prefix from the inline Lock Screen widget above the clock?

iOS forces the date to be shown. This is out of my control.

### The inline Lock Screen widget above the clock does not respect my font choice

iOS forces the text to be the same style as the prefixed date. This is out of my control.

### Can it open a specific app instead when tapping the widget?

Create a shortcut in the Shortcuts app that opens the app you want, then open “Any Text”, go to one of the widgets, open settings, and set the tap action to the shortcut you just made.

### Can I prevent my child from editing the text when tapping the widget?

You can set the “Widget Tap Action” setting to “None”.

### Can I edit the text directly from the Home Screen or Lock Screen?

No, widgets only support tapping interactions.

## Scripting

The text in the widgets can be changed using the Shortcuts app.

### Shortcuts app

- [Shortcuts usage guide](https://www.xda-developers.com/guide-shortcuts-macos/)
- [How to run shortcuts from the command-line on macOS](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac)

### Command-line on macOS

Shortcuts can be executed via the command-line, allowing you to set widget text programmatically.

For example, to set the text for widget 1, add [this shortcut](https://www.icloud.com/shortcuts/6873c23a3cbb4718b23135e367d6be1b), and then run this:

```sh
echo 'TEST' | shortcuts run 'Set Widget 1 Text'
```
