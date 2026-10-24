---
title: 'Photo Widget'
subtitle: 'Photos on your Home Screen and desktop'
publicationDate: '2020-09-22'
platforms: [
	'macOS'
	'iOS'
	'visionOS'
]
isPaid: true
appStoreID: 1532588789
sharedQuestions: [
	'widget-missing'
	'widget-run-shortcut'
]
# links: {
# 	TestFlight: 'https://testflight.apple.com/join/ybGzYJ28',
# }
feedbackNote:
	'''
	If you are seeing black/white widgets, this is an iOS bug. Possible workaround:
	- Restart your device.
	- Remove the widget and add it again.
	- Remove the app and download it again.

	It’s unfortunate that this happens, but the widget system in iOS is very buggy.
	'''
---

See your favorite photos every time you look at your Home Screen or desktop. Make a widget with a single photo, a slideshow, or the photos in an album.

For macOS, it’s only available for Apple silicon Macs.

## Frequently Asked Questions {#faq}

### I’m not seeing the new widget settings for showing date and album title

Try adding a new widget. Sometimes existing widgets get stuck and don’t receive new settings. This is an iOS bug and out of my control.

### Some widget settings are missing

Same as the above.

### How do I add a widget to the Home Screen?

When on the Home Screen, long-press on the background (not on any icons), press the top-left “+” button, and select “Photo Widget”. [Learn more.](https://support.apple.com/HT207122)

### How do I edit a widget?

When on the Home Screen, long-press on the widget, and select “Edit Widget”. [Learn more.](https://support.apple.com/HT207122)

### Why is there no Lock Screen widget?

Lock Screen widgets are monochrome-only and too small to properly display photos.

### Why can I only add 100 photos to the app?

This is because of a technical limitation in the iOS widget system. Hopefully, it can be increased in the future. It should be enough for most users though.

If you use the “Album” widget, there’s no limit to the number of photos.

### How can I hide the name of the app shown below the widget?

This is not possible. App developers have no way to hide it. However, in iOS 18 you can hide the title for all apps and widgets.

### If I select an album in a widget, does it include new photos added to the album after I set it up?

Yes. The widget fetches a list of all the photos in the album each time and picks a random one.

### Can I show an animated GIF in a widget?

This is not possible.

### Why does my widget update more often than the interval I set or not as often?

The interval is a suggestion to iOS, not a strict rule. iOS manages widget updates independently to optimize performance and battery life. It may refresh widgets more or less frequently based on various factors. Apps cannot control this behavior.

### How is this different from the built-in “Photos” widget?

The built-in widget only shows photos from “Memories” and “Featured Photos” in your photo library. There is no way to customize it or pick the photos to be shown.

### Can you make the cropping prioritize faces?

This is something I want to add, but it’s more complicated than it sounds. Widgets have limited resources, and currently, it’s not enough to do face detection. Apple works around that by having the face data already available, but this data is not available to third-party apps. Other photo widget apps solve this by letting the user pick the album in the app itself and then they do the face detection in the app upfront, however, that would require a rewrite of this app, which is not something I have time to do right now.

### Why are the images in the widget not full quality?

Widgets get very few system resources so it’s not possible to load a high-resolution image.

If you work at Apple, you know what to do:
- [FB8832751](https://github.com/feedback-assistant/reports/issues/177)

### How can I select a people album?

Apple does not let third-party apps access these albums.

