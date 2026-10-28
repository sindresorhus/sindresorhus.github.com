---
title: 'Amazing AI'
subtitle: 'Generate images from text using Stable Diffusion'
publicationDate: 2022-12-21
platforms: [
	'macOS'
	'iOS'
	'visionOS'
]
appStoreID: 1660147028
hasSentry: true
nonAppStoreVersion: {
	version: '1.7.0'
	macOS: 26
	url: 'https://github.com/sindresorhus/sindresorhus.github.com/releases/download/v1.0.0/Amazing.AI.1.7.0.zip'
}
sharedQuestions: [
	'suggested-filenames'
	'ai-custom-models'
	'ai-inpainting'
	'ai-adult-images'
	'ai-slow'
	'ai-model-size'
	'ai-marking'
]
olderVersions: [
	{
		version: '1.6.0'
		macOS: '15'
		url: 'https://github.com/sindresorhus/sindresorhus.github.com/releases/download/v1.0.0/Amazing.AI.1.6.0.zip'
	}
	{
		version: '1.5.0'
		macOS: '14'
		url: 'https://github.com/sindresorhus/sindresorhus.github.com/releases/download/v1.0.0/Amazing.AI.1.5.0.zip'
	}
	{
		version: '1.2.2'
		macOS: '13'
		url: 'https://drive.google.com/file/d/1mcEhAKhmQGYzmSS-zlejt3_qsKFzqm0h/view?usp=sharing'
	}
]
pressQuotes: [
	{
		quote: 'Like the already available free competitors DiffusionBee and AI Photo, Amazing AI has no cloud dependencies and runs completely locally.'
		source: 'ifun.de'
		translatedFrom: 'German'
		url: 'https://www.ifun.de/amazing-ai-neuer-deep-learning-bildgenerator-fuer-den-mac-200992/'
		year: 2022
	}
]
---

Describe the image you want, and the app makes it for you.

It runs locally on your device.

**Note:** It uses Stable Diffusion 1.5, which is flexible, but it requires a detailed description to generate a usable image.

> [!WARNING]
> On macOS, the app is developed exclusively for Apple silicon. It is NOT compatible with devices running on Intel chips.\
> On iOS, it requires at minimum an iPhone 15 Pro or iPad with an M1 processor.

> [!TIP]
> Check out my [Imago](/imago) app, which uses Flux 2 instead — a much better model.

[Stable Diffusion](https://en.wikipedia.org/wiki/Stable_Diffusion) is a deep learning, text-to-image model used to generate detailed images conditioned on text descriptions.

The app is [highly optimized](https://machinelearning.apple.com/research/stable-diffusion-coreml-apple-silicon) and runs on the [Apple Neural Engine](https://apple.fandom.com/wiki/Neural_Engine).

## Tips

### Preview

Click a thumbnail to view a larger version of it. Click again to exit.

### Negative prompt

To write a [negative prompt](https://en.wikipedia.org/wiki/Stable_Diffusion#Text_to_image_generation) (what to exclude), write `##` after your prompt, followed by your negative prompt. For example, “photo of a cake, high-quality ## strawberry, out of frame”, where `strawberry, out of frame` is your negative prompt. Anything after the `##` is your negative prompt. You only write `##` once.

### Keyboard shortcuts

On macOS, when in preview mode, there are some keyboard shortcuts available:
- ++◀++ — Previous image
- ++▶++ — Next image
- ++Space++ — Save image
- ++Command+C++ — Copy image
- ++Esc++ — Exit preview

### Metadata

On macOS, when you save a generated image, it includes a lot of useful metadata (prompt, steps, etc). You can [view this in Finder](https://x.com/sindresorhus/status/1611441129622278146/photo/1) by right-clicking the image file and selecting “Get Info”. The file also includes some relevant tags which can be used to create [smart folders](https://support.apple.com/guide/mac-help/tag-files-and-folders-mchlp15236/mac).

## Frequently Asked Questions {#faq}

### Why not use Stable Diffusion 3? {#why-not-use-stable-diffusion-3}

When I tried it, it gave worse results than 1.5. For a better model, check out my [Imago](/imago) app.

### Why does the app require Apple silicon for Macs? {#why-does-the-app-require-apple-silicon-for-macs}

The app takes advantage of recent [optimizations by Apple](https://machinelearning.apple.com/research/stable-diffusion-coreml-apple-silicon).

### Why does the app require at least iPhone 15 Pro and iPad M1? {#why-does-the-app-require-at-least-iphone-15-pro-and-ipad-m1}

Generating images with Stable Diffusion requires a lot of system resources. It would not be a good experience on older devices. It could probably run fine on iPhone 15 and iPhone 14 Pro, but Apple does not let us do such a fine-grained requirement. Either I require these devices, or I have to support all devices that can run the app, including those that are not nearly powerful enough.

### What are the usage restrictions for the generated images? {#what-are-the-usage-restrictions-for-the-generated-images}

You can use the images for commercial or non-commercial purposes, but you must adhere to the [Creative ML OpenRAIL-M license’s usage restrictions](https://github.com/CompVis/stable-diffusion/blob/21f890f9da3cfbeaba8e2ac3c425ee9e998d5229/LICENSE#L69-L82). These restrictions include not using the images for illegal activity, false information, discrimination, or medical advice.

### Can it generate images with aspect ratios other than a square? {#can-it-generate-images-with-aspect-ratios-other-than-a-square}

The Stable Diffusion library used by this app only supports squares.

### Why is the first image slow? {#why-is-the-first-image-slow}

The first generation after installing the app may take longer due to model validation.

### The image was “deemed not safe for all ages”, but my prompt is harmless {#not-safe-for-all-ages}

The safety check sometimes also blocks harmless images. Generate again, or change some words of the prompt. If you set a “Seed”, remove it first, as the same seed makes the same image.
