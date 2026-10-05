---
title: 'HEIC Converter'
subtitle: 'Convert HEIC images to JPEG or PNG'
publicationDate: '2017-10-09'
platforms: [
	'macOS'
]
appStoreID: 1294126402
hasSentry: true
olderVersions: [
	{
		version: '3.5.0'
		macOS: '15'
		url: 'https://www.dropbox.com/scl/fi/3pp92ufejv6rixixkkzcl/HEIC-Converter-3.5.0-macOS-15-1777070030.zip?rlkey=g248y3inhtf5ld3buatxxh9ex&raw=1'
	}
	{
		version: '3.3.0'
		macOS: '14'
		url: 'https://github.com/user-attachments/files/18555573/HEIC.Converter.3.3.0.-.macOS.14.zip'
	}
	{
		version: '3.2.0'
		macOS: '13'
		url: 'https://github.com/sindresorhus/meta/files/13981994/HEIC.Converter.3.2.0.-.macOS.13.zip'
	}
	{
		version: '3.0.1'
		macOS: '12'
		url: 'https://github.com/sindresorhus/meta/files/11401710/HEIC.Converter.3.0.1.-.macOS.12.zip'
	}
	{
		version: '2.1.5'
		macOS: '11'
		url: 'https://github.com/sindresorhus/meta/files/9218007/HEIC.Converter.2.1.5.-.macOS.11.zip'
	}
	{
		version: '2.1.5'
		macOS: '10.15'
		url: 'https://github.com/sindresorhus/meta/files/8817868/HEIC.Converter.2.1.5.-.macOS.10.15.zip'
	}
	{
		version: '1.9.0'
		macOS: '10.14'
		url: 'https://github.com/sindresorhus/meta/files/6715716/HEIC.Converter.1.9.0.-.macOS.10.14.zip'
	}
	{
		version: '1.5.3'
		macOS: '10.13'
		url: 'https://github.com/sindresorhus/meta/files/13539124/HEIC-Converter-for-macOS-10.13.zip'
	}
]
---

Convert [HEIC](https://www.macworld.co.uk/feature/iphone/what-is-heic-3660408/) photos from your iPhone to JPEG or PNG, so you can upload them anywhere and share them with people who don’t use Apple devices.

HEIC is Apple’s default image format since iOS 11, replacing JPEG. HEIC uses more advanced and modern compression methods to achieve much smaller file sizes with the same visual quality. Unfortunately, many websites, apps, and devices outside of Apple’s platforms still do not support HEIC.

If you don’t have any HEIC images, you can try the app out with [this one](/apps/heic-converter/heic-example.heic).

## Frequently Asked Questions {#faq}

### Does it preserve 10-bit depth?

No. JPEG only supports 8-bit. PNG supports 8-bit and 16-bit, but macOS doesn’t have a way to convert 10-bit HEIC to 16-bit PNG, so it ends up as 8-bit too.

### Does it support other HEIF variants like `.heif` or `.hif`?

No. Only `.heic` is supported at the moment because macOS support for other variants is buggy.

### Can you support converting JPEG to HEIC?

I don’t have plans to support JPEG to HEIC conversion. While HEIC offers some benefits over JPEG, I believe [JPEG XL](https://en.wikipedia.org/wiki/JPEG_XL) is a more promising next-generation image format:

- Lossless conversion from JPEG to JPEG XL
- Superior compression compared to JPEG and HEIC
- Support for HDR, wide color gamuts, and animation
- Royalty-free, open standard

I expect JPEG XL to gain more widespread support and become the preferred format in the coming years. At that point, I plan to add JPEG XL conversion capabilities here.

### What’s the benefit of this app over the built-in Quick Actions converter?

The built-in converter (right-click › Quick Actions › Convert Image) works well for basic conversions. This app offers adjustable JPEG quality and granular metadata control (separately toggle location data and modification dates instead of all-or-nothing).

## Non-App Store Version

A special version for users that cannot access the App Store. It won’t receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/ftfkqamu1yd2pjk4r8jyb/HEIC-Converter-3.6.0-1777069218.zip?rlkey=8ljysol8pl6syee2t5ubk46e3&raw=1) *(3.6.0)*

*Requires macOS 26 or later*
