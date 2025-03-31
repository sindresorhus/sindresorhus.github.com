---
title: Shareful
subtitle: Give the macOS share menu superpowers
pubDate: 2020-09-08
platforms:
  - macOS
appStoreId: 1522267256
hasSentry: true
olderMacOSVersions:
  - '10.15'
  - '11'
  - '12'
  - '13'
  - '14'
---

Shareful makes the system share menu even more useful by providing some commonly needed share services like copy and save.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Shareful&referrer=Website-FAQ)

#### The share services do not show up in System Settings

Shareful provides share services (Copy, Open In, etc.) which macOS is supposed to pick up. Shareful has no control over how it works. In some rare cases, macOS can fail to pick up these share services. This is a problem with macOS not Shareful.

Here are some things you could try:
- Restart your computer
- Reinstall the app
- [Reset NVRAM](https://support.apple.com/en-us/HT204063)
- [Reset the share services registry](https://web.archive.org/web/20180711015728/https://support.apple.com/en-us/HT203129)

If you are on a work computer, it could also be that your company has blocked third-party share services.

#### Can you add a “Move” action?

This is unfortunately not possible. [Share extensions](https://support.apple.com/guide/mac-help/use-the-share-menu-on-mac-mh40614/mac) (for example, the "Copy" action), usually only receive a copy of the file. They have no guaranteed access to the original file.

#### Can you add a “Copy Path” action for use in Finder?

That would be moot. Right-click a file in Finder, press the <kbd>Option</kbd> key, and select “Copy as Pathname”.

#### Why is this free without ads?

I just enjoy making apps. Consider leaving a nice review on the App Store.

#### [More FAQs…](/apps/faq)

## Older Versions

- [1.10.4](https://github.com/user-attachments/files/18914470/Shareful.1.10.4.-.macOS.14.zip) for macOS 14+
- [1.9.1](https://github.com/sindresorhus/meta/files/14158056/Shareful.1.9.1.-.macOS.13.zip) for macOS 13+
- [1.8.0](https://github.com/sindresorhus/meta/files/11297902/Shareful.1.8.0.-.macOS.12.zip) for macOS 12+
- [1.6.0](https://github.com/sindresorhus/meta/files/8800088/Shareful.1.6.0.-.macOS.11.zip) for macOS 11+
- [1.4.0](https://github.com/sindresorhus/meta/files/7119520/Shareful.1.4.0.-.macOS.10.15.zip) for macOS 10.15+

## Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/4wko3a9hmmv756jn42tc1/Shareful-1.11.0-1740166187.zip?rlkey=rf6vjg4vdbxu04ikt9ic16gqq&raw=1) *(1.11.0)*

*Requires macOS 15 or later*
