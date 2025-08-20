---
title: Default Browser
subtitle: Switch default browser from your menu bar
pubDate: 2025-01-13
platforms:
  - macOS
isPaid: true
isMenuBarApp: true
releasesRepo: default-browser-meta
mainLinks:
  'Buy': https://sindresorhus.gumroad.com/l/default-browser?wanted=true
  # 'Buy': https://buy.polar.sh/polar_cl_tWjWd0yRVXb9w0bhohTfxkqjwMUsjpegZM1na4HH9ER
# olderMacOSVersions:
#   - '15'
---

<sup>Requires macOS 15.4 or later</sup>

Seamlessly switch between browsers directly from your menu bar, keyboard shortcut, Focus mode, or using Shortcuts. Perfect for users who work with multiple browsers.

Unlike similar apps, this one actually changes the system default browser (and without a prompt).

[**Review in MacStories**](https://www.macstories.net/reviews/default-browser-a-mac-menu-bar-utility-for-quickly-switching-browsers/)

**Features**

- Set the system default browser
- Choose which browsers are shown in the menu
- Hide menu bar icon
- Show the default browser’s icon in the menu bar
- Keyboard shortcut to show the menu
- [Shortcuts app integration](#shortcuts)
- [Focus filter](#focus-filter) to automatically switch browser based on [Focus mode](https://support.apple.com/guide/mac-help/mchl613dc43f/mac#mchl49b73d04)

---

**💡 Also available in the [Power User Bundle](https://sindresorhus.gumroad.com/l/power-user) - Get 3 of my power user apps for 26% off normal price.**

---

*Switching the default browser is also a feature of my [Supercharge](/supercharge) app.*

---

## Tips

### Browser selector

Set a keyboard shortcut to open the menu. Once open, select a browser by pressing its number key or navigate using the arrow keys.

### Launch browser

Hold the Option key and click a browser in the menu to open it, rather than setting it as the default.

### Switch to specific browser with keyboard shortcut {#keyboard-shortcut-set-browser}

Create a [shortcut in the Shortcuts app](https://support.apple.com/guide/shortcuts-mac/intro-to-shortcuts-apdf22b0444c/mac) for each browser using the “Set Default Browser” action, then assign a keyboard shortcut to the shortcut.

### Automatically switch browser based a trigger {#auto-switch-browser}

The triggers could be: time, location, active app, Wi-Fi network, etc.

For example, set up automatic browser switching between work and personal use through the Shortcuts app. Create two shortcuts using the “Set Default Browser” action - one for each browser. Then use [Shortery](https://apps.apple.com/app/id1594183810) to automatically trigger these shortcuts based on time of day or Wi-Fi network. The Wi-Fi trigger is particularly useful for office workers, as it switches browsers automatically when you connect to your work network.

Use the [Focus filter](#focus-filter) to switch browser based on the active Focus mode.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Default%20Browser&referrer=Website-FAQ)

#### The app does not show up in the menu bar

[Try this](/apps/faq#app-not-showing-in-menu-bar)

You may also have disabled the “Show menu bar icon” setting, which hides the menu bar icon. Launch the app again to show the menu bar icon.

#### Can it support rules for which browser to use for certain URLs? {#rules-support}

Features like rules require the app to intercept and forward URLs by acting as the default browser. This app simply changes the default browser. Check out my [Velja](/velja) app for rules and more.

#### Can it support browser profiles? {#browser-profiles}

Same answer as the above.

With the exception of Orion, which implements profiles as separate apps.

#### How is it different from your [Velja](/velja) app?

Velja works by acting as a browser and forwarding URLs to other browsers, enabling features like rules, interactive browser prompt, desktop app handling, and URL tracking parameter cleaning. This app is simpler - it just changes the system default browser directly.

#### I already own [Supercharge](/supercharge). Does this offer any benefits over its browser switcher feature? {#supercharge}

- Default browser app icon in the menu bar.
- Larger app icons in the menu.
- Keyboard shortcut to show the menu.
- Number key selection for browsers in the menu.

#### Why is this not in the App Store?

Much of the functionality would not be possible in the App Store because of [sandboxing](/apps/faq#macos-sandbox).

#### Why is it a paid app?

I love making [free apps](/apps/free) and having them available to everyone, but they come with a heavy support burden—I already handle 10–40 app-related emails daily. To focus on quality and sustainability, my new apps will mostly be paid.

#### [More FAQs…](/apps/faq)

<!-- ### Older Versions

- [] for macOS 15

These are free for everyone but they will not run on newer macOS versions.
 -->

## Scripting

### Shortcuts

The app comes with support for the Shortcuts app. Look up the app in the Shortcuts app to see what actions it provides.

For example, you could switch to a certain browser at a [specific time of the day](#auto-switch-browser), or maybe when joining a specific Wi-Fi network. For such triggers, you will also need the [Shortery](https://apps.apple.com/app/id1594183810) app.

### Focus filter

The app includes a [Focus filter](https://support.apple.com/guide/mac-help/mchl613dc43f/mac#mchl49b73d04) to automatically switch the default browser based on the Focus mode. Enable it in “System Settings › Focus”.

### Events

The [distributed notification](/apps/faq#distributed-notifications) `com.sindresorhus.defaultBrowserDidChange` is emitted when the default browser is changed from the app or the Shortcuts action.
