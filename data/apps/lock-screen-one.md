---
title: Lock Screen One
subtitle: Put any text on the Lock Screen
date: 2022-09-12
platforms:
  - iOS
appStoreId: 1643199620
---

The app provides Lock Screen widgets where you can write any kind of text. It could be an important note, your goal, a list of tasks, etc.

*iPhone-only for now. iPad version will come later this year.*

**You may also like [my similar app](https://sindresorhus.com/one-thing) for macOS.**

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Lock%20Screen%20One&referrer=Website-FAQ)

#### How do I add the widget to the Lock Screen?

When on the Lock Screen, tap and hold on the clock, tap the “Customize” button, and select “Lock Screen One”.

[Learn more](https://support.apple.com/en-gb/guide/iphone/iph4d0e6c351/ios#iph0ee454f4c)

#### The widget does not show up in the widget picker

This is a well known iOS 16 issue. [Try this.](https://webtrickz.com/third-party-lock-screen-widgets-not-showing-ios-16/)

#### Can you support having multiple pieces of text that change during the day?

I would like to keep the app simple and only support one piece of text. It's kinda in the app name. However, the app comes with a shortcut action to change the text, so you could use the Shortcuts automations to change the text during the day.

#### Can you add support user-installed fonts?

This is unfortunately not possible as widgets cannot access user-installed fonts.

#### The widget does not update if I write some text in the app and then reveal the Lock Screen

You need to first close the app. This is a iOS bug.

If you work at Apple → [FB11522275](https://github.com/feedback-assistant/reports/issues/360)

#### The widget does not update when setting the text with the Shortcuts action

This is unfortunatly a iOS 16 bug. The app correctly tells iOS to update the widget, but iOS delays it for some reason. The text will update eventually.

If you work at Apple → [FB11522170](https://github.com/feedback-assistant/reports/issues/359)

#### Can you make the widget bigger?

The widget size is controlled by iOS. This is the largest size it allows.

#### How can I remove the date prefix from the inline widget above the clock?

iOS forces the date to be shown. This is out of my control.

#### The inline widget above the clock does not respect my font choice

iOS forces the text to be the same style as the prefixed date. This is out of my control.

#### Can it open a specific app instead when tapping the widget?

Create a shortcut in the Shortcuts app that opens the app you want, then open “Lock Screen One”, go to one of the widgets, open settings, and set the tap action to the shortcut you just made.

#### Can it do nothing when tapping the widget?

iOS always opens the main app when you tap a widget. This is not something the app can control.

#### Why is this free without ads?

I just enjoy making apps. I earn money on other apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1643199620) and click “Version History”.
