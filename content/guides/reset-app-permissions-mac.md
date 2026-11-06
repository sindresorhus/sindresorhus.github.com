---
title: 'How to Reset the Privacy Permissions of an App on Mac'
description: 'Make an app ask again for the camera, the microphone, or screen recording. Reset its permissions with Supercharge, or with a command in Terminal.'
publicationDate: 2026-11-11
topic: 'mac'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	System Settings can turn a permission off, but it cannot make an app ask again. In the “Tools” settings of [Supercharge](../apps/supercharge/index.md), click “Choose App…” below “Reset privacy permissions for any apps”. Without an app, run `tccutil reset All` with the bundle identifier of the app in Terminal.
}

A reset helps when an app does not ask for a permission, when a permission is on but does not work, like screen recording after an update, or when you clicked “Don’t Allow” by mistake.

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](../apps/supercharge/index.md), and click “Tools”.
1. Below “Reset privacy permissions for any apps”, click “Choose App…”.
1. Choose the app.
1. If the app was open, Supercharge quits it and opens it again. The app asks for each permission when it needs it.
}

This resets all the privacy permissions of that app, like the camera, the microphone, screen recording, and accessibility. It does not reset the Local Network permission, as macOS has no command for it.

## Without an app

macOS has the `tccutil` command. It needs the bundle identifier of the app, which you get with the first command. Quit the app first.

```console
osascript -e 'id of app "Slack"'
tccutil reset All com.tinyspeck.slackmacgap
```

To reset only one permission, write its name in place of `All`, like `Camera`, `Microphone`, `ScreenCapture`, or `Accessibility`. Be careful: without a bundle identifier, like `tccutil reset Camera`, the command resets that permission for all apps.

To only turn a permission on or off, open “[System Settings › Privacy & Security](x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension)”, and click the permission. [Apple’s instructions.](https://support.apple.com/guide/mac-help/mchl211c911f/mac)

Terminal is fine when you know the bundle identifier. Supercharge does the same for the app that you pick, without the commands.
