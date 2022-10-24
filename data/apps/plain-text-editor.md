---
title: Plain Text Editor
subtitle: Simple distraction-free notepad
date: 2022-10-25
platforms:
  - macOS
appStoreId: 1572202501
---

Simple text editor without any rich text nonsense. The simplicity is a feature.

It won't handle your 1 million line log file, but it is a nice way to write down some ideas.

*Requires macOS 13 or later*

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Plain%20Text%20Editor&referrer=Website-FAQ)

#### How is it better than TextEdit?

- Editor padding
- Optimal line spacing and length
- Word count
- Hide the title bar
- Vibrant background
- Window can stay on top
- Force dark/light mode
- Brain dump mode

#### Can you add Markdown syntax highlighting?

I don't plan to add that as I want to keep the app simple. I do plan to make a proper Markdown editor at some point, but that's not this app.

#### Can you add a typewriter mode (centered text)?

I don't plan to add that.

#### When I save a file using the popover in the title bar, it always appends `.txt` when I choose a different file extension

This is a macOS bug. Instead, save the file from the “File” menu or by pressing <kbd>Command</kbd> + <kbd>S</kbd>.

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

#### How can I export, import, sync, or backup the settings?

[See this guide.](https://github.com/sindresorhus/guides/blob/main/backup-app-settings.md)

#### Why is this free without ads?

I just enjoy making Mac apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1572202501) and click “Version History”.

#### Can you localize the app into my language?

I don't have any immediate plans to localize the app.

<br>

### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive updates.

[Download](https://dsc.cloud/sindresorhus/Plain-Text-Editor-1.2.1-1668625106) *(1.2.1)*

*Requires macOS 13 or later*
