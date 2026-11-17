---
title: 'How to Change the Default Browser Automatically on Mac'
description: 'Use one browser for work and another at home: a Shortcuts automation sets the default browser with Default Browser when your Mac joins the office Wi-Fi.'
publicationDate: 2026-11-23
topic: 'browsers-links-and-email'
apps: [
	'default-browser'
]
---

@QuickAnswer {
	Install [Default Browser](/default-browser), and make a Shortcuts automation that runs its “Set Default Browser” action, like when your Mac joins the Wi-Fi of your office. macOS does not ask you to confirm the change. [Without an app](#without-an-app), you change the browser by hand in System Settings.
}

## With Default Browser

On macOS 26 and later, the Shortcuts app can run a shortcut when something happens on your Mac, like when it joins a Wi-Fi network, or at a time of day. <source:https://support.apple.com/125148>

@Steps {
1. Install [Default Browser](/default-browser), and open it one time.
1. In the Shortcuts app, make a shortcut with the “Set Default Browser” action of Default Browser, and choose the browser for work, like Chrome.
1. Make a second shortcut that sets the other browser, like Safari.
1. Add an automation with the “Wi-Fi” trigger for the network of your office. Choose the first shortcut.
1. Add one more automation, like at 17:00 on weekdays (“Time of Day”), and choose the second shortcut.
}

Default Browser changes the browser without the confirmation of macOS, so the automation runs without you. You can also switch the browser from the menu bar of Default Browser, or with a keyboard shortcut.

@Tips {
- The “App” trigger can set a browser when an app opens, like your work chat app.
- Default Browser also has a Focus Filter, but Focus Filters do not work on macOS 26.5 and later, because of a bug in macOS.
- To choose the browser for each link, not for all links, use [Velja](/velja). [How to open links in a specific browser.](guide:open-links-in-specific-browser-mac)
}

## Without an app

macOS has no setting that changes the default browser by itself, and Shortcuts has no action for it. Change it by hand:

@Steps {
1. Open “[System Settings › Desktop & Dock](x-apple.systempreferences:com.apple.Desktop-Settings.extension)”.
1. Choose the browser in “Default web browser”.
}

This is enough if you change the browser now and then. [More ways to change the default browser.](guide:change-default-browser-mac)
