---
title: Scratchpad
subtitle: Quick notes, always available
pubDate: 2024-08-30
platforms:
  - macOS
  - iOS
  - visionOS
  - watchOS
isPaid: true
isMenuBarApp: true
appStoreId: 6504040051
olderMacOSVersions:
  - '14'
feedbackNote: |
  If you are having problems with sync, [read this](/scratchpad#troubleshooting).
---

Capture your thoughts instantly in a single, always-accessible note.

Plain text only. Simple by design.

On macOS, the app sits in your menu bar or Dock, ready whenever inspiration strikes. On iOS, it can be accessed from the Home Screen, Lock Screen, or Control Center.

- One-tap access
- Clean, distraction-free interface
- Lightning-fast and lightweight
- Sync with iCloud, or not
- Word and character count
- Custom hotkey for instant writing <sup>(macOS)</sup>
- Translucent background <sup>(macOS)</sup>
- Font settings
- Support for [Shortcuts](https://support.apple.com/en-ng/guide/shortcuts/welcome/ios), [share service](https://support.apple.com/en-ng/guide/mac-help/mh40614/mac), and [macOS Services](https://support.apple.com/en-bh/guide/mac-help/mchlp1012/mac)

Perfect for brain dumps, quick drafts, and fleeting ideas. Your thoughts are just a click away, without breaking your workflow.

It's an [Universal Purchase](/apps/faq#universal-purchase).

[Review by MacStories](https://www.macstories.net/reviews/scratchpad-the-cross-device-text-utility-that-pairs-perfectly-with-your-clipboard-manager/)

<a href="https://www.producthunt.com/posts/scratchpad-3?embed=true&utm_source=badge-top-post-badge&utm_medium=badge&utm_souce=badge-scratchpad&#0045;3" target="_blank"><img src="https://api.producthunt.com/widgets/embed-image/v1/top-post-badge.svg?post_id=486333&theme=light&period=daily" alt="Scratchpad - Quick&#0032;notes&#0044;&#0032;always&#0032;available | Product Hunt" style="width: 250px; height: 54px;" width="250" height="54" /></a>

#### Privacy

The app uses iCloud syncing to securely sync your text across devices. This feature is opt-in. Neither the app developer nor Apple can access the text in your scratchpad. The app does not collect any personal data and contains no tracking.

## Trial

Try the fully functional trial of the macOS app [here](https://www.dropbox.com/scl/fi/fku2ko060srmht2zbtl1l/Scratchpad-1.3.7-trial-1748874499.zip?rlkey=35epjlrmrr700xh8fy514pkze&raw=1). The only limitation is a reminder to buy the app every 12 hours, and no automatic updates. All data and settings carry over if you buy it on the App Store.

There is no trial for the iOS version.

## Tips

### Troubleshoot syncing {#troubleshooting}

- After enabling sync, try writing some more text on all the devices.
- [More…](/apps/faq#icloud-sync)

### Keyboard shortcuts <sup>macOS</sup>

- Increase text size: <kbd>⌘+</kbd>
- Decrease text size: <kbd>⌘-</kbd>
- Reset text size: <kbd>⌘0</kbd>

### Launch app from Lock Screen

Quickly open the app using the built-in Lock Screen widget. For more customization options, you can also use my [Quick Launch](/quick-launch) app.

### Quickly add text to the scratchpad

1. Tap the share button in any app that deals with text and select “Add to Scratchpad”.
1. macOS: Select some text in any app, right-click, and select “Services › Add to Scratchpad” or “Share › Add to Scratchpad”.
2. iOS: Select some text in any app, tap “Share › Add to Scratchpad”.
1. Use the [Shortcuts action](#scripting)
1. Use the [custom URL scheme](#scripting)
1. Use [this shortcut](https://www.icloud.com/shortcuts/caa5fd4f5a7240cf951ef9a4184b0522) directly from a share sheet

### PopClip integration {#popclip}

Select the below snippet and install it with PopClip:

```yaml
#popclip Add selected text to Scratchpad
name: Scratchpad
icon: iconify:material-symbols:add-notes
url: scratchpad:append?text={popclip text}&hide
```

You can replace `append` with `prepend`. And you can remove `&hide` if you want Scratchpad to show when adding text.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Scratchpad&referrer=Website-FAQ)

#### The macOS app does not show up in the menu bar

[Try this](/apps/faq#app-not-showing-in-menu-bar)

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

#### How can I make the macOS app show up right below the menu bar icon?

Move the window to below the menu bar icon. It remembers its position.

#### Can I open and save an external file?

No, see my [Plain Text Editor](/plain-text-editor) app for that.

#### Does it support [Advanced Data Protection for iCloud](https://support.apple.com/en-us/102651)?

No. The app stores the note in iCloud Drive, which is covered by Advanced Data Protection. But it also syncs using [`NSUbiquitousKeyValueStore`](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore) to be able to support watchOS, and this is not covered by Advanced Data Protection. I also don't want to commit to Advanced Data Protection support because I could potentially change how syncing works in the future.

#### Why doesn’t the app appear in my Dock?

By default, it only appears in the menu bar. You can enable the Dock icon in the settings.

#### Can it show the text in a widget?

No, but check out my [Any Text](/any-text) app for that.

#### Can it show the text in the macOS menu bar?

No, but check out my [One Thing](/one-thing) app for that.

#### The text sometimes jumps when I write fast

This is a macOS bug. There is unfortunately nothing I can do about it.

#### How can I toggle “Stay on Top” with a keyboard shortcut in the macOS app?

The keyboard shortcut is listed in the “…” menu. When in menu bar mode, it's always on top.

#### Can you add a color setting?

I don't plan to add that. It's not essential and I'm trying to keep the app simple.

#### Why is it suddenly showing a scrollbar in the macOS app?

You either have a system setting set to always show scrollbars or you have an external mouse connected. This is simply how macOS works. You can see the behavior in other text editing apps too. See the “Appearance › Show scroll bars” system setting.

#### Why is the scrollbar still white even with window translucency enabled?

macOS does not let apps style the scrollbar. Its background remains solid regardless of translucency.

#### Why is there no way to print?

The app is made using Apple's latest technologies (SwiftUI) and they have not added print support there yet. If you need to print, copy-paste the text over to the TextEdit instead.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### On iOS, the item in the share sheet opens the app, how can I add text to the app in the background?

Add [this shortcut](https://www.icloud.com/shortcuts/caa5fd4f5a7240cf951ef9a4184b0522). You can then tap the “Add to Scratchpad” action in a share sheet to add text to Scratchpad in the background.

#### What's the difference between [Plain Text Editor](/plain-text-editor) and Scratchpad? {#plain-text-editor-comparison}

These two apps serve different purposes. Plain Text Editor is a traditional text editor that lives in your Dock and handles multiple documents - perfect for working with separate text files and longer writing sessions.

Scratchpad is designed for quick notes - it lives in your menu bar (macOS) or Lock Screen/Control Center (iOS) and maintains just one persistent note that syncs across your devices. Think of it as a digital sticky note that's always one click away.

Both apps handle plain text only and work on macOS, iOS, and visionOS (Scratchpad also on watchOS). They're complementary tools: Plain Text Editor for focused writing with multiple files, Scratchpad for quick, always-accessible note-taking.

#### How does this compare to [Tot](https://tot.rocks)? {#tot}

Scratchpad advantages:

- Simpler, focused design: A single plain text note for minimal distraction.
- Can float on top of other windows in menu bar mode.
- iCloud sync is optional. Tot does not have a setting to turn off iCloud sync.
- More affordable pricing: $8 vs $20 for Tot.
- visionOS support.
- Unlimited note size. Tot is limited to 100,000 characters.
- Translucent background on macOS.

Tot advantages:

- Supports 7 notes.
- Rich-text support.

#### [More FAQs…](/apps/faq)

## Scripting

The app can be automated using the Shortcuts app or with a custom URL scheme.

<!-- More integrations:

- [Command-line tool](https://github.com/sindresorhus/one-thing)
- [Node.js API](https://github.com/sindresorhus/one-thing)
-->

### Shortcuts app

- [Shortcuts usage guide](https://www.xda-developers.com/guide-shortcuts-macos/)
- [How to run shortcuts from the command-line on macOS](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac)

**Examples**

- [*Tell me if you have done anything cool with scripting*](https://sindresorhus.com/feedback?product=Scratchpad&referrer=Website-FAQ)

### Custom URL scheme

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

## Older Versions

- [1.2.8](https://github.com/user-attachments/files/18575785/Scratchpad.1.2.8.-.macOS.14.zip) for macOS 14

These are free for everyone but they will not run on newer macOS versions.
