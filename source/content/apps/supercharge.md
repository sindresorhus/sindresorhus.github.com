---
title: Supercharge
subtitle: Elevate your Mac experience
pubDate: 2024-09-29
platforms:
  - macOS
isPaid: true
isMenuBarApp: true
setappId: 742
releasesRepo: supercharge-meta
mainLinks:
  'Buy': https://sindresorhus.gumroad.com/l/supercharge?wanted=true
# olderMacOSVersions:
#   - '15'
feedbackNote: |
  When reporting bugs, try quitting Supercharge, and if the issue disappears, it is likely not an issue with Supercharge. If the issue is still there, try turning off things in the “Tweaks” settings tab until it does not happen anymore, to narrow down which feature is causing the issue, and let me know.

  The Finder context menu items will not show up in any [sync folder like iCloud, Dropbox, etc](#finder-context-menu-icloud).
---

<sup>Requires macOS 15.2 or later</sup>

Improve your Mac experience with a bunch of useful functionality:

*(Every feature is opt-in, so you can enable only what you need)*

- Clear notifications with a keyboard shortcut or from the menu
- [Close & minimize windows and hide & quit apps directly from Mission Control](#mission-control-improvements)
- [Clicking an active app's Dock icon hides the app or minimizes its windows](#dock-icon-click-behavior)
- Unminimizes an app’s windows when activated <sup>(e.g., via <kbd>Command+Tab</kbd>)</sup>
- Hide all windows <sup>(aka. boss mode)</sup>
- [Capture and translate text from anywhere on screen](#capture-translate-text)
<!-- - [Hyper key](#hyper-key) -->
- Prevent accidental app quits[^quit] by instead using <kbd>⇧⌘Q</kbd>, double tap <kbd>Q</kbd> while holding <kbd>⌘</kbd>, or [press and hold <kbd>⌘Q</kbd>](https://github.com/user-attachments/assets/0515e50f-2a93-4369-836e-085ad462fdf8)
- [Launch any app with a customizable global keyboard shortcut](https://github.com/user-attachments/assets/22bf135a-cc39-45ef-82ef-bf23176f0746)
- [Clicking green traffic light button fills window instead of entering fullscreen](#green-traffic-light-button-fill)
- [Clicking yellow traffic light button hides app instead of minimizing window](#yellow-traffic-light-button-hide)
- [Scan QR codes and barcodes from anywhere on screen](#scan-qr-codes)
- Quit apps when closing their last window (clicking the red traffic light button or <kbd>Command+W</kbd>) (similar to Swift Quit and RedQuits apps)
- Finder: Move files by cutting[^commandx] (<kbd>Command+X</kbd>) and pasting (<kbd>Command+V</kbd>)
- Finder: Open files with <kbd>Return</kbd> (you can then rename with <kbd>Shift+Return</kbd> or <kbd>F2</kbd>)
- Finder: Create new text file with <kbd>Option+N</kbd> *([video](https://github.com/user-attachments/assets/cb2c4606-12eb-4915-a64c-9b8ac3e123cf))* or from the [context menu](#finder-context-menu)
- Finder: Move files to the trash with <kbd>⌫</kbd> (Delete) instead of <kbd>⌘⌫</kbd>
- Finder: Go back to the previous folder with <kbd>⌫</kbd> (Delete)
- [Finder: Adds many useful actions to the context menu:](#finder-context-menu) copy path, move to, open folder with, AirDrop, folder colors, etc.
- Finder: Auto-adjust column widths to filenames in column view, or do it once with a keyboard shortcut
- Finder: Invert selection (deselects what's currently selected and selects everything that wasn't selected)
- Exclude AirDrop, Mail, and Messages from the system Share menu
  <span class="list-description">These are usually forced to be shown by macOS.</div>
- [Show markup tools by default in screenshot preview](https://github.com/user-attachments/assets/20b0cfe8-d588-4329-9132-9120b32da7ff)
- Auto-open screenshot preview after capturing
- [Mail: Copy message link](#mail-copy-message-link)
- [Notes: Copy note link](#notes-copy-note-link)
- Toggle Finder with a keyboard shortcut <sup>(aka. [visor mode](https://totalfinder.binaryage.com/visor))</sup>
- Show the [menu bar window](https://github.com/user-attachments/assets/1b8e2e12-187a-4d32-8ba3-c13f154de9e0) for the Passwords app with a keyboard shortcut
- Show the [menu bar window](https://github.com/user-attachments/assets/567bbbf5-12a1-45be-8ffa-93712574d4a0) for the Weather app with a keyboard shortcut
- Show the window for the “Now Playing” menu bar item with a keyboard shortcut
- [Change default browser](https://github.com/user-attachments/assets/b58a04da-2bdc-4bd0-bed4-ba62ba456491) (without a prompt)
	- Also available as an [independent app](/default-browser).
- [Make volume key adjustments more precise with quarter-step increments](https://github.com/user-attachments/assets/e994755b-94ca-4e3c-8f70-5d3bffc3aed1)
- Export/import (backup) settings for any apps *([video](https://github.com/user-attachments/assets/82727408-3acb-4c18-91c6-428f1e0ad8c5))*
- Toggle Terminal with a keyboard shortcut
- [Offers to install apps from mounted DMG files](https://github.com/user-attachments/assets/5ecb9b0b-5719-4382-98a0-c3316bd20a6b)
- Show desktop (menu action)
- Quit all apps (menu action and keyboard shortcut)
- Eject all disks (menu action and keyboard shortcut)
- Dim icons of hidden apps in the Dock
- Pick color on screen and copy as Hex color (menu action and keyboard shortcut)
- Toggle mute sound
- Toggle dark mode
- Toggle [Night Shift](https://support.apple.com/en-us/102191)
- Toggle [True Tone](https://support.apple.com/en-us/102147)
- Toggle low power mode
- Toggle grayscale mode[^grayscale]
- Toggle desktop widgets visibility
- Toggle function keys (switch between using F1, F2, etc., as standard function keys or media keys)
	- Only supported for the built-in MacBook keyboard and Magic Keyboard.
- Clear clipboard
- Empty trash keyboard shortcut
- [Clicking a Dock folder reveals it in Finder instead of showing its contents](#dock-folder-click)
- Open system settings directly (usually requires a lot of clicks):
	- Hide My Email
	- Private Relay
- [Show seconds hand in the Clock app's Dock icon](https://github.com/user-attachments/assets/b1d025dc-0465-4d0f-adf8-48bc079ad438)
- [Only show sound menu bar icon when either muted or unmuted](https://github.com/user-attachments/assets/10447e39-f288-406b-a504-6ab7b8fcf261)
- Add [Dock spacers](#dock-spacers)
- Reset [privacy permissions](https://support.apple.com/en-vn/guide/mac-help/mchl211c911f/mac) for any apps
- Flush DNS cache
- Shortcuts actions
- *More planned…*

This is my playground for supercharging macOS. It's just the start. Come along for the ride.

- [**Video review**](https://www.youtube.com/watch?v=hp-WMYZQ75U)
	- [Follow-up](https://www.youtube.com/watch?v=srZH0eTjylU)
- [**Article about the app**](https://todayonmac.com/supercharge/)

[^commandx]: Without this feature, you have to first copy (<kbd>Command+C</kbd>) and then remember to move (<kbd>Option+Command+V</kbd>). The feature works by overriding the normal cut <kbd>⌘X</kbd> keyboard shortcut when Finder is active and executes a copy <kbd>⌘C</kbd> instead. When you then paste <kbd>⌘V</kbd>, it executes the native move <kbd>⌥⌘V</kbd> keyboard shortcut. So really, it's Finder moving the files. This app just makes the keyboard shortcuts more intuitive. If you don't paste, the files just stay in place. This feature also works with the Forklift app.

[^quit]: The <kbd>Q</kbd> key is next to <kbd>W</kbd>, making it easy to accidentally hit <kbd>Command+Q</kbd> (quit) when reaching for <kbd>Command+W</kbd> (close window).

[^grayscale]: Grayscale mode on macOS can be a useful tool for various purposes. It can help reduce eye strain during long work sessions, especially in low-light environments. For designers and developers, it's valuable for checking contrast and readability of user interfaces without the influence of color. Content creators may use it to evaluate the tonal balance of images or videos. Additionally, some users find that grayscale helps minimize distractions and improve focus by reducing the visual appeal of non-work-related apps and websites. While initially an adjustment, many users report increased productivity and a more mindful approach to computer usage when employing grayscale mode periodically.

---

#### Features explained

<br>

<!-- ##### Hyper key {#hyper-key}

Remaps <kbd>Caps Lock</kbd> to function as a Hyper key—a single key that simultaneously activates all standard modifiers (Control + Option + Shift + Command). This enables the creation of highly unique shortcuts that are unlikely to conflict with existing ones, making them both easy to remember and quick to use. -->

##### Dock icon click behavior {#dock-icon-click-behavior}

By default, clicking an app's Dock icon when the app is active does nothing. With Supercharge, you can make it either hide the app or minimize all its windows. This can be particularly useful for quickly clearing your workspace.

You can also choose to unminimize all windows instead of just one when clicking a Dock icon of an app with minimized windows.

##### Clicking green traffic light button fills window instead of entering fullscreen {#green-traffic-light-button-fill}

Makes clicking the green traffic light button fill the window to fit the screen instead of entering fullscreen mode. Hold <kbd>Option</kbd> while clicking for the default fullscreen behavior. Click again to restore the previous window size.

[Screenshot](https://github.com/user-attachments/assets/41dd0f46-05f7-46f2-b9a5-a5ae441da8a9)

##### Clicking yellow traffic light button hides app instead of minimizing window {#yellow-traffic-light-button-hide}

Makes clicking the yellow traffic light button hide the app instead of minimizing the window. Hold <kbd>Option</kbd> while clicking for the default minimize behavior.

##### Finder context menu additions {#finder-context-menu}

Adds the following actions (can be customized) directly in the right-click menu in Finder:

- New Text File
	<span class="list-description">Shown only when right-clicking an empty area in Finder.</span>
- New From Template
	<span class="list-description">Create new files from templates. For example, a Markdown or Excel file. Templates can be organized in subfolders. Shown only when right-clicking an empty area in Finder, not a file. Supports dynamic placeholders in filenames (like `Diary {datetime-fixed}` → `Diary 2025-02-14 15.30`). And you can even have the file automatically open after naming it. [Screenshot.](https://github.com/user-attachments/assets/cb401a0e-2e40-4714-9493-b91563a7b387)</span>
- Image/Video Dimensions
- Copy Path
- Copy Filename
- Copy File URL
	<span class="list-description">Useful for deep links. Clicking such link reveals it in Finder.</span>
- Copy Markdown Link
- Copy Contents
	<span class="list-description">Copies the contents of text files to the clipboard.</span>
- Open Folder With
	<span class="list-description">[Missing apps?](https://sindresorhus.com/supercharge#add-app-open-folder-with)</span>
- Make Symlink
- Move To
- Copy To
- Share
	<span class="list-description">Shows the old-style Share item that is a submenu instead of a separate popover, which is faster to access. You can exclude AirDrop, Messages, and Mail from the menu, which are normally forced to be shown. However, there is no way to hide the existing Share item.</span>
- Open in App
	<span class="list-description">Add menu items like “Open in Visual Studio Code” directly to the Finder context menu. Text editors show up for folders and text files, while other apps only show up for types they support. [Screenshot.](https://github.com/user-attachments/assets/980340bc-a257-475c-9a02-7b98853df9a7)</span>
- Open in Terminal
	<span class="list-description">Shown only when right-clicking a folder or an empty area in Finder. Supports Terminal, iTerm, Ghostty, kitty, WezTerm, Alacritty, and Warp.</span>
- AirDrop
- Run Shortcut
- Update Modified Date
- Folder Color
	<span class="list-description">Change the color of folders. [Screenshot.](https://github.com/user-attachments/assets/0687455b-61d3-4fdd-a863-1e378a3701d5)</span>
- Toggle Hidden Files
	<span class="list-description">Toggle visibility of hidden files.</span>
- Make Executable
	<span class="list-description">Makes files executable, similar to `chmod +x` in the terminal. Useful for shell scripts.</span>
- Invert Selection
	<span class="list-description">Selects the files/folders in Finder that are not selected.</span>
- Delete Immediately
	<span class="list-description">Permanently deletes files/folders without sending them to the Trash.</span>
- Copy Checksum
	<span class="list-description">SHA-1, SHA-256, SHA-384, SHA-512, MD5, CRC32</span>
- Unquarantine
	<span class="list-description">Removes the quarantine flag that macOS adds to downloaded files and apps. This removes [security prompts](https://github.com/user-attachments/assets/adbf3c7e-8fee-4cd9-9a90-3958badfa94e) and restrictions for trusted items.</span>
- Scan QR Code
	<span class="list-description">Scans QR codes in images and copies the content to the clipboard. Only shown when right-clicking image files.</span>

*They appear at the bottom of the context menu. There is no way to change that. [They also won't appear in iCloud, Dropbox, or any other sync folder.](#finder-context-menu-icloud)*

##### Capture and translate text from anywhere on screen {#capture-translate-text}

Select any region of your screen to instantly translate text, even from images or unselectable text.

- [Screenshot](https://github.com/user-attachments/assets/e7c6b336-6b70-4dfe-bba1-ba6ca18907c0)
- [Supported languages](https://www.apple.com/macos/feature-availability/#translate-system-wide-translation) (except Hindi)

##### Scan QR codes and barcodes {#scan-qr-codes}

Select any region of your screen or use an image from your clipboard to instantly scan QR codes and barcodes and copy their content to the clipboard. Supports scanning multiple codes at once.

- [Screenshot](https://github.com/user-attachments/assets/caa5aed9-5db2-460e-bbbb-15fae45a5195)
- [Supported barcodes](https://developer.apple.com/documentation/vision/vnbarcodesymbology#Supported-Symbologies)

##### Copy message link in Mail {#mail-copy-message-link}

When you are in the Mail app, you can [open the Supercharge menu](https://github.com/user-attachments/assets/5cce205b-6743-4a60-958c-074a308ccc68) to copy a direct link to one or more selected messages. You can also set up a keyboard shortcut for this. Copying a message link can be useful if you want to refer to specific emails in other contexts. The link will look like this: `message://%3c66e85e1db33c7_961cfc499cd@lowworker-c6756b946-4rskj.mail%3e`.

##### Copy note link in Notes {#notes-copy-note-link}

When you are in the Notes app, you can [open the Supercharge menu](https://github.com/user-attachments/assets/028c2952-d708-4eda-ad39-613767532eb7) to copy a direct link to one or more selected notes. You can also set up a keyboard shortcut for this. Copying a note link can be useful if you want to refer to specific notes in other contexts, like in a task manager or calendar event. The link will look like this: `applenotes:note/933C49CC-04F4-5F21-A3EE-2CA93AFC88DD`. When clicked, it opens directly in the Notes app.

##### Close and minimize windows and hide and quit apps directly from Mission Control {#mission-control-improvements}

Enhances Mission Control by letting you close windows or quit apps by right-clicking the hovered window and use keyboard shortcuts (⌘W, ⌘Q, ⌘H, ⌘M) on the window you are hovering over. This makes window management more efficient as you don't have to exit Mission Control to perform these actions. [Example](https://github.com/user-attachments/assets/23c71431-4d3b-4913-b484-3a3f0b7b2b07)

##### Dock folder click behavior {#dock-folder-click}

By default, clicking a folder in the Dock shows its contents in a popover. With Supercharge, you can make it directly reveal the folder in Finder instead.

---

You may also like my [Shareful](/shareful), [Menu Bar Spacing](/menu-bar-spacing), and [Pure Paste](/pure-paste) apps.

---

### Trial

Try the fully functional trial [here](https://www.dropbox.com/scl/fi/cxvu72pdirpr6er6a2i13/Supercharge-1.13.0-trial-1740480614.zip?rlkey=o9oai5oun4kseiynvbqekool6&raw=1). The only limitation is a reminder to buy the app every 12 hours, and no automatic updates. All data and settings carry over if you buy it.

You can also [try it on Setapp](https://go.setapp.com/stp181?refAppID=742&utm_medium=vendor_program&utm_content=button) for 7 days for free.

**Requires macOS 15.2**

### Tips

#### Troubleshooting {#troubleshooting}

- Ensure you are on the latest version (click the “Check for Updates” button).
- Restart your computer.
- Try closing any anti-virus app you have running as it may [interfere with the app](/apps/faq#secure-input-problem) (or at least disable any Secure Keyboard Entry type setting it may have). And if you don't have any anti-virus app, try closing down all apps and menu bar items, just to rule out some other app interfering. If it's a work computer, your company may have something installed that prevents the app from working.
- Try clicking “Reset Permissions” in the Supercharge menu.

##### Cut and paste files troubleshooting

Ensure you pressed <kbd>Command+X</kbd> and not <kbd>Command+C</kbd>.

To make sure you used the feature correctly, try this: Select a file in Finder, press <kbd>Command+X</kbd>, change to a different folder, press <kbd>Command+V</kbd>. The file should have been moved to this new folder.

**Note:** You cannot cut, highlight a folder, and then paste. You have to actually go into the folder to paste to it. That's just how Finder works. Same with copy-pasting.

If it's still not working, try this: Select a file in Finder, press <kbd>Command+C</kbd>, change to a different folder, press <kbd>Option+Command+V</kbd>. The file should have been moved to this new folder. If this did not work, the problem is not this app, as those are the keyboard shortcuts it simulates.

As a last resort, try [resetting permissions](/apps/faq#mac-reset-permissions) and restarting your computer.

Also try closing any anti-virus app you have running as it may [interfere with the app](/apps/faq#secure-input-problem) (or at least disable any Secure Keyboard Entry type setting it may have). And if you don't have any anti-virus app, try closing down all apps and menu bar items, just to rule out some other app interfering. If it's a work computer, your company may have something installed that prevents the app from working.

#### Launch browser

If you have enabled showing browsers in the menu, you can hold the Option key and click a browser in the menu to open it, rather than setting it as the default.

#### Tricks

Some things you can already do that you may not know about:

- Hide an app by <kbd>Option</kbd>-clicking on the app's Dock icon.
- Show Control Center by pressing <kbd>Fn+C</kbd>.
- Toggle a specific VPN using a keyboard shortcut with Shortcuts. Add [this shortcut](https://www.icloud.com/shortcuts/a0c3171fe98a4379b8197299a84b060e) and set the VPN parameter and a keyboard shortcut.
- [Make Finder remember its size and position.](https://apple.stackexchange.com/a/171274/2363)
- [Prevent opening apps when clicking links that are Universal Links.](https://lapcatsoftware.com/articles/universal-links2.html)
- [Change the keyboard shortcut for menu item actions a specific app.](https://support.apple.com/guide/mac-help/create-keyboard-shortcuts-for-apps-mchlp2271/mac)
- [Change the keyboard shortcut for menu item actions in all apps.](https://apple.stackexchange.com/a/125628/2363)
- Set Finder's default view options: Open a folder, press <kbd>Command+J</kbd>, adjust settings, and click “Use as Defaults”. To reset a folder's custom settings, press <kbd>Command+J</kbd>, hold <kbd>Option</kbd>, and click “Restore to Defaults”.
- [Show “Dimensions” column in Finder.](https://apple.stackexchange.com/questions/18728/how-can-i-show-the-dimension-column-in-finder)

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Supercharge&referrer=Website-FAQ)

Some things are not possible though:

- [Removing the Trash icon in the Dock.](https://apple.stackexchange.com/a/454812/2363)
- Removing the Finder icon in the Dock.
- Disabling Stage Manager animations.
- Fill the entire row with the file's tag color in Finder.
- Naming spaces. Check out [this app](https://github.com/Jaysce/Spaceman) for showing space names in the menu bar.
- Removing or changing Finder context menu items. It can only add items.

Some things are not planned:

- Keep awake
	- Check out [Lungo](/lungo).
- Memory cleaner
	- Apps like these are a scam. macOS handles memory efficiently. There is no need for an app like this.

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some other menu bar apps to free up space. If this does not solve the issue, try quitting Bartender/Ice if you have it installed.

You may also have disabled the “Show menu bar icon” setting, which hides the menu bar icon. Launch the app again to show the main window.

##### The tweaks like Finder cut & paste no longer works

This usually happens when an app [blocks keyboard input reading](/apps/faq#secure-input-problem).

##### The tweaks like Finder cut & paste no longer works

This is usually caused by an app using Secure Input - a security feature that blocks other apps from reading keystrokes. Common culprits are password managers like Bitwarden and 1Password, even when they're not in focus. Try quitting these apps. And if it doesn't help, try quitting all apps and menu bar apps. [Learn more >](https://espanso.org/docs/troubleshooting/secure-input/)

#### I can already do this with the command-line, BetterTouchTool, Keyboard Maestro, etc.

Supercharge offers a simpler, more user-friendly approach. It's designed for users who want quick access to useful features without the complexity of scripting or configuring advanced tools. Supercharge provides a curated set of enhancements that work right out of the box, saving you time and effort in setup and maintenance. If you prefer more granular control and don't mind the setup process, those other tools might be a better fit for you.

#### Why <kbd>Command+X</kbd>? I can already move files with <kbd>Command+C</kbd> and <kbd>Option+Command+V</kbd>

- It's more logical to cut & paste than copy & move.
- Consistency and muscle memory benefits if you also use Linux or Window.

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

#### Why don’t the Finder context menu items show up in iCloud and Dropbox folders? {#finder-context-menu-icloud}

Finder Sync extensions, which power these context menu items, are intended to add sync functionality for third-party services in Finder. Since iCloud and Dropbox folders have their own built-in sync, macOS doesn't allow the Supercharge extension in these locations to prevent conflicts.

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

If you know the app supports opening folders but it doesn't show up, it may be that the app has not properly declared support for it. Contact the app developer about adding the above. You could also [contact me](https://sindresorhus.com/feedback?product=Supercharge), and I can manually add the app.

#### Can you add support keyboard shortcuts to change default browser?

Maybe. For now, you can make a shortcut in the Shortcuts app, give it a keyboard shortcut, and use the “Set Default Browser” Shortcuts action that comes with Supercharge.

#### Can you add more features to changing the default browser, like rules?

Features like rules require the app to intercept and forward URLs by acting as the default browser. This is out of scope for this app. Check out my [Velja](/velja) app for that.

#### Why do some tweaks have a list of pre-defined keyboard shortcuts instead of a shortcut recorder?

The pre-defined shortcuts are intentionally curated to help users quickly select sensible shortcuts that won't conflict with built-in app shortcuts. This approach reduces potential support issues. Missing a useful key combination? Let me know, and I will consider adding it.

#### Can the app support clearing clipboard formatting? {#pure-paste}

Check out my [Pure Paste](/pure-paste) app for this. I think it makes more sense as a separate app.

#### How can I run the actions from Raycast or Alfred?

Most of the actions are exposed as Shortcuts actions, so create a shortcut with the action and run it from Raycast or Alfred.

#### Can I trigger the actions using a custom URL scheme?

It's something I plan to support at some point, but for now, you can use Shortcuts, as mentioned above.

#### Can the app support hiding menu bar items?

No, that's out of scope for this app. I recommend [Ice](https://icemenubar.app).

#### Can you add Alt-Tab functionality like Windows?

No, this would be very complex to implement well and there is already an excellent free app called [AltTab](https://alt-tab-macos.netlify.app) that does exactly this.

#### Why is this not in the App Store?

Much of the functionality would not be possible in the App Store because of [sandboxing](/apps/faq#macos-sandbox).

#### [More FAQs…](/apps/faq)

<!-- ### Older Versions

- [] for macOS 15

These are free for everyone but they will not run on newer macOS versions.
 -->

<!-- TODO: When supercharge 1.13.0 is out.

### Scripting

#### Events

The [distributed notification](/apps/faq#distributed-notifications) `com.sindresorhus.defaultBrowserDidChange` is emitted when the default browser is changed from the app or the Shortcuts action.
 -->
