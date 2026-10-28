---
title: 'Online Check'
subtitle: 'Online status in your menu bar'
publicationDate: 2024-06-23
platforms: [
	'macOS'
]
isPaid: true
isMenuBarApp: true
appStoreID: 6504709660
olderVersions: [
	{
		version: '1.5.0'
		macOS: '15'
		url: 'https://www.dropbox.com/scl/fi/jj4d0jqg9vjvxi75ojigb/Online-Check-1.5.0-macOS-15-1772136482.zip?rlkey=vty9ff9bcz2usxsrurls6tczf&raw=1'
	}
	{
		version: '1.3.0'
		macOS: '14'
		url: 'https://github.com/user-attachments/files/19074059/Online.Check.1.3.0.-.macOS.14.zip'
	}
]
pressQuotes: [
	{
		quote: 'The Online Check mini-app offers a simple way to monitor online status. […] The app aims to indicate a lost connection quickly and reliably by regularly checking the availability of Apple’s and Cloudflare’s servers with ping requests.'
		source: 'ifun.de'
		translatedFrom: 'German'
		url: 'https://www.ifun.de/online-check-mini-app-wacht-ueber-eure-online-anbindung-234967/'
		year: 2024
	}
]
privacyNote: 'To check the connection, the app sends a small request to Apple or Cloudflare servers. No data is collected.'
---

Check if you are online directly from the menu bar. The menu bar icon turns red when you are offline, and the app can optionally show a notification.

Unlike just checking if Wi-Fi is connected, the app verifies actual internet connectivity through network tests.

The app can also show a red border around the screen while you are offline, keep a history of the status changes that you can export as CSV, and run a shortcut when the status changes.

## Tips

### Connect to other Wi-Fi when status is offline

You can have the app connect to a different Wi-Fi if the current one becomes offline. Add the [shortcut that connects to another Wi-Fi](https://www.icloud.com/shortcuts/bf64ec8fd3d24f80b2af845464306614) to the Shortcuts app and edit the required information. Then select this shortcut in the “Run shortcut on status change” setting of Online Check.

### Restart Wi-Fi when status is offline

You could also restart the Wi-Fi when it becomes offline. Add the [shortcut that restarts the Wi-Fi](https://www.icloud.com/shortcuts/8bbe914b13ff4f3ab9f063e835c92747), and select it in the “Run shortcut on status change” setting.

## Frequently Asked Questions {#faq}

### How is it different from just checking whether the Wi-Fi is connected? {#how-is-it-different-from-just-checking-whether-the-wi-fi-is-connected}

A Wi-Fi connection only means you are connected to a network. The app verifies internet access by connecting to “captive.apple.com”, “apple.com”, or “cloudflare.com”, ensuring you’re truly online.

### The app shows that I’m offline even though I’m not {#the-app-shows-that-im-offline-even-though-im-not}

- Ensure network requests from the app to “captive.apple.com”, “apple.com”, and “cloudflare.com” are not blocked. These domains are used to verify your online status.

### How can I run this only when not connected to certain networks? {#how-can-i-run-this-only-when-not-connected-to-certain-networks}

Create a shortcut in the Shortcuts app to launch and quit this app. Set up a Shortcuts automation with a “Wi-Fi” trigger to run the shortcut based on your Wi-Fi connection status. This allows the app to launch or quit when connecting to or disconnecting from specific Wi-Fi networks.

### How does it work? {#how-does-it-work}

Anytime the network changes, and every 10 seconds while online (2 seconds while offline), it loads “captive.apple.com”, the page that macOS also uses to detect Wi-Fi login pages. If that fails, it sends a HEAD request to “apple.com”, and then to “cloudflare.com”. If all the requests fail, it considers the internet to be offline. You can change the check intervals in the settings.

### Can you make the history persistent? {#can-you-make-the-history-persistent}

It’s something I’m considering.

### Can you make the menu bar icon green when online? {#green-icon}

No. Menu bar icons are intended to be mostly monotone, changing color only to indicate critical states. For example, the battery icon turns red when low but stays monochrome when full. Showing green also isn’t that useful as you can assume it’s connected when not red, and having a constant green color there could be distracting.
