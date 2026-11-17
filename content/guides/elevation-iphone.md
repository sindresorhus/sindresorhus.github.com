---
title: 'How to See Your Elevation on iPhone'
description: 'The Compass app of your iPhone shows your elevation. To use the number in a shortcut, like to log it on a hike, use the free Actions app.'
publicationDate: 2026-11-16
topic: 'iphone'
apps: [
	'actions'
]
---

@QuickAnswer {
	Open the Compass app. It shows your elevation with your coordinates. To get the number in a shortcut, like to log it on a hike, use the “Get Elevation” action of the free [Actions](/actions) app.
}

## With Actions

@Steps {
1. Install [Actions](/actions), and open it once.
1. In the Shortcuts app, make a new shortcut, and add the [“Get Elevation”](/actions#:~:text=Get%20Elevation) action.
1. Add the “Show Content” action, or “Append to Text File” to log each reading.
1. Run the shortcut. The first time, allow the access that it asks for.
}

The action gives the height above sea level in meters. It uses the barometer of the iPhone, and iOS limits the reading to about 2194 meters (7200 feet). Add the shortcut to the Home Screen to read the elevation with one tap. The action is not on the Mac.

The “Get Barometric Pressure” action gives the air pressure. [How to use the barometer of your iPhone.](guide:iphone-barometer)

## Without an app

@Steps {
1. Open the Compass app.
1. Read the elevation on the screen, with your coordinates. If you see no elevation, turn on “Location Services” for Compass in “Settings › Privacy & Security › Location Services”.
}

[Apple’s instructions.](https://support.apple.com/guide/iphone/iph1ac0b663/ios) The coordinates and the elevation are not available in all countries or regions. For a quick look, Compass is all you need.

The Shortcuts app can also give a number without an app: add “Get Current Location”, and then “Get Details of Locations” with “Altitude”. This altitude comes from GPS, and “Get Elevation” of Actions uses the barometer.
