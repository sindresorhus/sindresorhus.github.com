---
title: 'HEIC Converter'
subtitle: 'Convert HEIC images to JPEG or PNG'
publicationDate: 2017-10-09
platforms: [
	'macOS'
]
appStoreID: 1294126402
hasSentry: true
nonAppStoreVersion: {
	version: '3.6.0'
	macOS: 26
	url: 'https://www.dropbox.com/scl/fi/ftfkqamu1yd2pjk4r8jyb/HEIC-Converter-3.6.0-1777069218.zip?rlkey=8ljysol8pl6syee2t5ubk46e3&raw=1'
}
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
pressQuotes: [
	{
		quote: 'HEIC Converter is a very straightforward way to convert your HEIC photos to the almost universally-compatible JPEG and PNG formats. It works via simple drag and drop while allowing you to customize several output settings.'
		source: 'Softpedia'
		url: 'https://mac.softpedia.com/get/Graphics/HEIC-Converter.shtml'
		year: 2017
	}
]
---

Convert [HEIC](https://support.apple.com/116944) photos from your iPhone to JPEG or PNG, so you can upload them anywhere and share them with people who don’t use Apple devices.

HEIC is Apple’s default image format since iOS 11, replacing JPEG. HEIC uses more advanced and modern compression methods to achieve much smaller file sizes with the same visual quality. Unfortunately, many websites, apps, and devices outside of Apple’s platforms still do not support HEIC.

If you don’t have any HEIC images, you can try the app out with [this one](heic-example.heic).

You can convert up to 1,000 photos at a time, because of a macOS bug.

## Frequently Asked Questions {#faq}

### How do I make my iPhone take JPEG photos? {#iphone-jpeg}

On your iPhone, go to “Settings › Camera › Formats”, and select “Most Compatible”. New photos are then JPEG, and new videos are H.264. The photos use more storage than HEIC.

To convert only when you copy photos to a computer with a USB cable, go to “Settings › Apps › Photos”, and select “Automatic” below “Transfer to Mac or PC”.

### Can I drag and drop photos from the Photos app? {#photos-app}

No. When you drag photos from the Photos app, it gives only a smaller JPEG copy, not the original HEIC image. To convert photos in full quality, select them in the Photos app and choose “File › Export › Export Photos”, where you can choose JPEG or PNG. Or choose “File › Export › Export Unmodified Originals…” to get the original HEIC files, and convert those with the app.

### Does it preserve 10-bit depth? {#does-it-preserve-10-bit-depth}

No. JPEG only supports 8-bit. PNG supports 8-bit and 16-bit, but macOS doesn’t have a way to convert 10-bit HEIC to 16-bit PNG, so it ends up as 8-bit too.

### Does it support other HEIF variants like `.heif` or `.hif`? {#does-it-support-other-heif-variants-like-heif-or-hif}

No. Only `.heic` is supported at the moment because macOS support for other variants is buggy.

### Can you support converting JPEG to HEIC? {#can-you-support-converting-jpeg-to-heic}

I don’t have plans to support JPEG to HEIC conversion. While HEIC offers some benefits over JPEG, I believe [JPEG XL](https://en.wikipedia.org/wiki/JPEG_XL) is a more promising next-generation image format:

- Lossless conversion from JPEG to JPEG XL
- Superior compression compared to JPEG and HEIC
- Support for HDR, wide color gamuts, and animation
- Royalty-free, open standard

I expect JPEG XL to gain more widespread support and become the preferred format in the coming years. At that point, I plan to add JPEG XL conversion capabilities here.

### Can it convert the photos in a folder automatically? {#watch-folder}

Not by itself. However, the Shortcuts app can: make an automation with the “Folder” trigger, and let it run a shortcut that uses the built-in “Convert Image” action on the added files.

### What’s the benefit of this app over the built-in Quick Actions converter? {#whats-the-benefit-of-this-app-over-the-built-in-quick-actions-converter}

The built-in converter (right-click › Quick Actions › Convert Image) works well for basic conversions. This app offers adjustable JPEG quality and granular metadata control (separately toggle location data and modification dates instead of all-or-nothing).
