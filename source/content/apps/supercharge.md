---
title: Supercharge
subtitle: Elevate your Mac experience
pubDate: 2024-09-29
platforms:
  - macOS
isPaid: true
isMenuBarApp: true
hasSentry: true
setappId: 742
releasesRepo: supercharge-meta
forceHasIosAppIcon: true
mainLinks:
  'Buy': https://sindresorhus.gumroad.com/l/supercharge?wanted=true
requirement: Requires macOS 15.4 or later
# olderMacOSVersions:
#   - '15'
feedbackNote: |
  If you have moved to a new Mac and need to download the app again, you can download it from your [Gumroad receipt email or Gumroad account](https://gumroad.com/help/article/199-how-do-i-access-my-purchase).

  When reporting bugs, try quitting Supercharge, and if the issue disappears, it is likely not an issue with Supercharge. If the issue is still there, try turning off things in the “Tweaks” settings tab until it does not happen anymore, to narrow down which feature is causing the issue, and let me know.

  If the issue is that a keyboard shortcut is not working, it could be [this](/apps/faq#secure-input-problem).

  The Finder context menu items will not show up in any [sync folder like iCloud, Dropbox, OneDrive, etc](#finder-context-menu-icloud)

  If you are seeing the Supercharge icon showing up for drives in the Finder sidebar, see [this](#i-am-seeing-incorrect-icons-for-external-drives-in-the-finder-sidebar-when-enabling-context-menu-items).
---

> [!TIP]
> Also available in the [Power User Bundle](https://sindresorhus.gumroad.com/l/power-user) - Get 3 of my power user apps for 26% off normal price.

Improve your Mac experience with a bunch of useful functionality. Supercharge adds power tools for Mission Control, the Dock, Finder, window management, and more, helping you work faster, reduce friction, and fix everyday macOS annoyances.

*(Every feature is opt-in, so you can enable only what you need)*

#### Highlights

- [Mission Control actions](#mission-control-improvements) — Close, hide, minimize, and quit right inside Mission Control.
- [Dock icon behavior](#dock-icon-click-behavior) — Click to hide/minimize/cycle.
- [Finder power-ups](#finder-context-menu) — Cut/paste files, new file, templates, open in terminal, inline share services, etc.
- [Better window buttons](#green-traffic-light-button-fill) — Red quits app, green fills instead of fullscreen, [yellow hides app](#yellow-traffic-light-button-hide).
- Notifications — Clear all or click with a shortcut.
- Stop Music app from launching when you press Play/Pause.
- [Auto-quit or hide inactive apps](#auto-quit-apps) — Keep focused by automatically managing distraction apps.
- [Keyboard Shortcut Inspector](#keyboard-shortcut-inspector) — See which app owns a global hotkey.
- Utility — [Keep Awake](#keep-awake), Cleaning Mode, Cat Mode, auto-select AirDrop target.
- [Capture text](#capture-text) + [Translate anywhere](#capture-translate-text) — OCR and instant translate from any screen region.
- [Scan QR & barcodes](#scan-qr-codes) — From screen or clipboard, multi-code aware.
- [Isolate Window](#isolate-window) — One window, zero distractions.
- Spotlight keyboard shortcuts - Open clipboard history directly.
- Toggles - Dark Mode, Night Shift, etc.
- Extras — Add Dock & Finder sidebar spacers, change default browser without prompts.
<!-- - [Remap Spotlight/Dictation keys](#remap-spotlight-dictation-keys) — Make the dedicated keys keyboard shortcuts, Supercharge actions, or run shortcuts. -->
<!-- - [Double-tap modifier keys (Fn, Shift, Control, Option, Command) to trigger keyboard shortcuts, Supercharge actions, or run shortcuts](#double-tap-modifier) -->

#### All

- Clear notifications with a keyboard shortcut or from the menu
- Click top visible notification with a keyboard shortcut
- [Close & minimize windows and hide & quit apps directly from Mission Control](#mission-control-improvements)
- [Clicking an active app's Dock icon hides the app, minimizes its windows, or cycles through its windows](#dock-icon-click-behavior)
	- You can also middle-click any running app for the same actions, plus quit.
- Unminimizes an app’s windows (all or one) when activated <sup>(e.g., via <kbd>Command+Tab</kbd>)</sup>
- Hide all windows <sup>(aka. boss mode)</sup>
- [Isolate window](#isolate-window)
- [Automatically quit or hide apps after inactivity](#auto-quit-apps)
- [Capture text from anywhere on screen](#capture-text)
- [Capture and translate text from anywhere on screen](#capture-translate-text)
- Prevent the Music app from auto-opening when you don't want to.
	<span class="list-description">For example, when pressing Play/Pause on your keyboard or AirPods. You can also have it launch another app like Spotify instead. Similar to apps like noTunes and Overkill.</span>
<!-- - [Hyper key](#hyper-key) -->
<!-- - [Remap Spotlight/Dictation keys](#remap-spotlight-dictation-keys) — Make the dedicated keys keyboard shortcuts, Supercharge actions, or run shortcuts. -->
<!-- - [Double-tap modifier keys (Fn, Shift, Control, Option, Command) to trigger keyboard shortcuts, actions, or run shortcuts](#double-tap-modifier) -->
- Prevent accidental app quits[^quit] by instead using <kbd>⇧⌘Q</kbd>, double tap <kbd>Q</kbd> while holding <kbd>⌘</kbd>, or [press and hold <kbd>⌘Q</kbd>](https://github.com/user-attachments/assets/0515e50f-2a93-4369-836e-085ad462fdf8)
- Prevent accidental ⌘W window closes
	<span class="list-description">Adds a safety layer to ⌘W so you don’t nuke the wrong window (perfect for Safari web apps and standalone sites). Pick your gesture: ⇧⌘W, double-tap W while holding ⌘, or press-and-hold ⌘W with a visual timer. Works per-app with an inclusion filter, so you can guard only the apps that matter.</span>
- [Launch any app with a customizable global keyboard shortcut](https://github.com/user-attachments/assets/22bf135a-cc39-45ef-82ef-bf23176f0746)
- [Clicking green traffic light button fills window instead of entering fullscreen](#green-traffic-light-button-fill)
- [Clicking yellow traffic light button hides app instead of minimizing window](#yellow-traffic-light-button-hide)
- Trigger specific Spotlight tabs directly with keyboard shortcuts <sup>(macOS 26+)</sup>
	<span class="list-description">Jump straight to Apps, Shortcuts, Files, or Clipboard History in Spotlight with customizable keyboard shortcuts.</span>
- [Scan QR codes and barcodes from anywhere on screen](#scan-qr-codes)
- Automatically select AirDrop target (macOS 26 only)
	<span class="list-description">Enter a device name to automatically select it when the AirDrop dialog appears.</span>
- Cleaning Mode
	<span class="list-description">Makes your screen black and disables keyboard and mouse to let you safely clean your device. [Screenshot.](https://www.dropbox.com/scl/fi/6vm94elcusix6oqe5su78/434266737-572f4e43-d42a-49c2-925f-4db90ebbfd06-1748011610.mp4?rlkey=r538vzwv0k9ba5rjqhw4goaa7&raw=1)</span>
- Cat Mode
	<span class="list-description">Disables keyboard and mouse to prevent cats and other cute creatures from interfering with your computer. Similar to Cleaning Mode but without blacking out the screen. [Screenshot.](https://www.dropbox.com/scl/fi/tpxsx5i9r1vkjlf2recad/Cat-Mode-1756829427.mp4?rlkey=wfyu7192971mnu19p3i2mmqs4&raw=1)</span>
<!-- - Quit apps when closing their last window (clicking the red traffic light button or <kbd>Command+W</kbd>) (similar to Swift Quit and RedQuits apps)
	- (beta - try the [trial](#trial)) -->
- [Run shortcuts from the menu](#run-shortcuts)
	<span class="list-description">Show your favorite shortcuts from the Shortcuts app in the menu.</span>
	- Also available as an [independent app](/short-run).
- Move files received through AirDrop to a specified folder
	<span class="list-description">Automatically move files from the Downloads folder as soon as they are received.</span>
- Prevent Finder window from opening when receiving through AirDrop
	<span class="list-description">Stops Finder from opening a new window and stealing focus when you receive AirDropped files.</span>
- [Keep computer awake](#keep-awake)
- [Automatically clear clipboard for improved privacy](#automatic-clipboard-clearing)
- [Prevent accidental window closing for certain apps](#prevent-accidental-window-closing)
- Prevent Dock from showing when moving mouse to screen edge
	<span class="list-description">Useful if you want to hide the Dock entirely or only show it with a keyboard shortcut. Does not apply to fullscreen.</span>
- Open new window by Shift+clicking a running app in the Dock
	<span class="list-description">Makes it easy to open a new window for an app, similar to Windows. Works by simulating Command+N in the app, so it may not work correctly in all apps.</span>
	- (beta)
- Launch alternative app when clicking Finder icon in the Dock (e.g., Bloom, QSpace, Path Finder).
- Auto-dismiss Shortcuts “Running your automation” notifications
	<span class="list-description">Automatically dismisses the “Running your automation” notifications that appear when running Shortcuts automations.</span>
- Finder: Move files by cutting[^commandx] (<kbd>Command+X</kbd>) and pasting (<kbd>Command+V</kbd>)
- Finder: Open files with <kbd>Return</kbd> (you can then rename with <kbd>Shift+Return</kbd> or <kbd>F2</kbd>)
- Finder: Create new text file with <kbd>Option+N</kbd> *([video](https://github.com/user-attachments/assets/cb2c4606-12eb-4915-a64c-9b8ac3e123cf))* or from the [context menu](#finder-context-menu)
	<span class="list-description">Set default extension, auto-open after naming, and choose app.</span>
- Finder: Move files to the trash with <kbd>⌫</kbd> (Delete) instead of <kbd>⌘⌫</kbd>
- Finder: Go back to the previous folder with <kbd>⌫</kbd> (Delete)
- [Finder: Adds many useful actions to the context menu:](#finder-context-menu) copy path, move to, open folder with, AirDrop, folder colors, etc.
- Finder: Auto-adjust column widths to filenames in column view, or do it once with a keyboard shortcut
	- Known (unfixable) issues:
		- Columns may not adjust correctly in synced folders due to sync status icons.
		- Columns may not expand fully if the Finder window is narrow. A workaround is to make the Finder window very wide.
	- **If you are buying Supercharge just for this feature. Please try out the [trial](#trial) first.**
- Finder: Invert selection (deselects what's currently selected and selects everything that wasn't selected)
- Finder: Move or copy selected files with a keyboard shortcut
	<span class="list-description">Shows a system file dialog to choose where to move files.</span>
- Finder: Open new window when activating without windows
	<span class="list-description">By default, when you <kbd>Command-Tab</kbd> to Finder without any windows open, nothing happens. This ensures a new window opens automatically.</span>
- Finder: Make <kbd>⌘Q</kbd> close all windows and hide Finder
	<span class="list-description">By default, <kbd>⌘Q</kbd> does nothing in Finder.</span>
- Finder: Customize clicking Finder icon in Dock
	<span class="list-description">Choose what happens when you click the Finder icon in the Dock: System default behavior, open new window when already focused (first click focuses, subsequent clicks open new windows), or always open new window.</span>
- [Adds many useful services to “Services” in context menus (like in Finder):](#macos-services) copy path, move to, AirDrop, etc.
- Exclude AirDrop, Mail, and Messages from the system Share menu
  <span class="list-description">These are usually forced to be shown by macOS.</span>
- Center mouse pointer on primary display when waking and unlocking
	<span class="list-description">Helps you quickly locate the mouse pointer after returning to your Mac. Also available via keyboard shortcut.</span>
- Disable delay when showing Dock.
	<span class="list-description">Does not apply to fullscreen.</span>
- Minimize all windows or just all except frontmost with keyboard shortcuts and from the menu.
- Minimize all windows of the active app except frontmost with keyboard shortcuts and from the menu.
- Unminimize all windows or first window of active app with keyboard shortcut.
- Auto-copy screenshots to clipboard.
	<span class="list-description">Useful if you want screenshots saved and also instantly available to paste. Works with the built-in screenshot tool.</span>
- [Show markup tools by default in screenshot preview](https://github.com/user-attachments/assets/20b0cfe8-d588-4329-9132-9120b32da7ff)
- Auto-open screenshot preview after capturing
- [Show input devices in the Sound menu bar item menu](https://github.com/user-attachments/assets/e6015206-c927-4c97-8f66-7408231d4f23)
	<span class="list-description">By default, it only shows output devices.</span>
- Archive old items in the Downloads folder automatically
	<span class="list-description">Keeps your Downloads folder tidy by moving older items to a separate location based on when they were added.</span>
- [Mail: Copy message link](#mail-copy-message-link)
- [Notes: Copy note link](#notes-copy-note-link)
- Safari: Use <kbd>Delete</kbd> and <kbd>Shift+Delete</kbd> to navigate back and forward
- Toggle Finder with a keyboard shortcut <sup>(aka. [visor mode](https://totalfinder.binaryage.com/visor))</sup>
- Show the [menu bar window](https://github.com/user-attachments/assets/1b8e2e12-187a-4d32-8ba3-c13f154de9e0) for the Passwords app with a keyboard shortcut
- Show the [menu bar window](https://github.com/user-attachments/assets/567bbbf5-12a1-45be-8ffa-93712574d4a0) for the Weather app with a keyboard shortcut
- Show the window for the “Now Playing” menu bar item with a keyboard shortcut
- [Change default browser](https://github.com/user-attachments/assets/b58a04da-2bdc-4bd0-bed4-ba62ba456491) (without a prompt)
	- Also available as an [independent app](/default-browser).
- Auto-open downloaded calendar event (`.ics`) files and move them to trash after import
	<span class="list-description">Optionally remove alarms from events.</span>
- Lowercase file extension of files in Downloads folders
	<span class="list-description">For example, images from iPhone, which usually have `.JPG` or `.HEIC` extensions. Applies to both the local Downloads folder and the Downloads folder in iCloud Drive.</span>
- [Make brightness and volume key adjustments more precise with half and quarter-step increments](https://github.com/user-attachments/assets/e994755b-94ca-4e3c-8f70-5d3bffc3aed1)
- [Export/import (backup) settings for any apps](#export-import-app-settings)
- Toggle Terminal with a keyboard shortcut
- [Offers to install apps from mounted DMG files](https://github.com/user-attachments/assets/5ecb9b0b-5719-4382-98a0-c3316bd20a6b)
- Toggle Stage Manager directly from its menu bar item
	<span class="list-description">Normally, clicking it would open a window with a toggle. This saves one click.</span>
- Hide mouse pointer with keyboard shortcut
	<span class="list-description">Reappears on movement or when the shortcut is pressed again.</span>
- Show desktop (menu action)
- Sleep displays (menu action and keyboard shortcut)
	<span class="list-description">Puts all your Mac’s screens to sleep.</span>
- Quit all apps (menu action and keyboard shortcut)
	<span class="list-description">Optionally exclude specific apps.</span>
- Quit all apps except frontmost (menu action and keyboard shortcut)
	<span class="list-description">Optionally exclude specific apps.</span>
- Eject all disks (menu action and keyboard shortcut) (optionally exclude some)
- Dim icons of hidden apps in the Dock
- Pick color on screen and copy (menu action and keyboard shortcut) (Hex, RGB, OKLCH)
- Toggle mute sound
	<span class="list-description">Mute or unmute your Mac sound with a keyboard shortcut, from the menu, or using Shortcuts.</span>
- Toggle mute microphone
	<span class="list-description">Mute or unmute your microphone with a keyboard shortcut, from the menu, or using Shortcuts. Can show a menu bar icon for the current state. [Screenshot.](https://www.dropbox.com/scl/fi/dh8qprcekcjftnjc1hy2l/Mute-microphone-Screen-Shot-2025-07-31-at-19.16.08-1753983397.mp4?rlkey=i9c1ehd348v07g72t2ahpqcsz&raw=1)</span>
- Toggle dark mode
- Toggle [Night Shift](https://support.apple.com/en-us/102191)
- Toggle [True Tone](https://support.apple.com/en-us/102147)
- Toggle low power mode
- Toggle grayscale mode[^grayscale]
- Toggle desktop icons and widgets visibility
- Toggle [hot corners](https://support.apple.com/guide/mac-help/mchlp3000/mac)
- Toggle function keys (switch between using F1, F2, etc., as standard function keys or media keys)
	<span class="list-description">Only supported for the built-in MacBook keyboard and Magic Keyboard.</span>
- Toggle iOS notifications
	<span class="list-description">Only works if your Mac supports notifications from iOS.</span>
- Control keyboard brightness with customizable keyboard shortcuts
	<span class="list-description">Only supported for the built-in MacBook keyboard.</span>
- Clear clipboard
- Empty trash keyboard shortcut
- [Clicking a Dock folder reveals it in Finder instead of showing its contents](#dock-folder-click)
- Open system settings directly (usually requires a lot of clicks):
	- Hide My Email
	- Private Relay
	- VPN & Filters
- [Only show sound menu bar icon when either muted or unmuted](https://github.com/user-attachments/assets/10447e39-f288-406b-a504-6ab7b8fcf261)
- [Keyboard shortcut inspector](#keyboard-shortcut-inspector)
- Add [Dock spacers](#dock-spacers)
- Add [Finder sidebar spacers](#finder-sidebar-spacers)
- Access hidden iMac accent colors
	<span class="list-description">Apply the special accent colors from iMac models on any Mac. These colors are normally only available on their respective iMac models. Note: iMac computers have fixed model accent color that cannot be modified through this feature. [Screenshot.](https://www.dropbox.com/scl/fi/oq8v03kvqj8kq4tnipqsz/Screen-Shot-2025-10-06-at-20.40.35-1759751136.png?rlkey=756uo6hmfepec095ibzcbw1pb&raw=1)</span>
- Disable Command+Tab app switcher
	<span class="list-description">Useful to prevent accidental activation if you don't use the app switcher.</span>
- Remove Caps Lock activation delay
	<span class="list-description">Makes Caps Lock respond instantly.</span>
- TextEdit: Open a blank document instead of file picker on launch
- Override Maps app language
	<span class="list-description">macOS doesn't allow changing the Maps app language in System Settings. This fixes that. Useful when search doesn't work well with your system language.</span>
- Reset [privacy permissions](https://support.apple.com/en-vn/guide/mac-help/mchl211c911f/mac) for any apps
- Flush DNS cache
- Shortcuts actions

<!-- - [Show seconds hand in the Clock app's Dock icon](https://github.com/user-attachments/assets/b1d025dc-0465-4d0f-adf8-48bc079ad438) -->

Mentions:
- [Video review](https://www.youtube.com/watch?v=hp-WMYZQ75U)
	- [Follow-up](https://www.youtube.com/watch?v=srZH0eTjylU)
- [Article about the app](https://todayonmac.com/supercharge/)
- [This App Brings Some of My Favorite Windows Features to Mac - Lifehacker](https://lifehacker.com/tech/this-app-brings-some-of-my-favorite-windows-features-to-mac)
- [Best Mac App Runner-Up - Best Apps of the Year - MacStories](https://www.macstories.net/stories/macstories-selects-2025-recognizing-the-best-apps-of-the-year/#best-mac-app-runner-up)
- [11 Mac Apps I (Almost) Can't Live Without - FromSergio](https://www.youtube.com/watch?v=ozVkroyqVGU&t=122s)
- [Tiny macOS utility apps I love – Part 6](https://creativerly.com/tiny-macos-utility-apps-part-6/#supercharge)
- [Video walkthrough (Spanish)](https://www.youtube.com/watch?v=jvwbDM4cfC8)

[^commandx]: Without this feature, you have to first copy (<kbd>Command+C</kbd>) and then remember to move (<kbd>Option+Command+V</kbd>). The feature works by overriding the normal cut <kbd>⌘X</kbd> keyboard shortcut when Finder is active and executes a copy <kbd>⌘C</kbd> instead. When you then paste <kbd>⌘V</kbd>, it executes the native move <kbd>⌥⌘V</kbd> keyboard shortcut. So really, it's Finder moving the files. This app just makes the keyboard shortcuts more intuitive. If you don't paste, the files just stay in place. This feature also works with the Forklift app.

[^quit]: The <kbd>Q</kbd> key is next to <kbd>W</kbd>, making it easy to accidentally hit <kbd>Command+Q</kbd> (quit) when reaching for <kbd>Command+W</kbd> (close window).

[^grayscale]: Grayscale mode on macOS can be a useful tool for various purposes. It can help reduce eye strain during long work sessions, especially in low-light environments. For designers and developers, it's valuable for checking contrast and readability of user interfaces without the influence of color. Content creators may use it to evaluate the tonal balance of images or videos. Additionally, some users find that grayscale helps minimize distractions and improve focus by reducing the visual appeal of non-work-related apps and websites. While initially an adjustment, many users report increased productivity and a more mindful approach to computer usage when employing grayscale mode periodically.

---

### Features explained

<br>

<!-- ##### Hyper key {#hyper-key}

Remaps <kbd>Caps Lock</kbd> to function as a Hyper key—a single key that simultaneously activates all standard modifiers (Control + Option + Shift + Command). This enables the creation of highly unique shortcuts that are unlikely to conflict with existing ones, making them both easy to remember and quick to use. -->

#### Run shortcuts {#run-shortcuts}

Add shortcuts from the [Shortcuts](https://support.apple.com/guide/shortcuts-mac/intro-to-shortcuts-apdf22b0444c/mac) app to the menu for quick access. Show them in the main menu or a submenu. This is especially powerful as shortcuts can run AppleScript and shell scripts.

You can even configure shortcuts to only show up when specific apps are active.

Launch apps, run scripts, automate tasks — anything Shortcuts can do, now just one click away.

[Screenshot](https://www.dropbox.com/scl/fi/ny886w93chpav0b325ioi/441329057-67290c47-4d78-490f-b0b8-f263ebc1022d-1748012141.png?rlkey=kf2ha9ygkvd4iu3zme8a0wo07&raw=1)

Example shortcuts:
- [Presentation Mode](https://www.icloud.com/shortcuts/c559563486a74b1dafb6ca2cb05e2cb5) - Turns on “Do Not Disturb”, keeps screen awake, and hides desktop icons.
- [Toggle “Do Not Disturb”](https://www.icloud.com/shortcuts/17a79c58e70446c5a0f1c1c89653a4aa)
- [Flush DNS cache](https://www.icloud.com/shortcuts/a91b36f037d74cd7a647284e8c376f3d)
- [Keep computer awake for 1 hour](https://www.icloud.com/shortcuts/b5a51cb8ef664377a0536de34711a641)

**How is this better than the built-in Shortcuts menu bar item?**

- One less menu bar item.
- Closes the menu when running a shortcut.
- Shortcuts can be configured to only show up for specific apps.
- Shortcuts can be shown in a submenu.
- Visually less noisy.

#### Keep awake {#keep-awake}

Prevent your Mac from sleeping and optionally prevent your screen from dimming.

A menu bar icon can be shown when active for visual indication.

For advanced features like timing, check out [Lungo](/lungo).

> [!IMPORTANT]
> It will not prevent your computer from sleeping if you close the lid (except when connected to power and an external display). This is a macOS safety precaution and out of my control.

> [!NOTE]
> This will not prevent you from appearing idle in apps like Slack, Teams, or Discord, which track mouse movement to determine activity.

#### Dock icon click behavior {#dock-icon-click-behavior}

By default, clicking an app's Dock icon when the app is active does nothing. With Supercharge, you can make it either hide the app, minimize all its windows, or cycle through the app's windows. This can be particularly useful for quickly clearing your workspace or navigating between windows.

You can also choose to unminimize all windows instead of just one when clicking a Dock icon of an app with minimized windows.

#### Clicking green traffic light button fills window instead of entering fullscreen {#green-traffic-light-button-fill}

Makes clicking the green traffic light button fill the window to fit the screen instead of entering fullscreen mode. Hold <kbd>Option</kbd> while clicking for the default fullscreen behavior. Click again to restore the previous window size.

[Screenshot](https://github.com/user-attachments/assets/41dd0f46-05f7-46f2-b9a5-a5ae441da8a9)

*It requires the “Displays have separate Spaces” system setting to be enabled because it relies on the window tile functionality, which is only available then.*

#### Clicking yellow traffic light button hides app instead of minimizing window {#yellow-traffic-light-button-hide}

Makes clicking the yellow traffic light button hide the app instead of minimizing the window. Hold <kbd>Option</kbd> while clicking for the default minimize behavior.

#### Prevent accidental window closing for certain apps {#prevent-accidental-window-closing}

Disables the red traffic light button for selected apps to prevent accidentally closing windows. This is particularly useful for apps where you want to be extra careful about not losing your work.

You can hold <kbd>Option</kbd> while clicking the red traffic light button to close the window.

#### Keyboard shortcut inspector {#keyboard-shortcut-inspector}

Detects which apps are listening to or have registered a certain global keyboard shortcut. This is useful for troubleshooting keyboard shortcut conflicts between apps. Simply press any keyboard shortcut combination to see which apps are handling it.

[Screenshot](https://github.com/user-attachments/assets/0f3ddfaa-caf5-471d-a880-93c97952dada)

#### Automatic clipboard clearing {#automatic-clipboard-clearing}

The clipboard is a common privacy risk as it can retain sensitive content (passwords, credit card numbers, private messages) long after you've copied it. Any app on your Mac can silently read the clipboard at any time.

When enabled, it automatically clears the clipboard:
- About one minute after copying (timer restarts on new copy)
- When your Mac sleeps or locks
<!-- - 10 seconds after pasting with Command+V -->

This ensures sensitive data doesn't linger in your clipboard longer than needed, protecting you from both accidental exposure and malicious apps.

<!-- #### Double-tap modifier key {#double-tap-modifier}

Trigger actions by quickly double-tapping modifier keys (Fn, Shift, Control, Option, Command). Configure each key independently — left and right variants can have different actions.

For each modifier, choose to:
- Trigger a keyboard shortcut
- Run a built-in action (toggle dark mode, show desktop, etc.)
- Run a shortcut from the Shortcuts app

Great for quickly launching apps (through a shortcut), toggling settings, or triggering automations without memorizing complex key combinations.

**Notes:**
- The <kbd>Fn</kbd> key will not work if you have configured a “Press 🌐 key to” action in “System Settings → Keyboard”.
- macOS uses double-tap <kbd>Control</kbd> for Dictation by default. You may want to disable that in “System Settings → Keyboard → Dictation” if using <kbd>Control</kbd> here. -->

#### Isolate window {#isolate-window}

Hides all other apps and minimizes all other windows of the current app, leaving only the frontmost window visible. It's like a turbocharged “Hide Others”, but also minimizes your extra windows in the current app, so you see just the one you care about.

Perfect for quickly clearing away distractions when you have many windows open (for example, multiple Safari windows across profiles).

Available as a menu action, a customizable keyboard shortcut, and as a Shortcuts action for automations.

#### Automatically quit or hide inactive apps {#auto-quit-apps}

Automatically quits or hides apps when you're not using them, to maintain focus and free system resources. Like [Quitter](https://marco.org/apps#quitter) or Raycast's [Auto Quit](https://manual.raycast.com/window-management/auto-quit-applications), but built into Supercharge.

Set up rules per app: quit or hide after a certain amount of inactivity. You might hide Slack after 3 minutes but quit X (Twitter) after 5 minutes, depending on how you work.

Pauses for all apps while any camera/mic is in use or screen is being captured. Won't affect the active app. Menu bar-only apps won't be affected since they never become active or inactive.

[Screenshot](https://www.dropbox.com/scl/fi/am443hh5uuglk8fiwmdqk/Auto-quit-feature-Screen-Shot-2025-11-06-at-15.45.16-1762418767.png?rlkey=fbbdi22wsdclq1cxeiwiijlam&raw=1)

> [!TIP]
> To enable only during specific times, places, or Focus modes, you can automate it with the Shortcuts app.

*Available on macOS 26 or later. Currently experimental — feedback welcome!*

**Why use auto-quit instead of just closing apps manually?**

Apps don't close themselves. You check Slack once, then switch to other work and it sits there all day using 3GB of memory, spiking CPU on animated GIFs, draining battery. Same with Discord, Teams, Twitter. They accumulate. You could manually quit them each time, but you won't. Nobody does consistently. Even when backgrounded, these Electron apps consume resources that macOS App Nap can't fully reclaim. Auto-quit handles it automatically: apps only run when you're actually using them, not because you forgot to close them hours ago. Removes both the resource drain and the notification temptation that breaks your flow state.

**Why not apply to all apps automatically?**

Safety and control. You don't want your code editor or music player suddenly quitting. Each app needs different timing: hide Slack after 3 minutes, quit Mail after 10. Manual selection ensures only resource-heavy, distraction-prone apps get auto-quit—not your productivity tools or background utilities.

#### Add spacers to the Finder sidebar {#finder-sidebar-spacers}

Creates visual separators in the Finder sidebar to help organize your folders into groups. Simply drag the spacer between two folders in the sidebar. The spacer appears as an invisible folder.

> [!NOTE]
> The spacer still shows a folder icon. It's not possible to hide this.

[Screenshot](https://www.dropbox.com/scl/fi/7ndp0sdiocgf0n7xdbolz/441615369-d929e3fe-6605-46f6-a99f-6f0f3486a88e-1748012169.png?rlkey=xr7716dr9xiyim0pu80qv6n5x&raw=1)

#### Finder context menu additions {#finder-context-menu}

Adds the following actions (can be customized) directly in the right-click menu in Finder:

- New Text File
	<span class="list-description">Shown only when right-clicking an empty area in Finder.</span>
- New From Template
	<span class="list-description">Creates new files from templates. For example, a Markdown or Excel file. Templates can be organized in subfolders. Click a folder to copy its entire structure, or navigate into it to select individual files. Shown only when right-clicking an empty area in Finder, not a file. Supports dynamic placeholders in filenames (like `Diary {datetime-fixed}` → `Diary 2025-02-14 15.30`). And you can even have the file automatically open after naming it. [Screenshot.](https://github.com/user-attachments/assets/cb401a0e-2e40-4714-9493-b91563a7b387)</span>
- Open in New Window
	<span class="list-description">Opens the folder in a new window instead of a tab, even if you have set new windows to open as tabs. This action also shows up in the context menu for sidebar items. Useful when you want to view multiple folders side by side or drag items between locations.</span>
- Image/Video Dimensions
- File Size
- Date Created
	<span class="list-description">Shows the file's creation date. Click to copy.</span>
- Date Modified
	<span class="list-description">Shows when the file was last modified. Click to copy.</span>
- Date Added
	<span class="list-description">Shows when the file was added to the current folder. Click to copy.</span>
- Copy Path
- Copy Filename
- Copy File URL
	<span class="list-description">Useful for deep links. Clicking such link reveals it in Finder.</span>
- Copy Markdown Link
	<span class="list-description">Useful for deep links. Clicking such link reveals it in Finder.</span>
- Copy Contents
	<span class="list-description">Copies the contents of text files to the clipboard.</span>
- Open Folder With
	<span class="list-description">[Missing apps?](/supercharge#add-app-open-folder-with)</span>
- Make Symlink
- Move To
	<span class="list-description">Moves files and folders to a chosen location.</span>
- Copy To
	<span class="list-description">Copies files and folders to a chosen location.</span>
- Share
	<span class="list-description">Shows the old-style Share item that is a submenu instead of a separate popover, which is faster to access. You can exclude AirDrop, Messages, and Mail from the menu, which are normally forced to be shown. However, there is no way to hide the existing Share item.</span>
- Inline Share Services
	<span class="list-description">Shows selected share extensions directly in the context menu for faster sharing. Customize which services appear in settings. [Screenshot](https://www.dropbox.com/scl/fi/wqlofapn6k11s3x2atmcp/Screen-Shot-2025-10-19-at-23.52.14-1760892902.png?rlkey=ek55ijtrjufe6if922cll2k2j&raw=1)</span>
- Open in App
	<span class="list-description">Adds menu items like “Open in Visual Studio Code” directly to the Finder context menu. Text editors show up for folders and text files, while other apps only show up for types they support. [Screenshot.](https://github.com/user-attachments/assets/980340bc-a257-475c-9a02-7b98853df9a7)</span>
- Open in Terminal
	<span class="list-description">Shown only when right-clicking a folder or an empty area in Finder. Supports Terminal, iTerm, Ghostty, kitty, WezTerm, Alacritty, and Warp.</span>
- AirDrop
	<span class="list-description">Shares files via AirDrop.</span>
- Email
	<span class="list-description">Creates a new email message in the default email app with the selected files as attachments. Works with Mail, Outlook, Spark, Mimestream, Airmail, Canary Mail, and maybe other apps. Not Thunderbird.</span>
- Run Shortcut
	<span class="list-description">Shares files with a shortcut from the Shortcuts app.</span>
- Update Modified Date
- Folder Color
	<span class="list-description">Changes the color of folders. [Screenshot.](https://github.com/user-attachments/assets/0687455b-61d3-4fdd-a863-1e378a3701d5)</span>
- Toggle Hidden Files
	<span class="list-description">Toggles visibility of hidden files.</span>
- New Folder Inside
	<span class="list-description">Creates a new folder inside the selected folder and automatically opens it for renaming. Only shown when selecting a single folder.</span>
- Flatten Folder
	<span class="list-description">Moves all files from subdirectories to the folder's root, eliminating nesting. Useful for cleaning up messy downloads or simplifying complicated folder structures. Handles duplicate names automatically.</span>
- Make Executable
	<span class="list-description">Makes files executable, similar to `chmod +x` in the terminal. Useful for shell scripts.</span>
- Invert Selection
	<span class="list-description">Selects the files and folders in Finder that are not selected.</span>
- Delete Immediately
	<span class="list-description">Permanently deletes files and folders without sending them to the Trash.</span>
- Copy Checksum
	<span class="list-description">SHA-1, SHA-256, SHA-384, SHA-512, MD5, CRC32</span>
- Unquarantine
	<span class="list-description">Removes the quarantine flag that macOS adds to downloaded files and apps. This removes [security prompts](https://github.com/user-attachments/assets/adbf3c7e-8fee-4cd9-9a90-3958badfa94e) and restrictions for trusted items.</span>
- Scan QR Code
	<span class="list-description">Scans QR codes in images and copies the content to the clipboard. Only shown when right-clicking image files.</span>
- Print
	<span class="list-description">Prints files directly with the default printer without showing any dialog.</span>
- Remove Location Metadata
	<span class="list-description">Removes GPS location metadata from images to protect your privacy.</span>
- Remove All Metadata
	<span class="list-description">Removes all metadata (EXIF, GPS, etc.) from images.</span>
- Lock / Unlock
	<span class="list-description">Locks or unlocks files and folders. Locked items cannot be modified, renamed, or deleted until unlocked. Same as “Finder › Get Info › Locked”.</span>
- Git: Go to Root
	<span class="list-description">Navigates to the Git repository root folder in the current Finder window. Only shown when inside a Git repository.</span>
- Git: Show on GitHub
	<span class="list-description">Opens the selected file or folder on GitHub at the current commit. Only shown when inside a GitHub repository with an “origin” or “upstream” remote pointing to GitHub.</span>
- App: Bundle Identifier
	<span class="list-description">Shows the app's bundle identifier. Only shown when selecting a single app. Click to copy.</span>
- App: Version
	<span class="list-description">Shows the app's version. Only shown when selecting a single app. Click to copy.</span>
- App: Show on App Store
	<span class="list-description">Opens the app's page in the App Store app. Only shown when selecting a single app.</span>
- App: Copy App Store URL
	<span class="list-description">Copies shareable links to the App Store pages of the selected apps.</span>
- Is Identical
	<span class="list-description">Shows whether two or more selected files are identical.</span>
- Is Identical (Interactive)
	<span class="list-description">Opens a comparison window showing whether selected files are identical. Supports drag-and-drop to add more files. Groups identical files together and lists unique files separately. [Screenshot.](https://www.dropbox.com/scl/fi/cctbogzq60huyxceoa5xh/Is-Identical-Supercharge-Screen-Shot-2025-12-11-at-04.59.12-1765425592.png?rlkey=gzwhyzvgmakzz5r14nvrkko1s&raw=1)</span>

*They appear at the bottom of the context menu. There is no way to change that. [They also won't appear in iCloud, Dropbox, OneDrive or any other sync folder.](#finder-context-menu-icloud)*

#### Services {#macos-services}

- Copy Path
- Copy Filename
- Copy File URL
	<span class="list-description">Useful for deep links. Clicking such link reveals it in Finder.</span>
- Copy Markdown Link
	<span class="list-description">Useful for deep links. Clicking such link reveals it in Finder.</span>
- Copy File Contents
	<span class="list-description">Copies the contents of text files to the clipboard.</span>
- Copy Checksum (SHA-1, SHA-256, SHA-384, SHA-512, MD5, CRC32)
	<span class="list-description">Copies checksums of files.</span>
- AirDrop
	<span class="list-description">Shares files via AirDrop.</span>
- Run Shortcut
	<span class="list-description">Shares files with a shortcut from the Shortcuts app.</span>
- Scan QR Code
	<span class="list-description">Scans QR codes from images and copies their content to the clipboard.</span>
- Email
	<span class="list-description">Creates a new email message in the default email app with the selected files as attachments. Works with Mail, Outlook, Spark, Mimestream, Airmail, Canary Mail, and maybe other apps. Not Thunderbird.</span>
- Open URLs
	<span class="list-description">Opens all given URLs or those automatically detected in text.</span>
- Copy URLs
	<span class="list-description">Copies all given URLs or those automatically detected in text.</span>
<!-- - Remove Location Metadata
	<span class="list-description">Remove GPS location metadata from images.</span>
- Remove All Metadata
	<span class="list-description">Remove all metadata (EXIF, GPS, etc.) from images.</span> -->

Finder-specific services:

- Move To…
	<span class="list-description">Moves files and folders to a chosen location.</span>
- Copy To…
	<span class="list-description">Copies files and folders to a chosen location.</span>
- Open in Terminal
	<span class="list-description">Shown only when right-clicking a folder in Finder. Supports Terminal, iTerm, Ghostty, kitty, WezTerm, Alacritty, and Warp.</span>
- Update Modified Date
	<span class="list-description">Updates the modified date of files and folders to the current time.</span>
- Make Symlink
- Unquarantine
	<span class="list-description">Removes the quarantine flag that macOS adds to downloaded files and apps. This removes [security prompts](https://github.com/user-attachments/assets/adbf3c7e-8fee-4cd9-9a90-3958badfa94e) and restrictions for trusted items.</span>
- New Folder Inside
	<span class="list-description">Creates a new folder inside the selected folder and opens it for renaming.</span>
- Flatten Folder
	<span class="list-description">Moves all files from subdirectories to the folder's root, eliminating nesting.</span>
- Make Executable
	<span class="list-description">Makes files executable, similar to `chmod +x` in the terminal. Useful for shell scripts.</span>
- New Text File in Finder
	<span class="list-description">Creates a new text file in the current folder. You must right-click an existing file or folder to access it.</span>
- Invert Selection in Finder
	<span class="list-description">Selects the files and folders in Finder that are not selected.</span>
- Toggle Hidden Files in Finder
	<span class="list-description">Toggles visibility of hidden files.</span>
- Lock
	<span class="list-description">Locks files and folders. Locked items cannot be modified, renamed, or deleted.</span>
- Unlock
	<span class="list-description">Unlocks files and folders, allowing them to be modified, renamed, or deleted.</span>
- Are Files Identical?
	<span class="list-description">Shows whether two or more selected files are identical.</span>
- Are Files Identical? (Interactive)
	<span class="list-description">Opens a comparison window showing whether selected files are identical. Supports drag-and-drop to add more files. Groups identical files together and lists unique files separately.</span>
<!-- - Open in New Finder Window
	<span class="list-description">Opens the folder in a new window instead of a tab, even if you have set new windows to open as tabs.</span> -->
<!-- - Delete Immediately
	<span class="list-description">Permanently delete files and folders without moving to Trash.</span> -->

*[macOS Services](https://macreports.com/what-is-the-services-menu-in-macos/) are built-in quick actions available in right-click and app menus system-wide. They let you perform tasks like copying file info or text without leaving your current app. Supercharge adds extra, genuinely useful services to make these menus even more powerful.*

#### Capture text from anywhere on screen {#capture-text}

Select any region of your screen to instantly copy the text, even if it's unselectable. Great for extracting text from images, PDFs, presentations, or any other content.

Powered by macOS’ built-in OCR. Text quality and language support depend on the system, not the app.

[Screenshot](https://www.dropbox.com/scl/fi/6t4hst8wtbnm9k5hvrg1q/Capture-Text-Screen-Shot-2025-09-02-at-21.32.17-1756825559.mp4?rlkey=hztcfyrcba7v7hn7ex34tjy2y&raw=1)

*Check out my [Text Lens](/text-lens) app for more features.*

**Supported languages**

- English
- French
- Italian
- German
- Spanish
- Portuguese
- Chinese, Simplified
- Chinese, Traditional
- Cantonese, Simplified
- Cantonese, Traditional
- Korean
- Japanese
- Russian
- Ukrainian
- Thai
- Vietnamese
- Arabic
- Arabic, Najdi

And on macOS 26 and later:
- Turkish
- Indonesian
- Czech
- Danish
- Dutch
- Norwegian Nynorsk
- Norwegian Bokmål
- Malay
- Polish
- Romanian
- Swedish

#### Capture and translate text from anywhere on screen {#capture-translate-text}

Select any region of your screen to instantly translate text, even from images or unselectable text.

- [Screenshot](https://github.com/user-attachments/assets/e7c6b336-6b70-4dfe-bba1-ba6ca18907c0)
- [Supported languages](https://www.apple.com/macos/feature-availability/#translate-system-wide-translation) (except Hindi)

#### Scan QR codes and barcodes {#scan-qr-codes}

Select any region of your screen or use an image from your clipboard to instantly scan QR codes and barcodes and copy their content to the clipboard. Supports scanning multiple codes at once.

- [Screenshot](https://github.com/user-attachments/assets/caa5aed9-5db2-460e-bbbb-15fae45a5195)
- [Supported barcodes](https://developer.apple.com/documentation/vision/vnbarcodesymbology#Supported-Symbologies)

#### Copy message link in Mail {#mail-copy-message-link}

When you are in the Mail app, you can [open the Supercharge menu](https://github.com/user-attachments/assets/5cce205b-6743-4a60-958c-074a308ccc68) to copy a direct link to one or more selected messages. You can also set up a keyboard shortcut for this. Copying a message link can be useful if you want to refer to specific emails in other contexts. The link will look like this: `message://%3c66e85e1db33c7_961cfc499cd@lowworker-c6756b946-4rskj.mail%3e`.

#### Copy note link in Notes {#notes-copy-note-link}

When you are in the Notes app, you can [open the Supercharge menu](https://github.com/user-attachments/assets/028c2952-d708-4eda-ad39-613767532eb7) to copy a direct link to one or more selected notes. You can also set up a keyboard shortcut for this. Copying a note link can be useful if you want to refer to specific notes in other contexts, like in a task manager or calendar event. The link will look like this: `applenotes:note/933C49CC-04F4-5F21-A3EE-2CA93AFC88DD`. When clicked, it opens directly in the Notes app.

#### Close and minimize windows and hide and quit apps directly from Mission Control {#mission-control-improvements}

Enhances Mission Control by letting you close windows or quit apps by right-clicking the hovered window and use keyboard shortcuts (⌘W, ⌘Q, ⌘H, ⌘M) on the window you are hovering over. This makes window management more efficient as you don't have to exit Mission Control to perform these actions. [Example](https://github.com/user-attachments/assets/23c71431-4d3b-4913-b484-3a3f0b7b2b07)

Why not add an “X” overlay button on previews? Because right-click is faster and easier: you can click anywhere on the preview instead of hunting a tiny target. It keeps Mission Control visually clean, reduces misclicks, and avoids fighting its animations.

#### Dock folder click behavior {#dock-folder-click}

By default, clicking a folder in the Dock shows its contents in a popover. With Supercharge, you can make it directly reveal the folder in Finder instead. Does not work with smart folders.

#### Export/import app settings {#export-import-app-settings}

Back up and restore settings for Mac apps. Export to `.app-settings` files, then import on any Mac that has Supercharge.

[Video](https://github.com/user-attachments/assets/82727408-3acb-4c18-91c6-428f1e0ad8c5)

**How it works**

- Export: Select apps to create backup files (saved to Downloads)
- Import: Double-click `.app-settings` files to restore

**Compatibility**

- Works: Apps that store settings in the standard way ([UserDefaults](https://en.wikipedia.org/wiki/Defaults_(software))). Most native Mac apps do, like: Apple apps, my apps, Things, OmniFocus, etc.
- Doesn’t work: Electron/Chrome-based apps and web wrappers (Slack, VS Code, Discord, Spotify, Notion) or apps that store settings outside UserDefaults

**Tips**

- Verify mission-critical apps before relying on this for migrations
- `.app-settings` are standard [Property List](https://en.wikipedia.org/wiki/Property_list) files, and can be opened in any text editor
- Use "Export All" for complete backup (timestamped folder)

### For Windows switchers {#from-windows}

Just moved to macOS from Windows? Supercharge helps you feel at home:

- Use <kbd>Command+X</kbd> and <kbd>Command+V</kbd> to move files in Finder — just like Cut and Paste in Windows Explorer.
- Quit apps by closing their last window — like most Windows apps.
- Fill windows to screen size instead of entering fullscreen — matches Windows maximize behavior.
- Hide apps by clicking their Dock icon — like minimizing to the taskbar in Windows.
- Press <kbd>Return</kbd> to open files in Finder (rename with <kbd>F2</kbd> or <kbd>Shift+Return</kbd>).
- <kbd>Delete</kbd> moves files to the trash (no need for <kbd>Command+Delete</kbd>).
- Create new text files in Finder with <kbd>Option+N</kbd> or from the right-click menu — just like in Windows Explorer.
- Add “Move To” and “Copy To” to Finder’s right-click menu — like in Windows.
- Open Terminal from Finder — like “Open in Terminal” in Windows Explorer.
- Restore all app windows when focusing an app — like taskbar behavior in Windows.
- “Delete Immediately” in Finder’s right-click menu — like <kbd>Shift+Delete</kbd> in Windows.
- Minimize all windows or all but the frontmost — same as <kbd>Win+M</kbd> or <kbd>Win+Home</kbd>.
- Shift-click Dock icons to open a new window — just like Shift+clicking taskbar icons.
- <kbd>Command+Q</kbd> (kinda) quits Finder — like closing Explorer in Windows.
- Finder shows a new window when activated with no windows open — Windows Explorer always shows a window when launched.
- Click Dock folders to open them in Finder — like clicking taskbar folders in Windows, which opens Explorer.
- Use <kbd>Delete</kbd> / <kbd>Shift+Delete</kbd> in Safari to go back/forward — just like in Windows browsers.
- Invert selection in Finder — matches “Invert Selection” in Windows Explorer.
- Print files from Finder’s right-click menu — like Windows’ right-click “Print”.

Make macOS feel less foreign — and more powerful.

<br>

> [!TIP]
> You may also like my [Shareful](/shareful), [Menu Bar Spacing](/menu-bar-spacing), and [Pure Paste](/pure-paste) apps.

## Trial

Try the fully functional trial [here](https://www.dropbox.com/scl/fi/da6imr6yx09ru6x1115a0/Supercharge-1.25.0-trial-1769898535.zip?rlkey=6f0uyxl4plg4879dyhwmxy4ua&raw=1). The only limitation is a reminder to buy the app every 12 hours, and no automatic updates. All data and settings carry over if you buy it.

*Download it to the Downloads folder, double-click to unzip, and then move it to the `/Applications` folder.*

You can also [try it on Setapp](https://go.setapp.com/stp181?refAppID=742&utm_medium=vendor_program&utm_content=button) for 7 days for free.

**Requires macOS 15.4**

## Tips

### Troubleshooting {#troubleshooting}

- Ensure you are on the latest version (click the “Check for Updates” button).
- Restart your computer.
- Try closing any anti-virus app you have running as it may [interfere with the app](/apps/faq#secure-input-problem) (or at least disable any Secure Keyboard Entry type setting it may have). And if you don't have any anti-virus app, try closing down all apps and menu bar items, just to rule out some other app interfering. If it's a work computer, your company may have something installed that prevents the app from working.
- Reset permissions: Try clicking “… › Debug › Reset Permissions” in the Supercharge menu.

#### Accidental quit troubleshooting

A common issue is that macOS corrupts the privacy permissions. Try resetting permissions (see above).

#### Cut and paste files troubleshooting

Ensure you pressed <kbd>Command+X</kbd> and not <kbd>Command+C</kbd>.

To make sure you used the feature correctly, try this: Select a file in Finder, press <kbd>Command+X</kbd>, change to a different folder, press <kbd>Command+V</kbd>. The file should have been moved to this new folder.

> [!NOTE]
> You cannot cut, highlight a folder, and then paste. You have to actually go into the folder to paste to it. That's just how Finder works. Same with copy-pasting.

If it's still not working, try this: Select a file in Finder, press <kbd>Command+C</kbd>, change to a different folder, press <kbd>Option+Command+V</kbd>. The file should have been moved to this new folder. If this did not work, the problem is not this app, as those are the keyboard shortcuts it simulates.

As a last resort, try [resetting permissions](/apps/faq#mac-reset-permissions) and restarting your computer.

Also try closing any anti-virus app you have running as it may [interfere with the app](/apps/faq#secure-input-problem) (or at least disable any Secure Keyboard Entry type setting it may have). And if you don't have any anti-virus app, try closing down all apps and menu bar items, just to rule out some other app interfering. If it's a work computer, your company may have something installed that prevents the app from working.

### Launch browser

If you have enabled showing browsers in the menu, you can hold the Option key and click a browser in the menu to open it, rather than setting it as the default.

### Tricks

Some things you can already do that you may not know about:

- Hide an app by <kbd>Option</kbd>-clicking on the app's Dock icon.
- Show Control Center by pressing <kbd>Fn+C</kbd>.
- Toggle a specific VPN using a keyboard shortcut with Shortcuts. Add [this shortcut](https://www.icloud.com/shortcuts/a0c3171fe98a4379b8197299a84b060e) and set the VPN parameter and a keyboard shortcut.
- [Make Finder remember its size and position.](https://apple.stackexchange.com/a/171274/2363)
- [Prevent opening apps when clicking links that are Universal Links.](https://lapcatsoftware.com/articles/universal-links2.html)
- [Change the keyboard shortcut for menu item actions in a specific app.](https://support.apple.com/guide/mac-help/create-keyboard-shortcuts-for-apps-mchlp2271/mac)
- [Change the keyboard shortcut for menu item actions in all apps.](https://apple.stackexchange.com/a/125628/2363)
- Set Finder's default view options: Open a folder, press <kbd>Command+J</kbd>, adjust settings, and click “Use as Defaults”. To reset a folder's custom settings, press <kbd>Command+J</kbd>, hold <kbd>Option</kbd>, and click “Restore to Defaults”.
- [Show “Dimensions” column in Finder.](https://apple.stackexchange.com/questions/18728/how-can-i-show-the-dimension-column-in-finder)
- Option-click the sound menu bar icon to be able to also choose input device. Or use the tweak in Supercharge to see it by default.
- In open/save dialogs, navigate to a copied absolute path by pressing <kbd>Command+V</kbd>.
- [Translate website in Safari using a keyboard shortcut.](https://www.reddit.com/r/Safari/comments/1auqjjc/how_to_make_safari_full_page_translation_by/)
- In Safari, enter Picture-in-Picture by pressing <kbd>Shift+Command+R</kbd>.
- In Finder, select a file, and then press <kbd>Command+Option+C</kbd> to copy its path.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](/feedback?product=Supercharge&referrer=Website-FAQ)

Some things are not possible though:

- [Removing the Trash icon in the Dock.](https://apple.stackexchange.com/a/454812/2363)
- Removing the Finder icon in the Dock.
- Disabling Stage Manager animations.
- Fill the entire row with the file's tag color in Finder.
- Naming spaces. Check out [this app](https://github.com/Jaysce/Spaceman) for showing space names in the menu bar.
- Removing or changing Finder context menu items. It can only add items.
- Colored Finder sidebar icons.
- Moving Stage Manager to the right without having the Dock on the left side.
- The "Mission Control tweaks" feature for Stage Manager.
- Toggle “auto brightness” system setting.

Some things are not planned:

- Memory cleaner
	- Apps like these are a scam. macOS handles memory efficiently. There is no need for an app like this.

#### The app does not show up in the menu bar

[Try this](/apps/faq#app-not-showing-in-menu-bar)

You may also have disabled the “Show menu bar icon” setting, which hides the menu bar icon. Launch the app again to show the main window.

#### I moved to a new computer, how can I download the app again?

If you purchased it on [Gumroad](https://gumroad.com), you can download the app again from your Gumroad account or the Gumroad receipt email.

#### The tweaks like Finder cut & paste no longer work

This usually happens when an app [blocks keyboard input reading](/apps/faq#secure-input-problem).

#### Why is Supercharge so expensive? {#price}

- **It's really 10 apps in 1**\
	Supercharge packs dozens of powerful features that would typically require multiple separate apps.
- **One-time purchase, lifetime value**\
	In a world where everything is subscription-based, Supercharge is a one-time purchase with unlimited free updates forever. No monthly fees, no restrictions on how many personal devices you can use it on.
- **Fixes countless macOS annoyances**\
	Apple leaves many frustrating gaps in macOS functionality. Supercharge addresses dozens of these pain points that users encounter daily but Apple hasn't fixed.
- **Complex engineering under the hood**\
	The app performs very difficult technical tasks, from low-level system integration to advanced automation features. Each feature requires significant development effort to work reliably across macOS updates.
- **Dedicated ongoing support**\
	You get responsive support and regular feature additions.
- **Professional quality and reliability**\
	I have been obsessively crafting Mac apps for years.
- **Small market, high development costs**\
	Mac power users are a niche market. The development costs must be spread across fewer users compared to mass-market apps.
- **Support an indie developer**\
	Get actual human support, genuine privacy protection, and a developer who listens to your feedback, unlike faceless corporations where you're just another number. I'm in it for the long haul.

Try the [trial](#trial) and see for yourself.

#### I can already do this with the command-line, BetterTouchTool, Keyboard Maestro, etc.

Supercharge offers a simpler, more user-friendly approach. It's designed for users who want quick access to useful features without the complexity of scripting or configuring advanced tools. Supercharge provides a curated set of enhancements that work right out of the box, saving you time and effort in setup and maintenance. If you prefer more granular control and don't mind the setup process, those other tools might be a better fit for you.

#### Why <kbd>Command+X</kbd>? I can already move files with <kbd>Command+C</kbd> and <kbd>Option+Command+V</kbd>

- It's more logical to cut & paste than copy & move.
- Consistency and muscle memory benefits if you also use Linux or Windows.

#### What are Dock spacers? {#dock-spacers}

Dock spacers are [invisible gaps](https://res.cloudinary.com/cpenned/image/upload/f_auto,w_auto/v1636732613/Blog/post-images/20211112-dock.jpg) you can add to your Mac's Dock. They help organize your apps into groups, improving visual clarity. Supercharge lets you easily add these spacers, giving you better control over your Dock's layout.

#### Can I add custom actions to the app?

As of now, the app focuses on providing a curated set of built-in features for enhancing your Mac experience. I'm happy to consider requests.

#### Can you add a certain toggle?

I'm happy to consider requests, but I don't intend for this app to turn into a “toggler” app. I have just provided some commonly needed toggles.

Some toggles I don't plan to add:

- AirPods
- Keep awake *(check out [Lungo](/lungo))*

#### Does the app consume a lot of system resources?

No, the app is optimized to run efficiently in the background with minimal CPU, memory, and battery usage. Most features are event-driven and only activate when needed.

#### I cannot use <kbd>Control+Space</kbd> or <kbd>Control+Shift+Space</kbd> as a keyboard shortcut

Go to “System Settings › Keyboard › Keyboard Shortcuts › Input Sources” and disable them all.

#### Why would I want to clear my clipboard?

Clearing the clipboard helps protect privacy by removing potentially sensitive information (like passwords or personal data) that might otherwise remain available for pasting. Any app can silently read the clipboard. And you could also accidentally paste it somewhere you didn't intend to.

#### Why don’t the Finder context menu items show up in iCloud, Dropbox, and OneDrive folders? {#finder-context-menu-icloud}

Finder Sync extensions, which power these context menu items, are intended to add sync functionality for third-party services in Finder. Since iCloud, Dropbox, and OneDrive folders have their own built-in sync, macOS doesn't allow the Supercharge extension in these locations to prevent conflicts.

Some of the Finder context menu items are also available as [macOS services](#macos-services), which do show up in synced folders.

#### I am seeing incorrect icons for external drives in the Finder sidebar when enabling context menu items

This is a macOS bug and out of my control. When context menu items are enabled for external volumes, macOS shows document icons instead of drive icons in the Finder sidebar. As a workaround, you can disable showing the context menu items on external drives.

#### How can I add my preferred apps to the “Open Folder With” Finder context menu? {#add-app-open-folder-with}

The menu shows apps that declare support for opening folders. This is controlled by app developers, not by Supercharge. To get your preferred apps to appear in this menu, contact the developers of those apps and request them to add folder opening support.

The developer will need to add `public.folder` to `LSItemContentTypes` in their app's Info.plist:

```xml
<key>LSItemContentTypes</key>
<array>
		<string>public.folder</string>
</array>
```

*(If the app already contains `public.directory`, it will still have to add `public.folder`)*

[Example report.](https://github.com/coteditor/CotEditor/issues/1809)

If you know the app supports opening folders but it doesn't show up, it may be that the app has not properly declared support for it. Contact the app developer about adding the above. You could also [contact me](/feedback?product=Supercharge), and I can manually add the app.

#### Can you add support for keyboard shortcuts to change default browser?

Maybe. For now, you can make a shortcut in the Shortcuts app, give it a keyboard shortcut, and use the “Set Default Browser” Shortcuts action that comes with Supercharge.

#### Can you add more features to changing the default browser, like rules?

Features like rules require the app to intercept and forward URLs by acting as the default browser. This is out of scope for this app. Check out my [Velja](/velja) app for that.

#### Why do some tweaks have a list of pre-defined keyboard shortcuts instead of a shortcut recorder?

The pre-defined shortcuts are intentionally curated to help users quickly select sensible shortcuts that won't conflict with built-in app shortcuts. This approach reduces potential support issues. Missing a useful key combination? Let me know, and I will consider adding it.

#### Can you add a Finder keyboard shortcut to move selected items into a new folder?

This is already supported natively. See the “File › New Folder with Selection” menu item. Select some items and then press <kbd>Control+Command+N</kbd>. You can change the keyboard shortcut in the [System Settings](https://support.apple.com/guide/mac-help/create-keyboard-shortcuts-for-apps-mchlp2271/mac).

#### Can the app support clearing clipboard formatting? {#pure-paste}

Check out my [Pure Paste](/pure-paste) app for this. I think it makes more sense as a separate app.

#### How can I copy the original text in the translate popover?

The translate popover is provided by macOS and does not support copying the original text. As a workaround, select the same language as the destination language, and then click “Copy Translation”.

#### How can I run the actions from Raycast or Alfred?

Most of the actions are exposed as Shortcuts actions, so create a shortcut with the action and run it from Raycast or Alfred.

#### Can I trigger the actions using a custom URL scheme?

It's something I plan to support at some point, but for now, you can use Shortcuts, as mentioned above.

#### Can the app support hiding menu bar items?

No, that's out of scope for this app. I recommend [Ice](https://icemenubar.app).

#### Can you add Alt-Tab functionality like Windows?

No, this would be very complex to implement well and there is already an excellent free app called [AltTab](https://alt-tab-macos.netlify.app) that does exactly this.

#### Supercharge and Shortcutie seem to have some of the same actions for Shortcuts {#shortcutie}

There is some overlap, but [Shortcutie](/shortcutie) includes many more actions. Supercharge only includes actions for its own features.

Supercharge has the following Shortcuts actions that Shortcutie does not have:

- Pick Color
- Scan QR Code (Interactive)
- Capture Text (Interactive)
- Capture & Translate Text (Interactive)
- Get Links to Selected Mail Messages
- Copy Links to Selected Mail Messages
- Get Links to Selected Notes
- Copy Links to Selected Notes
- Start Cleaning Mode
- Start Cat Mode
- Export App Settings
- Get/Set Auto-Quit State
- Get/Set Keep Awake State
- Get/Set Sound Mute State
- Get/Set Microphone Mute State
- Toggle Finder
- Toggle Terminal
- Toggle Passwords Menu Bar Window
- Toggle Weather Menu Bar Window
- Toggle Now Playing Window
- Toggle Hot Corners

#### Why is this not in the App Store?

Much of the functionality would not be possible in the App Store because of [sandboxing](/apps/faq#macos-sandbox).

#### [More FAQs…](/apps/faq)

<!-- Intentionally using the wrong header level so it doesn't show up as a main thing. -->

### Scripting

#### Events

The [distributed notification](/apps/faq#distributed-notifications) `com.sindresorhus.defaultBrowserDidChange` is emitted when the default browser is changed from the app or the Shortcuts action.

<!-- ## Older Versions

- [] for macOS 15

These are free for everyone but they will not run on newer macOS versions.
-->
