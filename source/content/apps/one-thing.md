---
title: One Thing
subtitle: Put a single task or goal in your menu bar
pubDate: 2022-01-12
platforms:
  - macOS
isMenuBarApp: true
appStoreId: 1604176982
olderMacOSVersions:
  - '12'
  - '13'
---

This can be a useful tool to help you focus on a single task.

Some examples of what you could write:

- Eat more healthily
- Exercise
- Reply to Sara's email
- Be happy
- Stop procrastinating
- Finish the 🦄 project
- Important meeting today

However, what you use this space for is really up to you.

<br>

> You can achieve almost anything in life — as long as you focus on achieving one thing at a time. It’s a time-tested strategy that’s been shared by many successful people.

— [https://dariusforoux.com/one-thing/](https://dariusforoux.com/one-thing/)

<br>

**You may also like my [Any Text](/any-text) and [One Task](/one-task) apps.**

### Tips

- Press <kbd>return</kbd>/<kbd>esc</kbd> or click the menu bar item to close the edit window.
- Click the menu bar item while pressing <kbd>shift</kbd> to clear the text.
- Right-click the menu bar item to be able to quit the app quickly.
- If the menu bar item text is truncated, hover over it to see the full text in a tooltip.
- You can use [Markdown](https://www.markdownguide.org/basic-syntax/#emphasis) to [style the text](https://twitter.com/sindresorhus/status/1481818533294407680) (supports bold, italic, and strikethrough) and add links.
- You can [drag & drop text](https://twitter.com/sindresorhus/status/1481862243755376642) onto the menu bar item to set it. For example, you could drag a todo item from the Reminders app or Things.
- Select some text in any app, right-click, select “Services”, and click “Send to One Thing” to set One Thing to the selected text. You can also use the “Share” menu item if the app supports that.

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=One%20Thing&referrer=Website-FAQ)

#### The menu bar item has disappeared!

macOS hides menu bar items that do not fit. [Click here](one-thing:?text=) to reset the text.

#### I made the text too long and now the menu bar item is hidden

[Click here](one-thing:?text=) to reset the text.

#### How is this different from your [One Task](/one-task) app? {#one-task-difference}

See [this answer](/one-task#one-thing-difference).

#### Can I execute an action when I click the text?

You can add a [link using Markdown](https://www.markdownguide.org/basic-syntax/#links).

#### What if I have two things?

The point is to focus on one thing at a time. [Humans work best this way.](https://dariusforoux.com/one-thing/) However, nothing is stopping you from writing two things, for example, with a `·` character in-between.

#### Can I have two instances of One Thing running at the same time? {#one-thing2}

I have made a special version of One Thing with a different identifier. You can run this together with the App Store version. It also has separate Shortcuts actions and URL scheme: `one-thing2:`. This version will not receive updates.

[Download](https://www.dropbox.com/scl/fi/pn3k0r6edea21my7beqz3/One-Thing-2-1.11.0-1684349283-1701610241.zip?rlkey=qgv6rmx9bitjki4xbh05tn2ty&raw=1)

#### How can I show the next task in the “Today” list in [Things](https://culturedcode.com/things/) in One Thing? {#things}

You can use the Shortcuts app for this. Here is an [example shortcut](https://www.icloud.com/shortcuts/7f8a4cc8764348518c5b7774d60191cc) that sets the next todo in “Today” as the text in One Thing.

Shortcuts does not yet support automation, so to have the shown todo stay in sync with Things, we need to use the [Shortery](https://apps.apple.com/us/app/shortery/id1594183810) app to run the shortcut. Choose the “Application” trigger type and make it trigger when Things becomes “Inactive”. Alternatively, place the shortcut in the menu bar and run it manually.

#### How can I show the upcoming reminder from the Reminders app in One Thing? {#reminders}

You can use the Shortcuts app for this. Here is an [example shortcut](https://www.icloud.com/shortcuts/4bed5f56a0f94e9a9e9ba05c97c6e64b).

Shortcuts does not yet support automation, so to have the shown todo stay in sync with Reminders, we need to use the [Shortery](https://apps.apple.com/us/app/shortery/id1594183810) app to run the shortcut. Choose the “Application” trigger type and make it trigger when Reminders becomes “Inactive”. Alternatively, place the shortcut in the menu bar and run it manually.

#### How can I show a todo from my favorite todo app in One Thing?

Do something similar to the above answer.

#### How can I show a random quote in the menu bar? {#quote}

You can use the Shortcuts app for this. Here is an [example shortcut](https://www.icloud.com/shortcuts/35d88a7b56154893bd2e28e3988410f1).

Shortcuts does not yet support automation, so you have to use the time trigger in the [Shortery](https://apps.apple.com/us/app/shortery/id1594183810) app to run the shortcut at a certain interval to change the quotes.

#### How can I put spacing on the sides of the text?

You can add some horizontal padding around the text by adding multiple spaces to the “Prefix” and “Suffix” settings.

#### How can I show different text for each day of the week?

You can use the macOS Shortcuts app for this. Make a shortcut for each piece of text you want to be shown by using the “Set Text” action provided by One Thing. Shortcuts does not yet support automation (it most likely will in macOS 15), so for now we need to use the [Shortery](https://apps.apple.com/us/app/shortery/id1594183810) app to schedule these shortcuts to run at the specific days.

#### Can you add iOS / watchOS support?

I plan to do it if the app takes off. So tell your friends.

#### How can I export, import, sync, or back up the settings?

[See this guide.](https://github.com/sindresorhus/guides/blob/main/backup-app-settings.md)

#### Is the app native?

Yes, it's native and written in Swift and SwiftUI.

#### Why is this free without ads?

I just enjoy making Mac apps. Consider leaving a nice review on the App Store.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### [More FAQs…](/apps/faq)

### Scripting

The app can be automated using the Shortcuts app or with a custom URL scheme.

More integrations:

- [Command-line tool](https://github.com/sindresorhus/one-thing)
- [Node.js API](https://github.com/sindresorhus/one-thing)
- [Raycast commands](https://github.com/raycast/script-commands/tree/master/commands#one-thing)
	- Note: Raycast commands are not the same as plugins. [How to install commands.](https://github.com/raycast/script-commands#install-script-commands-from-this-repository)

#### Shortcuts app

- [Example shortcut](https://www.icloud.com/shortcuts/381619f1c8404770ad020d439a48fd9c)
- [Shortcuts usage guide](https://www.xda-developers.com/guide-shortcuts-macos/)
- [How to run shortcuts from the command-line](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac)

**Examples**

- [Reminders app: Show latest due reminder](https://www.icloud.com/shortcuts/5d3e63030877471697dd0023fefc4819)
- [Things app: Show the first todo in the “Today” list](#things)

#### Custom URL scheme

The menu bar item text can be set from any tool that can open an URL. This includes a website, Bash, Node.js, Python, Swift, etc.

For example, in your terminal:

```sh
open --background 'one-thing:?text=Exercise'
```

*Don't forget to [URL encode](https://www.urlencoder.org) the value for the `text=` search parameter. For example, using [this](https://gist.github.com/cdown/1163649) Bash function.*

There is no way to get the text using the URL scheme, but if you are in the terminal, you can run this command:

```sh
defaults read com.sindresorhus.One-Thing text
```

### Older Versions

- [1.11.3](https://github.com/sindresorhus/meta/files/14759175/One.Thing.1.11.3.-.macOS.13.zip) for macOS 13+
- [1.9.0](https://github.com/sindresorhus/meta/files/11081660/One.Thing.1.9.0.-.macOS.12.zip) for macOS 12+

### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/djlxpnzgyko826sdwkulf/One-Thing-1.12.0-1707465000.zip?rlkey=jbth4wugckqcf49aiw8m3hzzp&raw=1) *(1.12.0)*

*Requires macOS 14 or later*
