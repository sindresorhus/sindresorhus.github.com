---
title: 'How to Stop Finder from Opening After AirDrop on Mac'
description: 'When you get a file with AirDrop, Finder opens a window and takes the focus. Supercharge has a setting that stops it.'
publicationDate: 2026-11-23
topic: 'finder-and-desktop'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	In the settings of [Supercharge](/supercharge), click “Tweaks”, and turn on “Prevent Finder window opening when receiving through AirDrop”. [Without an app](#without-an-app), close the window with ++Command+W++ when it opens, as Apple’s AirDrop guide names no setting for it.
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](/supercharge), and click “Tweaks”.
1. In the “AirDrop” section, turn on “Prevent Finder window opening when receiving through AirDrop”.
1. Send a file to the Mac with AirDrop. The file is saved as before, but no Finder window opens.
}

Then the “Show in Finder” button of the AirDrop notification does not work.

@Tips {
- To make AirDrop files go to another folder, set “Move files received through AirDrop to” in the same section. Then Finder does not open either. <guide:change-airdrop-folder-mac>
}

## Without an app

Apple’s guide to AirDrop on Mac names no setting that stops the Finder window. <source:https://support.apple.com/guide/mac-help/mh35868/mac>

When the window opens, press ++Command+W++ to close it.
