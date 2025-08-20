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

Since shortcuts can open URLs, folders, apps, and run shell scripts or AppleScript, you can put virtually any action in your menu bar.

#### Highlights

- Instant Access – All your favorite shortcuts available from the menu bar
- Smart Organization – Organize shortcuts into sections and submenus
- App-Specific Shortcuts – Show different shortcuts based on the active app
- Linked Folders – Display folders from the Shortcuts app dynamically
- Keyboard Shortcut – Toggle the menu with a customizable hotkey
- Quick Keys – Assign 1-9 and a-z keys to shortcuts for instant triggering when menu is open
- Customizable Menu Bar Icon – Choose between multiple menu bar icons to match your style
- Launch at Login – Always ready when you need it

#### Common use cases

- Essential Folders – Instantly jump to Desktop, Downloads, current project, or that deeply nested work directory
- Daily Websites – One-click access to X, Gmail, GitHub, or your company dashboard
- File Management – Bulk rename photos, compress for email, convert between formats, organize screenshots
- System Shortcuts – Toggle Dark Mode, empty trash, force-quit apps
- Developer Workflows – Open terminal here, restart local server, run build scripts, push to Git
- Text & Clipboard – Create meeting summary, clean text
- Quick Actions – Take annotated screenshots, start screen recording, set focus modes, create calendar events

#### URL scheme {#url-scheme}

Supports the `shortrun://` URL scheme for running shortcuts silently in the background without opening the Shortcuts app. Works exactly like the standard [Shortcuts URL scheme](https://support.apple.com/en-ke/guide/shortcuts-mac/apd624386f42/mac) `shortcuts://` but executes silently. Perfect for automation workflows and third-party integrations.

*It does not support `shortcuts://x-callback-url`.*

#### Privacy

Your shortcuts and data never leave your device. The app is built without internet permissions (no network entitlement), so macOS prevents it from connecting to the internet even if it wanted to.

#### Example shortcuts

- [Open a folder](https://www.icloud.com/shortcuts/29925fe3ff684d0699c82e51f6e86e2f)
- [Open a URL](https://www.icloud.com/shortcuts/403bc58451f442e4b94fb4e13043abf1)

## Tips

- <kbd>Option</kbd>-click a shortcut in the menu to edit it.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Short%20Run&referrer=Website-FAQ)

#### The app does not show up in the menu bar

[Try this](/apps/faq#app-not-showing-in-menu-bar)

#### How is this different from the built-in Shortcuts menu bar item? {#difference-builtin}

The built-in menu bar item shows shortcuts in one long, unorganized list.

Short Run benefits:
- Choose the order of shortcuts
- Organize shortcuts into sections and submenus
- Show some shortcuts only when a specific app is active
- Assign quick keys (1-9, a-z) to shortcuts for instant triggering when menu is open
- Cleaner interface with just the shortcut name
- Menu closes automatically when running a shortcut
- Open the menu with a keyboard shortcut and navigate to shortcuts using arrow keys
- Customizable menu bar icon and menu width

#### How do I disable the built-in Shortcuts menu bar item to avoid duplication?

Open the Shortcuts app, select “Menu Bar” in the sidebar, select all shortcuts, right-click on them, and select “Remove from Menu Bar”.

#### I already own [Supercharge](/supercharge). Does this offer any benefits over its similar feature? {#supercharge}

- Group shortcuts into sections and submenus.
- More focused since there are only shortcuts in the menu.
- Global keyboard shortcuts to open the menu, create a new shortcut, and to open the Shortcuts app.
- [URL scheme](#url-scheme) for running shortcuts silently in the background.

#### What's the difference between sections and submenus?

Sections display shortcuts inline with a header (like "Development" followed by your dev shortcuts). Submenus create a separate menu that opens when you hover over the folder name. You can toggle between these modes for each folder.

#### How do I make a folder show inline as a section?

Right-click a folder when organizing and enable “Show Inline”.

#### How can I select Safari web apps for app-specific shortcuts? {#safari-web-apps}

Safari web apps (created via “File › Add to Dock” in Safari) are just normal apps. In the app picker, click the `+` button, navigate to `~/Applications`, and select the web app. They don't appear by default because Short Run cannot automatically access this folder.

#### Will you add icon support for menu items?

No. While macOS 26 introduces icons in menu items (similar to iOS), I believe this creates visual noise rather than improving usability. Short Run intentionally maintains a clean, text-only interface to keep the menu focused and distraction-free.

#### Can you add search?

This is not planned. For searching, use Spotlight on macOS 26 or later, or Raycast or Alfred on earlier versions.

#### Do I need to recreate my shortcuts?

No. The app uses your existing shortcuts from the Shortcuts app. You're just organizing how they appear in the menu bar.

#### How do app-specific shortcuts work?

You can set certain shortcuts to only appear when specific apps are active. For example, show your Git shortcuts only when Xcode is open, or media processing shortcuts only when Final Cut Pro is active.

#### Can I use keyboard shortcuts to navigate the menu?

Yes. Set a keyboard shortcut to open the menu, then use arrow keys to navigate and <kbd>return</kbd> to run shortcuts. Much faster than clicking.

#### Can I pass arguments to a shortcut from the menu?

No. Menu runs have no input. Design the shortcut to prompt, read the clipboard, or pull context itself.

#### Why does running a shortcut sometimes add a “Stop and Output” action to it?

The Shortcuts app automatically inserts a “Stop and Output” action when a shortcut doesn't have a clear final output. This ensures the shortcut has something to return when executed, preventing execution errors. The action appears when shortcuts contain actions that don't naturally produce output, like opening apps. This is not ideal, but it's out of my control.

This does not happen when running shortcuts from the built-in menu bar item.

I have reported it to Apple: [FB19805797](https://github.com/feedback-assistant/reports/issues/703)\
*(Consider duplicating my report. The more duplicates, the more likely Apple will look into it.)*

#### My shortcut fails when it needs “Full Disk Access”

Give Short Run “Full Disk Access” too (“System Settings › Privacy & Security › Full Disk Access”).
Short Run is what actually executes the shortcut, so it needs the same permission as the Shortcuts app.

#### Can I assign hotkeys to individual shortcuts?

No. Use Shortcuts’ own keyboard shortcuts (or Raycast/Alfred) if you want per-shortcut bindings.

#### Can you add sync?

No. iCloud sync is unreliable and causes a huge support burden. It's not worth the effort for this app.

#### Can you add export/import for the shortcuts organization?

Maybe at some point, but I want the app to be mature first, since it commits me to that exact format.

For now, you can [export/import all app data](https://sindresorhus.com/apps/faq#export-settings).

#### Can you support iOS?

No, because there is no way to run shortcuts in the background on iOS.

#### Can you add another menu bar icon option?

Sure! Find an icon you like in the [SF Symbols app](https://developer.apple.com/sf-symbols/) or [here](https://thenounproject.com/icons/), and send me the name or link to it.

#### [More FAQs…](/apps/faq)

<!-- ## Older Versions

- []() for macOS 15+ -->
