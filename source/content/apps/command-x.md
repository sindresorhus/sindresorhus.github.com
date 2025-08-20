---
title: Command X
subtitle: Cut and paste files in Finder
pubDate: 2023-04-30
platforms:
  - macOS
isPaid: true
appStoreId: 6448461551
hasSentry: true
olderMacOSVersions:
  - '13'
  - '14'
feedbackNote: |
  [The app randomly disappears/quits](/apps/faq#randomly-quits)
---

Cut and paste files and folders in Finder using Command+X and Command+V. Without this app, you have to first copy (Command+C) and then remember to move (Option+Command+V).

[Review by Softpedia](https://mac.softpedia.com/get/System-Utilities/Command-X.shtml)

Known limitation: You cannot cut the name of a file when editing a filename in Finder or cut when using the search field. [Learn more.](#textfield-limitation)

---

You may also like my [Supercharge](/supercharge) app.

---

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](/feedback?product=Command%20X&referrer=Website-FAQ)

#### Why? I can already use <kbd>Option+Command+V</kbd>

- It's more logical to cut & paste than copy & move.
- Consistency and muscle memory benefits if you also use Linux or Window.

#### The app does not show up in the menu bar

[Try this](/apps/faq#app-not-showing-in-menu-bar)

#### The app does not work {#not-working}

First try relaunching the app.

Then, make sure you pressed <kbd>Command+X</kbd> and not <kbd>Command+C</kbd>.

To make sure you used the app correctly. Try this: Select a file in Finder, press <kbd>Command+X</kbd>, change to a different folder, press <kbd>Command+V</kbd>. The file should have been moved to this new folder.

**Note:** You cannot cut, highlight a folder, and then paste. You have to actually go into the folder to paste to it. That's just how Finder works. Same with copy-pasting.

**It could also be that certain apps (password managers and browsers) are [interfering with the app](/apps/faq#secure-input-problem).**

If still not working, try closing down all apps and menu bar items, just to rule out some other app interfering.

Then try toggling the setting “Use more reliable way of handling Command+X”, and try the above steps again. If it works then, please report it to me.

If it's still not working, try this: Select a file in Finder, press <kbd>Command+C</kbd>, change to a different folder, press <kbd>Option+Command+V</kbd>. The file should have been moved to this new folder. If this did not work, the problem is not this app, as those are the keyboard shortcuts it simulates.

If it's a work computer, your company may have something installed that prevents the app from working.

The last thing you could try is to reset the permissions. Either use [App Buddy](/app-buddy), or quit the app, and run this in the Terminal app:

```sh
tccutil reset All com.sindresorhus.Command-X
```

To help me figure out the issue, make sure the “Use more reliable way of handling Command+X” setting is enabled, press <kbd>Command+X</kbd> and <kbd>Command+V</kbd> in Finder, click the “Copy Debug Info” button in the Command X menu bar menu, and then [send the debug info to me](/feedback?product=Command%20X&referrer=Website-FAQ), including a short explanation of what didn't work.

#### How does the app work?

The app works by overriding the normal cut <kbd>⌘X</kbd> keyboard shortcut when Finder is active and executes a copy <kbd>⌘C</kbd> instead. When you then paste <kbd>⌘V</kbd>, it executes the native move <kbd>⌥⌘V</kbd> keyboard shortcut. So really, it's Finder moving the files. This app just makes the keyboard shortcuts more intuitive.

#### Is there any risk of data loss if I forget to paste?

No. The files are not touched until you paste. If you don't paste, the files just stay in place.

#### Can I move files by clicking the “Paste” menu item?

No, you can only use the keyboard shortcuts. The app works by overriding the original keyboard shortcuts. There is no way to override the Finder menu items.

#### Can it make the cut files in Finder have less opacity?

This is not possible. The app works by overriding some key combinations. It doesn't and cannot modify Finder in any way.

#### It does not work when I try to paste directly to an expanded subfolder shown in its parent folder

This is a Finder bug. You can reproduce it even without Command X by selecting the file to move, pressing <kbd>Command+C</kbd>, selecting the destination folder, and then pressing <kbd>Option+Command+V</kbd>.

#### It does not work when I try to paste into a folder in column view where the parent is a tag

Same as the above.

#### I am not able to cut text when editing a filename in Finder {#textfield-limitation}

This is a known issue that is unfortunately not fixable. The app works by overriding the normal cut keyboard shortcut when Finder is active, which also affects cutting text in a filename. There is no way to differentiate between cutting a file and cutting text in a filename in Finder. The main reason this is not possible is because of restrictions ([sandboxing](/apps/faq#macos-sandbox)) imposed on apps on the App Store. My [Supercharge](/supercharge) app has the Command X feature without this rename limitation because it's not on the App Store.

#### I am not able to cut text in the search field in Finder

Same as the above.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### [More FAQs…](/apps/faq)

## Older Versions

- [1.4.7](https://github.com/user-attachments/files/19031153/Command.X.1.4.7.-.macOS.14.zip) for macOS 14
- [1.3.1](https://github.com/sindresorhus/meta/files/13987707/Command.X.1.3.1.-.macOS.13.zip) for macOS 13

These are free for everyone but they will not run on newer macOS versions.
