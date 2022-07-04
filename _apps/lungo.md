---
title: Lungo
subtitle: Prevent your Mac from going to sleep
description: Lungo is a macOS app that prevents your Mac from falling asleep and your screen from dimming.
date: 2017-07-26
platforms:
  - macOS
is_paid: true
app_store_app_id: 1263070803
mac_app_store_url: https://apps.apple.com/app/id1263070803
setapp_url: https://go.setapp.com/stp181?_target=https://setapp.com/apps/lungo
---

<br>

### Older versions

- [Last macOS 11 compatible version (free)](https://github.com/sindresorhus/meta/files/8870132/Lungo.2.0.4.-.macOS.11.zip) *(2.0.4)*
- [Last macOS 10.15 compatible version (free)](https://github.com/sindresorhus/meta/files/7404362/Lungo.1.9.0.-.macOS.10.15.zip) *(1.9.0)*
- [Last macOS 10.14 compatible version (free)](https://github.com/sindresorhus/meta/files/5507155/Lungo-1-7-0.zip) *(1.7.0)*
- [Last macOS 10.13 compatible version (free)](https://github.com/sindresorhus/meta/files/4556911/Lungo-1.6.0-High-Sierra.zip) *(1.6.0)*

*(These builds will not run on newer macOS versions)*

<br>

<h3 id="faq">Frequently Asked Questions</h3>

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback/?product=Lungo&referrer=Website-FAQ)

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some menu bar apps to free up space. If this does not solve it, try quitting Bartender if you have it installed.

#### Lungo did not keep my computer awake

- If you have the “Allow display to sleep while keeping computer awake” setting enabled, the computer is still awake even if it looks like it's sleeping because the screen is off.
- If you have the “Pause while screen is locked” setting enabled, you may have locked the screen before leaving it, which would cause Lungo to not keep your computer awake.
- If you have the “Deactive when switching to battery” setting enabled and you disconnect the power adapater, Lungo would not keep your computer awake. You might have accidentally unplugged it or there might have been a power failure.
- If you have set a sleep schedule in “System Preferences › Battery › Schedule”, it will take priority over Lungo. This is out of Lungo's control.
- If you see apps open again when you wake up your computer, it means your computer was restarted for some reason. Lungo cannot keep your computer from restarting. Some common reason it may have restarted are: Power outage, macOS crashed, or scheduled shutdown/restart (in Battery system settings).
  + You can [check how long your computer has been awake and when it was last rebooted](https://www.macobserver.com/tips/quick-tip/mac-system-uptime-terminal/) to narrow down the problem.

Some things you could try:
- Make sure you are on the latest macOS and Lungo version.
- [Reset NVRAM](https://support.apple.com/en-us/HT204063)
- [Reset SMC](https://support.apple.com/en-us/HT201295)

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1263070803) and click “Version History”.

<a id="lid-closed"></a>
#### Does it work when the lid is closed?

No, that’s not allowed for apps on the App Store, for good reasons. Imagine you activate it while your computer is doing a heavy task and then put the laptop in your bag. Your laptop could easily overheat.

However, if you really want this, there are some solutions [here](https://apple.stackexchange.com/questions/2389/is-there-any-way-to-set-a-macbook-pro-to-not-sleep-when-you-close-the-lid?rq=1).

#### Does Lungo keep my Mac awake even if there is a scheduled sleep?

If you have set a sleep schedule in “System Preferences › Battery › Schedule”, it will take priority over Lungo. This is out of Lungo's control.

#### Can I left-click the icon to toggle it like with Caffeine?

Yes, choose “Activate on Left-click” in the preferences.

<a id="custom-duration"></a>
#### Can I use a custom duration?

Lungo comes with a set of commonly used durations, which should be enough for most users. People love Lungo for its simplicity. Lungo has tens of thousands of users and only a few people have requested a custom duration. However, power users can take advantage of the Shortcuts app to use custom durations. Drag the the “Set Enabled State” Lungo action into the shortcut editor in the Shortcuts app. Click “Show more” and then choose a custom duration. You can pin the shortcut workflow to the menu bar for easy access or set a global keyboard shortcut for it.

#### Can you localize the app into my language?

I don't have any immediate plans to localize the app.

#### How is it different from Amphetamine?

Amphetamine has lots of features. Most of which I would never use. It ships with a myriad of menu bar icons to choose from, but none that looks good. With Lungo, I wanted a focused and simple app with great defaults.

<h3 id="scripting">Scripting</h3>

You can control Lungo using anything that supports opening a URL with a custom scheme.

*Lungo also comes with support for Shortcuts.*

Tip: You can [run shortcuts from the command-line](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac).

#### Integrations

- [lungo-cli](https://github.com/sindresorhus/lungo-cli) - Command-line tool.
- [Raycast commands](https://github.com/raycast/script-commands/tree/master/commands#lungo)

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

# Activate Lungo for 1 hours and 30 minutes
open --background 'lungo:activate?hours=1&minutes=30'

# Activate Lungo for 1 hours and 30 minutes (Alternative)
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
