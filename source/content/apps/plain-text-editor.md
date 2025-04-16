---
title: Plain Text Editor
subtitle: Simple distraction-free notepad
pubDate: 2022-10-25
platforms:
  - macOS
  - iOS
  - visionOS
isPaid: true
appStoreId: 1572202501
olderMacOSVersions:
  - '13'
  - '14'
---

Simple text editor without any rich text nonsense. The simplicity is a feature.

It won't handle your 1 million line log file, but it is a nice way to write down some ideas.

It's an [Universal Purchase](/apps/faq#universal-purchase).

*It only handles UTF-8 text files (meaning no UTF-16).*

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Plain%20Text%20Editor&referrer=Website-FAQ)

#### How is the macOS version better than TextEdit?

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

#### Does the app support window tabs on macOS? {#tabs}

Yes. Click “View › Show Tab Bar” in the menu bar and then click the plus button in the window.

You can also press <kbd>Command</kbd> + <kbd>N</kbd> if you have [tabs enabled for document apps](https://support.apple.com/guide/mac-help/mchla4695cce/mac).

#### Can I keep it in the menu bar?

No, that's not supported. However, you may be interested in my [Scratchpad](/scratchpad) app.

#### What's the difference between Plain Text Editor and [Scratchpad](/scratchpad)?

[Learn more](/scratchpad#plain-text-editor-comparison)

#### How can I make the app preserve open documents when I quit on macOS?

This is already how it works. Actually, it's how all document-based apps on macOS work. Make sure you don't have “System Settings › Desktop & Dock › Close windows when quitting an application” enabled.

#### How can I make the app not open previously opened documents when I launch the app?

Disable the setting mentioned above.

#### I have enabled the translucent setting on the macOS app, why is the title bar not translucent?

Making the title bar translucent is not supported by macOS. I'm hoping to find a workaround in the future.

#### How does “brain dump mode” help with creativity?

It helps you focus on the actual writing, instead of getting distracted with editing and nitpicking. [Learn more.](https://writingcooperative.com/how-the-brain-dump-method-can-boost-your-writing-output-881089bb897a)

#### When I save a file using the popover in the title bar on macOS, it always appends `.txt` when I choose a different file extension

This is a macOS bug. Instead, save the file from the “File” menu or by pressing <kbd>Command</kbd> + <kbd>S</kbd>.

#### How can I toggle “Stay on Top” with a keyboard shortcut on macOS?

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

#### The window size and position is not preserved

For document-based apps, which this app is, window size and position are stored per document. macOS is in charge of persisting window size and position for apps, so this is not something the app controls.

#### Why is there no way to print? {#print}

The app is made using Apple's latest technologies (SwiftUI) and they have not added print support there yet. If you need to print, open the document in TextEdit instead. Sorry for the inconvenience.

#### Why is it suddenly showing a scrollbar?

You either have a system setting set to always show scrollbars or you have an external mouse connected. This is simply how macOS works. You can see the behavior in other text editing apps too. See the “Appearance › Show scroll bars” system setting.

#### The “Check Spelling While Typing” setting in the context menu does not work

This is unfortunately a macOS bug and not something I can fix.

*If you work at Apple → [FB13607434](https://github.com/feedback-assistant/reports/issues/467)*

#### Can you add line numbers?

This is out of scope for this app.

#### Can you add a setting to turn off line wrapping?

This is out of scope for this app.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### [More FAQs…](/apps/faq)

## Older Versions

- [1.5.1](https://github.com/user-attachments/files/18928644/Plain.Text.Editor.1.5.1.-.macOS.14.zip) for macOS 14+
- [1.3.2](https://github.com/sindresorhus/meta/files/14232390/Plain.Text.Editor.1.3.2.-.macOS.13.zip) for macOS 13+

These are free for everyone but they will not run on newer macOS versions.
