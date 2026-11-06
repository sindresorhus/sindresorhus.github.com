---
title: 'How to Restore Minimized Windows with Command+Tab on Mac'
description: 'Command+Tab leaves the minimized windows of an app in the Dock. Supercharge brings them back when you switch to the app.'
publicationDate: 2026-11-10
topic: 'windows-apps-and-dock'
isForWindowsUsers: true
apps: [
	'supercharge'
]
---

@QuickAnswer {
	When you switch to an app with ++Command+Tab++, its minimized windows stay in the Dock, so you see no window. Click the window in the Dock to get it back. [Supercharge](../apps/supercharge/index.md) brings the windows back when the app becomes active.
}

## With Supercharge

@Steps {
1. Open [Supercharge](../apps/supercharge/index.md), and give it the access that it asks for in [“Device Control and Data Access”](/apps/faq#device-control-access).
1. Open the Supercharge settings, and click “Tweaks”.
1. In the “Apps & Windows” section, set “Unminimize windows when app becomes active” to “All Windows”, “All Windows (only if all minimized)”, or “One Window (only if all minimized)”.
1. Minimize all the windows of an app, switch to another app, and switch back with ++Command+Tab++. The windows come back.
}

It works for all the ways to switch apps, not only ++Command+Tab++. Because of limits in macOS, it cannot bring back windows in other spaces or fullscreen windows.

## Without an app

- **Dock:** Click the minimized window on the right side of the Dock.
- **Window menu:** Switch to the app, open the “Window” menu, and choose the window. Minimized windows have a diamond next to their name.

These work for one window at a time. Supercharge is for when you minimize windows often and expect them back when you switch to the app.
