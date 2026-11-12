---
title: 'How to Check the Battery Cycle Count and Health on MacBook'
description: 'See the cycle count, the health, and the condition of the battery in the menu bar with Battery Indicator, or in System Settings and System Information.'
publicationDate: 2026-11-12
topic: 'menu-bar'
apps: [
	'battery-indicator'
]
---

@QuickAnswer {
	Click the icon of [Battery Indicator](../apps/battery-indicator/index.md) in the menu bar, and hold ++Option++. The menu shows the condition, the health, and the cycle count of the battery. Without an app, the condition is in “[System Settings › Battery](x-apple.systempreferences:com.apple.Battery-Settings.extension)”, and the cycle count is in System Information.
}

## With Battery Indicator

@Steps {
1. Open [Battery Indicator](../apps/battery-indicator/index.md). Its icon is in the menu bar.
1. Click the icon, and hold ++Option++. The menu shows “Condition”, “Health” (a percentage), and “Cycle Count”.
1. To always see them without ++Option++, click the “…” button at the bottom of the menu, choose “Settings…”, and turn on “Show advanced info by default”.
}

The health is the maximum capacity of the battery, compared to when it was new. It is the same value as “Maximum Capacity” in System Information, but System Information can keep an older, lower value for some time after the battery recalibrates.

@Tips {
- The “Get Battery Details” action of Battery Indicator in the Shortcuts app gives the health and the condition of the battery.
- Battery Indicator also shows the time remaining when you move the pointer over its icon in the menu bar. [How to show the battery time remaining.](show-battery-time-remaining-mac.md)
}

## Without an app

macOS shows the condition and the cycle count in two places:

@Steps {
1. Open “[System Settings › Battery](x-apple.systempreferences:com.apple.Battery-Settings.extension)”. “Battery Health” shows “Normal”, or “Service Recommended” when the battery holds less charge than when it was new.
1. To see the cycle count, hold ++Option++, and choose “System Information…” in the Apple menu.
1. Select “Power” in the sidebar. The cycle count is in the “Battery Information” section.
}

Apple has a list of the maximum cycle count of each Mac model. [Apple: Determine battery cycle count for Mac laptops](https://support.apple.com/102888)

For one check, this is enough. Battery Indicator is for when you want the three values one click away, next to the time remaining.
