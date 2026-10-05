---
title: 'Shortcutie'
subtitle: 'Power up the Shortcuts app on Mac'
publicationDate: '2025-02-11'
platforms: [
	'macOS'
]
isPaid: true
price: 10
hasSentry: true
setappID: 1814
releasesRepository: 'shortcutie-meta'
mainLinks: {
	Buy: 'https://sindresorhus.gumroad.com/l/shortcutie?wanted=true'
}
requirement: 'Requires macOS 26 or later'
announcement: {
	text: 'Save 28% with the Power User Bundle: Default Browser, Shortcutie, and Supercharge'
	url: 'https://sindresorhus.gumroad.com/l/power-user'
	linkText: 'Get the Bundle'
}
pressQuotes: [
	{
		quote: 'Once you have Shortcutie, you can add these triggers to your shortcuts and execute complex automations that your Mac doesn’t otherwise support.'
		source: 'Lifehacker'
		url: 'https://lifehacker.com/tech/this-app-lets-you-create-automations-your-mac-usually-doesnt-support'
	}
	{
		quote: 'It’s absolutely essential for anyone who uses Shortcuts because it unlocks so many new things you can do. I love the extra power it gives my Mac and it’s totally worth it for those advanced features!'
		source: 'Anonymous'
		url: 'https://sindresorhus.gumroad.com/l/shortcutie'
	}
]
olderVersions: [
	{
		version: '1.5.0'
		macOS: '15'
		url: 'https://www.dropbox.com/scl/fi/1nny73fqfa423v87vz0q6/Shortcutie-1.5.0-macOS-15-1770752068.zip?rlkey=3fxry52nv7nflmc60r4leqlfm&raw=1'
	}
]
feedbackNote:
	'''
	### If the actions don’t show up in the Shortcuts app or if you get a “com.apple.extensionKit.errorDomain error 2” error when running your shortcut, restart your device. You could also try setting a different device language and then back. If you just updated the operating system, give it some time to re-index all shortcut actions.

	Check the [Actions](/actions) app before requesting an action. It may already exist there.

	This is not the place to ask general Shortcuts questions. Try [r/shortcuts](https://www.reddit.com/r/shortcuts/) instead.
	'''
categories: [
	'shortcuts'
]
---

Adds 70+ actions to the Shortcuts app on Mac, for things the App Store does not allow, like changing the default browser without a prompt.

While my free [Actions](/actions) app provides useful functionality for the Shortcuts app through the App Store for macOS, iOS and visionOS, Shortcutie is a Mac-only app that offers more powerful system-level features by operating outside of Apple’s restrictions. This enables capabilities like changing the system default browser or mail app (without a prompt), getting the active browser tab, clearing notifications, etc. These are things that wouldn’t be possible under App Store rules.

> [!IMPORTANT]
> Restart your device if the actions do not show up in the Shortcuts app. [Learn more ›](#troubleshooting)

#### Included actions

- Get Active Browser Tab
	: Gets the URL and title of the active browser tab
	:: Supports Safari, Chrome, Edge, Brave, Opera, Vivaldi, Arc, Orion, Atlas, and any Chromium-based browser. Firefox and Firefox-based browsers (including Zen) are not supported as they do not implement the required [AppleScript interface](https://bugzilla.mozilla.org/show_bug.cgi?id=125419) for getting tab info.
- Run JavaScript on Active Browser Tab
	: Runs JavaScript code on the active browser tab and returns JSON
	:: Supports the same browsers as “Get Active Browser Tab”, except ChatGPT Atlas.
- Open URLs in Private Browser Window
	: Opens URLs in a private/incognito browser window
	:: Supports Safari, Chrome, Edge, Brave, Opera, Vivaldi, Arc, Orion, Firefox, Zen, and any Chromium-based and Firefox-based browser. Not DuckDuckGo and ChatGPT Atlas.
- Get Active Browser
	: Gets the frontmost app if it’s a browser
- Get Selected Text
	: Gets the selected text in the currently focused window
- Get/Set Current Folder in Finder
	: Gets or sets the currently viewed folder in Finder
- Get Document of App
	: Returns the file of the currently active document in the active or specified app
	:: Works with native macOS apps like Preview, TextEdit, Pages, Keynote, Numbers, and other document-based apps.
- Get File from Path
	: Converts a text path to a file or folder object for use in other Shortcuts actions
	:: Accepts both absolute paths (like “/Users/username/Documents/file.txt”) and paths with “~” (like “~/Documents/file.txt”). Returns a reference to the actual file on disk.
- Show Alert (Extended)
	: Shows an alert dialog with multiple buttons and returns which button was clicked
	:: Timeout, custom icon, and up to 8 buttons. [Screenshot.](https://www.dropbox.com/scl/fi/439bkpixjwssiss0ye7ln/Screen-Shot-2025-05-20-at-18.43.32-1747756364.png?rlkey=jrq1etjed15uz66tpanokw0q6&raw=1)
- Join Wi-Fi <!--
	: Join a Wi-Fi network or personal hotspot
	:: Tip: You could use it to join your iPhone’s hotspot -->
- Clear Top Notification
	: Clears the top visible system notification
- Clear Notifications
	: Clears all system notifications
- Click Top Notification
	: Activates the top visible system notification
- Get/Set Default Browser
	: View or change the system default web browser
- Get/Set Default Mail App
	: View or change the system default mail app
- Get/Set Appearance (Extended)
	: View or change the system appearance mode (Light, Dark, or Auto)
	:: Unlike the native action, this also supports Auto mode.
- Get/Set Icon & Widget Style
	: View or change how app icons and widgets appear
	:: Choose default, dark, clear, or tinted.
- Get/Set Liquid Glass Style
	: View or change the Liquid Glass style
	:: Controls whether the glass effect used throughout macOS appears clear or tinted.
- Press Keyboard Shortcut
	: Simulates pressing a keyboard shortcut
	:: Optionally target a specific app.
- Trigger Menu Bar Item
	: Executes a menu bar item in the frontmost or specified app
	:: Accepts menu paths like “File > Save As”.
- Get Menu Bar Item
	: Gets info about a menu bar item in the selected app
	:: Returns title, enabled state, checked state, and keyboard shortcut.
- Trigger Context Menu Item
	: Executes a context menu item at the current mouse pointer position
	:: Using this you can trigger context-menu items or sub-items for the current mouse pointer position in any app.
- Set Grayscale Mode
	: Makes screen display in black and white
- Is Screen Being Watched
	: Detects if the screen is being recorded, mirrored, or shared (Zoom, Teams, etc)
- Get/Set Display Resolution
	: View or change the resolution of a selected display
	:: Defaults to the primary display. Uses the resolutions available in System Settings, including scaled Retina resolutions.
- Find Display
	: Returns the connected displays
- Stash Text
	: Shows the given text in a floating window
	:: Multiple calls add items to the sidebar list. Intended for temporary viewing, not long-term storage. [Screenshot](https://www.dropbox.com/scl/fi/9oz7tnd24fohgasuuv6gd/Stash-Text-Screen-Shot-2026-02-01-at-23.17.36-1769962685.png?rlkey=9vd0p1c2zat89yrqssv8rhfnw&raw=1)
- Find Listening Port
	: Finds TCP ports that currently have a listening process on this Mac
	:: Useful for checking whether a local dev server is running, finding which process is using a specific port, and inspecting listeners before stopping them.
- Is Port Listening
	: Checks whether a specific TCP port currently has a listening process
- Kill Process
	: Stops a process by process ID, process name, port number, or listening port
	:: Supports dry-run mode (find matches without signaling). By default, no-match is treated as success for friendlier automations, with an option to fail when no matches are found.
- Open App (Extended)
	: Options to pass in URLs, activate, force new instance, hide, launch arguments, and environment variables
- Close All Windows of App
	: Closes all windows of the specified app
- Unminimize Windows of Active App
	: Unminimizes all windows or the first window of the currently active app
- Isolate Window
	: Hide all other apps and minimize all other windows of the current app, leaving only the frontmost window visible
	:: It’s like a turbocharged “Hide Others” — also minimizes your extra windows in the current app, so you see just the one you care about. Perfect for quickly clearing away distractions when you have many windows open.
- Get/Set Accent Color
	: View or change the system accent color
	:: Also includes special iMac and MacBook Neo colors normally only accessible on these Macs.
- Toggle Dock Folder
	: Expands or collapses a [folder in the Dock](https://support.apple.com/kk-kz/guide/mac-help/mchl231f08fb/mac), similar to manually clicking on it
	:: Tip: Add this to a shortcut and give it a keyboard shortcut to expand or collapse Dock folders from the keyboard.
- Get/Set Default Audio Device
	: View or change the default audio input (microphone) or output (speaker)
- Get Details of Audio Device
	: Returns comprehensive information about audio devices
	:: Includes volume, mute state, type, connection status, sample rates, manufacturer info, and more.
- Find Audio Device
	: Returns all audio devices
	:: Includes comprehensive details about them.
- Get/Set Audio Device Mute State
	: Control mute state of audio devices
- Get/Set Audio Device Volume
	: Control volume level of audio devices
- Set Folder Color
	: Change the color of folders
- Hide All Windows
	: Instantly hides windows for all apps
- Minimize All Windows
	: Minimizes all visible windows, with options to only affect the active app and exclude the frontmost window
- Quit All Apps
	: Closes all running apps except menu bar apps
	:: Options to exclude apps, exclude frontmost app, and close Finder windows.
- Get Night Shift
	: Returns whether Night Shift is currently enabled
- Get True Tone
	: Returns whether True Tone is currently enabled
- Eject All Disks
	: Safely unmounts all external drives (except excluded ones)
- Create Email with Files
	: Creates a new email message in the default email app with the given files as attachments
	:: Works with Mail, Outlook, Spark, Mimestream, Airmail, Canary Mail, and maybe other apps. Not Thunderbird.
- Empty Trash
	: Permanently deletes items in the trash
- Toggle Show Desktop
	: Shows or hides the desktop by temporarily moving windows aside
- Toggle Mission Control
	: Shows or hides [Mission Control](https://support.apple.com/guide/mac-help/view-open-windows-spaces-mission-control-mh35798/mac)
- Toggle App Exposé
	: Shows or hides [App Exposé](https://www.oreilly.com/library/view/switching-to-the/9781449338978/ch04s11.html)
- Toggle Launchpad
	: Shows or hides [Launchpad](https://support.apple.com/guide/mac-help/mh35840/mac)
- Toggle Spotlight
	: Toggles Spotlight search, optionally navigating to a specific tab (like Clipboard History)
- Get Latest Screenshots
	: Returns the most recent screenshots taken with the system screenshot tool
- Get/Set Screenshot Format
	: View or change the file format used when saving screenshots
	:: Choose from PNG, JPG, TIFF, or HEIC.
- Get/Set Screenshot Location
	: View or change the folder where screenshots are saved
- Get/Set Dock Position
	: View or change the position of the Dock
	:: Changes take effect immediately.
- Get/Set Dock Auto-Hide
	: View or change whether the Dock automatically hides and shows
- Get/Set Dock Minimize Effect
	: View or change the animation used when minimizing windows
	:: Choose between Genie and Scale.
- Get/Set Desktop Icons Visibility
	: Show, hide, or check visibility status of desktop icons
- Get/Set Desktop Widgets Visibility
	: Show, hide, or check visibility status of desktop widgets
- Get/Set Function Keys Mode
	: Toggle or check if F1-F12 keys operate as standard function keys or media keys
- Get/Set Hot Corner
	: View or change the configuration for a system [hot corner](https://support.apple.com/guide/mac-help/mchlp3000/mac)
- Get/Set Keyboard Brightness
	: View or change the keyboard backlight brightness level
	:: Only works on Macs with a built-in backlit keyboard.
- Get/Set Night Shift Color Temperature
	: Control the [Night Shift](https://support.apple.com/en-us/102191) color temperature.
- Get/Set Network Location
	: Switch between different [network configurations](https://support.apple.com/105129)
	:: Tip: Use Shortcuts automations to switch automatically on certain conditions.
- Get/Set DNS Servers
	: View or change the DNS servers for a network interface
	:: Setting requires administrator authorization.
- Get/Set iOS Notifications Enabled
	: Control whether notifications from your iOS device appear on your Mac
	:: Only works if your Mac supports notifications from iOS.
- Click Mouse Button
	: Simulates a mouse click at the current mouse pointer position or a specific screen coordinate
	:: Supports left, right, or middle button; single, double, or triple click; and optional modifier key override.
- Get/Set Mouse Position
	: Get the current mouse pointer position or move the mouse pointer to specific screen coordinates
- Center Mouse Pointer
	: Centers the mouse pointer on the primary display
- Get/Set Mouse Pointer Visibility
	: Get or set the visibility of the mouse pointer
	:: By default, it reappears on mouse movement.
- Get/Set Natural Scrolling
	: View or change whether natural (trackpad-style) scrolling is enabled
- Invert Selection in Finder
	: Inverts the current selection in Finder
	:: Deselects what’s currently selected and selects everything that wasn’t selected. Only works when Finder is the active app.
- Create New Text File in Finder
	: Creates a new text file in the current Finder location
	:: The file will be created in the frontmost Finder window’s current location and will be ready for you to rename.
- Toggle Hidden Files in Finder
	: Shows or hides hidden files in Finder
	:: Toggles the visibility of files that start with a dot (.) and other hidden system files. This is a temporary toggle that affects the current Finder session. The setting will revert when Finder is restarted.
- Get/Set App Desktop Assignment
	: View or change which desktop an app is assigned to
	:: This mirrors the Dock “Assign To” context menu item.
- Get Slack Workspace
	: Gets the name of the current Slack workspace
- Clear Recent Lists
	: Clears recent items (files, apps, and servers) from menus
- Open System Setting
	: Opens Hide My Email, Private Relay, VPN & Filters, or Apple Account Subscriptions settings directly
- Get/Set Finder New Window Target
	: Gets or sets the default folder that opens when creating new Finder windows
- Sleep Displays
	: Puts all displays to sleep immediately
	:: The Mac itself stays awake, only the displays go to sleep.
- Switch Space
	: Switches to the next or previous Space without the macOS slide animation
- Clear Clipboard
	: Clears all contents from the system clipboard
- Get Apps Using Secure Input
	: Secure Input prevents other apps from reading keystrokes when typing passwords. Sometimes apps don’t properly disable it, causing keyboard shortcuts to stop working. This can find such apps.

<!-- - Show Poof Animation
	: Shows the classic macOS [poof animation](https://substack.techreflect.org/p/origin-on-macos-cloud-poof-animation) at the mouse pointer or a specified location -->

<!-- - Get/Set Pointer Size
	: View or change the system-wide mouse pointer size -->

## Tips {#tips}

### Sharing shortcuts that use Shortcutie

Add a warning at the start of the shortcut to install the app if not installed. [Example](https://www.icloud.com/shortcuts/e31f8ce26d36405ca6d6aca0b2350d8f)

## Frequently Asked Questions {#faq}

### The actions don’t show up in the Shortcuts app {#troubleshooting}

This is caused by a macOS bug.

Some things you could try:

1. Restart your device.
1. Add [this shortcut](https://www.icloud.com/shortcuts/29943b986f934d9da5018853d4e2cc40), run it once, relaunch the Shortcuts app, and see if the actions show up in the Shortcuts app after that.
1. Change the device language to something else and back.
1. Remove the app, install it again, and restart your device.

### I get a “errorDomain error 2” error when running an action

Same solution as above.

### Why is this not in the App Store?

Much of the functionality would not be possible in the App Store because of [sandboxing](/apps/faq#macos-sandbox).

### Why is this paid when your Actions app is free?

Unlike Actions, which uses public APIs, Shortcutie relies on many private APIs that require constant maintenance as macOS evolves. The app targets power users who value these advanced capabilities, and the pricing helps ensure sustainable development while keeping the support burden manageable.

### Can I have this installed together with the Actions app?

Yes, they are complementary.

### Can you support iOS?

No. The app relies on macOS-specific system features that aren’t available on iOS and requires capabilities outside of App Store restrictions. Check out [Actions](/actions) for iOS shortcuts functionality.

### Do I need to keep the app running for the actions to work?

No, once installed, the app’s actions are always available to the Shortcuts app.

### I can already do some of these actions with AppleScript and the command-line, why use this app?

Yes, but the app packages these capabilities into maintained, ready-to-use actions that integrate perfectly with Shortcuts. This lets you focus on building workflows instead of writing and maintaining scripts.

### How is the “Quit All Apps” action better than the built-in “Quit App” action? {#quit-all-apps-vs-builtin}

The action can exclude the frontmost app and also close Finder windows.

### What’s up with the app icon?

A bit of whimsy makes software more human and approachable. Even Apple uses a smiling Finder icon to this day. Good software can be both powerful and fun. And since the icon is only visible in the App Store and as a tiny icon in Shortcuts, its design has minimal impact on the actual utility of the app.

### Shortcutie and Supercharge seem to have some of the same actions for Shortcuts {#supercharge}

There is [some overlap](/supercharge#shortcutie), but Shortcutie includes many more actions. Supercharge only includes actions for its own features.
