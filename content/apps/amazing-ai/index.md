---
title: 'Amazing AI'
subtitle: 'Generate images from text using Stable Diffusion'
publicationDate: '2022-12-21'
platforms: [
	'macOS'
	'iOS'
	'visionOS'
]
appStoreID: 1660147028
hasSentry: true
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

To write a [negative prompt](https://dreamlike.art/guides/guide-to-stable-diffusion-negative-prompt-parameter) (what to exclude), write `##` after your prompt, followed by your negative prompt. For example, “photo of a cake, high-quality ## strawberry, out of frame”, where `strawberry, out of frame` is your negative prompt. Anything after the `##` is your negative prompt. You only write `##` once.

### Keyboard shortcuts

On macOS, when in preview mode, there are some keyboard shortcuts available:
- <kbd>◀</kbd> — Previous image
- <kbd>▶</kbd> — Next image
- <kbd>Space</kbd> — Save image
- <kbd>Command+C</kbd> — Copy image
- <kbd>Esc</kbd> — Exit preview

### Metadata

On macOS, when you save a generated image, it includes a lot of useful metadata (prompt, steps, etc). You can [view this in Finder](https://x.com/sindresorhus/status/1611441129622278146/photo/1) by right-clicking the image file and selecting “Get Info”. The file also includes some relevant tags which can be used to create [smart folders](https://support.apple.com/guide/mac-help/tag-files-and-folders-mchlp15236/mac).

## Frequently Asked Questions {#faq}

### Why not use Stable Diffusion 3?

When I tried it, it gave worse results than 1.5. For a better model, check out my [Imago](/imago) app.

### Why does the app require Apple silicon for Macs?

The app takes advantage of recent [optimizations by Apple](https://machinelearning.apple.com/research/stable-diffusion-coreml-apple-silicon).

### Why does the app require at least iPhone 15 Pro and iPad M1?

Generating images with Stable Diffusion requires a lot of system resources. It would not be a good experience on older devices. It could probably run fine on iPhone 15 and iPhone 14 Pro, but Apple does not let us do such a fine-grained requirement. Either I require these devices, or I have to support all devices that can run the app, including those that are not nearly powerful enough.

### What are the usage restrictions for the generated images?

You can use the images for commercial or non-commercial purposes, but you must adhere to the [Creative ML OpenRAIL-M license’s usage restrictions](https://github.com/CompVis/stable-diffusion/blob/21f890f9da3cfbeaba8e2ac3c425ee9e998d5229/LICENSE#L69-L82). These restrictions include not using the images for illegal activity, false information, discrimination, or medical advice.

### Can you support custom models?

I don’t plan to support this. This app is intentionally simple. There are many other apps that support custom models.

### Can you support inpainting/outpainting?

I don’t plan to support this. [DiffusionBee](https://diffusionbee.com) supports this (see below for comparison).

### Can it generate images with aspect ratios other than a square?

The Stable Diffusion library used by this app only supports squares.

### Why can it not generate adult images?

The app would not be allowed on the App Store if it allowed creating such images.

### Why does it take so long to generate?

Several factors can affect the speed of image generation, including the performance of your device and the amount of available memory and CPU. Try closing down other apps or restarting your device before generating images.

And bear in mind that the initial generation after installing the app may take longer due to model validation.

### Why does the app take up so much space on disk and memory?

The AI model used to generate images is large. This is reasonable given the model’s capabilities.

### How does it compare to DiffusionBee? {#diffusionbee}

**Amazing AI benefits**

- Faster and more energy-efficient as it uses the [Apple Neural Engine](https://apple.fandom.com/wiki/Neural_Engine) and recent [macOS optimizations](https://machinelearning.apple.com/research/stable-diffusion-coreml-apple-silicon)
- Native user interface (DiffusionBee is a web app wrapped with Electron which does not follow platform conventions)
- Batch generation of different prompts (DiffusionBee supports batch for the same prompt only)
- Shortcuts support
- Automatic upscaling (DiffusionBee requires you to manually click an upscale button for each image)
- Sandboxed (More secure)
- Available on the App Store

**[DiffusionBee](https://github.com/divamgupta/diffusionbee-stable-diffusion-ui) benefits**

- Inpainting
- Outpainting
- Image-to-image
- Custom models

## Non-App Store Version

A special version for users that cannot access the App Store. It won’t receive automatic updates. I will update it here once a year.

[Download](https://github.com/sindresorhus/sindresorhus.github.com/releases/download/v1.0.0/Amazing.AI.1.7.0.zip) *(1.7.0)*

*Requires macOS 26 or later*
