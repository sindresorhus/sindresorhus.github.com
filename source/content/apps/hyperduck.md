---
title: Hyperduck
subtitle: Send links from your iOS & visionOS devices to your Mac
pubDate: 2023-01-27
platforms:
  - macOS
  - iOS
  - visionOS
isPaid: true
appStoreId: 6444667067
olderMacOSVersions:
  - '13'
  - '14'
feedbackNote: |
  If you are having problems with sync, [read this](/hyperduck#troubleshooting).
---

For example, share a link from Safari on your iPhone, iPad, or Apple Vision, and have it open in the default browser on your Mac moments later.

You can send a link even if your iOS/visionOS device and/or Mac is offline. The link will be sent and received the next time the devices are online. The link will never be lost.

My personal use-case is that I often discover cool stuff when I check X (Twitter) on the go and I want to dig deeper into it later on my Mac. I have tried Instapaper, Pocket, Safari Reading List, iCloud Tabs, and more. The problem with them all is that I forget to check them.

[**Why not AirDrop?**](#airdrop)

[Review by MacStories](https://www.macstories.net/reviews/automation-april-hyperduck-leverages-the-power-of-url-schemes-to-control-your-mac-from-an-iphone-or-ipad/)

[Video review by MacRumors](https://www.youtube.com/watch?v=XiLSieZ5b2c&t=486s)

#### Privacy

The app uses iCloud syncing to securely send links from your iOS/visionOS device to your Mac. The app developer will not see the links you share. The app does not collect any personal data and does not have any tracking.

## Troubleshooting

- If the “Send to Mac” button is not showing up in share sheets, you may have to enable it at the bottom of the share sheet with the “Edit Actions” button. You may even have to restart your device for it to show up (iOS bugs…).
- Ensure Hyperduck is running on the Mac.
- Hyperduck opens links in the background. Ensure you didn't miss it.
- Try opening the Hyperduck iOS app to force a sync.
- In the iOS app, if you triple-tap the text, it will show the most recently shared URLs, which may aid debugging. Also check the history in the macOS app.
- For a few users, initial sync took up to 24 hours due to weird iCloud syncing behavior.
  - This is controlled by Apple's iCloud system and outside the app's control.
- [More…](/apps/faq#icloud-sync)

## Tips

### Run shortcuts {#shortcuts}

You can use this app to trigger [shortcuts](https://support.apple.com/guide/shortcuts/welcome/ios) on your Mac from your iOS devices. This enables a lot of powerful use-cases. For example, you could make your Mac play a specific song directly from your iPhone.

First, create a shortcut on your Mac with some actions. Let's call it `Unicorn`.

On your iOS device, make a new shortcut, add the “Run Shortcut on Mac” action, and write `Unicorn` in the shortcut field.

You can now run this shortcut on your iOS device to trigger the `Unicorn` shortcut on your Mac.

[Learn more](https://www.macstories.net/reviews/automation-april-hyperduck-leverages-the-power-of-url-schemes-to-control-your-mac-from-an-iphone-or-ipad/) in the Hyperduck review by MacStories.

### Shut down Mac

You can use the Shortcuts support mentioned above to shut down your computer remotely from your iOS device. Just follow the above steps and use the “Shut Down” action (requires macOS 13.3) in the Shortcuts app or the AppleScript action with the following: `tell app "System Events" to shut down`.

### Trigger Raycast deeplinks {#raycast}

Similar to the above, we can use a [Raycast deeplink](https://manual.raycast.com/deeplinks).

For example, on your iOS device, make a new shortcut, add the “Send URLs to Mac” action, and in the URL field, write:

```
raycast://confetti
```

You can now trigger confetti to show up on your Mac from your iPhone.

### Send a link to a specific browser profile

Create an [iOS shortcut that triggers a macOS shortcut](#shortcuts) and set it to appear in the share sheet. In the macOS shortcut, use the "Open URLs" action from my [Velja](/velja) app to open the URL in a specific browser profile.

- [Example iOS shortcut](https://www.icloud.com/shortcuts/a00ac5bb31294084936fbd4dd6ca0245)
- [Example macOS shortcut](https://www.icloud.com/shortcuts/d39c57b67ed343d58192a899841d6457)

### Send a link to a specific Mac {#send-to-specific-mac}

Instead of using the “Send to Mac” share sheet button provided by the app, you can make a [shortcut](#shortcuts) for each Mac you want to send to and put those shortcuts in the share sheet.

Add these shortcuts (on any device):

- [iOS shortcut](https://www.icloud.com/shortcuts/f013c4a6da7d4a9eb0694f0a6532f34c)
- [macOS shortcut](https://www.icloud.com/shortcuts/e164558aa759486ca70553f32029fe40)

Then edit the macOS shortcut to match the device name of the device you want this to share to. You can rename the macOS shortcut, but don't forget to update the name in the iOS shortcut.

To support more Macs, repeat the process for each Mac.

### Download a file on your Mac from your iOS device

You can use Hypeduck to trigger a download from your iOS device and have it downloaded on your Mac.

Add the below [shortcuts](#shortcuts):

- [iOS shortcut](https://www.icloud.com/shortcuts/4819a11f4d0b40228df7ffd737b34c3d)
- [macOS shortcut](https://www.icloud.com/shortcuts/d319976dd4cf441780f6abcb049a3cff)

You can then tap “Download on Mac” in the share sheet on your iOS device, and the item will be downloaded on your Mac to the “Downloads” folder.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Hyperduck&referrer=Website-FAQ)

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

#### How is it better than [Universal Clipboard](https://support.apple.com/HT209460)? {#universal-clipboard}

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

#### How is it better than the Firefox [Send Tabs](https://support.mozilla.org/kb/send-tab-firefox-ios-another-device) feature?

- Works in any app with a share sheet, not just Firefox
- Supports any browser on your Mac
- Requires less taps

#### How is it better than the Firefox tab sync?

- Works in any app with a share sheet, not just Firefox
- Supports any browser on your Mac
- You don't need to keep the tab open on your iOS device for it to be available on your Mac

#### Can it open links in a specific browser or browser profile on my Mac? {#custom-browser}

You can use my [Velja app](/velja) for this. Create a custom rule where you set Hyperduck as the source app.

[It's not possible to open in Safari profiles.](/velja#safari-profiles)

#### The link did not open on my Mac right away

The app works by syncing the link over iCloud from your iOS device to your Mac. This is usually instantaneous, but there can be situations that delay it (iCloud problems, network issues, Low Power Mode, etc). This is unfortunately completely out of my control.

#### I don't see the “Send to Mac” action in the share sheet

Try restarting your device. Because of a iOS bug, it sometimes only appears after a restart.

#### The “Send to Mac” button does not appear when viewing a PDF file in Safari

Safari tries to share the PDF file itself, not the URL to the PDF, and Hyperduck can only handle URLs. Instead, go back, long-press the link to the PDF, and tap “Share”.

#### I use the Arc browser and I am not receiving all links

The Arc browser does not support opening multiple URLs at the time. I suggest sending feedback to the Arc team about this. There is nothing Hyperduck can do about it.

As a workaround, you could use my [Velja app](/velja) to make such links open in a different browser. Create a custom rule where you set Hyperduck as the source app and set the destination app to a different browser than Arc.

#### Can Hyperduck lose a shared link if my internet goes down?

No. Hyperduck stores your link in iCloud, ensuring it's available until successfully opened on your Mac, regardless of your internet connection quality.

#### Can you add a history screen to the iOS app?

I don't plan to add this. I would like to keep the app focused on one thing and do it well. The app is for sending links from iOS to Mac. That's it.

If you really need to see what URLs were shared, you can triple-tap on the text in the iOS app to get a list of recently shared URLs.

#### Can you support multiple Macs?

No. I would like to keep the app simple. However, you could [do it with Shortcuts](#send-to-specific-mac).

#### Can you support the reverse - Mac to iOS?

No. That is not something I plan to support. It's simply not something I need myself and it would make the app much more complicated. Also, it would not be possible to open the URL directly in the browser like it does on macOS, so the experience would not be great.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### [More FAQs…](/apps/faq)

## Older Versions

- [1.2.3](https://github.com/user-attachments/files/18591073/Hyperduck.1.2.3.-.macOS.14.zip) for macOS 14
- [1.0.7](https://github.com/sindresorhus/meta/files/14292936/Hyperduck.1.0.7.-.macOS.13.zip) for macOS 13

These are free for everyone but they will not run on newer macOS versions.
