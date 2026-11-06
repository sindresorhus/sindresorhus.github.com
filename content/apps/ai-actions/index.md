---
title: 'AI Actions'
subtitle: 'AI actions for the Shortcuts app'
publicationDate: 2023-09-26
platforms: [
	'macOS'
	'iOS'
	'visionOS'
]
appStoreID: 6465250302
categories: [
	'shortcuts'
]
nonAppStoreVersion: {
	version: '1.5.2'
	macOS: 27
	url: 'https://www.dropbox.com/scl/fi/kmzufw5hv2we46ae9kcn2/AI-Actions-1.5.2-1791817015.zip?rlkey=117s2j2y3zhelr7vv05g6w8ov&raw=1'
}
olderVersions: [
	{
		version: '1.5.1'
		macOS: '26'
		url: 'https://www.dropbox.com/scl/fi/z45d2f7ngiyc3t7qrbo4f/AI-Actions-1.5.1-macOS-26-1791816899.zip?rlkey=orqginnmip2anbb6jvw2xhi1n&raw=1'
	}
	{
		version: '1.4.5'
		macOS: '15'
		url: 'https://www.dropbox.com/scl/fi/o80d948mabpohlip3je6m/AI-Actions-1.4.5-macOS-15-1769233269.zip?rlkey=lgxnxyzv75g6r82b4c3fitwuz&raw=1'
	}
	{
		version: '1.3.3'
		macOS: '14'
		url: 'https://github.com/user-attachments/files/18376675/AI.Actions.1.3.3.-.macOS.14.zip'
	}
]
privacyNote: 'The actions send their input to the AI service you choose, like OpenAI. The app collects nothing else.'
feedbackNote: 'I cannot provide support for general Shortcuts questions. Use [Reddit](https://www.reddit.com/r/shortcuts) for that.'
---

The app provides additional AI-related actions (GPT, Claude Sonnet/Opus, etc.) for the Shortcuts app.

For example, an action to interact with the ChatGPT API.

> [!NOTE]
> The app requires you to specify your own OpenAI / Anthropic API key.
> Note that ChatGPT Plus or an Anthropic paid account does not give you free API access.

Your API key is securely stored in your keychain, not in a shortcut.

It also supports many more models through [Ollama and Groq](#alternative-providers).

> [!NOTE]
> The macOS version on the App Store requires an Apple silicon Mac. For Intel Macs on macOS 26, use [AI Actions 1.5.1](#older-versions).
> *(This is because Apple only accepted the iOS version and not the macOS version, so on macOS, the iOS version of the app is used, which only runs on Apple silicon Macs)*

<!-- **Apple is currently blocking updates for the iOS app, so I won't be able to submit an update for some time... I plan to get it [published to an alternative App Store](https://appleinsider.com/articles/23/08/15/setapp-plans-to-launch-eu-only-alternative-ios-app-store) in 2024.** -->

> [!TIP]
> You may also like my [Actions](/actions) app.

## Tips

### Ollama and Groq support {#alternative-providers}

The app also supports [Ollama](https://ollama.com/blog/openai-compatibility) (local models like GGUF) and [Groq](https://console.groq.com/docs/openai) (because they have OpenAI API compatibility), making it possible to use it with a lot more models.

Except for Gemini, the app sends requests to the base URL with `/v1/chat/completions` appended. For example, `https://openrouter.ai/api` becomes `https://openrouter.ai/api/v1/chat/completions`. If the server uses a custom port, include it in the base URL (e.g., `https://my-server:8080`).

For Ollama, set the “Base URL” to `http://localhost:11434` (or the network address of your Ollama instance). Since Ollama doesn’t require authentication, just enter any text (e.g., `ollama`) as the OpenAI API key. In the “Ask AI” action, select the “Custom” model and provide the name of the desired model (e.g., “llama3”).

For Groq, specify `https://api.groq.com/openai`. In the “Ask AI” action, select the “Custom” model and provide the name of the desired model.

For OpenRouter, specify `https://openrouter.ai/api`.

For [llama.cpp](https://github.com/ggml-org/llama.cpp/tree/master/tools/server), specify the server address with its port (e.g., `http://localhost:8080`).

For [LM Studio](https://lmstudio.ai/docs/developer/openai-compat), start its server and specify `http://localhost:1234`. Enter any text as the OpenAI API key. In the “Ask AI” action, select the “Custom” model and provide the name of the model.

For [Open WebUI](https://openwebui.com), specify the address of your instance with `/api` appended (e.g., `https://my-server/api`), and use an Open WebUI API key as the API key.

For [Gemini](https://ai.google.dev/gemini-api/docs/openai), specify `https://generativelanguage.googleapis.com/v1beta/openai/`. The app detects Gemini automatically and constructs its endpoint separately, without appending the `/v1/chat/completions` suffix above. In the “Ask AI” action, select the “Custom” model and provide the name of the desired model.

## Frequently Asked Questions {#faq}

### The actions do not show up in the Shortcuts app {#the-actions-do-not-show-up-in-the-shortcuts-app}

This is an iOS/macOS bug. Launch the app once and then restart your device. If that doesn’t work, [try these steps for missing widgets.](https://webtrickz.com/third-party-lock-screen-widgets-not-showing-ios-16/)

### Why are these actions not just part of your Actions app? {#why-are-these-actions-not-just-part-of-your-actions-app}

Apple prevents any app that includes AI-related functionality from being available in China. I didn’t want the [Actions](/actions) app to be unavailable in China just because of one action.

### How is this better than the “Ask ChatGPT” action provided by the official ChatGPT app? {#how-is-this-better-than-the-ask-chatgpt-action-provided-by-the-official-chatgpt-app}

It uses your own API key, so you do not need a ChatGPT account. It also supports longer text, has more options, like a system prompt, temperature, and reasoning effort, and lets you choose the provider: OpenAI, Anthropic (Claude), or an [OpenAI-compatible service](#alternative-providers).

Since version 1.5.2, long replies of the actions do not time out on iOS.

### How is this different from the built-in “Use Model” action? {#use-model}

The Shortcuts app has a built-in “Use Model” action. It uses Apple Intelligence (on the device or with Private Cloud Compute) or ChatGPT, and it is free. If it does what you need, use it.

AI Actions gives you more control:

- It works on devices that do not support Apple Intelligence.
- You choose the provider and the model: OpenAI, Anthropic (Claude), or any [OpenAI-compatible service](#alternative-providers), like Ollama, OpenRouter, Groq, and Gemini.
- It has more options, like a system prompt, temperature, and reasoning effort.

It uses your own API key, so you pay the provider for what you use.

The app has three actions: “Ask AI”, “Ask AI (Response API)”, and “Ask Claude”.

### How is this better than just calling the OpenAI API directly from Shortcuts? {#how-is-this-better-than-just-calling-the-openai-api-directly-from-shortcuts}

This makes it simpler, but more importantly, it stores your API key securely in the keychain. This means you can share your shortcuts with others without exposing your API key. The API key is not stored in the shortcut.

### Can you support the OpenAI Whisper API? {#can-you-support-the-openai-whisper-api}

No. The actions can send text, images, and some documents, like PDFs, to the AI, but not audio. For transcription, use my app [Aiko](/aiko). It runs Whisper locally on your device, so there are no API costs and your audio stays on your device, and it has Shortcuts actions too.

### Can you add built-in support for the Google Gemini API? {#gemini}

No. I don’t want to keep adding more providers, and I especially don’t want to take on Google-specific APIs and auth quirks. More providers means a larger API surface, more edge-cases, and more maintenance.

Workaround: Gemini already offers an OpenAI-compatible endpoint, which this app supports. Set the Base URL to `https://generativelanguage.googleapis.com/v1beta/openai/`, then choose “Custom” and enter the Gemini model name. You can also use an OpenAI-compatible proxy like [OpenRouter](https://openrouter.ai) if you prefer one unified endpoint.
