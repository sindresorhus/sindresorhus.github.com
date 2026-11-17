---
title: 'How to Run FLUX Locally on Mac'
description: 'Run the FLUX.2 image model of Black Forest Labs on your Mac, with the free Imago app, or with mflux in Terminal. No Python setup in the app.'
publicationDate: 2026-11-17
topic: 'text-and-images'
apps: [
	'imago'
]
---

@QuickAnswer {
	[Imago](/imago) is a free Mac app that runs the FLUX.2 [klein] 4B model of Black Forest Labs on your Mac: download the model in the app, type a prompt, and press ++Return++. You do not install Python. [Without an app](#without-an-app), install mflux, and run `mflux-generate-flux2` in Terminal.
}

FLUX.2 is an AI model that makes images from a text prompt. It runs on your Mac, so your prompts and images are not uploaded. It needs an Apple silicon Mac, and works best with 16 GB of memory or more.

## With Imago

@Steps {
1. Open [Imago](/imago). In “Download Flux 2 Model”, click “Download”. The model is 16 GB, so this can take a while.
1. Click the “Quick Settings” button in the toolbar, and choose the size in “Resolution”, like “1536×1024” (3:2 Landscape), and the number of “Images”.
1. Type the prompt, and press ++Return++.
1. To make an image again with a small change to the prompt, right-click the image, choose “Copy Seed”, and paste the number in “Seed” in the quick settings.
}

After the download, Imago makes images without the internet. [More about offline AI images.](guide:generate-ai-images-offline-mac)

@Tips {
- Click “Add Image” to give FLUX.2 a reference image for the style or the content of the new image.
- The “Generate Image with AI” action of the Shortcuts app makes images from a shortcut.
- To keep the model on another disk, change “Model location” in the settings.
}

## Without an app

[mflux](https://github.com/mflux-community/mflux) runs FLUX.2 in Terminal, with the MLX framework of Apple:

@Steps {
1. Install [uv](https://docs.astral.sh/uv/getting-started/installation/), a tool that installs Python apps.
1. Run `uv tool install --upgrade mflux` in the Terminal app.
1. Run `mflux-generate-flux2 --model flux2-klein-4b --prompt "A red fox in the snow" --steps 4`. The first run downloads the model, about 15 GB.
}

mflux also runs the larger FLUX.2 [klein] 9B model, has options for the size and the seed, and has a second command for reference images. [The FLUX.2 options of mflux.](https://github.com/mflux-community/mflux/blob/main/src/mflux/models/flux2/README.md) This is good for developers and for scripts. For other people, an app is easier, as each change needs a new command, and Terminal shows no preview.
