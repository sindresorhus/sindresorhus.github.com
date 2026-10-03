---
title: Googly Eyes
subtitle: Watchful eyes in your menu bar
pubDate: 2025-03-12
platforms:
  - macOS
isMenuBarApp: true
appStoreId: 6743048714
olderMacOSVersions:
  - '15'
script: /apps/googly-eyes/eyes.js
---

Add playful eyes to your menu bar that follow your cursor and blink when you click. Pure whimsy! 👀

## Frequently Asked Questions {#faq}

#### The app does not show up in the menu bar

[Try this](/apps/faq#app-not-showing-in-menu-bar)

#### Why is it using a lot of CPU?

The app is optimized as much as possible, but macOS is inefficient at updating menu bar items. Also, make sure you know how to [interpret CPU usage](/apps/faq#high-cpu).

#### Does it support multiple screens?

Partly.

The eyes follow your cursor across displays. However, menu bar items on inactive secondary displays are just static macOS clones, so those eyes cannot track independently.

The real eyes live on the display with the active menu bar. macOS only makes another display active when you click something on it, for example a window or the desktop. Moving the pointer there is not enough. So when you move the pointer to another display, the eyes there stay frozen until you click on that display.

This is a macOS limitation and cannot be worked around. There is no supported way for an app to change which display has the active menu bar.

## Older Versions

- [1.1.4](https://www.dropbox.com/scl/fi/p4ym425ivfp4ex1enlh1l/Googly-Eyes-1.1.4-macOS-15-1774281617.zip?rlkey=7jbf2llhjjielpvde6rcpvp8n&raw=1) for macOS 15+

## Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/t8qoulw2nfo2wbzoekbop/Googly-Eyes-1.2.0-1774281367.zip?rlkey=purr5ntc70na53ndpt06oxcuh&raw=1) *(1.2.0 · macOS 26+)*
