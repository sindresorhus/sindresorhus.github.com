---
title: Actions
subtitle: Additional actions for the Shortcuts app
pubDate: 2021-10-28
platforms:
  - macOS
  - iOS
  - visionOS
hasSentry: true
appStoreId: 1586435171
links:
  'TestFlight': https://testflight.apple.com/join/fJGUrsZx
olderMacOSVersions:
  - '12'
  - '13'
  - '14'
feedbackNote: |
  ### If you just updated to iOS 26, it may take some time for iOS to re-index all the Shortcuts actions. Give it some time.

  ### If the actions don't show up in the Shortcuts app or you get a “com.apple.extensionKit.errorDomain error 2”, [see this](/actions#actions-not-showing-up).<br><br>

  Tip: To pass a variable to a file input in Shortcuts, tap-and-hold (iOS) or right-click (macOS) the input and select the variable.

  **Some actions that are not possible: orientation lock status, flashlight status, ambient sensor info, flight mode status, [and more](/actions#impossible-actions).**
---

The app provides lots (180+) of powerful extra actions for the Shortcuts app on macOS, iOS, and visionOS. These actions make it significantly easier to create shortcuts.

**Restart your device if the actions do not show up in the Shortcuts app. Also try setting a different device language and then back. [Learn more](#actions-not-showing-up)**

If you have any questions about how to use the different actions or for what, try asking the [Actions GPT bot](https://chatgpt.com/g/g-6746353a017881918cceb0761aea3bfe-actions-app-companion). And if you want to feed your own AI, [here is the source data](https://gist.githubusercontent.com/sindresorhus/fbba65a774fb9da915e624807a02a6d2/raw/7be21a65977b6dd82d1a6cc34be4476df057ea06/actions.md).

---

*On macOS, also check out [Shortcutie](/shortcutie) for advanced actions and [Short Run](/short-run) for running shortcuts from the menu bar.*

---

#### Included actions

- Add to List
- Apply Capture Date
- Ask for Duration
- Ask for Text with Timeout
- Authenticate
- Blur Images
- Boolean
- Calculate Distance
- Calculate with Soulver
- Choose from List (Extended)
- Clamp Number
- Color
- Combine Lists
- Combine Videos
- Convert Coordinates to Location
- Convert Date to Reference Timestamp
- Convert Date to Unix Timestamp
- Convert Location to Geo URI
- Convert Reference Timestamp to Date
- Convert Unix Timestamp to Date
- Create Color Image
- Create Duration
- Create Gradient Color Image
- Create Menu Item
- Create URL
- Create URL Shortcut File
	<span class="list-description">Create [`.url` or `.webloc`](https://en.wikipedia.org/wiki/Shortcut_(computing)) files that open websites when double-clicked. Primarily for macOS.</span>
- Download File
- Edit URL
- Encrypt File
- Encrypt Text
- Filter List
- Find Music Playlist <sup>(iOS-only)</sup>
- Find Wi-Fi Network <sup>(macOS-only)</sup>
- Flash Screen <sup>(macOS-only)</sup>
- Format Currency
- Format Date Difference
- Format Duration
- Format Number as Ordinal
- Format Number — Compact
- Format Person Name
- Format Text List
	<span class="list-description">`["A", "B", "C"]` → `A, B, and C`</span>
- Generate CSV
- Generate Haptic Feedback <sup>(iOS-only)</sup>
- Generate Random Data
- Generate Random Text
- Generate UUID
- Get All System Colors
- Get Audio Playback Destination <sup>(iOS-only)</sup>
- Get Average Color
- Get Average Color of Image
- Get Battery State
- Get Bluetooth Device
- Get Bluetooth Devices
- Get Boolean from Input
- Get Compass Heading <sup>(iOS-only)</sup>
- Get Default Browser <sup>(macOS-only)</sup>
- Get Device Details (Extended)
	- Uptime (not including sleep)
	- Uptime (including sleep)
	- Active processor count
	- Physical memory
	- Time zone
	- Hostname
	- Thermal state
	- Total storage capacity
	- Available storage capacity
	- Battery condition <sup>(macOS-only)</sup>
	- Battery health <sup>(macOS-only)</sup>
	- Serial number <sup>(macOS-only)</sup>
- Get Device Motion Activity
	<span class="list-description">(stationary, walking, running, cycling, automotive, etc.)</span>
- Get Device Motion Data <sup>(iOS-only)</sup>
- Get Device Orientation
- Get Dominant Colors of Image
- Get Elevation <sup>(iOS-only)</sup>
- Get Emojis
- Get File Path
- Get High-Resolution Timestamp
- Get Index of List Item
- Get Map Image of Location
- Get Modifier Key State <sup>(macOS-only)</sup>
- Get Paragraphs from Text
- Get Printers <sup>(macOS-only)</sup>
- Get Query Item Value from URL
- Get Query Items from URL
- Get Query Items from URL as Dictionary
- Get Random Boolean
- Get Random Color
- Get Random Date and Time
- Get Random Emoticon
- Get Random Floating-Point Number
- Get Random Number from Seed
- Get Related Words
- Get Running Apps <sup>(macOS-only)</sup>
- Get Sentences from Text
- Get SF Symbol Image
- Get System Color
- Get Title of URL
- Get User Details
	- Username <sup>(macOS-only)</sup>
	- Full Name
	- Given Name
	- Family Name
	- Initials
	- Shell
	- Language Code
	- Idle Time <sup>(macOS-only)</sup>
	- Administrator Status <sup>(macOS-only)</sup>
- Get Values Using [JSONPath](https://en.wikipedia.org/wiki/JSONPath)
- Get/Set Default Printer <sup>(macOS-only)</sup>
- Get/Set File Extension Visibility <sup>(macOS-only)</sup>
	<span class="list-description">Check and control whether file extensions are shown in Finder for specific files. Only works if the “Show all filename extensions” Finder setting is disabled.</span>
- Get/Set File Icon <sup>(macOS-only)</sup>
	<span class="list-description">Get the icon of files and folders or set custom icons for them.</span>
- Get/Set File Tags
- Get/Set Image Capture Date
- Get/Set Image Location
- Get/Set Uniform Type Identifier
- Global Variable
- Hex Encode
- Hide Shortcuts App
- Invert Dictionary
	<span class="list-description">`{"en": "Hello", "es": "Hola"}` → `{"Hello": "en", "Hola": "es"}`</span>
- Invert Images
- Is Accessibility Feature On
- Is Audio Playing <sup>(iOS-only)</sup>
- Is Bluetooth On
- Is Call Active <sup>(iOS-only)</sup>
- Is Camera On <sup>(macOS-only)</sup>
- Is Cellular Data On
- Is Cellular Low Data Mode On
- Is Conforming to Uniform Type Identifier
- Is Connected to VPN <sup>(iOS-only)</sup>
- Is Dark Mode On
- Is Day
- Is Device Locked
- Is Device Moving
- Is Device Orientation
- Is Host Reachable
- Is Location Services Enabled
- Is Low Power Mode On
- Is Microphone On <sup>(macOS-only)</sup>
- Is Online
- Is Screen Locked <sup>(macOS-only)</sup>
- Is Screen Saver Active
- Is Shaking Device
- Is Silent Mode On <sup>(iOS-only)</sup>
- Is Time
- Is Time In Range
- Is Web Server Reachable
- Is Wi-Fi On <sup>(macOS-only)</sup>
- Join Wi-Fi <sup>(iOS-only)</sup>
- Merge Dictionaries
- Named Clipboard <sup>(macOS-only)</sup>
- Open URLs in Safari
- Open URLs with App <sup>(macOS-only)</sup>
	<span class="list-description">For example, open URLs in a specific browser.</span>
- Overwrite File
- Parse CSV
- Parse JSON5
- Pick Color
	<span class="list-description">Pick a color using the system color picker, optionally from a reference image.</span>
- Play Alert Sound <sup>(macOS-only)</sup>
- Pretty Print Dictionaries
- Remove Duplicate Lines
- Remove Duplicates from List
- Remove Emojis
- Remove Empty Lines
- Remove from List
- Remove Non-Printable Characters
- Reverse Lines
- Reverse List
- Round Number to Decimal Places
	<span class="list-description">`3.14159` → `3.14`</span>
- Round Number to Multiple
- Sample Color from Screen <sup>(macOS-only)</sup>
- Scan Documents <sup>(iOS-only)</sup>
- Scan QR Codes in Image
- Send Distributed Notification <sup>(macOS-only)</sup>
	- [What are distributed notifications?](/apps/faq#distributed-notifications)
- Set Creation and Modification Date of File
- Set Dictionary Value Using [JSONPath](https://en.wikipedia.org/wiki/JSONPath)
- Show Black Screen <sup>(iOS-only)</sup>
- Show Notification
- Shuffle List
- Sort List
- Sort Months
- Spell Out Number
- Toggle Boolean
- Transform Lists
- Transform Text
	- Camel case
	- Pascal case
	- Snake case
	- Constant case
	- Dash case
	- Slugify
	- Strip punctuation
	- Strip quotation marks
	- Strip HTML
	- Strip diacritics
	- Transliterate to Latin
	- Transliterate Latin to Arabic
	- Transliterate Latin to Cyrillic
	- Transliterate Latin to Greek
	- Transliterate Latin to Hebrew
	- Transliterate Latin to Hangul
	- Transliterate Latin to Hiragana
	- Transliterate Latin to Thai
	- Transliterate Hiragana to Katakana
	- Transliterate Mandarin to Latin
- Transform Text with JavaScript
- Trim Whitespace
- Truncate List
- Truncate Number
- Truncate Text
- Use System Font in Rich Text
	- [Example shortcut](https://www.icloud.com/shortcuts/03aecdb46eca496aaf996ebc625a0c54)
- Wait for Distributed Notification <sup>(macOS-only)</sup>
	- [What are distributed notifications?](/apps/faq#distributed-notifications)
- Wait Milliseconds
- Write or Edit Text

#### Want more shortcut actions? {#more-actions}

- High-quality transcription (speech to text) in 100 languages → [Aiko](/aiko)
- Trigger shortcuts on your Mac from your iOS device → [Hyperduck](/hyperduck#shortcuts)
- Set default browser → [Supercharge](/supercharge) & [Default Browser](/default-browser)
- Use the ChatGPT API, Ollama, Groq → [AI Actions](/ai-actions)
- Show text in menu bar → [One Thing](/one-thing)
- Open URLs in a specific browser → [Velja](/velja)
- Remove tracking parameters from URLs → [Velja](/velja) & [Pure Paste](/pure-paste)
- Check if online → [Online Check](/online-check)
- Generate images from text with AI locally → [Amazing AI](/amazing-ai)
- Clear clipboard formatting → [Pure Paste](/pure-paste)
- Get internet speed → [Speediness](/speediness)
- Join video calls → [Dato](/dato)
- Put text on the iOS Lock Screen → [Any Text](/any-text)
- Preview app icons → [Icon Preview](/icon-preview)
- Get clipboard items → [Pasteboard Viewer](/pasteboard-viewer)
<!-- - Get random animated GIF → [Jiffy](/jiffy) -->

#### Impossible actions {#impossible-actions}

Some common actions requests that are not possible:

- Orientation lock status
- Flashlight status
- Ambient sensor info
- Flight mode status
- Hotspot status
- Hotspot connect/disconnect
- All audio playback destinations
- CarPlay connection status
- Notifications in CarPlay

Anything related to changing system features/settings or interacting with other apps is generally not possible.

For these, I recommend sending a [feature request to Apple](https://feedbackassistant.apple.com).

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Actions&referrer=Website-FAQ)

#### The actions don't show up in the Shortcuts app {#actions-not-showing-up}

This is caused by a iOS/macOS bug.

Some things you could try:

1. Restart your device.
1. Change the device language to something else and back.
1. Add [this shortcut](https://www.icloud.com/shortcuts/14315b9af3774a0c8cb439718a67fb2f), run it once, relaunch Shortcuts, and see if the actions show up in the Shortcuts app after that.
1. Add [this shortcut](https://www.icloud.com/shortcuts/e3b39e37d8d6439db9119ebbff626958), copy the action, paste it into a new shortcut, and relaunch Shortcuts.
1. Remove the app, install it again, and restart your device.

*Please don't contact me about this issue. This is a problem with iOS/macOS and out of my control.*

#### I get a “errorDomain error 2” error when running an action

Same solution as above.

#### Why is this free without ads?

I just enjoy making apps and want this to be available for everyone. Consider leaving a nice review on the App Store.

#### How can I prevent the app from being offloaded when I have “app offloading” enabled on iOS?

iOS does not have a way to prevent individual apps from being offloaded (even though it should!) and there is no way for apps to tell iOS not to offload them. I recommend [sending feedback to Apple](https://feedbackassistant.apple.com) about this. You could try [this workaround](https://www.reddit.com/r/ios/comments/85k8b5/disable_offloading_for_specific_apps/).

#### [More FAQs…](/apps/faq)

## Older versions

- [3.5.1](https://github.com/user-attachments/files/18963268/Actions.3.5.1.-.macOS.14.zip) for macOS 14+
- [2.10.0](https://www.dropbox.com/scl/fi/lzy4po8qfggroxcv9pzdo/Actions-2.10.0-1731826197.zip?rlkey=f37xihlhq45syauygdn5268un&raw=1) for macOS 13+
- [1.13.1](https://www.dropbox.com/scl/fi/9iqfn8airygpk0la4gv1u/Actions-1.13.1-1731826428.zip?rlkey=y4u5ni2pn28rp3lse08lv96k6&raw=1) for macOS 12+

## Non-App Store Version

A special macOS version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/p1mxfqhy35ih6semoh28b/Actions-3.6.0-1740482537.zip?rlkey=u9p8r3gpqtbkslti39ttte1pa&raw=1) *(3.6.0 · macOS 15+)*
