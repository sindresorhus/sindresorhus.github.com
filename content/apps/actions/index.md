---
title: 'Actions'
subtitle: 'Additional actions for the Shortcuts app'
publicationDate: '2021-10-28'
platforms: [
	'macOS'
	'iOS'
	'visionOS'
]
hasSentry: true
appStoreID: 1586435171
links: {
	TestFlight: 'https://testflight.apple.com/join/fJGUrsZx'
}
olderVersions: [
	{
		version: '3.8.0'
		macOS: '15'
		url: 'https://www.dropbox.com/scl/fi/fhfw330g14eh35bwofuyy/Actions-3.8.0-macOS-15-1773919013.zip?rlkey=9l9f3noc5l64j9r0cai9lc5rm&raw=1'
	}
	{
		version: '3.5.1'
		macOS: '14'
		url: 'https://github.com/user-attachments/files/18963268/Actions.3.5.1.-.macOS.14.zip'
	}
	{
		version: '2.10.0'
		macOS: '13'
		url: 'https://www.dropbox.com/scl/fi/lzy4po8qfggroxcv9pzdo/Actions-2.10.0-1731826197.zip?rlkey=f37xihlhq45syauygdn5268un&raw=1'
	}
	{
		version: '1.13.1'
		macOS: '12'
		url: 'https://www.dropbox.com/scl/fi/9iqfn8airygpk0la4gv1u/Actions-1.13.1-1731826428.zip?rlkey=y4u5ni2pn28rp3lse08lv96k6&raw=1'
	}
]
feedbackNote:
	'''
	### If you just updated to iOS 26, it may take some time for iOS to re-index all the Shortcuts actions. Give it some time.

	### If the actions don’t show up in the Shortcuts app or you get a “com.apple.extensionKit.errorDomain error 2”, [see this](/actions#actions-not-showing-up).<br><br>

	Tip: To pass a variable to a file input in Shortcuts, tap-and-hold (iOS) or right-click (macOS) the input and select the variable.

	**Some actions that are not possible: orientation lock status, flashlight status, ambient sensor info, flight mode status, [and more](/actions#impossible-actions).**

	This is not the place to ask general Shortcuts questions. Try [r/shortcuts](https://www.reddit.com/r/shortcuts/) instead.
	'''
categories: [
	'shortcuts'
]
pressQuotes: [
	{
		quote: '[…] my shortcut uses an action from the excellent free (and aptly-named) Actions utility by Sindre Sorhus.'
		source: 'Daring Fireball'
		url: 'https://daringfireball.net/2023/09/the_iphones_15_pro'
	}
]
---

Adds 180+ free actions to the Shortcuts app on macOS, iOS, and visionOS. They do what the built-in actions cannot, and turn long shortcuts into a few steps.

> [!IMPORTANT]
> Restart your device if the actions do not show up in the Shortcuts app. [Learn more ›](#actions-not-showing-up)

If you have any questions about how to use the different actions or for what, try asking the [Actions GPT bot](https://chatgpt.com/g/g-6746353a017881918cceb0761aea3bfe-actions-app-companion). And if you want to feed your own AI, [here is the source data](https://gist.githubusercontent.com/sindresorhus/fbba65a774fb9da915e624807a02a6d2/raw/7be21a65977b6dd82d1a6cc34be4476df057ea06/actions.md).

---

> [!TIP]
> On macOS, also check out [Shortcutie](/shortcutie) for advanced actions and [Short Run](/short-run) for running shortcuts from the menu bar.

---

#### Included actions

- Add to List
- Apply Capture Date
- Ask for Duration
- Ask for Input with Dialog
	:: Show a dialog with a text field and multiple buttons. Returns both the entered text and which button was tapped, with support for timeout, custom icon (macOS), image, and destructive button styling. You can disable the text field to just have a confirmation dialog.
- Ask for Text with Timeout
- Authenticate
- Blur Images
- Boolean
- Calculate Bearing
	:: Get the compass direction between two coordinates.
- Calculate Distance
- Calculate String Distance
	:: [Damerau-Levenshtein distance](https://en.wikipedia.org/wiki/Damerau–Levenshtein_distance) for fuzzy search, typo detection, deduping, and matching names or identifiers.
- Calculate with Soulver
- Choose from List (Extended)
- Clamp Number
- Clean Zip
	:: Removes .DS_Store files and __MACOSX directories from a ZIP archive. Useful when sharing ZIP files with non-Mac users.
- Color
- Combine Audio Files
- Combine Lists
- Combine Videos
- Convert Coordinates to Location
- Convert Date to Reference Timestamp
- Convert Date to Unix Timestamp
- Convert Location to Geo URI
- Convert Number Base
	:: Convert between binary, octal, decimal, and hexadecimal.
- Convert Reference Timestamp to Date
- Convert Text File Encoding
	:: Convert text files between character encodings (UTF-8, Shift-JIS, Windows-1252, etc.) with automatic source detection.
- Convert Unix Timestamp to Date
- Counter
	:: Atomic counter. Use cases: avoid races in concurrent automations, rate-limit runs, store progress (“step-3”), track daily counts.
- Create Color Image
- Create Duration
- Create Gradient Color Image
- Create Menu Item
- Create Temporary Folder
	:: Creates a unique temporary folder.
- Create URL
- Create URL Shortcut File
	:: Create [`.url` or `.webloc`](https://en.wikipedia.org/wiki/Shortcut_(computing)) files that open websites when double-clicked. Primarily for macOS.
- Delete Empty Contacts
	:: Deletes contacts that have no name, phone number, email, or any other data.
- Download File
- Edit URL
- Encode Property List
	:: Convert a Shortcuts dictionary or JSON file into an XML or binary property list file.
- Encrypt File
- Encrypt Text
- Filter List
- Filter List of Dictionaries
- Find Music Playlist <sup>(iOS-only)</sup>
- Find Wi-Fi Network <sup>(macOS-only)</sup>
- Find Workout <sup>(iOS-only)</sup>
	:: Returns workouts from the Health app, including workout type, duration, source details, and metrics like active calories, heart rate, etc.
- Find Points of Interest
	:: Find nearby places matching a query around a location.
- Flash Screen <sup>(macOS-only)</sup>
- Format Currency
- Format Date Difference
- Format Duration
- Format Number as Ordinal
- Format Number — Compact
- Format Person Name
- Format Text List
	:: `["A", "B", "C"]` → `A, B, and C`
- Format URL
	:: Formats a URL into text with customizations of what to show.
- Generate CSV
- Generate Emojis
- Generate Haptic Feedback <sup>(iOS-only)</sup>
- Generate Random Data
- Generate Random Text
- Generate SOML
	:: Generate a [SOML](https://soml.sh) config file from a dictionary.
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
- Get Contents of URL (Extended)
	:: Enhanced HTTP requests with complete response details (status codes, headers, all methods) instead of just the response body like the built-in action, and also timeout.
- Get Date Added of File
	:: Returns the date when a file was added to its parent folder.
- Get Dates in Range
	:: Returns all dates between two dates filtered by type. For example, get all Mondays between two dates, or list every weekend in a month.
- Get Default Browser <sup>(macOS-only)</sup>
- Get Default Gateway IP Address
	:: Returns the default gateway IP address for the current network, usually the router address on Wi-Fi or Ethernet.
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
	:: (stationary, walking, running, cycling, automotive, etc.)
- Get Device Motion Data <sup>(iOS-only)</sup>
- Get Device Orientation
- Get Dominant Colors of Image
- Get Barometric Pressure <sup>(iOS-only)</sup>
	:: Returns the current barometric pressure from the device’s built-in barometer.
- Get Elevation <sup>(iOS-only)</sup>
- Get Emojis
- Get/Set Extended Attribute
	:: Returns or sets an [extended attribute](https://en.wikipedia.org/wiki/Extended_file_attributes) for a file.
- Get Extended Attribute Names
	:: Returns the names of the extended attributes on a file or folder.
- Get File Path
- Get Folder Size
	:: Returns the size of a folder, including files in subfolders. Use “Format File Size” to format the result.
- Get High-Resolution Timestamp
- Get Image URLs from Web Page
	:: Extracts image URLs from a web page and returns them without downloading.
- Get Images from Web Page
	:: Extracts images from a web page and returns them as files.
- Get Index of List Item
- Get Map Image of Location
- Get Media Metadata
- Get Meta Tags of URL
	:: Extract meta tags (title, description, Open Graph, etc.) from a webpage.
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
- Get Raw Media Metadata
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
	:: Check and control whether file extensions are shown in Finder for specific files. Only works if the “Show all filename extensions” Finder setting is disabled.
- Get/Set File Icon <sup>(macOS-only)</sup>
	:: Get the icon of files and folders or set custom icons for them.
- Get/Set File Tags
- Get/Set Image/Video Capture Date
- Get/Set Image/Video Location
- Get/Set Uniform Type Identifier
- Global Variable
- Hex Encode
- Hide Shortcuts App
- Invert Dictionary
	:: `{"en": "Hello", "es": "Hola"}` → `{"Hello": "en", "Hola": "es"}`
- Invert Images
- Is 24-Hour Time Format
- Is Accessibility Feature On
- Is Audio Playing <sup>(iOS-only)</sup>
- Is Bluetooth Device Connected
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
- Is True
	:: Check if boolean values satisfy a logical condition: all true (AND), all false (NOR), any true (OR), any false (NAND), or exactly one true (XOR). Supports up to 10 values.
- Is Web Server Reachable
- Is Wi-Fi On <sup>(macOS-only)</sup>
- Join Wi-Fi <sup>(iOS-only)</sup>
- Keychain
	:: Securely stores a value in the device [keychain](https://developer.apple.com/documentation/security/keychain-services). Useful for sensitive data like API keys, tokens, and passwords. Can be synced.
- Make Live Photo from Video
- Make Markdown Table
- Manage Shortcut Lock
	:: Prevents multiple instances of a shortcut from running simultaneously
- Merge Dictionaries
- Named Clipboard <sup>(macOS-only)</sup>
- Normalize URL
	:: Clean up URLs by lowercasing scheme and host, removing default ports, optional query/fragment removal, text-fragment cleanup, etc.
- Open URLs in Safari
- Open URLs with App <sup>(macOS-only)</sup>
	:: For example, open URLs in a specific browser.
- Overwrite File
- Overlay Image (Extended)
	:: Overlay an image on top of another one with blend modes, opacity, rotation, flipping, and precise positioning.
- Parse CSV
- Parse JSON5
- Parse Markdown Table
- Parse SOML
	:: Parse a [SOML](https://soml.sh) config file into a dictionary, with durations as seconds.
- Pick Color
	:: Pick a color using the system color picker, optionally from a reference image.
- Ping
	:: Ping a host using ICMP, similar to the `ping` command-line tool, and get statistics including average/min/max round-trip time and packet loss.
- Play Alert Sound <sup>(macOS-only)</sup>
- Play Media with Controls
	:: Play media from a URL or file with in-app playback controls, and optionally wait until playback ends.
- Pretty Print Dictionaries
- Read/Write NFC Tag <sup>(iOS-only)</sup>
	:: Read the identifier and content of an NFC tag, or write text or a URL to it.
- Remove Dictionary Values
- Remove Duplicate Lines
- Remove Duplicates from List
- Remove Emojis
- Remove Empty Lines
- Remove from List
- Remove Non-Printable Characters
- Reverse Lines
- Reverse List
- Round Number to Decimal Places
	:: `3.14159` → `3.14`
- Round Number to Multiple
- Run cURL Command
	:: Execute an HTTP request from a cURL command string. Simply paste a cURL command from Postman, Swagger, or browser dev tools. Supports common options like headers, body data, authentication, redirects, and more.
- Sample Color from Screen <sup>(macOS-only)</sup>
- Scan Barcodes in Image
- Scan Documents <sup>(iOS-only)</sup>
- Scan QR Codes in Image
- Send Distributed Notification <sup>(macOS-only)</sup>
	- [What are distributed notifications?](/apps/faq#distributed-notifications)
- Set Capture Date of Photos
	:: Change the capture date of photos and videos directly in your Photos library.
- Set Creation and Modification Date of File
- Set Dictionary Value Using [JSONPath](https://en.wikipedia.org/wiki/JSONPath)
- Set Location of Photos
	:: Change the location of photos and videos directly in your Photos library.
- Show Black Screen <sup>(iOS-only)</sup>
- Show Notification
- Show Overlay
	:: Display large centered text on a fullscreen overlay. Supports plain text with custom colors and HTML mode for custom styling. The overlay stays until tapped or an optional duration expires.
- Shuffle List
- Sign JSON Web Token
	:: Signs a JSON payload as a JWT using HS256.
- Sort List
- Sort List of Dictionaries
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
	- JSON Escape
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
- Trim Text
	:: Keep or drop a number of lines or characters from the start or end of text.
- Trim Whitespace
- Truncate List
- Truncate Number
- Truncate Text
- Use System Font in Rich Text
	- [Example shortcut](https://www.icloud.com/shortcuts/03aecdb46eca496aaf996ebc625a0c54)
- Wake on LAN <sup>(macOS-only)</sup>
	:: Wake a sleeping computer or network device by sending a [Wake on LAN](https://en.wikipedia.org/wiki/Wake-on-LAN) magic packet.
- Wait for Distributed Notification <sup>(macOS-only)</sup>
	- [What are distributed notifications?](/apps/faq#distributed-notifications)
- Wait Milliseconds
- Write or Edit Text

#### Want more shortcut actions? {#more-actions}

- Run shortcuts from the menu bar or silently in the background via URL scheme → [Short Run](/short-run)
- High-quality transcription (speech to text) in 100 languages → [Aiko](/aiko)
- Trigger shortcuts on your Mac from your iOS device → [Hyperduck](/hyperduck#shortcuts)
- Set default browser → [Supercharge](/supercharge) & [Default Browser](/default-browser)
- Use the ChatGPT API, Ollama, Groq → [AI Actions](/ai-actions)
- Show text in menu bar → [One Thing](/one-thing)
- Open URLs in a specific browser → [Velja](/velja)
- Remove tracking parameters from URLs → [Velja](/velja) & [Pure Paste](/pure-paste)
- Check if online → [Online Check](/online-check)
- Generate images from text with AI locally → [Imago](/imago)
- Clear clipboard formatting → [Pure Paste](/pure-paste)
- Get internet speed → [Speediness](/speediness)
- Join video calls → [Dato](/dato)
- Put text on the iOS Lock Screen → [Any Text](/any-text)
- Preview app icons → [Icon Preview](/icon-preview)
- Get clipboard items → [Pasteboard Viewer](/pasteboard-viewer)
<!-- - Get random animated GIF → [Jiffy](/jiffy) -->

#### Impossible actions {#impossible-actions}

Some common action requests that are not possible:

- Reading what’s on the screen
- Current text selection
- Orientation lock status
- Flashlight status
- Ambient sensor info
- Flight mode status
- Hotspot status
- Hotspot connect/disconnect
- All audio playback destinations
- CarPlay connection status
- Notifications in CarPlay
- Media volume
- More accessibility checks (like reduce white point)
- If charging wirelessly
- Get multiple representation from an item

Anything related to changing system features/settings or interacting with other apps is generally not possible.

For these, I recommend sending a [feature request to Apple](https://feedbackassistant.apple.com).

#### Already exists {#exists}

- Is Wi-Fi On (iOS): Already possible with the built-in “Get Network Details” action.
- Wi-Fi Strength: Already possible with the built-in “Get Network Details” action.

#### Declined actions {#declined-actions}

- Imgur: I generally don’t want to integrate with services. They cause a huge support burden, either by being unreliable, breaking the API, shutting down, and other things.

## Tips

### URL Scheme {#url-scheme}

The app supports the `actions://` URL scheme that can be used to open the app.

## Frequently Asked Questions {#faq}

### The actions don’t show up in the Shortcuts app {#actions-not-showing-up}

This is caused by an iOS/macOS bug.

Some things you could try:

1. Restart your device.
1. Change the device language to something else and back.
1. Add [this shortcut](https://www.icloud.com/shortcuts/14315b9af3774a0c8cb439718a67fb2f), run it once, relaunch Shortcuts, and see if the actions show up in the Shortcuts app after that.
1. Add [this shortcut](https://www.icloud.com/shortcuts/e3b39e37d8d6439db9119ebbff626958), copy the action, paste it into a new shortcut, and relaunch Shortcuts.
1. Remove the app, install it again, and restart your device.

*Please don’t contact me about this issue. This is a problem with iOS/macOS and out of my control.*

### I get a “errorDomain error 2” error when running an action

Same solution as above.

### How can I prevent the app from being offloaded when I have “app offloading” enabled on iOS?

iOS does not have a way to prevent individual apps from being offloaded (even though it should!) and there is no way for apps to tell iOS not to offload them. I recommend [sending feedback to Apple](https://feedbackassistant.apple.com) about this. You could try [this workaround](https://www.reddit.com/r/ios/comments/85k8b5/disable_offloading_for_specific_apps/).

### Can the “Show Notification” action send critical alerts?

No. I applied for Apple’s [Critical Alerts entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.usernotifications.critical-alerts), but it was declined.
Critical Alerts are reserved for very limited use cases such as medical, health, home security, and public safety notifications. General-purpose automation apps like Actions are not eligible.

## Non-App Store Version

A special macOS version for users that cannot access the App Store. It won’t receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/7mt9uvbmn589y4qobdpe9/Actions-4.0.1-1774194992.zip?rlkey=7tg0zlun69c19t6m5lmn2ph0q&raw=1) *(4.0.1 · macOS 26+)*
