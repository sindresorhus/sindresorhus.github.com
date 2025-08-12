---
title: Short Run
subtitle: Run shortcuts from your menu bar
pubDate: 2025-08-14
platforms:
  - macOS
isPaid: true
isMenuBarApp: true
appStoreId: 6745427035
forceHasIosAppIcon: true
# olderMacOSVersions:
#   - '15'
---

Quick access to your shortcuts from the [Shortcuts](https://support.apple.com/guide/shortcuts-mac/intro-to-shortcuts-apdf22b0444c/mac) app right from the menu bar.

Since shortcuts can run shell scripts and AppleScript, you can put virtually any script in your menu bar.

#### Highlights

- Instant Access – All your favorite shortcuts available from the menu bar
- Smart Organization – Organize shortcuts into sections and submenus
- App-Specific Shortcuts – Show different shortcuts based on the active app
- Keyboard Shortcut – Toggle the menu with a customizable hotkey
- Customizable Menu Bar Icon – Choose between multiple menu bar icons to match your style
- Launch at Login – Always ready when you need it

#### Privacy

Your shortcuts and data never leave your device. The app is built without internet permissions (no network entitlement), so macOS prevents it from connecting to the internet even if it wanted to.

## Tips

- <kbd>Option</kbd>-click a shortcut in the menu to edit it.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Short%20Run&referrer=Website-FAQ)

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some other menu bar apps to free up space. If this does not solve it, try quitting Bartender or Ice if you have it installed.

#### How is this different from the built-in Shortcuts menu bar item? {#difference-builtin}

The built-in menu bar item shows shortcuts in one long, unorganized list.

Short Run benefits:
- Choose the order of shortcuts
- Organize shortcuts into sections and submenus
- Show some shortcuts only when a specific app is active
- Cleaner interface with just the shortcut name
- Menu closes automatically when running a shortcut
- Open the menu with a keyboard shortcut and navigate to shortcuts using arrow keys
- Customizable menu bar icon

### Will you add icon support for menu items?

No. While macOS 26 introduces icons in menu items (similar to iOS), I believe this creates visual noise rather than improving usability. Short Run intentionally maintains a clean, text-only interface to keep the menu focused and distraction-free.

#### Can you add search?

This is not planned. For searching, use Spotlight on macOS 26 or later, or Raycast or Alfred on earlier versions.

#### Do I need to recreate my shortcuts?

No. The app uses your existing shortcuts from the Shortcuts app. You're just organizing how they appear in the menu bar.

#### How do app-specific shortcuts work?

You can set certain shortcuts to only appear when specific apps are active. For example, show your Git shortcuts only when Xcode is open, or media processing shortcuts only when Final Cut Pro is active.

#### What's the difference between sections and submenus?

Sections display shortcuts inline with a header (like "Development" followed by your dev shortcuts). Submenus create a separate menu that opens when you hover over the folder name. You can toggle between these modes for each folder.

#### Can I use keyboard shortcuts to navigate the menu?

Yes. Set a keyboard shortcut to open the menu, then use arrow keys to navigate and <kbd>Enter</kbd> to run shortcuts. Much faster than clicking.

### Can you add sync?

No. iCloud sync is unreliable and causes a huge support burden. It's not worth the effort for this app.

#### I already own [Supercharge](/supercharge). Does this offer any benefits over its similar feature? {#supercharge}

- Group shortcuts into sections and submenus.
- More focused since there are only shortcuts in the menu.
- Global keyboard shortcuts to open the menu, create a new shortcut, and to open the Shortcuts app.

#### [More FAQs…](/apps/faq)

<!-- ## Older Versions

- []() for macOS 15+ -->
