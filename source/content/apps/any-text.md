---
title: Any Text
subtitle: Put text on your Lock Screen and Home Screen
pubDate: 2022-09-12
platforms:
  - iOS
appStoreId: 1643199620
---

The app provides Lock Screen and Home Screen widgets where you can write any kind of text. It could be an important note, your goal, a list of tasks, etc.

*iPad supports the Home Screen widgets but not Lock Screen widgets.*

**You may also like [my similar app](https://sindresorhus.com/one-thing) for macOS.**

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Any%20Text&referrer=Website-FAQ)

#### How do I add the widget to the Lock Screen?

When on the Lock Screen, tap and hold on the clock, tap the “Customize” button, and select “Any Text”.

[Learn more](https://support.apple.com/en-gb/guide/iphone/iph4d0e6c351/ios#iph0ee454f4c)

#### How do I add the widget to the Home Screen?

When on the Home Screen, tap and hold on the background (not on any icons), tap the top-left “+” button, and select “Favorites”.

[Learn more](https://support.apple.com/en-us/HT207122)

#### The widget does not show up in the widget picker

This is a well-known iOS 16 issue. [Try this.](https://webtrickz.com/third-party-lock-screen-widgets-not-showing-ios-16/)

#### Can you support having multiple pieces of text that change during the day?

I would like to keep the app simple and only support one piece of text. It's kinda in the app name. However, the app comes with a shortcut action to change the text, so you could use the Shortcuts automations to change the text during the day.

#### Can you add support for user-installed fonts?

This is unfortunately not possible as widgets cannot access user-installed fonts.

#### Can I make the widget horizontally centered on the Lock Screen?

This is unfortunately not possible. Apple has decided that the rectangular widget can only appear on the left or right side.

#### Can I pick a color for the text?

Lock Screen widgets cannot have colors. I don't plan to support this for the Home Screen widgets as I would like to keep the app simple.

#### Can I pick a background color for the widget?

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

The widget sizes are controlled by iOS. The provided size is the largest it allows.

#### How can I remove the date prefix from the inline Lock Screen widget above the clock?

iOS forces the date to be shown. This is out of my control.

#### The inline Lock Screen widget above the clock does not respect my font choice

iOS forces the text to be the same style as the prefixed date. This is out of my control.

#### Can it open a specific app instead when tapping the widget?

Create a shortcut in the Shortcuts app that opens the app you want, then open “Any Text”, go to one of the widgets, open settings, and set the tap action to the shortcut you just made.

#### Can it do nothing when tapping the widget?

iOS always opens the main app when you tap a widget. This is not something the app can control.

#### Can I prevent my child from editing the text when tapping the widget?

You can set the “Widget Tap Action” setting to run a [shortcut](https://support.apple.com/en-sg/guide/shortcuts/welcome/ios) with the “Go to Home Screen” action.

#### The Lock Screen widget does not show the text after restarting the device, before unlocking it

This is an iOS limitation and is out of my control. It shows a placeholder until the first unlock. This is how all Lock Screen widgets work.

#### Can you support syncing the text with iCloud?

I don't plan to support that. iCloud is consistently unreliable and I don't want to increase my support burden.

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
