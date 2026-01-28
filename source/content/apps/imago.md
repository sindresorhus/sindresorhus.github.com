---
isUnlisted: true # TODO
title: Imago
subtitle: Generate images from text using Flux 2
pubDate: 2026-01-24 # TODO
platforms:
  - macOS
appStoreId: 6758187147
hasSentry: true
forceHasIosAppIcon: true
# olderMacOSVersions:
#   - '26'
---

Simply describe the image you desire, and the app will generate it for you like magic!

It runs locally on your device.

> [!WARNING]
> Requires an Apple silicon Mac (no Intel), minimum 16 GB RAM, and xGB free disk space.

Developed exclusively for Apple silicon - The app is NOT compatible with devices running on Intel chips.

<!-- On iOS, it requires at minimum an iPhone 15 Pro or iPad with an M1 processor. -->

[Flux 2](https://en.wikipedia.org/wiki/Flux_(text-to-image_model)) is a deep learning, text-to-image model used to generate detailed images conditioned on text descriptions.

## Tips

### Preview

Click a thumbnail to view a larger version of it. Click again to exit.

### Keyboard shortcuts

<!-- On macOS, when in preview mode, there are some keyboard shortcuts available: -->
When in preview mode, there are some keyboard shortcuts available:
- <kbd>◀</kbd> — Previous image
- <kbd>▶</kbd> — Next image
- <kbd>Space</kbd> — Save image
- <kbd>Command + C</kbd> — Copy image
- <kbd>Esc</kbd> — Exit preview

### Metadata

<!-- On macOS, w -->

When you save a generated image, it includes a lot of useful metadata (prompt, model, etc). You can [view this in Finder](https://x.com/sindresorhus/status/1611441129622278146/photo/1) by right-clicking the image file and selecting “Get Info”. The file also includes some relevant tags which can be used to create [smart folders](https://support.apple.com/guide/mac-help/tag-files-and-folders-mchlp15236/mac).

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Imago&referrer=Website-FAQ)

#### Why does the app require Apple silicon for Macs?

The AI model is optimized for Apple silicon. It would be unusably slow on Intel Macs.

<!-- #### Why does the app require at least iPhone 15 Pro and iPad M1?

Generating images with Stable Diffusion requires a lot of system resources. It would not be a good experience on older devices. It could probably run fine on iPhone 15 and iPhone 14 Pro, but Apple does not let us do such a fine-grained requirement. Either I require the current devices or I have to support devices down to iPhone XS, which are not nearly powerful enough. -->

#### Can you support iOS?

No. iOS devices don't have enough RAM.

#### What are the usage restrictions for the generated images?

You can use the images for commercial or non-commercial purposes, but you must follow the usage restrictions defined for [FLUX.2](https://huggingface.co/black-forest-labs/FLUX.2-klein-4B). These include not using the images for illegal activities, deception or misinformation, harassment, discrimination, exploitation or abuse (including of minors), misuse of personal data, non-consensual imagery, or other harmful uses.

#### Can you support custom models?

I don't plan to support this. This app is intentionally simple. There are many other apps that support custom models.

#### Can you support inpainting/outpainting?

I don't plan to support this.

#### Why can it not generate adult images?

The app would not be allowed on the App Store if it allowed creating such images.

#### Why does it take so long to generate?

Several factors can affect the speed of image generation, including the performance of your device and the amount of available memory and CPU. Try closing down other apps or restarting your device before generating images.

And bear in mind that the initial generation after installing the app may take longer due to model validation.

#### Why does the app take up so much space on disk and memory?

The AI model used to generate images is large. This is reasonable given the model's capabilities.

#### Why is this free without ads?

I just enjoy making apps. Consider leaving a nice review on the App Store.

#### [More FAQs…](/apps/faq)

<!-- ## Older Versions

- [1.0.0]() for macOS 26+

## Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download]() *(1.0.0)*

*Requires macOS 26 or later*
 -->
