---
title: Any Text
subtitle: Put text on your Lock Screen, Home Screen, and desktop
pubDate: 2022-09-12
platforms:
  - macOS
  - iOS
appStoreId: 1643199620
forceHasIosAppIcon: true
---

The app provides widgets where you can write any kind of text. It could be an important note, your goal, a list of tasks, etc.

For macOS, it's only available for Apple silicon Macs running macOS 14 or later.

<br>

*You may also like [my similar app](https://sindresorhus.com/one-thing) for macOS.*

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Any%20Text&referrer=Website-FAQ)

#### How do I add the widget?

- [iOS](https://support.apple.com/en-us/HT207122)
- [macOS](https://support.apple.com/en-gb/guide/mac-help/mchl52be5da5/mac)

#### The widget does not show up in the widget picker

This is a iOS issue. [Try this.](https://webtrickz.com/third-party-lock-screen-widgets-not-showing-ios-16/)

#### Can you support having multiple pieces of text that change during the day?

I would like to keep the app simple, so it's not something I plan to support built-in. However, the app comes with a shortcut action to change the text, so you could use the [Shortcuts automations](https://support.apple.com/en-gb/guide/shortcuts/apdfbdbd7123/7.0/ios/17.0) to change the text during the day.

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

This is unfortunately an iOS 16 bug. The app correctly tells iOS to update the widget, but iOS delays it for some reason. The text will update eventually.

If you work at Apple → [FB11522170](https://github.com/feedback-assistant/reports/issues/359)

#### Can you make the widget bigger?

The widget sizes are controlled by Apple. The provided size is the largest it allows.

#### Can you remove the title shown below the widget?

Apple does not allow removing the title. Some apps managed to do it early on, but these days, Apple rejects any attempt at doing that.

#### How can I remove the date prefix from the inline Lock Screen widget above the clock?

iOS forces the date to be shown. This is out of my control.

#### The inline Lock Screen widget above the clock does not respect my font choice

iOS forces the text to be the same style as the prefixed date. This is out of my control.

#### Can it open a specific app instead when tapping the widget?

Create a shortcut in the Shortcuts app that opens the app you want, then open “Any Text”, go to one of the widgets, open settings, and set the tap action to the shortcut you just made.

#### Can I prevent my child from editing the text when tapping the widget?

You can set the “Widget Tap Action” setting to “None”.

#### The Lock Screen widget does not show the text after restarting the device, before unlocking it

This is an iOS limitation and is out of my control. It shows a placeholder until the first unlock. This is how all Lock Screen widgets work.

#### Can you support syncing the text with iCloud?

Currently, there are no plans to integrate iCloud syncing due to its complexity and the potential for increased support queries.

#### When using the “Run Shortcut” action, why does tapping the widget first open the main app and then the Shortcuts app?

This is because of iOS limitations. A widget can only open its own app when a user taps it. And the only way to run a shortcut is to open the Shortcuts app using a special URL. So when you tap the widget, the widget opens the main app, and the main app then opens the Shortcuts app. It's not a very good user experience, but only Apple can fix this.

If you work at Apple, you know what to do:
- [FB9745173](https://github.com/feedback-assistant/reports/issues/240)
- [FB11516334](https://github.com/feedback-assistant/reports/issues/357)
- [FB11516273](https://github.com/feedback-assistant/reports/issues/356)

#### Why is this free without ads?

I just enjoy making apps. I earn money on other apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1643199620) and click “Version History”.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### [More FAQs…](/apps/faq)
