---
title: Photo Widget
subtitle: Photos on your home screen and desktop
pubDate: 2020-09-22
platforms:
  - macOS
  - iOS
appStoreId: 1532588789
forceHasIosAppIcon: true
---

For macOS, it's only available for Apple silicon Macs.

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Photo%20Widget&referrer=Website-FAQ)

#### I'm not seeing the new widget settings for showing date and album title

Try adding a new widget. Sometimes existing widgets get stuck and don't receive new settings. This is a iOS bug and out of my control.

#### Some widget settings are missing

Same as the above.

#### How do I add a widget to the home screen?

When on the home screen, long-press on the background (not on any icons), press the top-left “+” button, and select “Photo Widget”. [Learn more.](https://support.apple.com/en-us/HT207122)

#### How do I edit a widget?

When on the home screen, long-press on the widget, and select “Edit Widget”. [Learn more.](https://support.apple.com/en-us/HT207122)

#### The widget does not show up in the widget picker

This is a well-known iOS 16 issue. [Try this.](https://webtrickz.com/third-party-lock-screen-widgets-not-showing-ios-16/)

#### Why can I only add 100 photos to the app?

This is because of a technical limitation in the iOS widget system. Hopefully, it can be increased in the future. It should be enough for most users though.

If you use the “Album” widget, there’s no limit to the number of photos.

#### How can I hide the name of the app shown below the widget?

This is not possible. App developers have no way to hide it.

#### If I select an album in a widget, does it include new photos added to the album after I set it up?

Yes. The widget fetches a list of all the photos in the album each time and picks a random one.

#### Can I show an animated GIF in a widget?

This is not possible.

#### How is this different from the built-in “Photos” widget?

The built-in widget only shows photos from “Memories” and “Featured Photos” in your photo library. There is no way to customize it or pick the photos to be shown.

#### Can you make the cropping prioritize faces?

This is something I want to add, but it's more complicated than it sounds. Widgets have limited resources, and currently, it's not enough to do face detection. Apple works around that by having the face data already available, but this data is not available to third-party apps. Other photo widget apps solve this by letting the user pick the album in the app itself and then they do the face detection in the app upfront, however, that would require a rewrite of this app, which is not something I have time to do right now.

#### When using the “Run Shortcut” action, why does tapping the widget first open the main app and then the Shortcuts app?

This is because of iOS limitations. A widget can only open its own app when a user taps it. And the only way to run a shortcut is to open the Shortcuts app using a special URL. So when you tap the widget, the widget opens the main app, and the main app then opens the Shortcuts app. It's not a very good user experience, but only Apple can fix this.

If you work at Apple, you know what to do:
- [FB9745173](https://github.com/feedback-assistant/reports/issues/240)
- [FB11516334](https://github.com/feedback-assistant/reports/issues/357)
- [FB11516273](https://github.com/feedback-assistant/reports/issues/356)

#### Why are the images in the widget not full quality?

Widgets get very few system resources so it's not possible to load a high-resolution image.

If you work at Apple, you know what to do:
- [FB8832751](https://github.com/feedback-assistant/reports/issues/177)

#### How can I select a people album?

Apple does not let third-party apps access these albums.

#### Why is this free without ads?

I just enjoy making apps. I earn money on other apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1532588789) and click “Version History”.

#### [More FAQs…](/apps/faq)
