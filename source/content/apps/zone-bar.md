---
title: Zone Bar
subtitle: World clocks in your menu bar
pubDate: 2025-11-20
platforms:
  - macOS
isPaid: true
isMenuBarApp: true
appStoreId: 6755328989
forceHasIosAppIcon: true
# olderMacOSVersions:
#   - '26'
---

Show multiple world clocks in your menu bar.

Add clocks for any time zone, give them custom names and emoji, and see them at a glance. The time travel slider lets you check what time it will be hours from now across all clocks. Useful for planning meetings or checking if friends abroad are awake.

Simple by design. No sync, no widgets, no iOS version. Just your clocks, always there when you need them.

*Requires macOS 26.1 or later.*

#### Highlights

- **Menu Bar Display**\
  Show up clocks directly in your menu bar
- **Time Travel**\
  Slide to see what time it will be hours from now across all time zones
- **Custom Labels**\
  Name each clock (“Tokyo Office”, “Mom”) and add emoji icons
- **Keyboard Shortcut**\
  Toggle the window with a global shortcut
- **Adjustable Text Size**\
  Make it comfortable to read

#### Privacy

Your shortcuts and data never leave your device. The app is built without internet permissions (no network entitlement), so macOS prevents it from connecting to the internet even if it wanted to.

## Tips

- Right-click a time zone to see more info and copy.
- The +1/−1 indicator shows when a time zone is in a different day.
- Press <kbd>⌘+</kbd> when the time zone window is open to quickly add a new time zone.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Zone%20Bar&referrer=Website-FAQ)

#### The app does not show up in the menu bar

[Try this](/apps/faq#app-not-showing-in-menu-bar)

#### Some world clocks are missing from the menu bar

Probably same as the above.

#### Can it show seconds?

No. This is a glanceable menu bar app. Seconds clutter the UI and have real performance costs in menu bar updates.

#### Can it show the UTC offset (e.g. UTC+8)?

No. I want to keep it minimal. The focus is on name and time. You can right-click a time zone to see it.

#### Does it work offline?

Yes. Everything runs locally, except the time zone search.

#### Does it handle summer / winter time (DST) correctly?

Yes. It follows macOS time zone rules, including daylight saving, so times update automatically. Unless you pick a fixed time zone like UTC+2.

#### I only see Chinese cities when adding a time zone. Where are London, San Francisco, etc.?

This is a [macOS bug](https://github.com/feedback-assistant/reports/issues/462) when when searching from China. You will have to pick a time zone manually using the `…` button.

#### Can you add half hour steps to the Time Travel slider?

No. It’s meant for quick, rough shifts. Smaller steps slow it down. If you need an exact offset, just adjust the minutes yourself.

#### Does the app use CPU constantly to keep the time updated? {#cpu}

No. It updates once per minute. Negligible.

#### Can it show analog clocks?

No. Digital only.

#### Can you reduce the space between menu bar clocks?

The spacing is controlled by the system, but you could use [Menu Bar Spacing](/menu-bar-spacing) to change it for all items.

#### Can you add sync?

No. iCloud sync is unreliable and causes a huge support burden. It's not worth the effort for this app.

#### Can you add widgets?

No. This is a simple menu bar app.

#### Can you support iOS?

No.

#### Can you add another menu bar icon option?

Sure! Find an icon you like in the [SF Symbols app](https://developer.apple.com/sf-symbols/) or [here](https://thenounproject.com/icons/), and send me the name or a link.

#### I already own [Dato](/dato). Does this offer any benefits over its similar feature? {#dato}

- More minimal
- Flag or emoji icons
- Custom text size

#### [More FAQs…](/apps/faq)

<!-- ## Older Versions

- []() for macOS 26+ -->
