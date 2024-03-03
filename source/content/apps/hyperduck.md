---
title: Hyperduck
subtitle: Send links from your iOS/visionOS devices to your Mac
pubDate: 2023-01-27
platforms:
  - macOS
  - iOS
  - visionOS
appStoreId: 6444667067
olderMacOSVersions:
  - '13'
---

For example, share a link from Safari on your iPhone, iPad, or Apple Vision Pro, and have it open in the default browser on your Mac moments later.

You can send a link even if your iOS/visionOS device and/or Mac is offline. The link will be sent and received the next time the devices are online. The link will never be lost.

My personal use-case is that I often discover cool stuff when I check Twitter on the go and I want to dig deeper into it later on my Mac. I have tried Instapaper, Pocket, Safari Reading List, iCloud Tabs, and more. The problem with them all is that I forget to check them.

[**Why not AirDrop?**](#airdrop)

[Review by MacStories](https://www.macstories.net/reviews/automation-april-hyperduck-leverages-the-power-of-url-schemes-to-control-your-mac-from-an-iphone-or-ipad/)

#### Privacy

The app uses iCloud syncing to securely send links from your iOS/visionOS device to your Mac. The app developer will not see the links you share. The app does not collect any personal data and does not have any tracking.

<br>

### Troubleshooting

- Try restarting both devices.
- Try opening the Hyperduck iOS app to force a sync.
- Ensure you are on the latest operating system version.
- Ensure both devices are signed into the same iCloud account.
- Ensure both devices are online.
- Ensure Hyperduck is running on the Mac.
- Hyperduck opens links in the background. Ensure you didn't miss it.
- Ensure Low Power Mode is not enabled on the devices. It can cause iCloud to delay syncing.
- On iOS, ensure Hyperduck is enabled in “Settings › Apple ID › iCloud › Apps Using iCloud”.
- On macOS, ensure Hyperduck is enabled in “System Settings › Apple ID › iCloud › iCloud Drive › Apps syncing to iCloud Drive”.
- If it's a work device, make sure there are no restrictions in place that prevents iCloud or iCloud Drive.
- If you are using a VPN, try disconnecting it. Some VPNs prevent iCloud from syncing.
- Make sure the [iCloud service](https://www.apple.com/support/systemstatus/) is not currently experiencing issues.
- In the iOS app, if you triple-tap the text, it will show the most recently shared URLs, which may aid debugging.

<br>

### Tips

#### Run shortcuts {#shortcuts}

You can use this app to trigger [shortcuts](https://support.apple.com/en-gb/guide/shortcuts/welcome/ios) on your Mac from your iOS devices. This enables a lot of powerful use-cases. For example, you could make your Mac play a specific song directly from your iPhone.

First, create a shortcut on your Mac with some actions. Let's call it `Unicorn`.

On your iOS device, make a new shortcut, add the “Run Shortcut on Mac” action, and write `Unicorn` in the shortcut field.

You can now run this shortcut on your iOS device to trigger the `Unicorn` shortcut on your Mac.

[Learn more](https://www.macstories.net/reviews/automation-april-hyperduck-leverages-the-power-of-url-schemes-to-control-your-mac-from-an-iphone-or-ipad/) in the Hyperduck review by MacStories.

#### Shut down Mac

You can use the Shortcuts support mentioned above to shut down your computer remotely from your iOS device. Just follow the above steps and use the “Shut Down” action (requires macOS 13.3) in the Shortcuts app or the AppleScript action with the following: `tell app "System Events" to shut down`.

#### Trigger Raycast deeplinks {#raycast}

Similar to the above, we can use a [Raycast deeplink](https://manual.raycast.com/deeplinks).

For example, on your iOS device, make a new shortcut, add the “Send URLs to Mac” action, and in the URL field, write:

```
raycast://confetti
```

You can now trigger confetti to show up on your Mac from your iPhone.

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Hyperduck&referrer=Website-FAQ)

#### How is it better than AirDrop? {#airdrop}

- Works when your Mac is turned off
- Works when you are not near your Mac
- Much faster
- Opens links on your Mac in the background
- AirDrop sometimes refuses to work; this always works.

#### How is it better than iCloud Tabs? {#icloud-tabs}

- Works in any app with a share sheet, not just Safari
- Links are opened as tabs in your browser so you cannot miss them
- No need to spend time looking for the link in a long list of links
- Supports any browser on your Mac
- You don't need to keep the tab open on your iOS device for it to be available on your Mac

#### How is it better than Safari Tab Groups? {#safari-tab-groups}

- Works in any app with a share sheet, not just Safari
- Supports any browser on your Mac
- You don't need to keep the tab open on your iOS device for it to be available on your Mac

#### How is it better than Safari Reading List? {#safari-reading-list}

- Links are opened right in your browser so you cannot miss them
- No need to spend time looking for the link in a long list of links
- Supports any browser on your Mac

#### How is it better than remembering the URL and typing it out on your Mac?

- Works with every human
- Does not strain fingers and brain

#### How is it better than Handoff? {#handoff}

- Works in any app with a share sheet, not just a browser
- Works when your Mac is turned off
- Works when you are not near your Mac
- Supports any browser on your Mac
- Opens links on your Mac in the background
- The link opens automatically. Handoff requires clicking the Dock icon to open it.
- Handoff sometimes refuses to work. This always works.

#### How is it better than [Universal Clipboard](https://support.apple.com/en-us/HT209460)? {#universal-clipboard}

- No need to manually paste the link into the browser after copying it on your iOS device
- Works when your Mac is turned off
- Works when you are not near your Mac
- Much faster

#### How is it better than sending yourself links with iMessage? {#imessage}

- Links are opened right in your browser so you cannot miss them (it's easy to forget to check iMessage)
- Opens links on your Mac in the background

#### How is it better than sending yourself links with email? {#email}

- Links are opened right in your browser so you cannot miss them (it's easy to forget to check your email)
- Opens links on your Mac in the background
- Does not litter your email inbox with lots of random links

#### How is it better than [Pushbullet](https://www.pushbullet.com)? {#pushbullet}

- Works in any app with a share sheet
- Pushbullet does not have a iOS or macOS app
- Does not require signing up for another account

#### How is it better than the Firefox [Send Tabs](https://support.mozilla.org/en-US/kb/send-tab-firefox-ios-another-device) feature?

- Works in any app with a share sheet, not just Firefox
- Supports any browser on your Mac
- Requires less taps

#### How is it better than the Firefox tab sync?

- Works in any app with a share sheet, not just Firefox
- Supports any browser on your Mac
- You don't need to keep the tab open on your iOS device for it to be available on your Mac

#### Can it open links in a specific browser on my Mac?

You can use my free [Velja app](/velja) for this. Create a custom rule where you set Hyperduck as the source app.

#### The link did not open on my Mac right away

The app works by syncing the link over iCloud from your iOS device to your Mac. This is usually instantaneous, but there can be situations that delay it (iCloud problems, network issues, Low Power Mode, etc). This is unfortunately completely out of my control.

#### I don't see the “Send to Mac” action in the share sheet

Try restarting your device. Because of a iOS bug, it sometimes only appears after a restart.

#### The “Send to Mac” button does not appear when viewing a PDF file in Safari

Safari tries to share the PDF file itself, not the URL to the PDF, and Hyperduck can only handle URLs. Instead, go back, long-press the link to the PDF, and tap “Share”.

#### I use the Arc browser and I am not receiving all links

The Arc browser does not support opening multiple URLs at the time. I suggest sending feedback to the Arc team about this. There is nothing Hyperduck can do about it.

As a workaround, you could use my free [Velja app](/velja) to make such links open in a different browser. Create a custom rule where you set Hyperduck as the source app and set the destination app to a different browser than Arc.

#### Can you add a history screen to the iOS app?

I don't plan to add this. I would like to keep the app focused on one thing and do it well. The app is for sending links from iOS to Mac. That's it.

#### Can you support multiple Macs?

No. I would like to keep the app simple.

#### Can you support the reverse - Mac to iOS?

No. That is not something I plan to support. It's simply not something I need myself and it would make the app much more complicated.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id6444667067) and click “Version History”.

#### [More FAQs…](/apps/faq)

<br>

### Older Versions

- [1.0.7](https://github.com/sindresorhus/meta/files/14292936/Hyperduck.1.0.7.-.macOS.13.zip) for macOS 13+

<br>

### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/8uc8owhy3izpaj0pi7ob5/Hyperduck-1.1.0-1707315964.zip?rlkey=8v6ylbwibmi4yav8bp25sz468&raw=1) *(1.1.0)*

*Requires macOS 14 or later*
