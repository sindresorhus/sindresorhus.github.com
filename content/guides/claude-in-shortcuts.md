---
title: 'How to Use Claude in Shortcuts on iPhone and Mac'
description: 'Use Claude in the Shortcuts app with the Ask Claude action of the Claude app on iPhone, or with AI Actions and your own Anthropic API key.'
publicationDate: 2026-11-11
topic: 'iphone'
apps: [
	'ai-actions'
]
---

@QuickAnswer {
	On iPhone, the Claude app has an “Ask Claude” action for Shortcuts, which uses your Claude account. To choose the model, add a system prompt, or send images and PDFs, also on a Mac, use the “Ask Claude” action of [AI Actions](../apps/ai-actions/index.md) with your own Anthropic API key.
}

## With AI Actions

@Steps {
1. Get an API key in the [Claude Console](https://platform.claude.com/settings/keys). Anthropic bills the API separately from a Claude plan, so you pay for what you use.
1. Open [AI Actions](../apps/ai-actions/index.md), open “Settings”, and paste the key in “Anthropic API Key”.
1. In the Shortcuts app, make a new shortcut, and add the “Ask Claude” action of AI Actions.
1. Type your prompt, or insert a variable, like the text that the shortcut gets. Expand the action to choose the model, and to add a system prompt, images, or PDFs.
1. Run the shortcut. The result, “Claude Reply”, is text that the next action can use.
}

AI Actions is free. It stores your API key in the keychain, not in the shortcut, so you can share your shortcuts. The action does not remember earlier conversations.

@Tips {
- “Effort” sets how much Claude thinks, and “Max Output Tokens” limits the length of the reply.
- To get a dictionary, end your prompt with “Return the result as a JSON object. Don't include any other text than the JSON object.”, and give the result to the “Get Dictionary from Input” action.
- For ChatGPT and other models, see [how to use ChatGPT in Shortcuts](chatgpt-in-shortcuts.md).
}

## Without an app

The Claude app for iPhone has its own “Ask Claude” action, on iOS 18 and later:

@Steps {
1. Install the Claude app.
1. In the Shortcuts app, make a new shortcut, and add the “Ask Claude” action of the Claude app.
1. Type your prompt in the action, and run the shortcut.
}

It uses the default model of the Claude app, and the messages count for the usage limit of your plan. You can also say “Ask Claude” to Siri. [Anthropic’s instructions.](https://support.claude.com/en/articles/10263469-using-claude-app-intents-shortcuts-and-widgets-on-ios)

If you have the Claude app and only want an answer in a shortcut, use this. AI Actions is for when you want to choose the model and the other options, or pay for the API and not for a plan.
