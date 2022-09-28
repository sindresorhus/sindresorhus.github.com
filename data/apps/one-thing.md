---
title: One Thing
subtitle: Put a single task or goal in your menu bar
date: 2022-01-12
platforms:
  - macOS
appStoreId: 1604176982
---

---

**You may also like [my similar app](/any-text) for the iOS Lock Screen.**

---

This can be a useful tool to help you focus on a single task.

Some examples of what you could write:

- Eat more healthily
- Exercise
- Reply to Sarah's email
- Be happy
- Stop procrastinating
- Finish the 🦄 project
- Important meeting today

However, what you use this space for is really up to you.

<br>

> You can achieve almost anything in life — as long as you focus on achieving one thing at a time. It’s a time-tested strategy that’s been shared by many successful people.
>
> — [https://dariusforoux.com/one-thing/](https://dariusforoux.com/one-thing/)

<br>

### Tips

- Press <kbd>return</kbd>/<kbd>esc</kbd> or click the menu bar item to close the edit window.
- Click the menu bar item while pressing <kbd>shift</kbd> to clear the text.
- Right-click the menu bar item to be able to quit the app quickly.
- If the menu bar item text is truncated, hover over it to see the full text in a tooltip.
- You can use [Markdown](https://www.markdownguide.org/basic-syntax/#emphasis) to [style the text](https://twitter.com/sindresorhus/status/1481818533294407680) (supports bold, italic, and strikethrough) and add links.
- You can [drag & drop text](https://twitter.com/sindresorhus/status/1481862243755376642) onto the menu bar item to set it. For example, you could drag a todo item from the Reminders app or Things.
- Select some text in any app, right-click, select “Services”, and click “Send to One Thing” to set One Thing to the selected text. You can also use the “Share” menu item if the app supports that.

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=One%20Thing&referrer=Website-FAQ)

#### The menu bar item has disappeared!

macOS hides menu bar items that do not fit. [Click here](one-thing:?text=) to reset the text.

#### I made the text too long and now the menu bar item is hidden

[Click here](one-thing:?text=) to reset the text.

#### Can I have execute an action when I click the text?

You can add a [link using Markdown](https://www.markdownguide.org/basic-syntax/#links).

#### What if I have two things?

The point is to focus on one thing at a time. [Humans work best this way.](https://dariusforoux.com/one-thing/) However, nothing is stopping you from writing two things, for example, with a `·` character in-between.

#### Can I have two instances of One Thing running at the same time? {#one-thing2}

I have made a special version of One Thing with a different identifier. You can run this together with the App Store version. It also has a separate URL scheme: `one-thing2:`. This version will not receive updates.

[Download](https://github.com/sindresorhus/one-thing/files/9603759/One.Thing.2.app.zip)

#### How can I show the next task in the “Today” list in [Things](https://culturedcode.com/things/) in One Thing? {#things}

You can use the macOS Shortcuts app for this. Things unfortunately does not have very good Shortcuts support ([Please tell them to improve that!](https://culturedcode.com/contact/)), so we have to resort to AppleScript to fetch the next task in the “Today” list. Here's an [example shortcut](https://www.icloud.com/shortcuts/62c0f5fc4d194b72a6f97ce8cedf698f).

Shortcuts does not yet support automation, so to have the shown todo stay in sync with Things, we need to use the [Shortery](https://apps.apple.com/us/app/shortery/id1594183810) app to run the shortcut. Choose the “Application” trigger type and make it trigger when Things becomes “Inactive”. Alternatively, place the shortcut in the menu bar and run it manually.

#### How can I show a todo from my favorite todo app in One Thing?

Do something similar to the above answer.

#### How can I put spacing on the sides of the text?

You can add some horizontal padding around the text by adding multiple spaces to the “Prefix” and “Suffix” settings.

#### How can I show different text for each day of the week?

You can use the macOS Shortcuts app for this. Make a shortcut for each piece of text you want shown by using the “Set Text” action provided by One Thing. Shortcuts does not yet support automation (it most likely will in macOS 14), so for now we need to use the [Shortery](https://apps.apple.com/us/app/shortery/id1594183810) app to schedule these shortcuts to run at the specific days.

#### Can you add iOS / watchOS support?

I plan to do it if the app takes off. So tell your friends.

#### How can I export, import, sync, or backup the settings?

[See this guide.](https://github.com/sindresorhus/guides/blob/main/backup-app-settings.md)

#### Is the app native?

Yes, it's native and written in Swift and SwiftUI.

#### Why is this free without ads?

I just enjoy making Mac apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1604176982) and click “Version History”.

#### Can you localize the app into my language?

I don't have any immediate plans to localize the app.

<br>

### Scripting

One Thing can be automated using the Shortcuts app or with a custom URL scheme.

More integrations:

- [Command-line tool](https://github.com/sindresorhus/one-thing)
- [Node.js API](https://github.com/sindresorhus/one-thing)
- [Raycast command](https://github.com/raycast/script-commands/tree/master/commands#one-thing)

#### Shortcuts app

- [Example shortcut](https://www.icloud.com/shortcuts/381619f1c8404770ad020d439a48fd9c)
- [How to use Shortcuts](https://www.xda-developers.com/guide-shortcuts-macos/)
- [How to run shortcuts from the command-line](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac)

**Examples**

- [Reminders app: Show latest due reminder](https://www.icloud.com/shortcuts/5d3e63030877471697dd0023fefc4819)
- [Things app: Show first todo in the “Today” list](#things)

#### Custom URL scheme

The menu bar item text can be set from any tool that can open an URL. This includes, a website, Bash, Node.js, Python, Swift, etc.

For example, in your terminal:

```sh
open --background 'one-thing:?text=Exercise'
```

*Don't forget to [URL encode](https://www.urlencoder.org) the value for the `text=` search parameter. For example, using [this](https://gist.github.com/cdown/1163649) Bash function.*

<br>

### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive updates.

[Download](https://dsc.cloud/sindresorhus/One-Thing-1.8.0-1661784123) *(1.8.0)*

*Requires macOS 12 or later*
