---
title: 'How to Find Your Router IP Address on iPhone'
description: 'See the IP address of your router in the Wi-Fi settings of your iPhone, or open the settings page of the router with one tap with the free Actions app.'
publicationDate: 2026-11-16
topic: 'internet-and-network'
apps: [
	'actions'
]
---

@QuickAnswer {
	Open “Settings › Wi-Fi”, and tap the info button next to your network. The IP address of the router is next to “Router”. To open the settings page of the router with one tap, make a shortcut with the “Get Default Gateway IP Address” action of the free [Actions](/actions) app.
}

## With Actions

@Steps {
1. Install [Actions](/actions), and open it once.
1. In the Shortcuts app, make a new shortcut, and add the [“Get Default Gateway IP Address”](/actions#:~:text=Get%20Default%20Gateway%20IP%20Address) action.
1. Add the “URL” action, type `http://`, and then insert the “Default Gateway IP Address” variable after it.
1. Add the “Open URLs” action.
1. Run the shortcut. The settings page of the router opens in your browser.
}

Add the shortcut to the Home Screen to open the router page with one tap. The action also works on a Mac. It gives nothing if the network has no router.

## Without an app

@Steps {
1. Open “Settings › Wi-Fi”.
1. Tap the info button next to the network that you are on.
1. Find “Router”. The number next to it is the IP address of the router, like `192.168.1.1`.
}

[Apple’s instructions.](https://support.apple.com/guide/platform-support/supc4380e13e/web) To open the settings page, type the number in the address bar of your browser. For one look, this is all you need. Use Actions when you open the router page often.
