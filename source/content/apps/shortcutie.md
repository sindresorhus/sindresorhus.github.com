---
title: Shortcutie
subtitle: Power up the Shortcuts app on Mac
pubDate: 2025-02-11
platforms:
  - macOS
isPaid: true
releasesRepo: shortcutie-meta
hasSentry: true
mainLinks:
  'Buy': https://sindresorhus.gumroad.com/l/shortcutie?wanted=true
# olderMacOSVersions:
#   - '15
feedbackNote: |
  ### If the actions don't show up in the Shortcuts app or if you get a “com.apple.extensionKit.errorDomain error 2” error when running your shortcut, restart your device. You could also try setting a different device language and then back. If you just updated the operating system, give it some time to re-index all shortcut actions.

  Check the [Actions](/actions) app before requesting an action. It may already exist there.
---

<sup>Requires macOS 15.2 or later</sup>

The app provides lots (60+) of powerful extra actions for the Shortcuts app on macOS.

While my free [Actions](/actions) app provides useful functionality for the Shortcuts app through the App Store for macOS, iOS and visionOS, Shortcutie is a Mac-only app that offers more powerful system-level features by operating outside of Apple's restrictions. This enables capabilities like changing system default browser (without a prompt), getting the active browser tab, clearing notifications, etc. - things that wouldn't be possible under App Store rules.

**Restart your device if the actions do not show up in the Shortcuts app. Also try setting a different device language and then back.**

Can it be added to Setapp? Setapp curates apps based on demand, so if you'd like to see the app on Setapp, [email them](https://support.setapp.com/hc/en-us/articles/4950254561052-How-to-contact-Setapp-team#:~:text=to%20your%20issue.-,Send%20an%20email,%3A%20support%40setapp.com.) and request its inclusion.

---

**💡 Also available in the [Power User Bundle](https://sindresorhus.gumroad.com/l/power-user) - Get 3 of my power user apps for 26% off normal price.**

---

#### Included actions

- Get Active Browser Tab
	<span class="list-subtitle">Gets the URL and title of the active browser tab</span>
	<span class="list-description text-xs">Supports Safari, Chrome, Edge, Brave, Opera, Vivaldi, Arc, Orion, and any Chromium-based browser. Firefox and Firefox-based browsers (including Zen) are not supported as they do not implement the required [AppleScript interface](https://bugzilla.mozilla.org/show_bug.cgi?id=125419) for getting tab info.</span>
- Run JavaScript on Active Browser Tab
	<span class="list-subtitle">Runs JavaScript code on the active browser tab and returns JSON</span>
	<span class="list-description text-xs">Supports the same browsers as “Get Active Browser Tab”.</span>
- Open URLs in Private Browser Window
	<span class="list-subtitle">Opens URLs in a private/incognito browser window</span>
	<span class="list-description text-xs">Supports Safari, Chrome, Edge, Brave, Opera, Vivaldi, Arc, Orion, Firefox, Zen, and any Chromium-based and Firefox-based browser.</span>
- Get Active Browser
	<span class="list-subtitle">Gets the frontmost app if it’s a browser</span>
- Get Selected Text
	<span class="list-subtitle">Gets the selected text in the currently focused window</span>
- Get/Set Current Folder in Finder
	<span class="list-subtitle">Gets or sets the currently viewed folder in Finder</span>
- Get Document of App
	<span class="list-subtitle">Returns the file of the currently active document in the active or specified app</span>
	<span class="list-description text-xs">Works with native macOS apps like Preview, TextEdit, Pages, Keynote, Numbers, and other document-based apps.</span>
- Show Alert (Extended)
	<span class="list-subtitle">Shows an alert dialog with multiple buttons and returns which button was clicked</span>
	<span class="list-description text-xs">Timeout, custom icon, and up to 8 buttons. [Screenshot.](https://www.dropbox.com/scl/fi/439bkpixjwssiss0ye7ln/Screen-Shot-2025-05-20-at-18.43.32-1747756364.png?rlkey=jrq1etjed15uz66tpanokw0q6&raw=1)</span>
- Join Wi-Fi <!-- 	<span class="list-subtitle">Join a Wi-Fi network or personal hotspot</span>
	<span class="list-description text-xs">Tip: You could use it to join your iPhone’s hotspot</span> -->
- Clear Top Notification
	<span class="list-subtitle">Clears the top visible system notification</span>
- Clear Notifications
	<span class="list-subtitle">Clears all system notifications</span>
- Click Top Notification
	<span class="list-subtitle">Activates the top visible system notification</span>
- Get/Set Default Browser
	<span class="list-subtitle">View or change the system default web browser</span>
- Set Grayscale Mode
	<span class="list-subtitle">Makes screen display in black and white</span>
- Is Screen Being Watched
	<span class="list-subtitle">Detects if the screen is being recorded, mirrored, or shared (Zoom, Teams, etc)</span>
- Open App (Extended)
	<span class="list-subtitle">Options to pass in URLs, activate, force new instance, hide, launch arguments, and environment variables</span>
- Unminimize Windows of Active App
	<span class="list-subtitle">Unminimizes all windows or the first window of the currently active app</span>
- Isolate Window
	<span class="list-subtitle">Hide all other apps and minimize all other windows of the current app, leaving only the frontmost window visible</span>
	<span class="list-description text-xs">It's like a turbocharged “Hide Others” — also minimizes your extra windows in the current app, so you see just the one you care about. Perfect for quickly clearing away distractions when you have many windows open.</span>
- Get/Set Accent Color
	<span class="list-subtitle">View or change the system accent color</span>
	<span class="list-description text-xs">Also includes special iMac colors not normally accessible on non-iMac systems.</span>
- Toggle Dock Folder
	<span class="list-subtitle">Expands or collapses a [folder in the Dock](https://support.apple.com/kk-kz/guide/mac-help/mchl231f08fb/mac), similar to manually clicking on it</span>
	<span class="list-description text-xs">Tip: Add this to a shortcut and give it a keyboard shortcut to expand or collapse Dock folders from the keyboard.</span>
- Get/Set Default Audio Device
	<span class="list-subtitle">View or change the default audio input (microphone) or output (speaker)</span>
- Get Details of Audio Device
	<span class="list-subtitle">Returns comprehensive information about audio devices</span>
	<span class="list-description text-xs">Includes volume, mute state, type, connection status, sample rates, manufacturer info, and more.</span>
- Find Audio Device
	<span class="list-subtitle">Returns all audio devices</span>
	<span class="list-description text-xs">Includes comprehensive details about them.</span>
- Get/Set Audio Device Mute State
	<span class="list-subtitle">Control mute state of audio devices</span>
- Get/Set Audio Device Volume
	<span class="list-subtitle">Control volume level of audio devices</span>
- Set Folder Color
	<span class="list-subtitle">Change the color of folders</span>
- Hide All Windows
	<span class="list-subtitle">Instantly hides windows for all apps</span>
- Minimize All Windows
	<span class="list-subtitle">Minimizes all visible windows, with options to only affect the active app and exclude the frontmost window</span>
- Quit All Apps
	<span class="list-subtitle">Closes all running apps except menu bar apps</span>
	<span class="list-description text-xs">Options to exclude apps, exclude frontmost app, and close Finder windows.</span>
- Eject All Disks
	<span class="list-subtitle">Safely unmounts all external drives (except excluded ones)</span>
- Create Email with Files
	<span class="list-subtitle">Creates a new email message in the default email app with the given files as attachments</span>
	<span class="list-description text-xs">Works with Mail, Outlook, Spark, Mimestream, Airmail, Canary Mail, and maybe other apps. Not Thunderbird.</span>
- Empty Trash
	<span class="list-subtitle">Permanently deletes items in the trash</span>
- Toggle Show Desktop
	<span class="list-subtitle">Shows or hides the desktop by temporarily moving windows aside</span>
- Toggle Mission Control
	<span class="list-subtitle">Shows or hides [Mission Control](https://support.apple.com/guide/mac-help/view-open-windows-spaces-mission-control-mh35798/mac)</span>
- Toggle App Exposé
	<span class="list-subtitle">Shows or hides [App Exposé](https://www.oreilly.com/library/view/switching-to-the/9781449338978/ch04s11.html)</span>
- Toggle Launchpad
	<span class="list-subtitle">Shows or hides [Launchpad](https://support.apple.com/guide/mac-help/mh35840/mac)</span>
- Get Latest Screenshots
	<span class="list-subtitle">Returns the most recent screenshots taken with the system screenshot tool</span>
- Get/Set Dock Position
	<span class="list-subtitle">View or change the position of the Dock</span>
	<span class="list-description text-xs">Changes take effect immediately.</span>
- Get/Set Desktop Icons Visibility
	<span class="list-subtitle">Show, hide, or check visibility status of desktop icons</span>
- Get/Set Desktop Widgets Visibility
	<span class="list-subtitle">Show, hide, or check visibility status of desktop widgets</span>
- Get/Set Function Keys Mode
	<span class="list-subtitle">Toggle or check if F1-F12 keys operate as standard function keys or media keys</span>
- Get/Set Keyboard Brightness
	<span class="list-subtitle">View or change the keyboard backlight brightness level</span>
	<span class="list-description text-xs">Only works on Macs with a built-in backlit keyboard.</span>
- Get/Set Night Shift Color Temperature
	<span class="list-subtitle">Control the [Night Shift](https://support.apple.com/en-us/102191) color temperature.</span>
- Get/Set Network Location
	<span class="list-subtitle">Switch between different [network configurations](https://support.apple.com/105129)</span>
	<span class="list-description text-xs">Tip: You could automate switching based certain conditions with the [Shortery](https://www.numberfive.co/detail_shortery.html) app.</span>
- Get/Set iOS Notifications Enabled
	<span class="list-subtitle">Control whether notifications from your iOS device appear on your Mac</span>
	<span class="list-description text-xs">Only works if your Mac supports notifications from iOS.</span>
- Center Mouse Pointer
	<span class="list-subtitle">Centers the mouse pointer on the primary display</span>
- Get/Set Mouse Pointer Visibility
	<span class="list-subtitle">Get or set the visibility of the mouse pointer</span>
	<span class="list-description text-xs">By default, it reappears on mouse movement.</span>
- Get Slack Workspace
	<span class="list-subtitle">Gets the name of the current Slack workspace</span>
- Clear Recent Lists
	<span class="list-subtitle">Clears recent items (files, apps, and servers) from menus</span>
- Open System Setting
	<span class="list-subtitle">Opens Hide My Email, Private Relay, VPN & Filters, or Apple Account Subscriptions settings directly</span>
- Get/Set Finder New Window Target
	<span class="list-subtitle">Gets or sets the default folder that opens when creating new Finder windows</span>
- Get Apps Using Secure Input
	<span class="list-subtitle">Secure Input prevents other apps from reading keystrokes when typing passwords. Sometimes apps don't properly disable it, causing keyboard shortcuts to stop working. This can find such apps.</span>

<!-- - Get/Set Pointer Size
<span class="list-subtitle">View or change the system-wide mouse pointer size</span> -->

**And many more planned!**

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Shortcutie&referrer=Website-FAQ)

#### The actions don't show up in the Shortcuts app

This is caused by a macOS bug.

Some things you could try:

1. Restart your device.
1. Add [this shortcut](https://www.icloud.com/shortcuts/29943b986f934d9da5018853d4e2cc40), run it once, relaunch the Shortcuts app, and see if the actions show up in the Shortcuts app after that.
1. Change the device language to something else and back.
1. Remove the app, install it again, and restart your device.

#### I get a “errorDomain error 2” error when running an action

Same solution as above.

#### Why is this not in the App Store?

Much of the functionality would not be possible in the App Store because of [sandboxing](/apps/faq#macos-sandbox).

#### Why is this paid when your Actions app is free?

Unlike Actions, which uses public APIs, Shortcutie relies on many private APIs that require constant maintenance as macOS evolves. The app targets power users who value these advanced capabilities, and the pricing helps ensure sustainable development while keeping the support burden manageable.

#### Can I have this installed together with the Actions app?

Yes, they are complementary.

#### Can you support iOS?

No. The app relies on macOS-specific system features that aren't available on iOS and requires capabilities outside of App Store restrictions. Check out [Actions](/actions) for iOS shortcuts functionality.

#### Do I need to keep the app running for the actions to work?

No, once installed, the app's actions are always available to the Shortcuts app.

#### I can already do some of these actions with AppleScript and the command-line, why use this app?

Yes, but the app packages these capabilities into maintained, ready-to-use actions that integrate perfectly with Shortcuts. This lets you focus on building workflows instead of writing and maintaining scripts.

#### How is the “Quit All Apps” action better than the built-in “Quit App” action? {#quit-all-apps-vs-builtin}

The action can exclude the frontmost app and also close Finder windows.

#### What’s up with the app icon?

A bit of whimsy makes software more human and approachable. Even Apple uses a smiling Finder icon to this day. Good software can be both powerful and fun. And since the icon is only visible in the App Store and as a tiny icon in Shortcuts, its design has minimal impact on the actual utility of the app.

#### Shortcutie and Supercharge seem to have some of the same actions for Shortcuts

There is some overlap, but Shortcutie includes many more actions. [Supercharge](/supercharge) only includes actions for its own features.

#### [More FAQs…](/apps/faq)

<!-- ## Older Versions

- [] for macOS 15

These are free for everyone but they will not run on newer macOS versions.
 -->
