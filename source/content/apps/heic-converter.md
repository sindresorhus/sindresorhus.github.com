---
title: HEIC Converter
subtitle: Convert HEIC images to JPEG or PNG
pubDate: 2017-10-09
platforms:
  - macOS
appStoreId: 1294126402
hasSentry: true
olderMacOSVersions:
  - '10.13'
  - '10.14'
  - '10.15'
  - '11'
  - '12'
  - '13'
  - '14'
---

HEIC Converter is a macOS app that makes it easy to quickly convert images in the [HEIC](https://www.macworld.co.uk/feature/iphone/what-is-heic-3660408/) format to JPEG or PNG. HEIC is Apple's new default image format since iOS 11, replacing JPEG. HEIC uses more advanced and modern compression methods to achieve much smaller file sizes with the same visual quality. Unfortunately, HEIC is a very new format and not yet supported outside of iOS and macOS. This app makes it possible to share your HEIC images on the web or with non-Apple users.

If you don't have any HEIC images, you can try the app out with [this one](/apps/heic-converter/heic-example.heic).

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=HEIC+Converter&referrer=Website-FAQ)

#### Does it preserve 10-bit depth?

No. JPEG only supports 8-bit. PNG supports 8-bit and 16-bit, but macOS doesn't have a way to convert 10-bit HEIC to 16-bit PNG, so it ends up as 8-bit too.

#### Does it support other HEIF variants like `.heif` or `.hif`?

No. Only `.heic` is supported at the moment because macOS support for other variants is buggy.

#### Can you support converting JPEG to HEIC?

I don't have plans to support JPEG to HEIC conversion. While HEIC offers some benefits over JPEG, I believe [JPEG XL](https://en.wikipedia.org/wiki/JPEG_XL) is a more promising next-generation image format:

- Lossless conversion from JPEG to JPEG XL
- Superior compression compared to JPEG and HEIC
- Support for HDR, wide color gamuts, and animation
- Royalty-free, open standard

I expect JPEG XL to gain more widespread support and become the preferred format in the coming years. At that point, I plan to add JPEG XL conversion capabilities here.

#### Why is this free without ads?

I just enjoy making apps. Consider leaving a nice review on the App Store.

#### [More FAQs…](/apps/faq)

## Older Versions

- [3.3.0](https://github.com/user-attachments/files/18555573/HEIC.Converter.3.3.0.-.macOS.14.zip) for macOS 14+
- [3.2.0](https://github.com/sindresorhus/meta/files/13981994/HEIC.Converter.3.2.0.-.macOS.13.zip) for macOS 13+
- [3.0.1](https://github.com/sindresorhus/meta/files/11401710/HEIC.Converter.3.0.1.-.macOS.12.zip) for macOS 12+
- [2.1.5](https://github.com/sindresorhus/meta/files/9218007/HEIC.Converter.2.1.5.-.macOS.11.zip) for macOS 11+
- [2.1.5](https://github.com/sindresorhus/meta/files/8817868/HEIC.Converter.2.1.5.-.macOS.10.15.zip) for macOS 10.15+
- [1.9.0](https://github.com/sindresorhus/meta/files/6715716/HEIC.Converter.1.9.0.-.macOS.10.14.zip) for macOS 10.14+
- [1.5.3](https://github.com/sindresorhus/meta/files/13539124/HEIC-Converter-for-macOS-10.13.zip) for macOS 10.13+

## Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/67yxnp1eav42osqt2mlil/HEIC-Converter-3.4.0-1737966500.zip?rlkey=idqv2y6fmgyzwjlmkukr5ch26&raw=1) *(3.4.0)*

*Requires macOS 15 or later*
