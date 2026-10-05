---
title: 'One Thing'
subtitle: 'Put a single task or goal in your menu bar'
publicationDate: '2022-01-12'
platforms: [
	'macOS'
]
isMenuBarApp: true
appStoreID: 1604176982
olderVersions: [
	{
		version: '1.13.2'
		macOS: '15'
		url: 'https://www.dropbox.com/scl/fi/s092qpp3p5s77gnjsyty3/One-Thing-1.13.2-macOS-15-1770923231.zip?rlkey=big014nrx8xrw4mwfnxwxbmxy&raw=1'
	}
	{
		version: '1.12.2'
		macOS: '14'
		url: 'https://github.com/user-attachments/files/19145029/One.Thing.1.12.2.-.macOS.14.zip'
	}
	{
		version: '1.11.3'
		macOS: '13'
		url: 'https://github.com/sindresorhus/meta/files/14759175/One.Thing.1.11.3.-.macOS.13.zip'
	}
	{
		version: '1.9.0'
		macOS: '12'
		url: 'https://github.com/sindresorhus/meta/files/11081660/One.Thing.1.9.0.-.macOS.12.zip'
	}
]
pressQuotes: [
	{
		quote: 'One Thing is a super simple menu bar app that helps you remember the one main thing that you need to accomplish. Whatever you type in will show up in your menu bar so it’s front and center.'
		source: 'MacRumors'
		url: 'https://www.macrumors.com/2025/12/24/10-mac-apps-worth-trying-in-2026/'
	}
	{
		quote: 'Overall, this is a simple application you can use to leave yourself reminders somewhere that’s impossible to ignore.'
		source: 'Lifehacker'
		url: 'https://lifehacker.com/tech/one-thing-app-turns-your-macs-menu-bar-into-sticky-note'
	}
]
---

Write the one task or goal that matters most today, and see it in your menu bar all day. A quiet reminder to focus on one thing at a time.

Some examples of what you could write:

- Eat more healthily
- Exercise
- Reply to Sara’s email
- Be happy
- Stop procrastinating
- Finish the 🦄 project
- Important meeting today

However, what you use this space for is really up to you.

<br>

> You can achieve almost anything in life — as long as you focus on achieving one thing at a time. It’s a time-tested strategy that’s been shared by many successful people.

— [https://dariusforoux.com/one-thing/](https://dariusforoux.com/one-thing/)

<br>

> [!TIP]
> You may also like my [Any Text](/any-text) and [One Task](/one-task) apps.

<br>

### Mentions

- [10 Mac Apps That Will Change How You Use macOS in 2026](https://www.youtube.com/watch?v=LtuUwACZdsQ&t=108s)

## Tips

- Press <kbd>return</kbd>/<kbd>esc</kbd> or click the menu bar item to close the edit window.
- Click the menu bar item while pressing <kbd>shift</kbd> to clear the text.
- Right-click the menu bar item to be able to quit the app quickly.
- If the menu bar item text is truncated, hover over it to see the full text in a tooltip.
- You can use [Markdown](https://www.markdownguide.org/basic-syntax/#emphasis) to [style the text](https://x.com/sindresorhus/status/1481818533294407680) (supports bold, italic, and strikethrough) and add links.
- You can [drag & drop text](https://x.com/sindresorhus/status/1481862243755376642) onto the menu bar item to set it. For example, you could drag a todo item from the Reminders app or Things.
- Select some text in any app, right-click, select “Services”, and click “Send to One Thing” to set One Thing to the selected text. You can also use the “Share” menu item if the app supports that.

## Frequently Asked Questions {#faq}

### The menu bar item has disappeared!

macOS hides menu bar items that do not fit. [Click here](one-thing:?text=) to reset the text.

### I made the text too long and now the menu bar item is hidden

[Click here](one-thing:?text=) to reset the text.

### The text looks blurry or is not dimmed on my secondary display

[See this answer](/apps/faq#menu-bar-secondary-display)

### How is this different from your One Task app? {#one-task-difference}

See [this answer](/one-task#one-thing-difference).

### Can I execute an action when I click the text?

You can add a [link using Markdown](https://www.markdownguide.org/basic-syntax/#links).

### What if I have two things?

The point is to focus on one thing at a time. [Humans work best this way.](https://dariusforoux.com/one-thing/) However, nothing is stopping you from writing two things, for example, with a `·` character in-between.

### Can I have two instances of One Thing running at the same time? {#one-thing2}

I have made a special version of One Thing with a different identifier. You can run this together with the App Store version. It also has separate Shortcuts actions and URL scheme: `one-thing2:`. This version will not receive updates.

[Download](https://www.dropbox.com/scl/fi/pn3k0r6edea21my7beqz3/One-Thing-2-1.11.0-1684349283-1701610241.zip?rlkey=qgv6rmx9bitjki4xbh05tn2ty&raw=1)

### How can I show the next task in the “Today” list in Things in One Thing? {#things}

You can use the Shortcuts app for this. Here is an [example shortcut](https://www.icloud.com/shortcuts/7f8a4cc8764348518c5b7774d60191cc) that sets the next todo in “Today” as the text in One Thing.

To have the shown todo stay in sync with [Things](https://culturedcode.com/things/), use the [Shortery](https://apps.apple.com/app/id1594183810) app to run the shortcut when Things becomes inactive. Alternatively, place the shortcut in the menu bar and run it manually, or use [Short Run](/short-run).

### How can I show the upcoming reminder from the Reminders app in One Thing? {#reminders}

You can use the Shortcuts app for this. Here is an [example shortcut](https://www.icloud.com/shortcuts/4bed5f56a0f94e9a9e9ba05c97c6e64b).

To have the shown todo stay in sync with Reminders, use the [Shortery](https://apps.apple.com/app/id1594183810) app to run the shortcut when Reminders becomes inactive. Alternatively, place the shortcut in the menu bar and run it manually, or use [Short Run](/short-run).

### How can I show a todo from my favorite todo app in One Thing?

Do something similar to the above answer.

### How can I show a random quote in the menu bar? {#quote}

You can use the Shortcuts app for this. Here is an [example shortcut](https://www.icloud.com/shortcuts/35d88a7b56154893bd2e28e3988410f1).

Use a Shortcuts automation to run the shortcut at certain times to change the quote.

### How can I put spacing on the sides of the text?

You can add some horizontal padding around the text by adding multiple spaces to the “Prefix” and “Suffix” settings.

### How can I show different text for each day of the week?

You can use the macOS Shortcuts app for this. Make a shortcut for each piece of text you want to be shown by using the “Set Text” action provided by One Thing. Then use Shortcuts automations to run these shortcuts on the specific days.

### Can you add iOS / watchOS support?

I plan to do it if the app takes off. So tell your friends.

### How can I export, import, sync, or back up the settings?

[See this guide.](https://github.com/sindresorhus/guides/blob/main/backup-app-settings.md)

### Is the app native?

Yes, it’s native and written in Swift and SwiftUI.

## Scripting

The app can be automated using the Shortcuts app or with a custom URL scheme.

More integrations:

- [Command-line tool](https://github.com/sindresorhus/one-thing)
- [Node.js API](https://github.com/sindresorhus/one-thing)
- [Raycast commands](https://github.com/raycast/script-commands/tree/master/commands#one-thing)
	- Note: Raycast commands are not the same as plugins. [How to install commands.](https://github.com/raycast/script-commands#install-script-commands-from-this-repository)

### Shortcuts app

- [Example shortcut](https://www.icloud.com/shortcuts/381619f1c8404770ad020d439a48fd9c)
- [Shortcuts usage guide](https://www.xda-developers.com/guide-shortcuts-macos/)
- [How to run shortcuts from the command-line](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac)

**Examples**

- [Reminders app: Show latest due reminder](https://www.icloud.com/shortcuts/5d3e63030877471697dd0023fefc4819)
- [Things app: Show the first todo in the “Today” list](#things)

### Custom URL scheme

The menu bar item text can be set from any tool that can open an URL. This includes a website, Bash, Node.js, Python, Swift, etc.

For example, in your terminal:

```sh
open --background 'one-thing:?text=Exercise'
```

*Don’t forget to [URL encode](https://www.urlencoder.org) the value for the `text=` search parameter. For example, using [this](https://gist.github.com/cdown/1163649) Bash function.*

There is no way to get the text using the URL scheme, but if you are in the terminal, you can run this command:

```sh
defaults read com.sindresorhus.One-Thing text
```

## Non-App Store Version

A special version for users that cannot access the App Store. It won’t receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/4d3zqtuj4j2erm6ck80ei/One-Thing-2.0.2-1778696587.zip?rlkey=s2h6g802mi674wkg7s5olfb9l&raw=1) *(2.0.2)*

*Requires macOS 26 or later*
