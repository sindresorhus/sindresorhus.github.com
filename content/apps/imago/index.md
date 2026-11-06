---
title: 'Imago'
subtitle: 'Generate images from text using Flux 2'
description: 'Make images from a text prompt with the FLUX.2 model, locally on your Mac, with a 4× upscaler, and reference images.'
publicationDate: 2026-03-22
platforms: [
	'macOS'
]
appStoreID: 6758187147
hasSentry: true
nonAppStoreVersion: {
	version: '1.0.1'
	macOS: 26
	url: 'https://www.dropbox.com/scl/fi/3vgrzu42y0b8ex4ucer9w/Imago-1.0.1-1774386003.zip?rlkey=6m80smt12qv8dccxlb4uk8sfw&raw=1'
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
# olderVersions: [
# 	{
# 		version: '1.0.0',
# 		macOS: '26',
# 		url: '',
# 	},
# ]
pressQuotes: [
	{
		quote: 'Imago is a new tool developed by Sindre Sorhus. It uses the Flux.2 generator, which is optimized for creative work.'
		source: 'Compétence Mac'
		translatedFrom: 'French'
		url: 'https://competencemac.com/macos-generez-gratuitement-et-localement-des-images-a-laide-de-flux-2/'
		year: 2026
	}
]
privacyNote: 'The app downloads its AI model from Hugging Face.'
---

Describe the image you want, and the app makes it for you.

It runs locally on your device. It uses the FLUX.2 [klein] 4B model.

This app is focused on simplicity. No custom models, no complicated settings, no workflow editors. Just type a prompt and get an image. If you need fine-grained control, custom models, or advanced workflows, check out [ComfyUI](https://www.comfy.org). Imago is for everyone else.

> [!IMPORTANT]
> Requires an Apple silicon Mac (no Intel) and 20 GB free disk space. It works best with 16 GB RAM or more. With less, the app shows a warning, and making an image can be slow or fail.
>
> The first time you open the app, it asks you to download the AI model (16 GB). You need an internet connection, and the download can take a while, before you can make the first image.
>
> To keep the model on another disk, like an external drive, use “Model location” in the settings.

<!-- On iOS, it requires at minimum an iPhone 15 Pro or iPad with an M1 processor. -->

[Flux](https://en.wikipedia.org/wiki/Flux_(text-to-image_model)) is a deep learning, text-to-image model used to generate detailed images conditioned on text descriptions.

**Features**

- Square, 2:3 portrait, and 3:2 landscape sizes (also 9:16 and 16:9 on Macs with 64 GB of memory or more)
- Make the image 4× larger with the built-in upscaler
- Add reference images to guide the style, composition, and content
- The “Generate Image with AI” action in the Shortcuts app, which can make 1 to 100 images for a prompt, with reference images and a seed (right-click an image to copy its seed)

## Tips

### Preview

Click a thumbnail to view a larger version of it. Click again to exit.

### Keyboard shortcuts

<!-- On macOS, when in preview mode, there are some keyboard shortcuts available: -->
When in preview mode, there are some keyboard shortcuts available:
- ++◀++ — Previous image
- ++▶++ — Next image
- ++Space++ — Save image
- ++Command+C++ — Copy image
- ++Esc++ — Exit preview

### Metadata

<!-- On macOS, w -->

When you save a generated image, it includes a lot of useful metadata (prompt, model, etc). You can [view this in Finder](https://x.com/sindresorhus/status/1611441129622278146/photo/1) by right-clicking the image file and selecting “Get Info”. The file also includes some relevant tags which can be used to create [smart folders](https://support.apple.com/guide/mac-help/tag-files-and-folders-mchlp15236/mac).

## Frequently Asked Questions {#faq}

### Why does the app require Apple silicon for Macs? {#why-does-the-app-require-apple-silicon-for-macs}

The AI model is optimized for Apple silicon. It would be unusably slow on Intel Macs.

<!-- #### Why does the app require at least iPhone 15 Pro and iPad M1?

Generating images with Stable Diffusion requires a lot of system resources. It would not be a good experience on older devices. It could probably run fine on iPhone 15 and iPhone 14 Pro, but Apple does not let us do such a fine-grained requirement. Either I require the current devices or I have to support devices down to iPhone XS, which are not nearly powerful enough. -->

### How is it different from Image Playground? {#image-playground}

Imago makes the images on your Mac with the FLUX.2 model, with no daily limit. After the download of the model, it works without the internet. Image Playground, the built-in app, needs a Mac with Apple Intelligence. Apple says that Image Playground has a daily limit when it uses server models, and its ChatGPT styles send your description to ChatGPT. Image Playground can also make images of people from your photo library.

### Can you support iOS? {#can-you-support-ios}

No. iOS devices don’t have enough RAM.

### What are the usage restrictions for the generated images? {#what-are-the-usage-restrictions-for-the-generated-images}

You can use the images for commercial or non-commercial purposes, but you must follow the usage restrictions defined for [FLUX.2](https://huggingface.co/black-forest-labs/FLUX.2-klein-4B). These include not using the images for illegal activities, deception or misinformation, harassment, discrimination, exploitation or abuse, misuse of personal data, non-consensual imagery, or other harmful uses.

### How can I remove Imago and the Flux model entirely? {#uninstall}

First, open the app and choose “Help › Show Model Folder” to reveal the model in Finder, then delete that folder (about 16 GB). After that, [delete the app](https://support.apple.com/102610) from your Applications folder as usual.
