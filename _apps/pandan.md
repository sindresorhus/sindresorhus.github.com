---
title: Pandan
subtitle: Time awareness in your menu bar
date: 2021-05-31
platforms:
  - macOS
app_store_app_id: 1569600264
mac_app_store_url: https://apps.apple.com/app/id1569600264
---

### Older versions

- [Last macOS 11 compatible version](https://github.com/sindresorhus/meta/files/8003835/Pandan.1.9.1.-.macOS.11.zip) *(1.9.1)*

<br>

<h3 id="scripting">Scripting</h3>

Pandan comes bundled with actions for the built-in Shortcuts app which you can use to automate Pandan.

Tip: You can [run shortcuts from the command-line](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac).

<br>

<h3 id="faq">Frequently Asked Questions</h3>

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback/?product=Pandan&referrer=Website-FAQ)

#### Can you make the history be further back than 60 days?

The history is intentionally limited. Pandan is about time awareness right now, not analyzing past behavior. If you need more stats and graphs, check out the system [Screen Time](https://support.apple.com/en-gb/HT210387) feature.

#### Can you make the app available on iOS too?

This is unfortunately not possible as iOS does not let an app continuously check whether the user is idle.

#### How can I play a custom sound as a notification?

Make a [shortcut](https://support.apple.com/guide/shortcuts-mac/intro-to-shortcuts-apdf22b0444c/mac) that uses the [`Play Sound` action](https://www.icloud.com/shortcuts/9cfae8edd2dd48f3bf318a3d825b1212) and then select that shortcut in the Pandan preferences.

If you have my [Dato app](https://sindresorhus.com/dato) installed (even the free trial), you could use one of the sounds it provides. Find the `Get Sound` action.

#### How can I show an alert as a notification?

Same as the above, but use the `Show Alert` action instead.

#### How can I start a new session from the command-line?

Make a [shortcut](https://support.apple.com/guide/shortcuts-mac/intro-to-shortcuts-apdf22b0444c/mac) that uses the `New Session` action and [run that shortcut from the command-line](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac).

Tip: Shortcuts can be a bit slow sometimes. You can use this command to have it not wait for the shortcut to finish running: `(&>/dev/null shortcuts run ShortcutName &)`

#### Why is this free without ads?

I just enjoy making Mac apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1569600264) and click “Version History”.

#### Can you localize the app into my language?

I don't have any immediate plans to localize the app.
