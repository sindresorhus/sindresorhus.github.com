---
title: Hyperduck
subtitle: Send links from your iOS devices to your Mac
date: 2023-01-27
platforms:
  - macOS
  - iOS
appStoreId: 6444667067
---

For example, share a link from Safari on your iPhone or iPad and have it open in the default browser on your Mac moments later.

You can send a link even if your iOS device and/or Mac is offline. The link will be sent and received the next time the devices are online. The link will never be lost.

My personal use-case is that I often discover cool stuff when I check Twitter on the go and I want to dig deeper into it later on my Mac. I have tried Instapaper, Pocket, Safari Reading List, iCloud Tabs, and more. The problem with them all is that I forget to check them.

<br>

### Troubleshooting

- Ensure both devices are signed into the same iCloud account.
- Ensure both devices are online.
- Ensure Hyperduck is running on the Mac.
- Hyperduck opens links in the background. Ensure you didn't miss it.
- Try restarting both devices.

<br>

### Tips

#### Run shortcuts {#shortcuts}

You can use this app to trigger [shortcuts](https://support.apple.com/en-gb/guide/shortcuts/welcome/ios) on your Mac from your iOS devices. This enables a lot of powerful use-cases. For example, you could make your Mac play a specific song directly from your iPhone.

First, create a shortcut on your Mac with some actions. Lets call it `Unicorn`.

On your iOS device, make a new shortcut, add the “Send URLs to Mac” action, and in the URL field, write:

```
shortcuts://run-shortcut?name=Unicorn
```

You can now run this shortcut on your iOS device to trigger the `Unicorn` shortcut on your Mac.

[Learn more about running shortcuts using the custom URL scheme.](https://support.apple.com/en-gb/guide/shortcuts/apd624386f42/ios)

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

- Works when your Mac is offline
- Works when you are not near your Mac
- Much faster
- Opens links on your Mac in the background
- AirDrop sometimes refuses to work. This always works.

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
- Works when your Mac is offline
- Works when you are not near your Mac
- Supports any browser on your Mac
- Opens links on your Mac in the background
- The link opens automatically. Handoff requires clicking the Dock icon to open it.
- Handoff sometimes refuses to work. This always works.

#### How is it better than [Universal Clipboard](https://support.apple.com/en-us/HT209460)? {#universal-clipboard}

- No need to manually paste the link into the browser after copying it on your iOS device
- Works when your Mac is offline
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

The app works by syncing the link over iCloud from your iOS device to your Mac. This is usually instantaneous, but there can be situations that delay it (iCloud problems, network issues, etc). This is unfortunately completely out of my control.

#### Can you support multiple Macs?

No. I would like to keep the app simple.

#### Can you support the reverse - Mac to iOS?

No. That is not something I plan to support. It's simply not something I need myself and it would make the app much more complicated.

#### Can you localize the app into my language?

I don't have any immediate plans to localize the app.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id6444667067) and click “Version History”.
