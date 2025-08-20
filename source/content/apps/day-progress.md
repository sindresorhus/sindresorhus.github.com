---
title: Day Progress
subtitle: Time remaining today in your menu bar
pubDate: 2023-06-18
platforms:
  - macOS
isPaid: true
isMenuBarApp: true
appStoreId: 6450280202
# links:
#   'TestFlight': https://testflight.apple.com/join/mFx764Kp
olderMacOSVersions:
  - '13'
  - '14'
---

Use this as a visual cue to stay motivated and manage time more efficiently.

You can customize your day's start and end times per day, even allowing for a day's end past midnight, such as 2 AM.

You can set up multiple time ranges to run one after another throughout your day - the menu bar shows a single progress at a time. Perfect for tracking different parts of your day like work hours and personal time.

Choose between a progress pie or bar, showing percentage, remaining time, or minutes left.

## Tips

<!-- #### Time presets

You can use the Shortcuts app to make time presets. For example, you can make a shortcut that sets the day range to `13:00 - 18:00` and run it on the days where you want that range, and another shortcut to reset it back to the normal day range. [Example shortcut.](https://www.icloud.com/shortcuts/9636a1f2f0624aa787727afd306ff667)

#### Countdown from 8 hours when you decide

You can use a shortcut to make it count down 8 hours from when you decide. [Example shortcut.](https://www.icloud.com/shortcuts/39c8db30ce9d456bbbbdfcc8ba5eb136)

#### Make the day range be sunrise to sunset for the current location

Run [this shortcut](https://www.icloud.com/shortcuts/830746d544ce471cb1ff70b2f4de0e22) every day using [Shortery](https://apps.apple.com/app/id1594183810) and you will always have the correct sunrise and sunset times. -->

### Reminder about shortcuts

A shortcut can be run from the menu bar, using a global keyboard shortcut, from Spotlight, or from Raycast. You can even use [Shortery](https://apps.apple.com/us/app/shortery/id1594183810?mt=12) to make it run automatically, for example, when you change to the work focus.

### Hide the system clock {#hide-system-clock}

You could use Day Progress as an abstract clock instead of the system clock, to minimize anxiety and distraction from time, enhancing focus and productivity.

Unfortunately, it's not possible to fully hide the built-in menu bar clock. However, you could make it an analog clock, which makes it a lot less visible. In “System Settings › Control Center › Clock Options”, choose the analog clock and disable showing the date.

### Events

The [distributed notification](/apps/faq#distributed-notifications) `com.sindresorhus.Day-Progress.dayEnded` is emitted when a progress finishes.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Day%20Progress&referrer=Website-FAQ)

#### The app does not show up in the menu bar

[Try this](/apps/faq#app-not-showing-in-menu-bar)

#### Can you add widgets?

I plan to do that at some point.

#### Can you add support for iOS?

I plan to do that at some point.

#### Can you support more countdown ranges, like until the end of the week or a certain date?

There are already lots of apps for counting down to a specific date. I wanted to make something more unique. Also, the app name is “Day Progress”.

#### Can you support specifying different day range for different days of the week?

You can set up multiple schedules with different time ranges, both for different days and within the same day. Each time range runs its progress one after another in the menu bar. For even more flexibility with scheduling, check out the [tips](#tips) section for automation options using Shortcuts.

#### Does the app provide end-of-day notifications?

At this time, the app doesn't support this. Considering the wide-ranging user preferences of notifications, from system alerts to fullscreen notifications and differing "do not disturb" settings, I've opted to keep the app straightforward and not include notifications for now.

#### Can you add Pomodoro features?

This is outside the scope of the app. Day Progress is meant as a general day progress indicator, not a task timer. There are many dedicated Pomodoro apps available in the App Store.

#### Can it show a progress bar for how much time I have left in my life?

This is out of scope for this app, and there are existing apps for that already.

#### Can you localize the app into my language?

I do not plan to localize the app.

#### [More FAQs…](/apps/faq)

## Older Versions

- [1.4.0](https://github.com/user-attachments/files/18767518/Day.Progress.1.4.0.-.macOS.14.zip) for macOS 14
- [1.3.0](https://github.com/sindresorhus/meta/files/13979415/Day.Progress.1.3.0.-.macOS.13.zip) for macOS 13

These are free for everyone but they will not run on newer macOS versions.
