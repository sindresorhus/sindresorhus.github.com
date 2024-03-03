---
title: Lungo
subtitle: Prevent your Mac from going to sleep
pubDate: 2017-07-26
platforms:
  - macOS
isPaid: true
isMenuBarApp: true
appStoreId: 1263070803
setappId: 270
olderMacOSVersions:
  - '10.13'
  - '10.14'
  - '10.15'
  - '11'
  - '12'
  - '13'
---

Lungo prevents your Mac from falling asleep and your screen from dimming.

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Lungo&referrer=Website-FAQ)

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some other menu bar apps to free up space. If this does not solve it, try quitting Bartender if you have it installed.

#### Lungo did not keep my computer awake

- If you have the “Allow display to sleep while keeping computer awake” setting enabled, the computer is still awake even if it looks like it's sleeping because the screen is off.
- If you close the lid (clamshell mode), Lungo is only able to keep your Mac awake if it's connected to a charger and an external display. This is a macOS limitation.
- If you have the “Pause while screen is locked” setting enabled, you may have locked the screen before leaving it, which would cause Lungo to not keep your computer awake.
- If you have the “Deactive when switching to battery” setting enabled and you disconnect the power adapter, Lungo would not keep your computer awake. You might have accidentally unplugged it or there might have been a power failure.
- If you have set a sleep schedule in “System Preferences › Battery › Schedule”, it will take priority over Lungo. This is out of Lungo's control.
- If you have set the computer to log out after a certain amount of time in “System Preferences › Security & Privacy › Advanced”, it will take priority over Lungo. This is out of Lungo's control.
- If you see apps open again when you wake up your computer, it means your computer was restarted for some reason. Lungo cannot keep your computer from restarting. Some common reasons it may have restarted are a power outage, macOS crash, or scheduled shutdown/restart (in Battery system settings).
	+ You can [check how long your computer has been awake and when it was last rebooted](https://www.macobserver.com/tips/quick-tip/mac-system-uptime-terminal/) to narrow down the problem. You can also check when the computer was last logged in by typing the command `last` in the Terminal app.

Some things you could try:
- Make sure you are on the latest macOS and Lungo versions.
- [Reset NVRAM](https://support.apple.com/en-us/HT204063)
- [Reset SMC](https://support.apple.com/en-us/HT201295)

#### Does it work when the lid is closed? {#lid-closed}

No, that’s not allowed for apps on the App Store, for good reasons. Imagine you activate it while your computer is doing a heavy task and then put the laptop in your bag. Your laptop could easily overheat.

The exception to this is if it's connected to a charger and an external display.

However, if you want this, there are some solutions [here](https://apple.stackexchange.com/questions/2389/is-there-any-way-to-set-a-macbook-pro-to-not-sleep-when-you-close-the-lid?rq=1).

#### Does Lungo keep my Mac awake even if there is a scheduled sleep?

If you have set a sleep schedule in “System Preferences › Battery › Schedule”, it will take priority over Lungo. This is out of Lungo's control.

#### Can I left-click the icon to toggle it like with Caffeine?

Yes, choose “Activate on Left-click” in the settings.

#### Can Lungo automatically activate when I open a certain app?

I don't plan to support this. It's a lot of work to implement and only a few people have requested it.

However, you can achieve it using the Shortcuts app. Create a new shortcut with the “Set Enabled State” action provided by Lungo. Shortcuts on iOS has automations, which lets you run a shortcut when a certain app opens. macOS does not yet have automations. I'm confident it will come with macOS 15. In the meantime, you can use the [Shortery app](https://apps.apple.com/us/app/shortery/id1594183810?mt=12) to run a shortcut when a certain app opens.

You could also use BetterTouchTool or Keyboard Maestro instead of Shortery.

#### Can Lungo automatically activate on a set schedule?

I don't plan to do this built-in, but you can use Shortery for this as explained above. Shortery has a “Time” trigger.

#### Can Lungo automatically activate when I switch to a specific focus mode?

I don't plan to do this built-in, but you can use Shortery for this as explained above. Shortery has a “Focus Mode” trigger.

#### Can I use a custom duration? {#custom-duration}

Lungo comes with a set of commonly used durations, which should be enough for most users. People love Lungo for its simplicity. Not having custom times also helps prevent decision fatigue. Lungo has tens of thousands of users and the app has existed for 6 years, and only a few people have requested support for custom durations.

However, power users can take advantage of the Shortcuts app to use custom durations. Drag the “Set Enabled State” Lungo action into the shortcut editor in the Shortcuts app. Click “Show more” and then choose a custom duration. You can pin the shortcut workflow to the menu bar for easy access or set a global keyboard shortcut for it.

#### Can it keep my status on Slack, Microsoft Teams, etc, show as active?

No, that's not the purpose of this app. Different apps use different techniques for detecting active status, which could change at any time.

#### How can I export, import, sync, or back up the settings?

[See this guide.](https://github.com/sindresorhus/guides/blob/main/backup-app-settings.md)

#### How can I transfer my settings from the App Store version to the Setapp version?

Run this command in the Terminal app:

```sh
defaults export com.sindresorhus.Lungo - | defaults import com.sindresorhus.Lungo-setapp -
```

And to transfer the other way:

```sh
defaults export com.sindresorhus.Lungo-setapp - | defaults import com.sindresorhus.Lungo -
```

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1263070803) and click “Version History”.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### How is it different from Amphetamine?

Amphetamine has lots of features. Most of which I would never use. It ships with a myriad of menu bar icons to choose from, but none that looks good. With Lungo, I wanted a focused and simple app with great defaults.

#### [More FAQs…](/apps/faq)

### Scripting

You can control Lungo using anything that supports opening a URL with a custom scheme.

*Lungo also comes with support for Shortcuts.*

Tip: You can [run shortcuts from the command-line](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac).

#### Integrations

- [lungo-cli](https://github.com/sindresorhus/lungo-cli) - Command-line tool.
- [Raycast commands](https://github.com/raycast/script-commands/tree/master/commands#lungo)
	- Note: Raycast commands are not the same as plugins. [How to install commands.](https://github.com/raycast/script-commands#install-script-commands-from-this-repository)

#### Custom URL scheme

For example, to activate Lungo for 10 minutes, run this terminal command:

```sh
open --background 'lungo:activate?minutes=10'
```

#### Commands

- `activate`
- `deactivate`
- `toggle`

The `activate` and `toggle` commands support the parameters `hours` and `minutes`, which can be used together or individually. If you don't specify a duration, it will use the default duration you have set in Lungo.

*(Use [`lungo-cli`](https://github.com/sindresorhus/lungo-cli) if you need to get the active state)*

#### Examples

##### Shell

```sh
# Deactivate Lungo
open --background 'lungo:deactivate'

# Activate Lungo for 1 hour and 30 minutes
open --background 'lungo:activate?hours=1&minutes=30'

# Activate Lungo for 1 hour and 30 minutes (Alternative)
open --background 'lungo:activate?hours=1.5'

# Toggle Lungo with the default duration
open --background 'lungo:toggle'

# Toggle Lungo for 10 minutes
open --background 'lungo:toggle?minutes=10'
```

##### Node.js

```js
import {execFileSync} from 'node:child_process';

execFileSync('open', ['--background', 'lungo:toggle']);
```

##### Swift

```swift
import Cocoa

let command = "lungo:toggle"

let configuration = NSWorkspace.OpenConfiguration()
configuration.activates = false
NSWorkspace.shared.open(URL(string: command)!, configuration: configuration)
```

##### AppleScript

```applescript
do shell script "open --background 'lungo:toggle'"
```

##### Python

```python
import subprocess

subprocess.run(['open', '--background', 'lungo:toggle'])
```

<br>

### Older Versions

- [2.4.2](https://github.com/sindresorhus/meta/files/14276605/Lungo.2.4.2.-.macOS.13.zip) for macOS 13
- [2.2.2](https://github.com/sindresorhus/meta/files/11292407/Lungo.2.2.2.-.macOS.12.zip) for macOS 12
- [2.0.4](https://github.com/sindresorhus/meta/files/8870132/Lungo.2.0.4.-.macOS.11.zip) for macOS 11
- [1.9.0](https://github.com/sindresorhus/meta/files/7404362/Lungo.1.9.0.-.macOS.10.15.zip) for macOS 10.15
- [1.7.0](https://github.com/sindresorhus/meta/files/5507155/Lungo-1-7-0.zip) for macOS 10.14
- [1.6.0](https://github.com/sindresorhus/meta/files/4556911/Lungo-1.6.0-High-Sierra.zip) for macOS 10.13

These are free for everyone but they will not run on newer macOS versions.
