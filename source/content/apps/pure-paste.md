---
title: Pure Paste
subtitle: Paste as plain text by default
pubDate: 2022-03-02
platforms:
  - macOS
isPaid: true
isMenuBarApp: true
appStoreId: 1611378436
olderMacOSVersions:
  - '12'
  - '13'
  - '14'
---

Pure Paste lets you paste as plain text by default. It sits in the menu bar and automatically clears formatting (fonts, colors, bold, links, tables, etc.) from the text you copy, while intelligently preserving unrelated content like files, images, and passwords from password managers.

Beyond basic formatting removal, Pure Paste can also remove invisible characters (including AI watermarks), normalize quotes and lists, remove tracking parameters from URLs, and much more.

You can also choose to manually clear formatting whenever needed instead of automatically.

<br>

#### Limitations

Rich text copied from a different device will not have its formatting cleared because of a bug in Universal Clipboard.

## Tips

- Right-click the menu bar icon to toggle the “Automatically clear formatting” setting.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](/feedback?product=Pure%20Paste&referrer=Website-FAQ)

#### Why not just use the `Paste and Match Style` menu item or `⌥⇧⌘V`?

- This app can make it the default behavior.
- That menu item is not available in all apps.
- The keyboard shortcut is hard to remember and type.
- In some apps, like Chrome, the keyboard shortcut is different.
- This app can exclude certain apps, preserve links, normalize (quotes, newlines, lists, etc.) and also remove tracking parameters from URLs.
- The app has workarounds (9000+ lines of code) for lots of apps to make the experience *just work*.

#### Why not just remap the `Paste and Match Style` keyboard shortcut to `⌘V`?

Same as the above except the first two list items.

#### The app does not show up in the menu bar

[Try this](/apps/faq#app-not-showing-in-menu-bar)

You may also have enabled the “Hide menu bar icon” setting, which hides the menu bar icon. Launch the app again to reveal the menu bar item for 5 seconds.

#### The app does not work

- Ensure automatic clearing is enabled or you have set a keyboard shortcut for clearing.
- Ensure you have not excluded (in the settings) the app you want to use it with.
- Try copy-pasting to/from a different app to ensure the problem is with Pure Paste.
- If you are using a custom keyboard shortcut for clearing, try [resetting privacy permissions](/apps/faq#mac-reset-permissions).
- [More…](/apps/faq#app-problem)

#### Pure Paste conflicts with my clipboard manager

This is a known issue. It's just a flaw in how the clipboard works. If your clipboard manager reads the clipboard first, it will get it. If Pure Paste then reads the clipboard, it will do its thing, but also tell clipboard managers not to fetch the new contents as otherwise, they might end up with duplicates. This is required as otherwise certain features like "fast-append" don't work in Alfred and other clipboard managers. I'm working on a way all apps can collaborate, but it will take some time.

For now, I suggest setting a keyboard shortcut for "Clear formatting and paste" and then turning off "Automatically clear formatting".

#### The app clears formatting when it shouldn't or doesn't clear formatting when it should {#clear-formatting-problem}

[Let me know.](/feedback?product=Pure%20Paste&referrer=Website-FAQ) I will fix it quickly, if possible.

There are some cases I cannot fix though:
- **The Pages and Keynote apps paste text as a table.**
	These apps paste any text with multiple lines as a table. This is not a problem with Pure Paste and is also not something I can fix. You can complain to Apple about the behavior [here](https://www.apple.com/feedback/pages.html).
- [**Tables in Word are not preserved.**](#word-tables)
- Formatting is not cleared when copying and pasting inside LibreOffice.
	This is a LibreOffice bug. Pure Paste correctly clears the formatting of the clipboard contents, but LibreOffice does not read the new clipboard contents until you first focus a different window. Try copying some styled text in LibreOffice, focus a different window, focus LibreOffice again, and then paste. It now correctly pastes the text without formatting.
- Mail app: Formatting is cleared but does not match the style used for emails. Pure Paste correctly clears the formatting, but the Mail app does not correctly make text without formatting match the existing style.

#### The copy/paste custom keyboard shortcut does not work

Try [resetting privacy permissions](/apps/faq#mac-reset-permissions) for the app. macOS can sometimes corrupt these permissions, causing the shortcut to fail.

#### What are tracking parameters and why would I want to remove them?

Removing tracking parameters improve privacy and also make URLs more aesthetically pleasing. Tracking parameters are used by many websites to track your browsing activity across websites. [Learn more.](https://en.wikipedia.org/wiki/UTM_parameters)

Pure Paste supports 200+ common tracking parameters (e.g. Google UTM) and it has special support for removing tracking from links to X (Twitter), Facebook, and TikTok.

Before: `https://foo.com?utm_content=buffercf3b2&utm_source=snapchat.com`\
After: `https://foo.com`

Did you know that if you click a TikTok link that someone shared with you, they will be able to see that you watched it? Pure Paste anonymizes TikTok links so that you will not be tracked.

#### Tracking parameters are not removed {#tracking-parameters-not-removed}

First, make sure the setting to remove tracking parameters is enabled.

Tracking parameters are not removed if the “Automatically Clear Formatting” preference is disabled or you did not manually trigger format clearing.

The app contains a list of tracking parameters to remove, but there may be site-specific tracking parameters it doesn't know about. If you encounter any tracking parameters not being removed, [let me know](/feedback?product=Pure%20Paste&referrer=Website-FAQ) and I'll add support for them.

#### Can you add a setting to preserve bold and italic?

In short, no. To preserve bold and italic, the app has to preserve the font too, and by preserving the font, it has to set a font name and size. This means the text will not match the destination formatting. Instead, for example, in Word, you can copy with formatting and select “Paste and Match Formatting”, which correctly preserves bold and italic while clearing color and sizes.

#### I have “Preserve links” enabled, and when I paste into an app (for example, Mimestream), it ends up with the “Times New Roman” font instead of the system font

When “Preserve links” is enabled, Pure Paste removes formatting but keeps the text as rich text instead of plain text. Some apps don't handle this properly and default to “Times New Roman”. The only workaround is to disable “Preserve links”.

#### I have “Preserve links” enabled, and when I paste into Word, it ends up with the “Times New Roman” font instead of the existing font {#word-bug}

This is a bug in Word. ~~Please upvote [this report](https://feedbackportal.microsoft.com/feedback/idea/614f1602-cdd8-ec11-a81b-000d3a03dba2).~~ (Update: They removed the bug report and blocked me there 🤷‍♂️)

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

#### Tables are not preserved when I copy-paste in Word {#word-tables}

There is no way to preserve tables while clearing formatting of their cell contents. Different apps have different ways to represent tables on the clipboard. When you need to preserve a table, just temporarily disable Pure Paste. See the “Automatic clear formatting” setting on how to skip format clearing once. You can also right-click the menu bar icon to enable/disable automatic format clearing. Or set a global keyboard shortcut.

#### Why doesn't cutting work in Excel when Pure Paste is active?

Excel has unique (incorrect) interactions with the clipboard, which is incompatible with Pure Paste. When you cut text in Excel, the app puts metadata on the clipboard that a cut operation is being performed. Pure Paste, designed to remove formatting from copied text, inadvertently clears this info when it cleans the clipboard. The result is that Excel thinks it's a copy operation instead.

You can either add Excel to the exclude list in the Pure Paste settings or turn off automatic format clearing and set a “clear formatting and paste” keyboard shortcut instead.

#### The app does not clear formatting when copy-pasting an image inside Google Docs

Web apps do not follow the standard clipboard conventions that native desktop apps do. When you copy an image in Google Docs, it just puts a bunch of HTML code on the clipboard. Pure Paste cannot easily know it's an image you copied.

#### The app does not clear formatting when copy-pasting rich text inside Figma {#figma}

Web apps do not follow the standard clipboard conventions that native desktop apps do. When you copy some rich text in Figma, it just puts a bunch of HTML code on the clipboard. Pure Paste cannot easily know it's rich text you copied.

#### The app does not preserve links when pasting into Google Docs even with the “Preserve links” setting enabled

There is a [problem with Google Docs](https://webapps.stackexchange.com/questions/69248/is-there-a-way-to-paste-rtf-text-into-google-document) where it strips links from rich text content. It happens even without Pure Paste. Web apps are generally bad at following platform conventions.

#### Copying a cell with a formula in Numbers or Excel loses the formula {#numbers-formula}

Pure Paste clears formatting by replacing the clipboard with a plain text version (this is the only reliable way to clear formatting). However, some apps store metadata on the clipboard, and in this specific case, these apps store the formula as metadata in the clipboard, which is then lost. There is no way reliable way to detect this.

The solution is to either:
1. Skip clearing formatting for just this copy (see instructions in the app settings).
1. Exclude the app in the Pure Paste settings.

#### The exclude setting does not work

Copy something from the app you have excluded, press the <kbd>Option</kbd> key while clicking the Pure Paste menu bar item, and then make sure the app shown in the menu is the same as the one you excluded.

#### How can I exclude certain websites?

This will not be supported. A workaround would be to [turn the website into an app in Safari](https://support.apple.com/guide/safari/add-to-dock-ibrw9e991864/mac). You could then exclude that app.

The need for such a setting only arises because many web apps do not adhere to platform clipboard standards, unlike native apps.

#### Can it support pasting with formatting when pressing <kbd>Command+Shift+V</kbd>?

The app technically clears formatting when something is copied not pasted, so the formatting is already cleared when that shortcut is pressed.

#### Can you add support for removing newlines/linebreaks?

The app is designed to *just work*, but removing newlines is not suitable for all use cases. For instance, you may want to remove newlines when copying text from a PDF, but not from Word. If you still want this feature, add the following to the “JavaScript” setting:

```js
return $.text.replace(/(\r?\n)/gm, ' ');
```

And if you want to preserve paragraphs, use:

```js
return $.text.replace(/([^\r\n])(?:\r?\n)(?!\r?\n)/g, '$1 ');
```

#### Does it respect [nspasteboard.org](http://nspasteboard.org) conventions?

Yes, it ignores concealed (passwords), transient, and auto-generated content.

<!-- It also adds the `org.nspasteboard.AutoGeneratedType` identifier when putting the plain text content on the clipboard. -->

<!-- #### Why is this free without ads?

I just enjoy making Mac apps. Consider leaving a nice review on the App Store. -->

#### [More FAQs…](/apps/faq)

## Older Versions

- [1.11.4](https://github.com/user-attachments/files/18969765/Pure.Paste.1.11.4.-.macOS.14.zip) for macOS 14
- [1.9.2](https://github.com/sindresorhus/meta/files/14350035/Pure.Paste.1.9.2.-.macOS.13.zip) for macOS 13
- [1.6.4](https://github.com/sindresorhus/meta/files/10793621/Pure.Paste.1.6.4.-.macOS.12.zip) for macOS 12

These are free for everyone but they will not run on newer macOS versions.
