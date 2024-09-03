---
title: Online Check
subtitle: Online status in your menu bar
pubDate: 2024-06-23
platforms:
  - macOS
isMenuBarApp: true
isPaid: true
appStoreId: 6504709660
# olderMacOSVersions
#   - '14'
---

Check if you are online directly from the menu bar. The menu bar icon turns red when you are offline and it optionally shows a notification.

### Tips

#### Connect to other Wi-Fi when status is offline

You can have the app connect to a different Wi-Fi if the current one becomes offline. Add [this shortcut](https://www.icloud.com/shortcuts/bf64ec8fd3d24f80b2af845464306614) to the Shortcuts app and edit the required information. Then select this shortcut in the Online Check settings.

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here](https://sindresorhus.com/feedback?product=Online%20Check&referrer=Website-FAQ).

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some other menu bar apps to free up space. If this does not solve it, try quitting Bartender/Ice if you have it installed.

#### How is it different from just checking whether the Wi-Fi is connected?

A Wi-Fi connection only means you are connected to a network. The app verifies internet access by connecting to “apple.com” or “cloudflare.com”, ensuring you're truly online.

#### The app shows that I'm offline even though I'm not

- Ensure network requests from the app to “apple.com” and “cloudflare.com” are not blocked. These domains are used to verify your online status.

#### How can I run this only when not connected to certain networks?

Use the [Shortery](https://apps.apple.com/app/id1594183810) app. Create a shortcut in the Shortcuts app to launch and quit this app. Then, set up a "Wi-Fi" trigger in Shortery to run the shortcut based on your Wi-Fi connection status. This allows the app to launch or quit when connecting to or disconnecting from specific Wi-Fi networks.

#### How does it work?

Every 20 seconds and anytime the network changes, it sends a HEAD request to “apple.com”. If that fails, it sends a HEAD request to “cloudflare.com”. If both requests fail, it considers the internet to be offline.

#### Can you make the history persistent?

It's something I'm considering. Share your use-case through the feedback button in the app to increase the likelyhood of me doing this.

#### Can you make the menu bar icon green when online? {#green-icon}

No. Menu bar icons are intended to be mostly monotone, changing color only to indicate critical states. For example, the battery icon turns red when low but stays monochrome when full. Showing green also isn't that useful as you can assume it's connected when not red, and having a constant green color there could be distracting.

#### [More FAQs…](/apps/faq)

<!-- ### Older Versions

- [0.0.0]() for macOS 14

-->
