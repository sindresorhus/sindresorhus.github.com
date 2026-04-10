---
title: Folder Peek
subtitle: Put folders in your menu bar
pubDate: 2022-04-05
platforms:
  - macOS
isPaid: true
isMenuBarApp: true
appStoreId: 1615988943
hasSentry: true
olderMacOSVersions:
  - '12'
  - '13'
  - '14'
  - '15'
---

<br>

### Features

- Add multiple folders to the menu bar
- Each folder can be individually customized
- File preview
- View and copy image & video dimensions
- Drag & drop files directly from the menu
- Global keyboard shortcut to show/hide each folder menu (optionally opens at cursor position)
- Open a file or folder in a specific app
- Follows aliases and symlinks
- Shortcuts support

### Guide {#guide}

Folder Peek lets you put one or more folders in the menu bar.

Make sure you read the below tips and FAQ.

## Tips

- Click a file or folder in the menu to open it. Folders open in Finder.
- Click a file while pressing the <kbd>Option</kbd> key to show it in Finder.
- Click the folder title ([the top menu item](https://github.com/sindresorhus/meta/assets/170270/79c4e9c7-8abf-49da-b8fb-3a942017442e)) to open the folder.
- You can drag files directly from the menu. You can also drag the file thumbnail in the file submenu. Press the <kbd>Option</kbd> key while dragging to copy instead of moving.
- Press the <kbd>Option</kbd> key when viewing the file details to copy the path or image/video dimensions.
- You can use the Shortcuts support to show/hide certain folders depending on what project you are working on.
- If you have the menu bar item folders next to each other and you have one folder open, you can press <kbd>Control+Tab</kbd> or <kbd>Shift+Control+Tab</kbd> to switch between them.
- In Settings, you can configure the keyboard shortcut to open the menu at the cursor position instead of at the menu bar icon.
- Press the <kbd>Option</kbd> key while the menu is open to show the `…` menu item at the top if it normally is at the bottom.
- Right-click or <kbd>Option</kbd>-click the menu bar item to open the folder.
- Press the <kbd>Shift</kbd> key while viewing a subfolder to reveal more actions. For example, sort order settings.
- Search: Just start typing when the menu is open to find a file or folder in the menu. This is just the standard menu behavior where you can type to highlight a certain menu item. It's not a full-blown search.

### Links

You can use Folder Peek to access links too. Drag and drop the URL from the Safari address bar into a folder. You will end up with a file with a `.webloc` extension. When you click that file in Folder Peek, it will open in your browser.

### Desktop folder

You could add the “Desktop” folder to Folder Peek and then [hide the desktop icons](https://beebom.com/how-hide-desktop-icons-mac/) for a cleaner look.

## Frequently Asked Questions {#faq}

#### The app does not show up in the menu bar

[Try this](/apps/faq#app-not-showing-in-menu-bar)

#### Why is the app suddenly paid? It used to be free.

While I love making free apps that are available to anyone, the high volume of support requests became unsustainable. After providing the app for free for 4 years with more than 50K downloads, I made the decision to make it paid. This isn't about revenue - it's about managing my time more effectively by reducing the support burden to a sustainable level.

#### Some folders are suddenly missing from the menu bar

When the menu bar has no space left, macOS hides overflowing items. Try quitting some menu bar apps.

#### The menu bar icon is not perfectly vertically centered

This is a macOS bug on non-Retina displays. There is unfortunately not much I can do about this.

#### How can I show specific files and folders from various places? {#show-specific-items}

You can create a folder that contains aliases to the files and folders you want to be included in the menu.

Create a folder to put aliases in and add that folder to the app. Make aliases for the files and folders you want in the menu and move the aliases into the folder you just made.

#### What is an alias?

An [alias](https://support.apple.com/guide/mac-help/create-and-remove-aliases-on-mac-mchlp1046/mac) is a shortcut to an app, file, or folder that you can keep anywhere on your Mac. Right-click an item in Finder and select “Make Alias” to make one.

#### How can I use this as an app launcher? {#app-launcher}

Just add the “Applications” folder to the app if you want to show all your apps.

If you want to show only certain apps, create a normal folder anywhere, for example on your Desktop. Then open the “Applications” folder in Finder, right-click each app you want, choose “Make Alias”, and move those aliases into the new folder. Finally, add that new folder to Folder Peek.

#### How can I show multiple folders at the top level in a single menu? {#show-multiple-folders}

See the “Can I show specific files and folders from various places?” answer.

#### How can I show certain folders in the menu bar depending on what I'm working on? {#faq-shortcuts}

You can create a shortcut in the Shortcuts app using the “Set Folder Visibility” action where you show only certain folders. For example, you could make a shortcut named “Start Work” which hides your personal folders in the menu bar and shows folders for your work projects. On macOS 26, you can use Shortcuts automations to trigger this shortcut at a certain time or any other condition. On older macOS versions, you can use the [Shortery app](https://apps.apple.com/us/app/shortery/id1594183810) for this.

#### How can I drag & drop a file from the menu?

You can drag & drop files directly from the menu. Press the <kbd>Option</kbd> key while dragging to copy instead of moving.

#### How can I copy the file path? {#copy-file-path}

Press the <kbd>Option</kbd> key while viewing a file to reveal a “Copy Path” button.

#### How can I copy the image/video dimensions?

Press the <kbd>Option</kbd> key while viewing an image or video to reveal a “Copy Dimensions” button.

#### How can I change the sort order for a subfolder?

Press the <kbd>Shift</kbd> key while viewing a subfolder to reveal more actions, including a sort order setting.

#### How can I have a menu bar folder with my most recent screenshots?

Make a folder to hold the screenshots and add the folder to the app. Open the Screenshot app, click “Options”, then “Other Location”, and choose the folder you just made. In Folder Peek, open the folder config, change the sort order to “Date Created”, and set “Max Items” to something like 20.

You may also want to [disable the screenshot preview](https://osxdaily.com/2019/08/02/disable-screenshot-thumbnail-preview-mac/) so the screenshot shows up in the screenshot folder right away.

#### How can I add a [Smart Folder](https://support.apple.com/guide/mac-help/create-or-change-a-smart-folder-on-mac-mchlp2804/mac)? {#smart-folder}

A Smart Folder is a special feature in Finder that allows you to create a virtual folder based on specific search criteria. The files within the Smart Folder are not physically stored in one location, but rather are located in different areas of your computer. Unfortunately, it is not possible to add a Smart Folder to Folder Peek as the functionality cannot be replicated.

#### How do I remove a folder from Folder Peek?

- **Individual menu bar items mode:** Click the menu bar item, go to the first menu item (which is named after your folder), go to its submenu, and then select “Remove Folder”.
- **Single menu bar item mode:** In Settings, right-click the folder to reveal the “Remove” option.

#### Can I navigate to a folder multiple levels deep and then drop a file into it?

No, that is unfortunately not possible. Folder Peek is built as a system menu, and a menu cannot be kept open if it's not focused. Instead, first, navigate to the nested folder, click to open it in Finder, and then drag & drop the file into the Finder window.

#### Can it auto-mount a network volume when accessing it? {#network-volume}

No, this is not possible because of [sandboxing](/apps/faq#macos-sandbox). To use a network volume in the app, you need to either mount it manually first or use a tool like [AutoMounter](https://pixeleyes.co.nz/automounter/) to keep it always mounted.

#### Can it support adding a tag instead of a folder?

No. This is not planned.

#### The app I want does not show up in the “Open With” menu for a folder {#folder-open-with}

Apps define the types they support and Folder Peek just fetches a list of apps that support opening folders. However, many apps forget to declare support for folders even though they can open them. I would encourage reporting this to the developers of the app you want to open ([example report](https://github.com/microsoft/vscode/issues/146977)). In the meantime, I'm happy to manually add the app to the list if you contact me, but you are expected to also have reported the issue to the app's developers.

The app developer will need to add `public.folder` to `LSItemContentTypes` in their app's Info.plist:

```xml
<key>LSItemContentTypes</key>
<array>
    <string>public.folder</string>
</array>
```

#### How can I make folders open in a different app than Finder by default? {#finder-alternative}

Folder Peek opens the default app that handles folders, which is Finder by default.

- **Path Finder:** Enable the “Set as the default file browser” setting in Path Finder.
- **ForkLift:** [Follow this guide.](https://binarynights.com/manual#fileviewer)

For other apps, follow [this guide](https://binarynights.com/manual#fileviewer), but replace `com.binarynights.ForkLift-3` with the bundle identifier of the app you want.

#### How can I hide the `…` menu item?

There is a hidden setting for it. Run the following command in the Terminal app:

```sh
defaults write com.sindresorhus.Folder-Peek showFolderMoreMenu -bool false
```

You can show the `…` menu item again by pressing the <kbd>Option</kbd> key.

#### How is this better than having [folders in the Dock](https://support.apple.com/guide/mac-help/use-folders-in-the-dock-mchl231f08fb/mac)? {#dock-folders}

- Slightly faster access, since most users have the Dock automatically hidden and the menu bar always shown.
- File preview.
- Copy and share a file.
- View and copy image/video dimensions.
- Open a file or folder in a specific app.
- Keep folders on top.
- Sort by when the file was last accessed.
- Show the menu using a custom global keyboard shortcut.
- Limit the number of items shown in the menu.
- Shortcuts support.

#### How is this better than [XMenu](https://apps.apple.com/us/app/xmenu/id419332741)? {#xmenu}

- You can choose any folder and as many as you want, not just a few predefined ones and a single custom folder.
- Each folder can be individually customized.
- Sandboxed app (more secure).
- Custom menu bar icon.
- File preview.
- Copy, share, and drag & drop a file.
- View and copy image/video dimensions.
- Open a file or folder in a specific app.
- Sort files by date created, date modified, date accessed, date added, and kind.
- Show the menu using a custom global keyboard shortcut.
- Limit the number of items shown in the menu.
- Shortcuts support.

#### Can I add shortcuts or scripts to the menu? {#short-run}

The app is for folders only. However, I have an app for exactly this: [Short Run](/short-run), which lets you run shortcuts from the menu bar.

#### How can I export, import, sync, or back up the settings?

[See this guide.](https://github.com/sindresorhus/guides/blob/main/backup-app-settings.md)

#### Can you localize the app into my language?

I don't plan to localize the app.

## Older Versions

- [1.12.0](https://www.dropbox.com/scl/fi/hlyb11lf2m65st8daptme/Folder-Peek-1.12.0-macOS-15-1775931438.zip?rlkey=7bykzpnc4iik0izgibhxx1sxo&raw=1) for macOS 15
- [1.11.5](https://github.com/user-attachments/files/18925258/Folder.Peek.1.11.5.-.macOS.14.zip) for macOS 14
- [1.9.2](https://github.com/sindresorhus/meta/files/13980050/Folder.Peek.1.9.2.-.macOS.13.zip) for macOS 13
- [1.6.1](https://github.com/sindresorhus/meta/files/10901140/Folder.Peek.1.6.1.-.macOS.12.zip) for macOS 12

These are free for everyone but they will not run on newer macOS versions.
