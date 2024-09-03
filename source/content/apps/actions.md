---
title: Actions
subtitle: Additional actions for the Shortcuts app
pubDate: 2021-10-28
platforms:
  - macOS
  - iOS
  - visionOS
appStoreId: 1586435171
links:
  'TestFlight': https://testflight.apple.com/join/fJGUrsZx
olderMacOSVersions:
  - '12'
  - '13'
feedbackNote: |
  ### If you get a “com.apple.extensionKit.errorDomain error 2” error when running your shortcut or if the actions don't show up in the Shortcuts app, restart your device. You could also try setting a different device language and then back. If you just updated the operating system, give it some time to re-index all shortcut actions. Please don't contact me about this issue. This is a problem with iOS/macOS and out of my control.

  **Some actions that are not possible: orientation lock status, flashlight status, ambient sensor info, flight mode status, [and more](/actions#impossible-actions). Generally, anything related to changing system features/settings or interacting with other apps is not possible.**
---

The app provides lots of powerful extra actions for the Shortcuts app on macOS, iOS, and visionOS. These actions make it significantly easier to create shortcuts.

**Restart your device if the actions do not show up in the Shortcuts app. Also try setting a different device language and then back.**

---

#### Included actions

- Add to List
- Apply Capture Date
- Ask for Text with Timeout
- Authenticate
- Blur Images
- Boolean
- Calculate with Soulver
- Choose from List (Extended)
- Clamp Number
- Color
- Combine Lists
- Combine Videos
- Convert Coordinates to Location
- Convert Date to Unix Time
- Convert Location to Geo URI
- Convert Unix Time to Date
- Create Color Image
- Create Menu Item
- Create URL
- Edit URL
- Encrypt File
- Encrypt Text
- Filter List
- Find Music Playlist <sup>(iOS-only)</sup>
- Flash Screen <sup>(macOS-only)</sup>
- Format Currency
- Format Date Difference
- Format Duration
- Format Number — Compact
- Format Person Name
- Generate CSV
- Generate Haptic Feedback <sup>(iOS-only)</sup>
- Generate Random Data
- Generate Random Text
- Generate UUID
- Get Audio Playback Destination <sup>(iOS-only)</sup>
- Get Average Color
- Get Average Color of Image
- Get Battery State
- Get Bluetooth Device
- Get Bluetooth Devices
- Get Boolean from Input
- Get Compass Heading <sup>(iOS-only)</sup>
- Get Default Printer / Set Default Printer <sup>(macOS-only)</sup>
- Get Device Details (Extended)
- Get Device Motion Data <sup>(iOS-only)</sup>
- Get Device Orientation
- Get Dominant Colors of Image
- Get Elevation <sup>(iOS-only)</sup>
- Get Emojis
- Get File Icon <sup>(macOS-only)</sup>
- Get File Path
- Get High-Resolution Timestamp
- Get Image Location / Set Image Location
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
- Get Title of URL
- Get Uniform Type Identifier / Set Uniform Type Identifier
- Get User Details
- Global Variable
- Hex Encode
- Hide Shortcuts App
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
- Is Low Power Mode On
- Is Microphone On <sup>(macOS-only)</sup>
- Is Online
- Is Screen Locked <sup>(macOS-only)</sup>
- Is Shaking Device
- Is Silent Mode On <sup>(iOS-only)</sup>
- Is Time
- Is Web Server Reachable
- Is Wi-Fi On <sup>(macOS-only)</sup>
- Join Wi-Fi <sup>(iOS-only)</sup>
- Merge Dictionaries
- Named Clipboard <sup>(macOS-only)</sup>
- Open URLs with App <sup>(macOS-only)</sup>
- Overwrite File
- Parse CSV
- Parse JSON5
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
- Round Number to Multiple
- Sample Color from Screen <sup>(macOS-only)</sup>
- Scan Documents <sup>(iOS-only)</sup>
- Scan QR Codes in Image
- Set Creation and Modification Date of File
- Shuffle List
- Sort List
- Spell Out Number
- Transform Lists
- Transform Text *(camel case, slugify, transliteration, etc.)*
- Transform Text with JavaScript
- Trim Whitespace
- Truncate List
- Truncate Number
- Truncate Text
- Wait Milliseconds
- Write or Edit Text

#### Want more shortcut actions?

- High-quality transcription (speech to text) in 100 languages → [Aiko](https://sindresorhus.com/aiko)
- Trigger shortcuts on your Mac from your iOS device → [Hyperduck](https://sindresorhus.com/hyperduck#shortcuts)
- Show text in menu bar → [One Thing](https://sindresorhus.com/one-thing)
- Open URLs in a specific browser → [Velja](https://sindresorhus.com/velja)
- Remove tracking parameters from URLs → [Velja](https://sindresorhus.com/velja) & [Pure Paste](https://sindresorhus.com/pure-paste)
- Generate images from text with AI locally → [Amazing AI](https://sindresorhus.com/amazing-ai)
- Clear clipboard formatting → [Pure Paste](https://sindresorhus.com/pure-paste)
- Get internet speed → [Speediness](https://sindresorhus.com/speediness)
- Join video calls → [Dato](https://sindresorhus.com/dato)
- Put text on the iOS Lock Screen → [Any Text](https://sindresorhus.com/any-text)
- Get random animated GIF → [Jiffy](https://sindresorhus.com/jiffy)
- Get clipboard items → [Pasteboard Viewer](https://sindresorhus.com/pasteboard-viewer)
- Preview app icons → [Icon Preview](https://sindresorhus.com/icon-preview)
- Use the ChatGPT API, Ollama, Groq → [AI Actions](https://sindresorhus.com/ai-actions)

#### Impossible actions {#impossible-actions}

Some common actions requests that are not possible:

- Orientation lock status
- Flashlight status
- Ambient sensor info
- Flight mode status
- Hotspot status

Anything related to changing system features/settings or interacting with other apps is generally not possible.

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Actions&referrer=Website-FAQ)

#### The actions don't show up in the Shortcuts app

Restart your device. This is caused by a iOS/macOS bug. Changing the device language to something else and back can also sometimes resolve the issue.

#### I get a “errorDomain error 2” error when running an action

Same solution as above.

#### Why is this free without ads?

I just enjoy making apps and want this to be available for everyone. Consider leaving a nice review on the App Store.

#### How can I prevent the app from being offloaded when I have “app offloading” enabled on iOS?

iOS does not have a way to prevent individual apps from being offloaded (even though it should!) and there is no way for apps to tell iOS not to offload them. I recommend [sending feedback to Apple](https://feedbackassistant.apple.com) about this. You could try [this workaround](https://www.reddit.com/r/ios/comments/85k8b5/disable_offloading_for_specific_apps/).

#### [More FAQs…](/apps/faq)

### Older versions

- [2.10.0](https://github.com/sindresorhus/Actions/releases/download/v2.10.0/Actions.2.10.0.zip) for macOS 13+
- [1.13.1](https://github.com/sindresorhus/Actions/releases/download/v1.13.1/Actions.1.13.1.-.macOS.12.zip) for macOS 12+

### Non-App Store Version

A special macOS version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://github.com/sindresorhus/meta/files/13718302/Actions.3.0.0.zip) *(3.0.0 · macOS 14+)*
