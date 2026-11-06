---
title: 'Photo Widget'
subtitle: 'Photos on your Home Screen and desktop'
publicationDate: 2020-09-22
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
# testFlightURL: 'https://testflight.apple.com/join/ybGzYJ28'
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

### I’m not seeing the new widget settings for showing date and album title {#im-not-seeing-the-new-widget-settings-for-showing-date-and-album-title}

Try adding a new widget. Sometimes existing widgets get stuck and don’t receive new settings. This is an iOS bug and out of my control.

### Some widget settings are missing {#some-widget-settings-are-missing}

Same as the above.

### How do I add a widget to the Home Screen? {#how-do-i-add-a-widget-to-the-home-screen}

When on the Home Screen, long-press on the background (not on any icons) until the apps begin to jiggle, tap “Edit”, then tap “Add Widget”, and select “Photo Widget”. [Learn more about widgets.](https://support.apple.com/118610)

### How do I edit a widget? {#how-do-i-edit-a-widget}

When on the Home Screen, long-press on the widget, and select “Edit Widget”. [Learn more about widgets.](https://support.apple.com/118610)

### Why is there no Lock Screen widget? {#why-is-there-no-lock-screen-widget}

Lock Screen widgets are monochrome-only and too small to properly display photos.

### Why can I only add 100 photos to the app? {#why-can-i-only-add-100-photos-to-the-app}

This is because of a technical limitation in the iOS widget system. Hopefully, it can be increased in the future. It should be enough for most users though.

If you use the “Album” widget, there’s no limit to the number of photos.

### How do I show my favorites or my whole photo library? {#favorites}

Add the “Album” widget and choose the “Favorites” album, or the “Recents” album for all your photos. You do not need to add the photos to the app.

The “Album” widget needs access to all your photos. Go to “Settings › Apps › Photo Widget › Photos” and choose “All Photos”.

### How can I hide the name of the app shown below the widget? {#how-can-i-hide-the-name-of-the-app-shown-below-the-widget}

This is not possible. App developers have no way to hide it. However, you can hide the title for all apps and widgets.

### If I select an album in a widget, does it include new photos added to the album after I set it up? {#if-i-select-an-album-in-a-widget-does-it-include-new-photos-added-to-the-album-after-i-set-it-up}

Yes. The widget fetches a list of all the photos in the album each time and picks a random one.

### Can a widget show photos from a friend or a partner? {#shared-album}
<!-- @faq.keywords couple family -->

Yes, with a [Shared Album](https://support.apple.com/108314) of the Photos app. Make a Shared Album, invite the other person, and choose the album in the widget of each of you. When one of you adds a photo to the album, it can show in both widgets.

### Can I show an animated GIF in a widget? {#can-i-show-an-animated-gif-in-a-widget}

This is not possible.

### Why does my widget update more often than the interval I set or not as often? {#why-does-my-widget-update-more-often-than-the-interval-i-set-or-not-as-often}

The interval is a suggestion to iOS, not a strict rule. iOS manages widget updates independently to optimize performance and battery life. It may refresh widgets more or less frequently based on various factors. Apps cannot control this behavior.

### How is this different from the built-in “Photos” widget? {#how-is-this-different-from-the-built-in-photos-widget}

The built-in widget can show the photos of an album, not only “Featured Photos” and “Memories”. If that is all you need, it works well. Photo Widget gives you more control:

- Show the photos you pick, like a single photo, without making an album for them.
- Set how often each widget changes its photo.
- Show only the most recent photos of an album.
- Choose what happens when you tap the widget: show the photo, skip to the next photo, open a URL, or run a shortcut.
- Show the capture date, location, or album title on the photos of an album.
- Hide the photos while the device is locked.

### Two of my widgets show the same photos {#two-of-my-widgets-show-the-same-photos}

If two or more widgets of the same size show all the photos or the same album, they show the photos in the same order. This is a limitation of the iOS widget system. To fix it, edit each widget and give it a different “Unique Widget Name”.

### Can you make the cropping prioritize faces? {#can-you-make-the-cropping-prioritize-faces}

This is something I want to add, but it’s more complicated than it sounds. Widgets have limited resources, and currently, it’s not enough to do face detection. Apple works around that by having the face data already available, but this data is not available to third-party apps. Other photo widget apps solve this by letting the user pick the album in the app itself and then they do the face detection in the app upfront, however, that would require a rewrite of this app, which is not something I have time to do right now.

### Why are the images in the widget not full quality? {#why-are-the-images-in-the-widget-not-full-quality}

Widgets get very few system resources so it’s not possible to load a high-resolution image.

If you work at Apple, you know what to do:
- [FB8832751](https://github.com/feedback-assistant/reports/issues/177)

### How can I select a people album? {#how-can-i-select-a-people-album}

Apple does not let third-party apps access these albums.

