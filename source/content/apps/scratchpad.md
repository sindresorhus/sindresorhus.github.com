---
title: Scratchpad
subtitle: Quick notes, always available
pubDate: 2024-08-30
platforms:
  - macOS
  - iOS
  - visionOS
  # - watchOS
# isPaid: true TODO
isMenuBarApp: true
appStoreId: 6504040051
# olderMacOSVersions:
#   - '14'
---

Capture your thoughts instantly in a single, always-accessible note.

Plain text only. Simple by design.

On macOS, the app sits in your menu bar or Dock, ready whenever inspiration strikes. On iOS, it can be accessed from the Home Screen (and soon the Lock Screen and Control Center).

- One-tap access
- Clean, distraction-free interface
- Lightning-fast and lightweight
- Sync with iCloud, or not
- Custom hotkey for instant writing <sup>(macOS)</sup>
- Translucent background <sup>(macOS)</sup>

Perfect for brain dumps, quick drafts, and fleeting ideas. Your thoughts are just a click away, without breaking your workflow.

**watchOS version is planned later this year.**

#### Privacy

The app uses iCloud syncing to securely sync your text across devices. This feature is opt-in. Neither the app developer nor Apple can access the text in your scratchpad. The app does not collect any personal data and contains no tracking.

### Tips

#### Troubleshoot syncing {#troubleshooting}

- Ensure iCloud sync is enabled in the Scratchpad settings on all devices you wish to sync.
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

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Scratchpad&referrer=Website-FAQ)

#### The macOS app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some other menu bar apps to free up space. If this does not solve it, try quitting Bartender if you have it installed.

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

#### Why is my note not syncing between devices?

Refer to the [troubleshooting section](#troubleshooting) above to resolve syncing issues.

#### The text sometimes jumps when I write fast

This is a macOS bug. There is unfortunately nothing I can do about it.

#### How can I toggle “Stay on Top” with a keyboard shortcut in the macOS app?

The keyboard shortcut is listed in the “…” menu.

#### Can you add a font and color setting?

I don't plan to add that. It's not essential and I'm trying to keep the app simple.

#### Why is it suddenly showing a scrollbar in the macOS app?

You either have a system setting set to always show scrollbars or you have an external mouse connected. This is simply how macOS works. You can see the behavior in other text editing apps too. See the “Appearance › Show scroll bars” system setting.

#### Why is there no way to print?

The app is made using Apple's latest technologies (SwiftUI) and they have not added print support there yet. If you need to print, copy-paste the text over to the TextEdit instead.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### [More FAQs…](/apps/faq)

<!-- ### Older Versions

- [1.0.0]() for macOS 14+ -->

### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/c9yck1mydyytvkz8rk5dr/Scratchpad-1.0.3-1725305281.zip?rlkey=dfy3q9f3vuvo4q9kgbih7nke5&raw=1) *(1.0.3)*

*Requires macOS 14 or later*
