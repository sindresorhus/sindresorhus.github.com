---
title: 'How to Use Caps Lock as a Hyper Key on Mac'
description: 'Make Caps Lock press Control, Option, Shift, and Command at the same time with Supercharge, for keyboard shortcuts that no other app uses.'
publicationDate: 2026-11-06
topic: 'keyboard-and-trackpad'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	In the settings of [Supercharge](../apps/supercharge/index.md), turn on “Caps Lock as Hyper key”. Then ++Caps Lock++ presses ++Control+Option+Shift+Command++ together. macOS can only make Caps Lock one other modifier key, like ++Control++, not all four.
}

A Hyper key is one key that presses all four modifier keys. A shortcut with it, like ++Caps Lock+T++, is easy to press, and almost no app uses ++Control+Option+Shift+Command+T++, so it does not conflict with the shortcuts of your apps.

## With Supercharge

@Steps {
1. Open [Supercharge](../apps/supercharge/index.md), and give it the access that it asks for in [“Device Control and Data Access”](/apps/faq#device-control-access).
1. Open the Supercharge settings, and click “Tweaks”.
1. In the Experimental section, turn on “Caps Lock as Hyper key”. You can also search for “hyper” in the settings.
1. In any app that lets you record a keyboard shortcut, like a launcher or the Shortcuts app, hold ++Caps Lock++, and press a key.
}

The Hyper key is simple on purpose: a short press of ++Caps Lock++ does not type Escape, and there is no way to use ++Caps Lock++ as a normal Caps Lock while it is on. If you need that, the [Hyperkey](https://hyperkey.app) app has more options.

## Without an app

macOS can make ++Caps Lock++ another key, but only one:

@Steps {
1. Open “[System Settings › Keyboard](x-apple.systempreferences:com.apple.Keyboard-Settings.extension)”, and click “Keyboard Shortcuts…”.
1. Choose “Modifier Keys”.
1. For “Caps Lock key”, choose another key, like “Control” or “Escape”, and click “Done”.
}

This is good when you want ++Caps Lock++ as ++Control++ or ++Esc++. For shortcuts that never conflict, you need all four keys together, which macOS cannot do with one key.
