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

The app provides lots of powerful extra actions for the Shortcuts app on macOS.

While my free [Actions](/actions) app provides useful functionality for the Shortcuts app through the App Store for macOS, iOS and visionOS, Shortcutie is a Mac-only app that offers more powerful system-level features by operating outside of Apple's restrictions. This enables capabilities like changing system default browser (without a prompt), getting the active browser tab, clearing notifications, etc. - things that wouldn't be possible under App Store rules.

**Restart your device if the actions do not show up in the Shortcuts app. Also try setting a different device language and then back.**

Can it be added to Setapp? Setapp curates apps based on demand, so if you'd like to see the app on Setapp, [email them](https://support.setapp.com/hc/en-us/articles/4950254561052-How-to-contact-Setapp-team#:~:text=to%20your%20issue.-,Send%20an%20email,%3A%20support%40setapp.com.) and request its inclusion.

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
- Join Wi-Fi <!-- 	<span class="list-subtitle">Join a Wi-Fi network or personal hotspot</span>
	<span class="list-description text-xs">Tip: You could use it to join your iPhone’s hotspot</span> -->
- Clear Top Notification
	<span class="list-subtitle">Clears the top visible system notification</span>
- Clear Notifications
	<span class="list-subtitle">Clears all system notifications</span>
- Get/Set Default Browser
	<span class="list-subtitle">View or change the system default web browser</span>
- Set Grayscale Mode
	<span class="list-subtitle">Makes screen display in black and white</span>
- Is Screen Being Watched
	<span class="list-subtitle">Detects if the screen is being recorded, mirrored, or shared (Zoom, Teams, etc)</span>
- Open App (Extended)
	<span class="list-subtitle">Options to pass in URLs, activate, force new instance, hide, launch arguments, and environment variables</span>
- Get/Set Default Sound Device
	<span class="list-subtitle">View or change the default audio input (microphone) or output (speaker)</span>
- Find Sound Device
	<span class="list-subtitle">Returns all sound devices</span>
	<span class="list-description text-xs">Includes comprehensive details about them.</span>
- Set Folder Color
	<span class="list-subtitle">Change the color of folders</span>
- Hide All Windows
	<span class="list-subtitle">Instantly hides windows for all apps</span>
- Quit All Apps
	<span class="list-subtitle">Closes all running apps except menu bar apps</span>
- Eject All Disks
	<span class="list-subtitle">Safely unmounts all external drives (except excluded ones)</span>
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
- Get/Set Desktop Widgets Visibility
	<span class="list-subtitle">Show, hide, or check visibility status of desktop widgets</span>
- Get/Set Function Keys Mode
	<span class="list-subtitle">Toggle or check if F1-F12 keys operate as standard function keys or media keys</span>
- Get/Set Keyboard Brightness
	<span class="list-subtitle">View or change the keyboard backlight brightness level</span>
	<span class="list-description text-xs">Only works on Macs with a built-in backlit keyboard.</span>
- Get/Set Network Location
	<span class="list-subtitle">Switch between different [network configurations](https://support.apple.com/105129)</span>
	<span class="list-description text-xs">Tip: You could automate switching based certain conditions with the [Shortery](https://www.numberfive.co/detail_shortery.html) app.</span>
- Get Slack Workspace
	<span class="list-subtitle">Gets the name of the current Slack workspace</span>
- Clear Recent Lists
	<span class="list-subtitle">Clears recent items (files, apps, and servers) from menus</span>
- Open System Setting
	<span class="list-subtitle">Opens Hide My Email, Private Relay, VPN & Filters, or Apple Account Subscriptions settings directly</span>
- Get Apps Using Secure Input
	<span class="list-subtitle">Secure Input prevents other apps from reading keystrokes when typing passwords. Sometimes apps don't properly disable it, causing keyboard shortcuts to stop working. This can find such apps.</span>

<!-- - Get/Set Pointer Size
<span class="list-subtitle">View or change the system-wide mouse pointer size</span> -->

**And many more planned!**

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Shortcutie&referrer=Website-FAQ)

#### The actions don't show up in the Shortcuts app

This is caused by a macOS bug.

Some things you could try:

1. Restart your device.
1. Add [this shortcut](https://www.icloud.com/shortcuts/29943b986f934d9da5018853d4e2cc40), run it once, relaunch the Shortcuts app, and see if the actions show up in the Shortcuts app after that.
1. Change the device language to something else and back.

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

The action can close Finder windows.

#### What’s up with the app icon?

A bit of whimsy makes software more human and approachable. Even Apple uses a smiling Finder icon to this day. Good software can be both powerful and fun. And since the icon is only visible in the App Store and as a tiny icon in Shortcuts, its design has minimal impact on the actual utility of the app.

#### [More FAQs…](/apps/faq)

<!-- ### Older Versions

- [] for macOS 15

These are free for everyone but they will not run on newer macOS versions.
 -->
