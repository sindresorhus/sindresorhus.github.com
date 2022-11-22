---
title: Amazing AI
subtitle: Generate images from text using Stable Diffusion
date: 2022-12-21
platforms:
  - macOS
appStoreId: 1660147028
---

Simply describe the image you desire, and the app will generate it for you like magic!

**Developed exclusively for Apple silicon (M1/M2) - The app is NOT compatible with devices running on Intel chips.**

[Stable Diffusion](https://en.wikipedia.org/wiki/Stable_Diffusion) is a deep learning, text-to-image model used to generate detailed images conditioned on text descriptions.

The app is [highly optimized](https://machinelearning.apple.com/research/stable-diffusion-coreml-apple-silicon) and runs on the [Apple Neural Engine](https://apple.fandom.com/wiki/Neural_Engine).

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Amazing%20AI&referrer=Website-FAQ)

#### Why not use Stable Diffusion 2?

It will eventually be supported, but right now, it's worse than 1.5.

#### Why does the app require macOS 13.1 and Apple silicon?

The app takes advantage of recent [optimizations by Apple](https://machinelearning.apple.com/research/stable-diffusion-coreml-apple-silicon).

#### Can you support custom models?

It's something I plan to support, but other things are higher priority at the moment.

#### Can you support inpainting/outpainting?

I don't plan to support this. [DiffusionBee](https://diffusionbee.com) supports this (see below for comparison).

#### Can it generate images with aspect ratios other than a square?

Stable Diffusion can only generate square images as that's what it was trained on.

#### Why does the app take up so much space on disk and memory?

The AI model used to generate images is large. It's not too bad considering what it's capable of.

#### Can you support iOS?

I plan to add iOS support when the app is more mature.

#### How does it compare to [DiffusionBee](https://github.com/divamgupta/diffusionbee-stable-diffusion-ui)? {#diffusionbee}

**Amazing AI benefits**

- Faster and more energy efficient as it uses the [Apple Neural Engine](https://apple.fandom.com/wiki/Neural_Engine) and recent [macOS optimizations](https://machinelearning.apple.com/research/stable-diffusion-coreml-apple-silicon)
- Native user-interface (DiffusionBee is a web app wrapped with Electron which does not follow platform conventions)
- Batch generation of different prompts (DiffusionBee supports batch for the same prompt only)
- Shortcuts support
- Automatic upscaling (DiffusionBee requires you to manually click an upscale button for each image)
- Sandboxed (More secure)
- Available on the App Store

**DiffusionBee benefits**

- Inpainting
- Outpainting
- Image to image (planned for Amazing AI too)
- Custom models (planned for Amazing AI too)

#### Why is this free without ads?

I just enjoy making Mac apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1660147028) and click “Version History”.

#### Can you localize the app into my language?

I don't have any immediate plans to localize the app.
