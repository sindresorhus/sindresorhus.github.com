---
title: 'How to Use ChatGPT in Shortcuts on iPhone and Mac'
description: 'Use ChatGPT in the Shortcuts app with the built-in Use Model action, or with the Ask AI action of AI Actions and your own API key.'
publicationDate: 2026-11-07
topic: 'iphone'
apps: [
	'ai-actions'
]
screenshot: {
	number: 1
	description: 'A shortcut with the Ask AI action and the reply of the AI'
}
---

@QuickAnswer {
	On a device with Apple Intelligence, add the built-in “Use Model” action to a shortcut, and choose “Extension Model”, which uses ChatGPT. To choose the model, add a system prompt, or use it on any device, add the “Ask AI” action of [AI Actions](../apps/ai-actions/index.md) with your own OpenAI API key.
}

## With AI Actions

@Steps {
1. Get an API key on the [OpenAI platform](https://platform.openai.com/api-keys). A ChatGPT Plus plan does not include API access, so you pay OpenAI for what you use.
1. Open [AI Actions](../apps/ai-actions/index.md), open “Settings”, and paste the key in “OpenAI API Key”.
1. In the Shortcuts app, make a new shortcut, and add the “Ask AI” action.
1. Type your prompt, or insert a variable, like the text that the shortcut gets. Expand the action to choose the model and add a system prompt.
1. Run the shortcut. The reply of the AI is the output of the action, which the next action can use.
}

AI Actions is free, and stores your API key in the keychain, not in the shortcut, so you can share your shortcuts. It also has “Ask Claude” for Anthropic, and works with [Ollama, Groq, and other services](../apps/ai-actions/index.md#alternative-providers). If the actions do not show in Shortcuts, restart your device.

The ChatGPT app also has an “Ask ChatGPT” action, but it needs the ChatGPT app and its account. [How AI Actions is different](../apps/ai-actions/index.md#use-model).

## Without an app

On iOS 26 and macOS 26 or later, with Apple Intelligence (the names of the models below are from iOS 27 and macOS 27):

@Steps {
1. In the Shortcuts app, make a new shortcut.
1. Add the “Use Model” action, and choose “Extension Model” to use ChatGPT. “On-Device”, “Cloud”, and “Cloud Pro” use the models of Apple.
1. Type your prompt in the text field below “Use Model”, and run the shortcut.
}

“Use Model” is free, but it needs a device that supports Apple Intelligence, like iPhone 15 Pro or later, and Apple Intelligence is not in all languages or regions. If it does what you need, use it. AI Actions is for other devices, other models, and more options.
