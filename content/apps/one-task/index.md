---
title: 'One Task'
subtitle: 'Conquer one task at a time'
publicationDate: 2023-09-19
platforms: [
	'macOS'
	'iOS'
	'visionOS'
	'watchOS'
]
isPaid: true
appStoreID: 6465745322
sharedQuestions: [
	'blurry-secondary-display'
	'widget-transparent-background'
	'widget-missing'
	'lock-screen-centered'
	'lock-screen-after-restart'
	'lock-screen-widget-disappears'
]
olderVersions: [
	{
		version: '1.6.1'
		macOS: '15'
		url: 'https://www.dropbox.com/scl/fi/pw69xu9uuzhso36bpxobt/One-Task-1.6.1-macOS-15-1774212569.zip?rlkey=8qiv99b2xuhbl7emqfseesyf3&raw=1'
	}
	{
		version: '1.5.4'
		macOS: '14'
		url: 'https://github.com/user-attachments/files/18549490/One.Task.1.5.4.-.macOS.14.zip'
	}
]
---

Show a single task on your Home Screen, Lock Screen, or desktop.

Add some tasks to the app and then add the widget. Simply tap the widget to mark the task as completed. The next task will then appear.

The simplicity is a feature. The app will not have things like folders, tags, priority, notes, etc.

The optimal workflow in One Task is to add only the tasks you’re committed to completing today. The app is designed for task completion, not endless organization and neglect.

<!-- Syncs seamlessly across your devices with iCloud. -->

It syncs tasks over iCloud.

<br>

> You can achieve almost anything in life — as long as you focus on achieving one thing at a time. It’s a time-tested strategy that’s been shared by many successful people.

— [Darius Foroux](https://dariusforoux.com/one-thing/)

<br>

## Tips

### Import tasks from other todo apps

You can quickly import tasks from other todo apps by copying the tasks from such apps and pasting them with the “Paste” button in the “All Tasks” section of the “…” menu.

For example, on macOS, select the tasks you want in Reminders or Things, right-click and copy them, and then paste them into One Task with the “Paste” button.

### Add tasks from anywhere on macOS

- Drag text onto the menu bar item to add it as tasks. Each line becomes a task.
- Select text in any app and choose “Services › Add to One Task” from the app menu or the right-click menu. You can give the service its own keyboard shortcut in “System Settings › Keyboard › Keyboard Shortcuts › Services › Text”.

### Complete the task with a double tap on Apple Watch

When the One Task widget is in the Smart Stack, double tap (tap your index finger and thumb together twice) to complete the task it shows. Double tap needs Apple Watch Series 9, Apple Watch Ultra 2, or later.

### URL scheme {#url-scheme}

You can control One Task from other apps and tools, like Shortcuts and Raycast:

- `one-task://add?title=Buy%20milk` adds a task. Each line of the title becomes a task.
- `one-task://add?title=Buy%20milk&position=top` adds the task at the top of the list, where the widget shows it by default.
- `one-task://add` opens the app with the new task field focused.
- `one-task://focus` opens Focus mode. On Apple Vision Pro, it opens the single task window.

In the title, write a space as `%20` or `+`, and a plus sign as `%2B`.

## Frequently Asked Questions {#faq}

### How is this different from your One Thing app? {#one-thing-difference}

[One Thing](/one-thing) is a minimalist note app that sits in the menu bar, displaying a single piece of text like a sticky note. In contrast, One Task is a task management tool that lets you queue multiple tasks, check them off upon completion, and view them one at a time, with a strong emphasis on widgets. While both apps share a focus on simplicity, One Thing is designed for quick, single-note access, whereas One Task is geared towards managing multiple tasks with a more structured approach, similar to the difference between the Notes app and Reminders app.

### iCloud syncing does not work {#icloud-syncing-does-not-work}

[Troubleshooting.](/apps/faq#icloud-sync)

Known issue:
- Because of a macOS bug, the macOS app does not sync with iCloud while it’s focused.

### How can I rename a task? {#how-can-i-rename-a-task}

Swipe right on the task and choose “Rename…”.

On macOS, you can also right-click the task.

### Does the app integrate with other todo apps? {#does-the-app-integrate-with-other-todo-apps}

No, One Task deliberately avoids automatic integration with other todo apps. Most todo apps encourage task hoarding, leading to overwhelm and inaction. One Task focuses on actionable items you commit to completing within the day. Manually select your highest-priority tasks and add them to One Task for focused execution.

### Does the app support recurring tasks? {#recurring-tasks}

No. I want to keep this app super simple.

However, you can achieve this using the Shortcuts app. Create a [shortcut](https://support.apple.com/guide/shortcuts/welcome/ios) that uses the “Add Task” action to add the tasks you want to be recurring. Then create an [automation](https://support.apple.com/guide/shortcuts/apdfbdbd7123/ios) to run the shortcut at a certain interval. For example, every morning.

### Does the app support task templates? {#task-templates}

No, but you can achieve this using the Shortcuts app. Modify the [task template shortcut](https://www.icloud.com/shortcuts/51edae78b820457a89d12715a053fac6) and run it every time you want to apply the template tasks. You could even add the shortcut to the Home Screen.

### Why doesn’t the app have folders, tags, or priorities? {#why-doesnt-the-app-have-folders-tags-or-priorities}

One Task is designed for action, not endless categorization. It omits features like folders, tags, and priorities to eliminate distractions and decision fatigue. The app’s core functionality is to help you commit to and complete tasks today.

### How can I turn off iCloud syncing? {#turn-off-sync}

- **macOS:** Go to “System Settings › Apple Account › iCloud › Saved to iCloud” and turn off One Task.
- **iOS:** Go to “Settings › Apple Account › iCloud › Saved to iCloud” and turn off One Task.

It will erase your existing items, so you may want to first back them up with the “Copy” button in the “All Tasks” section of the “…” menu.

### Can you add a widget setting to choose background color? {#can-you-add-a-widget-setting-to-choose-background-color}

I don’t plan to add this. I want to keep the app super simple.

### Can I choose any color for the menu bar text on macOS? {#menu-bar-text-color}

The picker only offers system colors, not a freeform color. System colors automatically adapt to stay readable on both light and dark menu bars, while a fixed custom color could become unreadable when the menu bar background changes, for example with a dynamic wallpaper or when switching between light and dark mode.

### The text in the widget is quite large {#the-text-in-the-widget-is-quite-large}

The text automatically scales down to fit more content.
