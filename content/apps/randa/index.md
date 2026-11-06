---
title: 'Randa'
subtitle: 'Generate random numbers'
publicationDate: 2022-12-17
platforms: [
	'macOS'
	'iOS'
	'watchOS'
	'visionOS'
]
appStoreID: 1589044499
nonAppStoreVersion: {
	version: '1.5.0'
	macOS: 26
	url: 'https://www.dropbox.com/scl/fi/58cje2kirc6i7uv6cxfdb/Randa-1.5.0-1769609488.zip?rlkey=m2rikromxsav4ve3tvxyzq81x&raw=1'
}
olderVersions: [
	{
		version: '1.4.0'
		macOS: '15'
		url: 'https://www.dropbox.com/scl/fi/476tqhek1duur7j59vtu0/Randa-1.4.0-macOS-15-1769609531.zip?rlkey=qlzf72m22nqq9j0ddymbc1xrx&raw=1'
	}
	{
		version: '1.3.1'
		macOS: '14'
		url: 'https://github.com/user-attachments/files/18385766/Randa.1.3.1.-.macOS.14.zip'
	}
	{
		version: '1.0.0'
		macOS: '13'
		url: 'https://github.com/sindresorhus/meta/files/13852533/Randa.1.0.0.zip'
	}
]
pressQuotes: [
	{
		quote: 'Randa is a free tool of great simplicity that will help you pick completely random numbers.'
		source: 'Compétence Mac'
		translatedFrom: 'French'
		url: 'https://competencemac.com/app-randa-un-outil-pour-generer-des-nombres-au-hasard-sur-mac-iphone-et-ipad/'
		year: 2023
	}
]
---

Set a minimum and a maximum, and get a random number in that range.

This can be useful for decision-making, picking stuff from a list, board games, dice rolling, coin flips, etc. For example, it’s Netflix & chill night and you cannot decide on a movie. Just generate a random number from 1 to 20 and pick the movie at that position in your watchlist. Need to make a yes or no decision (coin flip)? Just set the minimum to 0 and the maximum to 1.

On iPhone and iPad, shake the device for a new number, and tap and hold the number to copy it. On Mac, press ++Return++ for a new number and ++Shift+Command+C++ to copy it, and “Window › Stay on Top” (++Control+Command+T++) keeps the small window above your other windows. On Apple Watch, tap the number.

## Frequently Asked Questions {#faq}

### Why do I get the same number twice in a row? {#same-number}

Each number is random, so the same number can come again, like when you roll a die. To always get a number that is different from the previous one, turn on “Consecutively unique numbers” in the settings.

### Why are the numbers back to 1 and 100? {#range-reset}
<!-- @faq.keywords reset range remember -->

The minimum and maximum are kept with the window, so they stay while the app is open or in the background. When you close the app in the app switcher on iPhone or iPad, or close the window on Mac, the system removes them, and the app starts again at 1 and 100.
