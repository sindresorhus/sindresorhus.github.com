---
title: Folder Peek
subtitle: Put folders in your menu bar
date: 2022-04-05
platforms:
  - macOS
app_store_app_id: 1615988943
mac_app_store_url: https://apps.apple.com/app/id1615988943
---

<br>

<h3 id="guide">Guide</h3>

Folder Peek lets you put one or more folders in the menu bar.

Make sure you read the below tips and FAQ.

<br>

<h3 id="tips">Tips</h3>

- Click a file or folder in the menu to open it.
- Click a file or folder while pressing the <kbd>Option</kbd> key to show it in Finder.
- Click the folder title ([the top menu item](https://dsc.cloud/sindresorhus/Screen-Shot-2022-04-22-at-00.49.49-1650563404)) to open the folder.
- You can drag and drop the file thumbnail in the file submenu.
- Just start typing when the menu is open to search for a file or folder.
- Press the <kbd>Option</kbd> when viewing the file details to copy path or image/video dimensions.
- You can use the Shortcuts support to show/hide certain folders depending on what project you are working on.
- If you have the menu bar item folders next to each other and you have one folder open, you can press <kbd>Control+Tab</kbd> or <kbd>Shift+Control+Tab</kbd> to switch between them.
- Press the <kbd>Option</kbd> key while the menu is open to show the `…` menu item at the top if it normally is as the bottom.
- Right-click or Option-click the menu bar item to open the folder.
- Press the <kbd>Option</kbd> key while viewing a subfolder to reveal more actions. For example, sort order settings.

<br>

<h3 id="faq">Frequently Asked Questions</h3>

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback/?product=Folder%20Peek&referrer=Website-FAQ)

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some menu bar apps to free up space. If this does not solve it, try quitting Bartender if you have it installed.

#### Some folders are suddenly missing from the menu bar

When the menu bar has no space left, macOS hides overflowing items. Try quitting some menu bar apps.

#### The menu bar icon is not perfectly vertically centered?

This is a macOS bug on non-Retina displays. There is unfortunately not much I can do about this.

<a id="show-specific-items"></a>
#### How can I show specific files and folders from various places?

You can create a folder that contains aliases to the files and folders you want to be included in the menu.

Create a folder to put aliases in and add that folder to the app. Make aliases for the files and folders you want in the menu and move the aliases into the folder you just made.

#### What is an alias?

An [alias](https://support.apple.com/guide/mac-help/create-and-remove-aliases-on-mac-mchlp1046/mac) is a shortcut to an app, file, or folder that you can keep anywhere on your Mac. Right-click an item in Finder and select “Make Alias” to make one.

<a id="app-launcher"></a>
#### How can I use this as an app launcher?

Just add the “Applications” folder to the app. If you want to show only specific apps, follow the first FAQ.

<a id="show-multiple-folders"></a>
#### How can I show multiple folders at the top level in a single menu?

See the “Can I show specific files and folders from various places?” answer.

<a id="faq-shortcuts"></a>
#### How can I show certain folders in the menu bar depending on what I'm working on?

You can create a shortcut in the Shortcuts app using the “Set Folder Visibility” action where you show only certain folders. For example, you could make a shortcut named “Start Work” which hides your personal folders in the menu bar and shows folders for your work projects. You could even use the [Shortery app](https://apps.apple.com/us/app/shortery/id1594183810) to trigger this shortcut at a certain time or any other condition.

#### How can I drag & drop a file from the menu?

You can drag & drop the file preview/thumbnail in the file submenu.

It would have been nicer if you could drag & drop directly from the top-level list of files and folders, but this is not possible because of limitations with the system menu.

<a href="copy-file-path"></a>
#### How can I copy the file path?

Press the <kbd>Option</kbd> key while viewing a file to reveal a “Copy Path” button.

#### How can I copy the image/video dimensions?

Press the <kbd>Option</kbd> key while viewing an image or video to reveal a “Copy Dimensions” button.

#### How can I change the sort order for a subfolder?

Press the <kbd>Option</kbd> key while viewing a subfolder to reveal more actions, including a sort order setting.

#### How can I have a menu bar folder with my most recent screenshots?

Make a folder to hold the screenshots and add it to the app. Open the Screenshot app, click “Options”, then “Other Location”, and choose the folder you just made. In Folder Peek, open the folder config, and change the sort order to “Date Created” and set “Max Items” to something like 20.

You may also want to [disable the screenshot preview](https://osxdaily.com/2019/08/02/disable-screenshot-thumbnail-preview-mac/) so the screenshot shows up in the screenshot folder right away.

#### Can I navigate to a folder multiple levels deep and then drop a file into it?

No, that is unfortunately not possible. Folder Peek is built as a system menu, and a menu cannot be kept open if it's not focused. Instead, first navigate to the nested folder, click to open it in Finder, and then drag & drop the file into the Finder window.

<a id="folder-open-with"></a>
#### The app I want does not show up in the “Open With” menu for a folder

Apps define the types they support and Folder Peek just fetches a list of apps that support opening folders. However, many apps forget to declare support for folders even though they can open them. I would encourage reporting this to the developers of the app you want to open ([example report](https://github.com/microsoft/vscode/issues/146977)). In the meantime, I'm happy to manually add the app to the list if you contact me, but you are expected to also have reported the issue to the app's developers.

<a id="finder-alternative"></a>
#### How can I make folders open in a different app than Finder by default?

Folder Peek opens the default app that handles folders, which is Finder by default.

- **Path Finder:** Enable the “Set as the default file browser” preference in Path Finder.
- **ForkLift:** [Follow this guide.](https://binarynights.com/manual#fileviewer)

For other apps, follow [this guide](https://binarynights.com/manual#fileviewer), but replace `com.binarynights.ForkLift-3` with the bundle identifier of the app you want.

<a id="dock-folders"></a>
#### How is this better than having [folders in the Dock](https://support.apple.com/guide/mac-help/use-folders-in-the-dock-mchl231f08fb/mac)?

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

<a id="xmenu"></a>
#### How is this better than [XMenu](https://apps.apple.com/us/app/xmenu/id419332741)?

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

#### Why is this free without ads?

I just enjoy making Mac apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1615988943) and click “Version History”.

#### Can you localize the app into my language?

I don't have any immediate plans to localize the app.
