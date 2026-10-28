---
title: 'UTC Time'
subtitle: 'Show the time in UTC in the menu bar or a widget'
publicationDate: 2021-03-16
platforms: [
	'macOS'
]
isMenuBarApp: true
appStoreID: 1538245904
hasSentry: true
nonAppStoreVersion: {
	version: '1.11.0'
	macOS: 26
	url: 'https://www.dropbox.com/scl/fi/t98b3p4kebmb7hrmahms4/UTC-Time-1.11.0-1769179922.zip?rlkey=2i3xk1wm2okqh1237rfkbuj3t&raw=1'
}
sharedQuestions: [
	'blurry-secondary-display'
]
olderVersions: [
	{
		version: '1.10.0'
		macOS: '15'
		url: 'https://www.dropbox.com/scl/fi/oj2tobls8f2dtotzo5u0j/UTC-Time-1.10.0-macOS-15-1769181410.zip?rlkey=3snz635x894dx95ngar8tns6p&raw=1'
	}
	{
		version: '1.9.1'
		macOS: '14'
		url: 'https://github.com/user-attachments/files/18215312/UTC.Time.1.9.1.-.macOS.14.zip'
	}
	{
		version: '1.7.1'
		macOS: '13'
		url: 'https://github.com/sindresorhus/meta/files/13973570/UTC.Time.1.7.1.-.macOS.13.zip'
	}
	{
		version: '1.5.1'
		macOS: '12'
		url: 'https://github.com/sindresorhus/meta/files/10767291/UTC.Time.1.5.1.-.macOS.12.zip'
	}
	{
		version: '1.3.0'
		macOS: '11'
		url: 'https://github.com/sindresorhus/meta/files/8007477/UTC.Time.1.3.0.-.macOS.11.zip'
	}
]
pressQuotes: [
	{
		quote: 'With UTC Time, Sorhus has now released his latest app on the Mac App Store, which is likely to serve a small niche of users. The menu bar item shows Coordinated Universal Time in the Mac menu bar on request.'
		source: 'ifun.de'
		translatedFrom: 'German'
		url: 'https://www.ifun.de/utc-time-die-koordinierte-weltzeit-in-der-mac-menueleiste-168380/'
		year: 2021
	}
]
---

See the time in UTC at a glance, in your menu bar or a widget. Useful when you work with servers, logs, or people in many time zones.

Copy the time from the menu as ISO 8601 time, ISO 8601 date and time, or Unix time in seconds or milliseconds. You can also get the time with the “Get Time and Date in UTC” action in the Shortcuts app.

## Frequently Asked Questions {#faq}

### Can you localize the app into my language? {#can-you-localize-the-app-into-my-language}

The date & time output adheres to your locale settings. I don’t plan to localize the app itself.

### Can you add an analog clock? {#can-you-add-an-analog-clock}

I have no plans to add that.

### Can you add support for other time zones? {#can-you-add-support-for-other-time-zones}

That is outside the scope of this app, but check out my [Zone Bar](/zone-bar) app, which shows many world clocks in the menu bar. My [Second Clock](/second-clock) and [Dato](/dato) apps also support this.

### How can I customize the menu bar date and time format? {#how-can-i-customize-the-menu-bar-date-and-time-format}

In the settings, you can show or hide the date, the day of the week, and the “UTC” text. If your Mac uses 12-hour time, you can also turn on 24-hour time. For a fully custom format, use [Dato](/dato).

### Can it show seconds in the clock? {#can-it-show-seconds-in-the-clock}

I don’t plan to add this. Showing seconds wastes a lot of system resources and energy as macOS is very inefficient at rendering updates in the menu bar. Instead, just enable seconds in the system clock.
