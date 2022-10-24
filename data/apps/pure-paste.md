---
title: Pure Paste
subtitle: Paste as plain text by default
date: 2022-03-02
platforms:
  - macOS
appStoreId: 1611378436
---

Pure Paste lets you paste as plain text by default. It sits in the menu bar and clears formatting (fonts, colors, bold, links, tables, etc.) from the text you copy. However, it does not touch unrelated content like files, images, etc. It also ignores content copied from password managers.

You can also choose to manually clear formatting whenever needed instead of automatically.

<br>

#### Limitations

Rich text copied from a different device will not have its formatting cleared because of a bug in Universal Clipboard.

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Pure%20Paste&referrer=Website-FAQ)

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some menu bar apps to free up space. If this does not solve it, try quitting Bartender if you have it installed.

You may also have enabled the “Hide menu bar icon” preference, which hides the menu bar icon. Launch the app again to reveal the menu bar item for 5 seconds.

#### Pure Paste conflicts with my clipboard manager

This is a known issue. It's really just a flaw in how the clipboard works. If your clipboard managers reads the clipboard first, it will get it. If Pure Paste then reads the clipboard, it will do its thing, but also tell clipboard managers not to fetch the new contents as otherwise they might end up with duplicates. This is required as otherwise certain features like "fast-append" don't work in Alfred and other clipboard managers. I'm working on a way all apps can collaborate, but it will take some time.

For now, I suggest setting a keyboard shortcut for "Clear formatting and paste" and then turn off "Automatically clear formatting".

#### The app clears formatting when it shouldn't or doesn't clear formatting when it should {#clear-formatting-problem}

[Let me know.](https://sindresorhus.com/feedback?product=Pure%20Paste&referrer=Website-FAQ) I will fix it quickly, if possible.

There are some cases I cannot fix though:
- **The Pages and Keynote apps paste text as a table.**
  These apps paste any text with multiple lines as a table. This is not a problem with Pure Paste and also not something I can fix. You can complain to Apple about the behavior [here](https://www.apple.com/feedback/pages.html).

#### Why not just use the `Paste and Match Style` menu item or `⌥⇧⌘V`?

- This app can make it the default behavior.
- That menu item is not available in all apps.
- The keyboard shortcut is hard to remember and type.
- In some apps, like Chrome, the keyboard shortcut is different.
- This app can exclude certain apps, preserve links, and also remove tracking parameters from URLs.

#### Why not just remap the `Paste and Match Style` keyboard shortcut to `⌘V`?

- That menu item is not available in all apps.
- In some apps, like Word, the menu item has a diffent label, which requires a separate mapping.
- This app can exclude certain apps, preserve links, and also remove tracking parameters from URLs.

#### What are tracking parameters and why would I want to remove them?

Removing tracking parameters improve privacy and also make URLs more aesthetically pleasing. Tracking parameters are used by many websites to track your browsing activity across websites. [Read more.](https://en.wikipedia.org/wiki/UTM_parameters)

Pure Paste supports 200+ common tracking parameters (e.g. Google UTM) and it has special support for removing tracking from links to Twitter, Facebook, and TikTok.

Before: `https://foo.com?utm_content=buffercf3b2&utm_source=snapchat.com`\
After: `https://foo.com`

Did you know that if you click a TikTok link that someone shared with you, they will be able to see that you watched it? Pure Paste anonymizes TikTok links so that you will not be tracked.

#### Tracking parameters are not removed {#tracking-parameters-not-removed}

First, make sure the setting to remove tracking parameters is enabled.

Tracking parameters are not removed if the “Automatically Clear Formatting” preference is disabled or you did not manually trigger format clearing.

The app contains a list of tracking parameters to remove, but there may be site-specific tracking parameters it doesn't know about. If you encounter any tracking parameters not being removed, [let me know](https://sindresorhus.com/feedback?product=Pure%20Paste&referrer=Website-FAQ) and I'll add support for them.

#### Can you add a setting to preserve bold and italic?

In short, no. To preserve bold and italic, the app has to preserve the font too, and by preserving the font, it has to set a font name and size. This means the text will not match the destination formatting. Instead, for example, in Word, you can copy with formatting and select “Paste and Match Formatting”, which correctly preserves bold and italic while clearing color and sizes.

#### I have “Preserve links” enabled, and when I paste into Word, it ends up with the “Times New Roman” font instead of the existing font {#word-bug}

This is a bug in Word. Please upvote [this report](https://feedbackportal.microsoft.com/feedback/idea/614f1602-cdd8-ec11-a81b-000d3a03dba2).

As a workaround, you can either disable the “Preserve links” setting or use “Paste and Match Formatting” in the “Edit” menu in Word.

#### I have “Preserve links” enabled, and when I paste into an app, it ends up with the “Helvetica” font instead of the existing font {#helvetica-bug}

This is a bug in macOS.

As a workaround, you can either disable the “Preserve links” setting or use “Paste and Match Style” in the “Edit” menu of the app.

If you work for Apple or want to help out by duplicating my reports, see:

- [FB10023436](https://github.com/feedback-assistant/reports/issues/307)
- [FB10023420](https://github.com/feedback-assistant/reports/issues/306)
- [FB10023393](https://github.com/feedback-assistant/reports/issues/305)

#### Excel, Word, and PowerPoint are missing some actions in “Paste Options” {#office-apps}

Pure Paste works by modifying the clipboard. Office hides most of the “Paste Options” actions if the clipboard is modified.

The solution is to either:
1. Exclude the Office apps in the Pure Paste settings.
1. Turn off “Automatically Clear Formatting” and instead set a keyboard shortcut in the settings. That way the clipboard stays unmodified until you use the keyboard shortcut to clear & paste.

#### The app does not clear formatting when copy-pasting an image inside Google Docs

Web apps do not follow the standard clipboard conventions that native desktop apps do. When you copy an image in Google Docs, it just puts a bunch of HTML code on the clipboard. Pure Paste cannot easily know it's an image you copied.

#### The app does not clear formatting when copy-pasting rich text inside Figma {#figma}

Web apps do not follow the standard clipboard conventions that native desktop apps do. When you copy some rich text in Figma, it just puts a bunch of HTML code on the clipboard. Pure Paste cannot easily know it's rich text you copied.

#### The app does not preserve links when pasting into Google Docs even with the “Preserve links” setting enabled

There is a [problem with Google Docs](https://webapps.stackexchange.com/questions/69248/is-there-a-way-to-paste-rtf-text-into-google-document) where it strips links from rich text content. It happens even without Pure Paste. Web apps are generally bad at following platform conventions.

#### Copying a cell with a formula in Numbers or Excel looses the formula {#numbers-formula}

Pure Paste clears formatting by replacing the clipboard with a plain text version (this is the only reliable way to clear formatting). However, some apps store metadata in on the clipboard, and in this specific case, these apps store the formula as metadata in the clipboard, which is then lost. There is no way reliable way to detect this.

The solution is to either:
1. Skip clearing formatting for just this copy (see instructions in the app settings).
1. Exclude the app in the Pure Paste settings.

#### Does it respect [nspasteboard.org](http://nspasteboard.org) conventions?

Yes, it ignores concealed (passwords), transient, and auto-generated content.

<!-- It also adds the `org.nspasteboard.AutoGeneratedType` identifier when putting the plain text content on the clipboard. -->

#### How can I export, import, sync, or backup the settings?

[See this guide.](https://github.com/sindresorhus/guides/blob/main/backup-app-settings.md)

#### Why is this free without ads?

I just enjoy making Mac apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1611378436) and click “Version History”.

#### Can you localize the app into my language?

I don't have any immediate plans to localize the app.

<br>

### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive updates.

[Download](https://dsc.cloud/sindresorhus/Pure-Paste-1.3.10-1661933216) *(1.3.10)*

*Requires macOS 12 or later*
