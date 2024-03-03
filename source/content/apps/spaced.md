---
title: Spaced
subtitle: Organize your menu bar items into groups
pubDate: 2023-01-20
platforms:
  - macOS
isMenuBarApp: true
appStoreId: 1666327168
olderMacOSVersions:
  - '13'
---

The app provides menu bar separators to group menu bar items for a more streamlined appearance.

It is particularly beneficial on larger screens where menu bar space is ample, as opposed to smaller laptop screens with limited space.

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Spaced&referrer=Website-FAQ)

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some other menu bar apps to free up space. If this does not solve it, try quitting Bartender if you have it installed.

#### Can the app let me hide and show menu bar items?

That is out of scope for this app. You want something like [Bartender](https://www.macbartender.com) or [Hidden Bar](https://apps.apple.com/no/app/hidden-bar/id1452453066?mt=12).

#### Can the app also support grouping icons in the Dock?

This is not possible because of restrictions imposed on apps in the App Store.

However, you can add spacers to the Dock yourself by running the following command in the Terminal app:

```sh
defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="spacer-tile";}' && killall Dock
```

#### Can you localize the app into my language?

I don't plan to localize the app.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1666327168) and click “Version History”.

#### [More FAQs…](/apps/faq)

<br>

### Older Versions

- [1.0.4](https://github.com/sindresorhus/meta/files/13852708/Spaced.1.0.4.-.macOS.13.zip) for macOS 13+

<br>

### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/3hcn8tysy1x2cjnlfdnlt/Spaced-1.1.0-1704617091.zip?rlkey=wyva3oju2yron1aoxydt3l9j0&raw=1) *(1.1.0)*

*Requires macOS 14 or later*
