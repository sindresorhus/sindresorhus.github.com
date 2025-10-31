---
title: Any Text
subtitle: Put text on your Lock Screen, Home Screen, and desktop
pubDate: 2022-09-12
platforms:
  - macOS
  - iOS
  - watchOS
isPaid: true
appStoreId: 1643199620
forceHasIosAppIcon: true
feedbackNote: |
  If you are having problems with sync, [read this](/any-text#troubleshoot-syncing).
---

The app provides widgets where you can write any kind of text. It could be an important note, your goal, a list of tasks, etc.

For macOS, it's only available for Apple silicon Macs running macOS 15 or later.

On iOS, you can also show the text in a Live Activity.

Syncs seamlessly across your devices with iCloud.

<br>

*You may also like [my similar app](/one-thing) for macOS.*

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

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Any%20Text&referrer=Website-FAQ)

#### How do I add the widget?

- [iOS](https://support.apple.com/HT207122)
- [macOS](https://support.apple.com/guide/mac-help/mchl52be5da5/mac)
- [watchOS](https://support.apple.com/guide/watch/see-widgets-in-the-smart-stack-apdecf142fb9/watchos)

#### The widget does not show up in the widget picker, the widget is stuck, or is missing from the Home Screen

The iOS widget system is quite buggy and can fail a lot. This is not a problem with the app and out of my control. [Try this.](https://webtrickz.com/third-party-lock-screen-widgets-not-showing-ios-16/)

#### The widget is blank

Try this:
- Restart your device.
- Change the language of the device to something else  and then back.
- Ensure Lock Screen widgets are allowed to show content while the device is locked at “Settings › Face ID & Passcode › Allow Access When Locked › Lock Screen Widgets”.

#### Can you support having multiple pieces of text that change during the day?

I would like to keep the app simple, so it's not something I plan to support built-in. However, the app comes with a shortcut action to change the text, so you could use the [Shortcuts automations](https://support.apple.com/guide/shortcuts/apdfbdbd7123/7.0/ios/17.0) to change the text during the day.

You could also put multiple widgets in a [widget stack](https://support.apple.com/118610).

*(macOS does not yet have automations. You can use [Shortery](https://apps.apple.com/app/id1594183810) for now.)*

#### Can you add support for user-installed fonts?

This is unfortunately not possible as widgets cannot access user-installed fonts.

#### Can I make the widget horizontally centered on the Lock Screen?

This is unfortunately not possible. Apple has decided that the rectangular widget can only appear on the left or right side.

#### Can I pick a color for the text on the Lock Screen?

Lock Screen widgets cannot have colors. You can set a custom text color for the normal widgets though.

#### Can I pick a background color for the Lock Screen widgets?

Same answer as the above.

#### The widget does not update if I write some text in the app and then reveal the Lock Screen

You need to first close the app. This is an iOS bug.

If you work at Apple → [FB11522275](https://github.com/feedback-assistant/reports/issues/360)

#### The widget does not update even if I do the above

The app tells iOS to update the widget, unfortunately, iOS can decide to delay an update for various reasons (low battery, low-power mode, etc). This is completely out of my control.

#### The widget does not update when setting the text with the Shortcuts action

This is unfortunately an iOS bug. The app correctly tells iOS to update the widget, but iOS delays it for some reason. The text will update eventually.

If you work at Apple → [FB11522170](https://github.com/feedback-assistant/reports/issues/359)

#### Can you make the widget bigger?

The widget sizes are controlled by Apple. The provided size is the largest it allows.

#### Can you make the widget background transparent

This is not possible.

#### Can you remove the title shown below the widget?

Apple does not allow removing the title. Some apps managed to do it early on, but these days, Apple rejects any attempt at doing that. However, in iOS 18 you can hide the title for all apps and widgets.

#### How can I remove the date prefix from the inline Lock Screen widget above the clock?

iOS forces the date to be shown. This is out of my control.

#### The inline Lock Screen widget above the clock does not respect my font choice

iOS forces the text to be the same style as the prefixed date. This is out of my control.

#### Can it open a specific app instead when tapping the widget?

Create a shortcut in the Shortcuts app that opens the app you want, then open “Any Text”, go to one of the widgets, open settings, and set the tap action to the shortcut you just made.

#### Can I prevent my child from editing the text when tapping the widget?

You can set the “Widget Tap Action” setting to “None”.

#### Can I edit the text directly from the Home Screen or Lock Screen?

No, widgets only support tapping interactions.

#### The Lock Screen widget does not show the text after restarting the device, before unlocking it

This is an iOS limitation and is out of my control. It shows a placeholder until the first unlock. This is how all Lock Screen widgets work.

#### When using the “Run Shortcut” action, why does tapping the widget first open the main app and then the Shortcuts app?

This is because of iOS limitations. A widget can only open its own app when a user taps it. And the only way to run a shortcut is to open the Shortcuts app using a special URL. So when you tap the widget, the widget opens the main app, and the main app then opens the Shortcuts app. It's not a very good user experience, but only Apple can fix this.

If you work at Apple, you know what to do:
- [FB9745173](https://github.com/feedback-assistant/reports/issues/240)
- [FB11516334](https://github.com/feedback-assistant/reports/issues/357)
- [FB11516273](https://github.com/feedback-assistant/reports/issues/356)

#### Can you localize the app into my language?

I don't plan to localize the app.

#### [More FAQs…](/apps/faq)

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
