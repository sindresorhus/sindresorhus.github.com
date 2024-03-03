---
title: Pandan
subtitle: Time awareness in your menu bar
pubDate: 2021-05-31
platforms:
  - macOS
isMenuBarApp: true
appStoreId: 1569600264
olderMacOSVersions:
  - '11'
  - '12'
  - '13'
---

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Pandan&referrer=Website-FAQ)

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some other menu bar apps to free up space. If this does not solve it, try quitting Bartender if you have it installed.

#### Can you make the history be further back than 120 days?

The history is intentionally limited. Pandan is about time awareness right now, not analyzing past behavior. If you need more stats and graphs, check out the system [Screen Time](https://support.apple.com/en-gb/HT210387) feature.

#### Can you make the app available on iOS too?

This is unfortunately not possible as iOS does not let an app continuously check whether the user is idle.

#### How can I play a custom sound as a notification? {#custom-notification-sound}

Make a [shortcut](https://support.apple.com/guide/shortcuts-mac/intro-to-shortcuts-apdf22b0444c/mac) that uses the [`Play Sound` action](https://www.icloud.com/shortcuts/9cfae8edd2dd48f3bf318a3d825b1212) and then select that shortcut in the Pandan settings.

If you have my [Dato app](https://sindresorhus.com/dato) installed (even the free trial), you could use one of the sounds it provides. Find the `Get Sound` action. [Example](https://www.icloud.com/shortcuts/2bf58f1c90134803a4765745f54794f6)

#### How can I show an alert as a notification? {#alert-as-notification}

Same as the above, but use the `Show Alert` action instead.

You could also use the “Flash Screen” action from the [Actions app](https://github.com/sindresorhus/Actions) to momentarily flash the screen.

#### How can I run multiple shortcuts as a notification?

Pandan lets you run a single shortcut as a notification, but a shortcut can run other shortcuts. So make the shortcuts you want to run, make another shortcut that uses the “Run Shortcut” action to run the other shortcuts, and then select this shortcut in Pandan.

#### How can I use this as an eye-break reminder? {#eye-break-reminder}

Set Pandan to remind you to take a break. Make a shortcut in the Shortcuts app that uses the “Wait” action and set it to the wanted duration of the break. After this action, you can either add a “Play Sound” or “Show Alert” action to notify you when the break is done. Then select this shortcut in the Pandan settings.

#### How can I disable Pandan while using certain apps? {#disable-for-certain-apps}

You can use the Shortcuts app for this. Make a shortcut that uses the “Set Enabled State” action that Pandan provides. To automate running this shortcut when certain apps are active, you will need the [Shortery](https://apps.apple.com/us/app/shortery/id1594183810) app. In the Shortery app, choose the “Application” trigger type, and then the “Active” or “Inactive” option.

*Note that Pandan already disables itself when you are inactive.*

#### How can I show the total active duration today as a countdown? {#countdown}

Get [this shortcut](https://www.icloud.com/shortcuts/fdf0cd45fedb4290bfe14d84a394b601) (requires the [Actions](https://sindresorhus.com/actions) and [One Thing](https://sindresorhus.com/one-thing) apps) and select it in the Pandan settings. The countdown will update every time Pandan shows a notification. If you want the countdown to update more often, you will need to download the [Shortery](https://apps.apple.com/us/app/shortery/id1594183810) app and set up an interval trigger.

#### How can I start a new session from the command-line?

Make a [shortcut](https://support.apple.com/guide/shortcuts-mac/intro-to-shortcuts-apdf22b0444c/mac) that uses the `New Session` action and [run that shortcut from the command-line](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac).

Tip: Shortcuts can be a bit slow sometimes. You can use this command to have it not wait for the shortcut to finish running: `(&>/dev/null shortcuts run ShortcutName &)`

#### How can I export, import, sync, or back up the settings?

[See this guide.](https://github.com/sindresorhus/guides/blob/main/backup-app-settings.md)

#### Why is this free without ads?

I just enjoy making apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1569600264) and click “Version History”.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### [More FAQs…](/apps/faq)

<br>

### Scripting

Pandan comes bundled with actions for the built-in Shortcuts app which you can use to automate Pandan.

Tip: You can [run shortcuts from the command-line](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac).

#### Use-cases {#shortcuts-use-cases}

- [Play custom notification sound](#custom-notification-sound)
- [Use Pandan as an eye break reminder](#eye-break-reminder)
- [Show an alert as a notification](#alert-as-notification)
- Flash the screen as a notification by using the “Flash Screen” action from the [Actions app](https://github.com/sindresorhus/Actions)
- [Show a web page as a notification](https://www.icloud.com/shortcuts/0e3914da016b446dbf2fef7aa0341567)
- [Lock the screen as a notification](https://www.icloud.com/shortcuts/a3aa4ba2640d4f1b97c85f498e9dd945)
- [Invert the screen for 20 seconds](https://www.icloud.com/shortcuts/0710b22b12b74ec1bad0f28b327412fd)
- [Make the screen gray for 20 seconds](https://www.icloud.com/shortcuts/dbdeea0a9a8b41749fa27f15cf3eb6c2)
- [Show the total active duration today as a countdown](#countdown)

*And you can combine these too.*

<br>

### Older Versions

- [1.15.0](https://github.com/sindresorhus/meta/files/14230031/Pandan.1.15.0.-.macOS.13.zip) for macOS 13+
- [1.13.2](https://github.com/sindresorhus/meta/files/11072195/Pandan.1.13.2.-.macOS.12.zip) for macOS 12+
- [1.9.1](https://github.com/sindresorhus/meta/files/8003835/Pandan.1.9.1.-.macOS.11.zip) for macOS 11+

<br>

### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/hlvorsw06mvf832dt2e3q/Pandan-1.16.0-1707587381.zip?rlkey=r2xffuz4jietc7p0jagtrt7r4&raw=1) *(1.16.0)*

*Requires macOS 14 or later*
