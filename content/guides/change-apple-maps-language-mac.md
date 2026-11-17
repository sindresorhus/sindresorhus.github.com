---
title: 'How to Change the Language of Apple Maps on Mac'
description: 'macOS does not let you choose a language for the Maps app. Supercharge sets one, like English, without a change to the language of your Mac.'
publicationDate: 2026-11-21
topic: 'mac'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	In the settings of [Supercharge](/supercharge), choose a language in “Override Maps app language”, like English. Maps then shows its menus and search results in that language. macOS has a language setting for each app, but not for Maps. [Without an app](#without-an-app), you use a Terminal command.
}

This is good when you travel or live in a country with another language, as search in Maps can work better in the language of the place, or in your own language.

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](/supercharge), and click “Tweaks”.
1. In the “Maps” section, choose the language in “Override Maps app language”.
1. Supercharge needs Full Disk Access to change the settings of Maps. Give it the access when it asks.
1. If Maps is open, restart it when Supercharge asks.
}

To use the language of your Mac again, choose “System Default”. The menu shows only the languages that Maps has.

## Without an app

In “[System Settings › General › Language & Region](x-apple.systempreferences:com.apple.Localization-Settings.extension)”, the “Applications” list lets you choose a language for most apps, but not for Maps. Use a Terminal command:

@Steps {
1. Give Terminal Full Disk Access in “[System Settings › Privacy & Security › Full Disk Access](x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles)”, as the settings of Maps are protected.
1. Quit Maps.
1. In Terminal, run this command, with the code of the language at the end, like `en` for English or `ja` for Japanese:
}

```console
defaults write com.apple.Maps AppleLanguages -array en
```

To use the language of your Mac again, run:

```console
defaults delete com.apple.Maps AppleLanguages
```

You can also change the primary language of the whole Mac in “Language & Region”, but then all apps change.
