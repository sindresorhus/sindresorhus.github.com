---
title: Favorites Widget
subtitle: Contacts on your Lock Screen and Home Screen
date: 2022-09-12
platforms:
  - iOS
  # - macOS (Apple silicon)
appStoreId: 1643660089
---

Call or message your favorite people directly from the Lock Screen or Home Screen.

You can also open a URL or run a shortcut instead when tapping the widget. This opens up a lot of cool possibilities. Here are [some ideas](https://github.com/bhagyas/app-urls) of what you could open.

*iPhone-only for now. iPad version will come when iPadOS supports Lock Screen widgets (probably iPadOS 17).*

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Favorites%20Widget&referrer=Website-FAQ)

#### How do I add the widget to the Lock Screen?

When on the Lock Screen, tap and hold on the clock, tap the “Customize” button, and select “Favorites”.

[Learn more](https://support.apple.com/en-gb/guide/iphone/iph4d0e6c351/ios#iph0ee454f4c)

#### How do I add the widget to the Home Screen?

When on the Home Screen, tap and hold on the background (not on any icons), tap the top-left “+” button, and select “Favorites”.

[Learn more](https://support.apple.com/en-us/HT207122)

#### The widget does not show up in the widget picker

This is a well known iOS 16 issue. [Try this.](https://webtrickz.com/third-party-lock-screen-widgets-not-showing-ios-16/)

#### Can I call someone by just tapping the widget without the confirmation dialog?

Yes. Enable the “Quick Call” setting in the app.

#### Can the Lock Screen photos be full-colored?

This is unfortunately not possible. iOS enforces that Lock Screen widgets are single-colored.

#### Can you support more actions when tapping a widget?

Sure. I'm happy to consider requests. [Send it here.](https://sindresorhus.com/feedback?product=Favorites%20Widget&referrer=Website-FAQ)

#### When using the “Run Shortcut” action, why does tapping the widget first open the main app and then the Shortcuts app?

This is because of iOS limitations. A widget can only open its own app when a user taps it. And the only way to run a shortcut is to open the Shortcuts app using a special URL. So when you tap the widget, the widget opens the main app, and the main app then opens the Shortcuts app. It's not a very good user-experience, but only Apple can fix this.

If you work at Apple, you know what to do:
- [FB9745173](https://github.com/feedback-assistant/reports/issues/240)
- [FB11516334](https://github.com/feedback-assistant/reports/issues/357)
- [FB11516273](https://github.com/feedback-assistant/reports/issues/356)

#### Why is this free without ads?

I just enjoy making apps. I earn money on other apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1643660089) and click “Version History”.
