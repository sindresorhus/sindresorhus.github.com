---
title: Plain Text Editor
subtitle: Simple distraction-free notepad
pubDate: 2022-10-25
platforms:
  - macOS
appStoreId: 1572202501
olderMacOSVersions:
  - '13'
---

Simple text editor without any rich text nonsense. The simplicity is a feature.

It won't handle your 1 million line log file, but it is a nice way to write down some ideas.

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Plain%20Text%20Editor&referrer=Website-FAQ)

#### How is it better than TextEdit?

- Editor padding
- Optimal line spacing and length
- Word count
- Hide the title bar
- Translucent background
- Window can stay on top
- Force dark/light mode
- Brain dump mode

#### Spellchecking does not work

This is a macOS bug. You can see the same problem in the built-in TextEdit app too.

#### Can you add Markdown syntax highlighting?

I don't plan to add that as I want to keep the app simple. I do plan to make a proper Markdown editor at some point, but that's not this app.

#### Can you add a typewriter mode (centered text)?

I don't plan to add that.

#### The text sometimes jumps when I write fast

This is a macOS bug. There is unfortunately nothing I can do about it.

#### Does the app support tabs? {#tabs}

Yes. Click “View › Show Tab Bar” in the menu bar and then click the plus button in the window.

You can also press <kbd>Command</kbd> + <kbd>N</kbd> if you have [tabs enabled for document apps](https://support.apple.com/en-gb/guide/mac-help/mchla4695cce/mac).

#### How can I make the app preserve open documents when I quit?

This is already how it works. Actually, it's how all document-based apps on macOS work. Make sure you don't have “System Settings › Desktop & Dock › Close windows when quitting an application” enabled.

#### I have enabled the translucent setting, why is the title bar not translucent?

Making the title bar translucent is not supported by macOS. I'm hoping to find a workaround in the future.

#### How does “brain dump mode” help with creativity?

It helps you focus on the actual writing, instead of getting distracted with editing and nitpicking. [Learn more.](https://writingcooperative.com/how-the-brain-dump-method-can-boost-your-writing-output-881089bb897a)

#### When I save a file using the popover in the title bar, it always appends `.txt` when I choose a different file extension

This is a macOS bug. Instead, save the file from the “File” menu or by pressing <kbd>Command</kbd> + <kbd>S</kbd>.

#### How can I toggle “Stay on Top” with a keyboard shortcut?

The keyboard shortcut is listed in the “Window” menu in the menu bar.

#### Can I open a text file directly from the command-line?

Make a [shell alias](https://shapeshed.com/unix-alias/):

```sh
alias pte="open -a 'Plain Text Editor'"
```

Usage:

```sh
pte unicorn.txt
```

#### Can you add a text color setting?

I don't plan to add that. It's not essential and I'm trying to keep the app simple.

#### The text flickers a little bit when it wraps on a new line

This is unfortunately a macOS bug and out of my control.

#### Why is there no way to print?

The app is made using Apple's latest technologies (SwiftUI) and they have not added print support there yet. If you need to print, open the document in TextEdit instead.

#### Why is it suddenly showing a scrollbar?

You most likely have an external mouse connected. This is simply how macOS works. You can see the behavior in other text editing apps too. The behavior is completely out of my control.

#### The “Check Spelling While Typing” setting in the context menu does not work

This is unfortunately a macOS bug and not something I can fix.

*If you work at Apple → [FB13607434](https://github.com/feedback-assistant/reports/issues/467)*

#### How can I export, import, sync, or back up the settings?

[See this guide.](https://github.com/sindresorhus/guides/blob/main/backup-app-settings.md)

#### Why is this free without ads?

I just enjoy making Mac apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1572202501) and click “Version History”.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### [More FAQs…](/apps/faq)

<br>

### Older Versions

- [1.3.2](https://github.com/sindresorhus/meta/files/14232390/Plain.Text.Editor.1.3.2.-.macOS.13.zip) for macOS 13+

<br>

### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/o4c1yceor1i75blq21k6z/Plain-Text-Editor-1.4.0-1707655107.zip?rlkey=sp7x6srayuld4gi8cuouevoef&raw=1) *(1.4.0)*

*Requires macOS 14 or later*
