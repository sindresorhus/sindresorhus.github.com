---
title: Scratchpad
subtitle: Quick notes, always available
pubDate: 2024-08-30
platforms:
  - macOS
  - iOS
  - visionOS
  # - watchOS
isPaid: true
isMenuBarApp: true
appStoreId: 6504040051
# olderMacOSVersions:
#   - '14'
feedbackNote: |
  If Scratchpad on macOS is freezing for you, update to 1.2.3.
  If you are having problems with sync, [read this](/scratchpad#troubleshooting).
---

Capture your thoughts instantly in a single, always-accessible note.

Plain text only. Simple by design.

On macOS, the app sits in your menu bar or Dock, ready whenever inspiration strikes. On iOS, it can be accessed from the Home Screen and Lock Screen (and soon Control Center).

- One-tap access
- Clean, distraction-free interface
- Lightning-fast and lightweight
- Sync with iCloud, or not
- Custom hotkey for instant writing <sup>(macOS)</sup>
- Translucent background <sup>(macOS)</sup>
- Font settings

Perfect for brain dumps, quick drafts, and fleeting ideas. Your thoughts are just a click away, without breaking your workflow.

**watchOS version is planned later this year.**

<a href="https://www.producthunt.com/posts/scratchpad-3?embed=true&utm_source=badge-top-post-badge&utm_medium=badge&utm_souce=badge-scratchpad&#0045;3" target="_blank"><img src="https://api.producthunt.com/widgets/embed-image/v1/top-post-badge.svg?post_id=486333&theme=light&period=daily" alt="Scratchpad - Quick&#0032;notes&#0044;&#0032;always&#0032;available | Product Hunt" style="width: 250px; height: 54px;" width="250" height="54" /></a>

#### Privacy

The app uses iCloud syncing to securely sync your text across devices. This feature is opt-in. Neither the app developer nor Apple can access the text in your scratchpad. The app does not collect any personal data and contains no tracking.

### Trial

Try the fully functional trial of the macOS app [here](https://www.dropbox.com/scl/fi/zi90gxtzcs1rcwwx9gma5/Scratchpad-1.2.5-trial-1728417955.zip?rlkey=wzbonsxmafel1v1wzbqbbzqlw&raw=1). The only limitation is a reminder to buy the app every 12 hours, and no automatic updates. All data and settings carry over if you buy it on the App Store.

### Tips

#### Troubleshoot syncing {#troubleshooting}

- Ensure iCloud sync is enabled in the Scratchpad settings on all devices you wish to sync.
- After enabling sync, try writing some more text on all the devices.
- The initial sync may take a while.
- Ensure all devices are signed into the same iCloud account.
- Ensure all devices are online.
- Try restarting all devices.
- Ensure Low Power Mode is not enabled on the devices. It can cause iCloud to delay syncing.
- Resolve any Apple ID or iCloud errors on your devices (e.g., sign-in prompts).
- Ensure your iCloud storage is not full.
- On iOS, ensure Scratchpad is enabled in “Settings › Apple ID › iCloud › Apps Using iCloud”.
- On macOS, ensure Scratchpad is enabled in “System Settings › Apple ID › iCloud › iCloud Drive › Apps syncing to iCloud Drive”.
- Ensure you are on the latest operating system version and Scratchpad version.
- If it's a work device, make sure there are no restrictions in place that prevents iCloud or iCloud Drive.
- If using a VPN, try disconnecting it, as some VPNs can interfere with iCloud syncing.
- Check the [iCloud system status](https://www.apple.com/support/systemstatus/) to ensure the service is not experiencing issues.

#### Launch app from Lock Screen

Quickly open the app using the built-in Lock Screen widget. For more customization options, you can also use my [Quick Launch](/quick-launch) app.

#### Quickly add text to the scratchpad

1. macOS: Select some text in any app, right-click, and select “Services › Add to Scratchpad” or “Share › Add to Scratchpad”.
1. Use the [Shortcuts action](#scripting)
1. Use the [custom URL scheme](#scripting)

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Scratchpad&referrer=Website-FAQ)

#### The macOS app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some other menu bar apps to free up space. If this does not solve it, try quitting Bartender/Ice if you have it installed.

You may also have disabled the “Show menu bar icon” setting, which hides the menu bar icon. Launch the app again to show the main window.

#### Why is my note not syncing between devices?

Refer to the [troubleshooting section](#troubleshooting) above to resolve syncing issues.

#### Can you add Markdown syntax highlighting?

I don't plan to add that as I want to keep the app simple. I do plan to make a proper minimal Markdown editor at some point, but that's not this app.

#### Does the app support text formatting?

No, it supports plain text only.

#### Can I add images to the note?

No, it supports plain text only.

#### Does the app support multiple notes?

No, it is designed for a single, persistent note. You could try out my [Plain Text Editor](/plain-text-editor) app for this, which can open multiple files. Also check out [Tot](https://tot.rocks) (not mine, but good).

#### Can I open and save an external file?

No, see my [Plain Text Editor](/plain-text-editor) app for that.

#### Does it support [Advanced Data Protection for iCloud](https://support.apple.com/en-us/102651)?

Yes. The app stores the note in iCloud Drive, which is covered by Advanced Data Protection.

#### Why doesn’t the app appear in my Dock?

By default, it only appears in the menu bar. You can enable the Dock icon in the settings.

#### Can it show the text in a widget?

No, but check out my [Any Text](/any-text) app for that.

#### Can it show the text in the macOS menu bar?

No, but check out my [One Thing](/one-thing) app for that.

#### The text sometimes jumps when I write fast

This is a macOS bug. There is unfortunately nothing I can do about it.

#### How can I toggle “Stay on Top” with a keyboard shortcut in the macOS app?

The keyboard shortcut is listed in the “…” menu.

#### Can you add a color setting?

I don't plan to add that. It's not essential and I'm trying to keep the app simple.

#### Why is it suddenly showing a scrollbar in the macOS app?

You either have a system setting set to always show scrollbars or you have an external mouse connected. This is simply how macOS works. You can see the behavior in other text editing apps too. See the “Appearance › Show scroll bars” system setting.

#### Why is there no way to print?

The app is made using Apple's latest technologies (SwiftUI) and they have not added print support there yet. If you need to print, copy-paste the text over to the TextEdit instead.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### How does this compare to [Tot](https://tot.rocks)? {#tot}

Scratchpad advantages:

- Simpler, focused design: A single plain text note for minimal distraction.
- Can float on top of other windows.
- iCloud sync is optional. Tot does not have a setting to turn off iCloud sync.
- More affordable pricing: $2 vs $20 for Tot.
- visionOS support.
- Unlimited note size. Tot is limited to 100,000 characters.
- Translucent background on macOS.

Tot advantages:

- Supports 7 notes.
- Rich-text support.
- More mature.
- Available for watchOS. *(Scratchpad will have a watchOS app soon)*

#### [More FAQs…](/apps/faq)

### Scripting

The app can be automated using the Shortcuts app or with a custom URL scheme.

<!-- More integrations:

- [Command-line tool](https://github.com/sindresorhus/one-thing)
- [Node.js API](https://github.com/sindresorhus/one-thing)
 -->
#### Shortcuts app

- [Shortcuts usage guide](https://www.xda-developers.com/guide-shortcuts-macos/)
- [How to run shortcuts from the command-line on macOS](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac)

**Examples**

- [*Tell me if you have done anything cool with scripting*](https://sindresorhus.com/feedback?product=Scratchpad&referrer=Website-FAQ)

#### Custom URL scheme

You can add text to the scratchpad from any tool that can open an URL. This includes a website, Bash, Node.js, Python, Swift, etc.

For example, in your terminal:

```sh
open --background 'scratchpad:append?text=Hello'
```

By default, the app window shows when this is run. On macOS, you can tell it to not show with the `hide` search parameter:

```sh
open --background 'scratchpad:append?text=Hello&hide'
```

You can also prepend:

```sh
open --background 'scratchpad:prepend?text=Hello'
```

*Don't forget to [URL encode](https://www.urlencoder.org) the value for the `text=` search parameter. For example, using [this](https://gist.github.com/cdown/1163649) Bash function.*

You can also use the custom URL scheme on iOS.

There is no way to get the text using the URL scheme, but you can use Shortcuts for that.

I have not included a way to overwrite the text because I don't want anything to be able to overwrite the scratchpad. If you want this, [tell me your use-case](https://sindresorhus.com/feedback?product=Scratchpad&referrer=Website-FAQ). I may add this with an opt-in setting. For now, you can do it with Shortcuts.

<!-- ### Older Versions

- [1.0.0]() for macOS 14+ -->

<!-- ### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/c9yck1mydyytvkz8rk5dr/Scratchpad-1.0.3-1725305281.zip?rlkey=dfy3q9f3vuvo4q9kgbih7nke5&raw=1) *(1.0.3)*

*Requires macOS 14 or later*
 -->
