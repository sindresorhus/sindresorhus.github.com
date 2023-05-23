---
title: Plain Text Editor
subtitle: Simple distraction-free notepad
pubDate: 2022-10-25
platforms:
  - macOS
appStoreId: 1572202501
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

The app is made using Apple's latest technologies (SwitUI) and they have not added print support there yet.

#### How can I export, import, sync, or back up the settings?

[See this guide.](https://github.com/sindresorhus/guides/blob/main/backup-app-settings.md)

#### Why is this free without ads?

I just enjoy making Mac apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1572202501) and click “Version History”.

#### Can you localize the app into my language?

I don't have any immediate plans to localize the app.

<br>

### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://dsc.cloud/sindresorhus/Plain-Text-Editor-1.2.1-1668625106) *(1.2.1)*

*Requires macOS 13 or later*
