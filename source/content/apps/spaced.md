---
title: Spaced
subtitle: Organize your menu bar items into groups
pubDate: 2023-01-20
platforms:
  - macOS
appStoreId: 1666327168
---

The app provides menu bar separators to group menu bar items for a more streamlined appearance.

It is particularly beneficial on larger screens where menu bar space is ample, as opposed to smaller laptop screens with limited space.

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Spaced&referrer=Website-FAQ)

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some menu bar apps to free up space. If this does not solve it, try quitting Bartender if you have it installed.

#### Can the app let me hide and show menu bar items?

That is out of scope for this app. You want something like [Bartender](https://www.macbartender.com) or [Hidden Bar](https://apps.apple.com/no/app/hidden-bar/id1452453066?mt=12).

#### Can the app also support grouping icons in the Dock?

This is not possible because of restrictions imposed on apps in the App Store.

However, you can add spacers to the Dock yourself by running the following command in the Terminal app:

```sh
defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="spacer-tile";}' && killall Dock
```

#### Can you localize the app into my language?

I don't have any immediate plans to localize the app.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1666327168) and click “Version History”.

<br>

### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://dsc.cloud/sindresorhus/Spaced-1.0.4-1686472769.zip) *(1.0.4)*

*Requires macOS 13 or later*
