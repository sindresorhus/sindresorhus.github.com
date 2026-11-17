---
title: 'How to Get the URL of the Current Browser Tab in Shortcuts on Mac'
description: 'Get the URL and title of the active tab in Chrome, Arc, Brave, Edge, Safari, and other browsers in a shortcut, with Shortcutie or with AppleScript.'
publicationDate: 2026-11-23
topic: 'shortcuts'
apps: [
	'shortcutie'
]
---

@QuickAnswer {
	Add the “Get Active Browser Tab” action of [Shortcutie](/shortcutie). It returns the URL and the title of the active tab of your default browser, or of the browser that you choose. [Without an app](#without-an-app), use the “Get Current Web Page from Safari” action for Safari, or AppleScript for Chrome.
}

## With Shortcutie

@Steps {
1. Install [Shortcutie](/shortcutie), and open it once.
1. In your shortcut, add the “Get Active Browser Tab” action of Shortcutie.
1. Leave the browser empty to use your default browser, or click it and choose a browser.
1. Use the result, “Browser Tab”, in the next action. Click it, and choose “URL” or “Title”.
1. Run the shortcut. The first time, macOS asks if Shortcutie can control the browser. Click “Allow”.
}

It works with Safari, Chrome, Edge, Brave, Opera, Vivaldi, Arc, Orion, Atlas, and other browsers that are made on Chromium. It does not work with Firefox and the browsers made on it, like Zen, or with the DuckDuckGo browser.

@Tips {
- To use the browser in front, not the default browser, put the “Get Active Browser” action before it.
- To run JavaScript on the page of the tab, use the “Run JavaScript on Active Browser Tab” action.
}

## Without an app

For Safari, the Shortcuts app on Mac has the “Get Current Web Page from Safari” action.

For Chrome, add the “Run AppleScript” action, and replace its text with:

```applescript
tell application "Google Chrome" to return URL of active tab of front window
```

If the shortcut cannot run the script, choose “Shortcuts › Settings”, click “Advanced”, and turn on “Allow Running Scripts”. For another browser made on Chromium, change the name of the app, like `"Brave Browser"`. You need one script for each browser. Shortcutie uses your default browser, and gives the title too.
