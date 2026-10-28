---
title: 'Second Clock'
subtitle: 'Show a second clock for a different time zone in your menu bar'
publicationDate: 2024-01-04
platforms: [
	'macOS'
]
isMenuBarApp: true
appStoreID: 6450279539
nonAppStoreVersion: {
	version: '1.2.0'
	macOS: 26
	url: 'https://www.dropbox.com/scl/fi/9a20p7mo6bdw45xqzl1a8/Second-Clock-1.2.0-1774271996.zip?rlkey=udacl6dtg5apz9guctolox1tu&raw=1'
}
sharedQuestions: [
	'blurry-secondary-display'
]
olderVersions: [
	{
		version: '1.1.0'
		macOS: '15'
		url: 'https://www.dropbox.com/scl/fi/8q5rzafvwh8h38nw162m8/Second-Clock-1.1.0-macOS-15-1774272407.zip?rlkey=3m3t78o84kfaaaxv9khdscuii&raw=1'
	}
	{
		version: '1.0.2'
		macOS: '14'
		url: 'https://github.com/user-attachments/files/18694293/Second.Clock.1.0.2.-.macOS.14.zip'
	}
]
pressQuotes: [
	{
		quote: 'The app’s core job is to show a second clock in the Mac menu bar. It is aimed primarily at users who have to communicate with colleagues, clients, family, or friends in other time zones and want to see at a glance (without doing the math) what time it is there.'
		source: 'ifun.de'
		translatedFrom: 'German'
		url: 'https://www.ifun.de/kostenfreie-mac-helfer-second-clock-und-widgettoggler-225199/'
		year: 2024
	}
]
---

The clock sits next to the system clock, so you always know the time for colleagues, family, or servers in another time zone.

The app is simple by design.

Check out [Zone Bar](/zone-bar) if you need more than one extra clock, [Dato](/dato) for more features and settings, or [UTC Time](/utc-time) if you just need the time in UTC.

## Frequently Asked Questions {#faq}

### Can it show a flag in front of the time? {#can-it-show-a-flag-in-front-of-the-time}

You can set a [flag emoji](https://emojipedia.org/flags) in the “Prefix text” setting. [Example.](https://x.com/sindresorhus/status/1742975880031543330)

### Can it show an icon in front of the time? {#can-it-show-an-icon-in-front-of-the-time}

You can set a [Unicode character](https://www.vertex42.com/ExcelTips/unicode-symbols.html) or SF Symbol in the “Prefix text” setting.

For an SF Symbol, download the [SF Symbols app](https://developer.apple.com/sf-symbols/), copy a symbol, and paste it into the “Prefix text” setting.

### Can it show seconds? {#can-it-show-seconds}

No, but you can make the system clock show seconds.

### Can it show the date? {#can-it-show-the-date}

No. Check out my [Dato](/dato) app for that.

### Can it show an analog clock? {#can-it-show-an-analog-clock}

I have no plans to support that.

### What if I want more than one additional clock? {#what-if-i-want-more-than-one-additional-clock}

My [Zone Bar](/zone-bar) app is made for this. It shows many world clocks in the menu bar. My [Dato](/dato) app also supports multiple time zone clocks, with settings like color and size.

If you want to keep using Second Clock, here are additional builds of the app with different identifiers so they can all run at the same time. They are older versions (1.1.0) and do not get updates.

- [Second Clock 2](https://www.dropbox.com/scl/fi/jp9vx3xqrfocpcpb9psnx/Second-Clock-2-1754956993.zip?rlkey=yfxracofur29b258y7aeb5850&raw=1)
- [Second Clock 3](https://www.dropbox.com/scl/fi/8p3cvjfpg1fd9gq1apsgi/Second-Clock-3-1754957017.zip?rlkey=3a66fig1j223nio1znv81vji9&raw=1)
- [Second Clock 4](https://www.dropbox.com/scl/fi/5v77qrgvwg2cyjxjnanjw/Second-Clock-4-1754957043.zip?rlkey=mxapcbqy7famt3srngb9agyf4&raw=1)
- [Second Clock 5](https://www.dropbox.com/scl/fi/cds0pdm6qpuanqs7pcooz/Second-Clock-5-1754957062.zip?rlkey=f4anp3pfe8mrtahlpsycn66c4&raw=1)
- [Second Clock 6](https://www.dropbox.com/scl/fi/ul7kevyvte8anl2f7mbi2/Second-Clock-6-1754957087.zip?rlkey=h4koh48yg49f50pskl6c9rm33&raw=1)

*Requires macOS 15 or later*

*If you had downloaded this previously and it stopped respecting the chosen time zone, download the new versions above.*

### Can macOS do this without an app? {#built-in}

Partly. The menu bar clock of macOS only shows your own time zone. The Clock app and its World Clock widget show other time zones, but you must open the app or show the desktop to see them.

Second Clock keeps the time of another time zone in the menu bar, where you can always see it.

### Can you add text weight and color settings? {#can-you-add-text-weight-and-color-settings}

This is not planned. The menu bar should generally be monochrome (no colors) and consistent (same text weight).

### Can you localize the app into my language? {#can-you-localize-the-app-into-my-language}

The time output adheres to your locale. I don’t plan to localize the app itself.
