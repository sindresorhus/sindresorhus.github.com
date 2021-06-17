---
title: Lungo
subtitle: Prevent your Mac from going to sleep
description: Lungo is a macOS app that prevents your Mac from falling asleep and your screen from dimming.
type: macOS
date: 2017-07-26
app_store_app_id: 1263070803
mac_app_store_url: https://apps.apple.com/app/id1263070803
setapp_url: https://go.setapp.com/stp181?_target=https://setapp.com/apps/lungo
---

<br>

### Older versions

- [Last macOS 10.14 compatible version (free).](https://github.com/sindresorhus/meta/files/5507155/Lungo-1-7-0.zip)
- [Last macOS 10.13 compatible version (free).](https://github.com/sindresorhus/meta/files/4556911/Lungo-1.6.0-High-Sierra.zip)

*(These builds will not run on newer macOS versions)*

<br>

<h3 id="faq">Frequently Asked Questions</h3>

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback/?product=Lungo&referrer=Website-FAQ)

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1263070803) and click “Version History”.

<a id="lid-closed"></a>
#### Does it work when the lid is closed?

No, that’s not allowed for apps on the App Store, for good reasons. Imagine you activate it while your computer is doing a heavy task and then put the laptop in your bag. Your laptop could easily overheat.

However, if you really want this, there are some solutions [here](https://apple.stackexchange.com/questions/2389/is-there-any-way-to-set-a-macbook-pro-to-not-sleep-when-you-close-the-lid?rq=1).

#### Does Lungo keep my Mac awake even if there is a scheduled sleep?

If you have set a sleep schedule in “System Preferences › Battery › Schedule”, it will take priority over Lungo. This is out of Lungo‘s control.

#### Can I left-click the icon to toggle it like with Caffeine?

Yes, choose “Activate on Left-click” in the preferences.

#### Can you localize the app into my language?

I don't have any immediate plans to localize the app.

####  How is it different from Amphetamine?

Amphetamine has lots of features. Most of which I would never use. It ships with a myriad of menu bar icons to choose from, but none that looks good. With Lungo, I wanted a focused and simple app with great defaults.

<h3 id="scripting">Scripting</h3>

You can control Lungo using anything that supports opening a URL with a custom scheme.

For example, to activate Lungo for 10 minutes, run this terminal command:

```
$ open -g 'lungo:activate?minutes=10'
```

#### Commands

- `activate`
- `deactivate`
- `toggle`

The `activate` and `toggle` commands support the parameters `hours` and `minutes`, which can be used together or individually. If you don't specify a duration, it will use the default duration you have set in Lungo.

#### Tools

- [lungo-cli](https://github.com/sindresorhus/lungo-cli) - Command-line tool.

#### Examples

##### Shell

```
# Deactivate Lungo
$ open -g 'lungo:deactivate'

# Activate Lungo for 1 hours and 30 minutes
$ open -g 'lungo:activate?hours=1&minutes=30'

# Activate Lungo for 1 hours and 30 minutes (Alternative)
$ open -g 'lungo:activate?hours=1.5'

# Toggle Lungo with the default duration
$ open -g 'lungo:toggle'

# Toggle Lungo for 10 minutes
$ open -g 'lungo:toggle?minutes=10'
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
