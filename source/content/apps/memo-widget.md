---
title: Memo Widget
subtitle: Sticky notes on your Home Screen, Lock Screen, and desktop
pubDate: 2023-12-16
platforms:
  - macOS
  - iOS
isPaid: true
appStoreId: 6465682248
forceHasIosAppIcon: true
---

The app provides widgets that act like sticky notes. Show them on your Home Screen, Lock Screen, StandBy, or desktop.

The app is simple by design.

For macOS, it's only available for Apple silicon Macs running macOS 15 or later.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Memo%20Widget&referrer=Website-FAQ)

#### How do I add the widget?

- [iOS](https://support.apple.com/HT207122)
- [macOS](https://support.apple.com/guide/mac-help/mchl52be5da5/mac)

#### The widget does not show up in the widget picker, the widget is stuck, or is missing from the Home Screen

The iOS widget system is quite buggy and can fail a lot. This is not a problem with the app and out of my control. [Try this.](https://webtrickz.com/third-party-lock-screen-widgets-not-showing-ios-16/)

#### Can you add more features and settings?

I'm happy to consider it, but I also want to keep the app simple. Check out my [Any Text app](/any-text), which has a lot more features.

#### Can you add a text size setting?

The text size is large for short text but scales down to make the text fit. I don't want to complicate it with a text size setting. If you really need it, check out [Any Text](/any-text).

#### Can you add a text color setting?

Same answer as the above.

#### Can I edit text directly in the widget?

No. Widgets cannot have interactivity like that. This is a macOS/iOS limitation.

#### How is this different from the built-in Stickies app on macOS? {#stickies}

The Stickies app is a normal app and has to either float on top of everything or it has to be manually brought to the front when needed. Memo Widget always lives on your desktop or in the Notification Center, just a [gesture away](https://www.howtogeek.com/678073/how-to-quickly-show-your-desktop-on-mac/). The Stickies app also takes up space in your Dock. The Stickies app supports formatting, while Memo Widget keeps it simple with just plain text.

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

#### The Lock Screen widget does not show the text after restarting the device, before unlocking it

This is an iOS limitation and is out of my control. It shows a placeholder until the first unlock. This is how all Lock Screen widgets work.

#### Can you add actions for Shortcuts?

I don't plan to add this. Check out my [Any Text app](/any-text), which has this.

#### Can you make the widget background transparent

This is not possible.

#### Can you support syncing the widget with iCloud?

Currently, there are no plans to integrate iCloud syncing due to its complexity and the potential for increased support queries.

#### How is this different from your [Any Text](/any-text) app?

Any Text has a lot of features and is very flexible. With this app, I wanted to make something simple and focused.

#### [More FAQs…](/apps/faq)
