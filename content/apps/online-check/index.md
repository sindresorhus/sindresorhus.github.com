---
title: 'Online Check'
subtitle: 'Online status in your menu bar'
publicationDate: '2024-06-23'
platforms: [
	'macOS'
]
isMenuBarApp: true
isPaid: true
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
privacyNote: 'To check the connection, the app sends a small request to apple.com or cloudflare.com. No data is collected.'
---

Check if you are online directly from the menu bar. The menu bar icon turns red when you are offline, and the app can optionally show a notification.

Unlike just checking if Wi-Fi is connected, the app verifies actual internet connectivity through network tests.

## Tips

#### Connect to other Wi-Fi when status is offline

You can have the app connect to a different Wi-Fi if the current one becomes offline. Add [this shortcut](https://www.icloud.com/shortcuts/bf64ec8fd3d24f80b2af845464306614) to the Shortcuts app and edit the required information. Then select this shortcut in the Online Check settings.

#### Restart Wi-Fi when status is offline

You could also restart the Wi-Fi when it becomes offline. Add [this shortcut](https://www.icloud.com/shortcuts/8bbe914b13ff4f3ab9f063e835c92747).

## Frequently Asked Questions {#faq}

### How is it different from just checking whether the Wi-Fi is connected?

A Wi-Fi connection only means you are connected to a network. The app verifies internet access by connecting to “apple.com” or “cloudflare.com”, ensuring you’re truly online.

### The app shows that I’m offline even though I’m not

- Ensure network requests from the app to “apple.com” and “cloudflare.com” are not blocked. These domains are used to verify your online status.

### How can I run this only when not connected to certain networks?

Create a shortcut in the Shortcuts app to launch and quit this app. Set up a Shortcuts automation with a “Wi-Fi” trigger to run the shortcut based on your Wi-Fi connection status. This allows the app to launch or quit when connecting to or disconnecting from specific Wi-Fi networks.

### How does it work?

Every 20 seconds and anytime the network changes, it sends a HEAD request to “apple.com”. If that fails, it sends a HEAD request to “cloudflare.com”. If both requests fail, it considers the internet to be offline.

### Can you make the history persistent?

It’s something I’m considering.

### Can you make the menu bar icon green when online? {#green-icon}

No. Menu bar icons are intended to be mostly monotone, changing color only to indicate critical states. For example, the battery icon turns red when low but stays monochrome when full. Showing green also isn’t that useful as you can assume it’s connected when not red, and having a constant green color there could be distracting.
