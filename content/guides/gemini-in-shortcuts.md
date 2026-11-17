---
title: 'How to Use Gemini in Shortcuts on iPhone and Mac'
description: 'Use Google Gemini in the Shortcuts app with the Ask AI action of AI Actions and your own Gemini API key.'
publicationDate: 2026-11-12
topic: 'shortcuts'
apps: [
	'ai-actions'
]
---

@QuickAnswer {
	In [AI Actions](/ai-actions), enter your Gemini API key and the Gemini base URL. Then add the “Ask AI” action to a shortcut, choose the “Custom” model, and type the name of a Gemini model. Shortcuts has no built-in action for Gemini.
}

## With AI Actions

@Steps {
1. Get a Gemini API key in [Google AI Studio](https://aistudio.google.com/apikey).
1. Open [AI Actions](/ai-actions), and open its settings (the first time, tap or click “Set API key (required)”). Paste the key in “OpenAI API Key”.
1. In “Ask AI Base URL”, enter `https://generativelanguage.googleapis.com/v1beta/openai/`.
1. In the Shortcuts app, make a new shortcut, and add the “Ask AI” action.
1. Type your prompt, or insert a variable. Expand the action, set “Model” to “Custom”, and type the name of a [Gemini model](https://ai.google.dev/gemini-api/docs/models), like `gemini-3.8-flash`, in the field for the model name.
1. Run the shortcut. The result, “AI Reply”, is text that the next action can use.
}

AI Actions is free. Google bills the API, and it has a free tier with limits. [Google: Gemini API pricing](https://ai.google.dev/gemini-api/docs/pricing)

The base URL is for all “Ask AI” actions. While it is the Gemini URL, “Ask AI” cannot use the models of OpenAI. The “Ask AI (Response API)” action does not use the base URL, so it always uses OpenAI.

@Tips {
- AI Actions stores your API key in the keychain, not in the shortcut, so you can share your shortcuts.
- To keep the key of another API out of a shortcut, use the keychain actions of Actions. <guide:shortcuts-store-api-key>
- To use models on your own Mac, see [how to use Ollama in Shortcuts](guide:ollama-in-shortcuts).
- For ChatGPT, see [how to use ChatGPT in Shortcuts](guide:chatgpt-in-shortcuts).
}

## Without an app

The Shortcuts app has no action for Gemini. Its built-in “Use Model” action uses the models of Apple or ChatGPT, on iOS 26 and macOS 26 or later with Apple Intelligence. It is free. If you do not need Gemini, use it:

@Steps {
1. In the Shortcuts app, make a new shortcut.
1. Add the “Use Model” action, and choose a model.
1. Type your prompt in the action, and run the shortcut.
}

You can also send a request to the Gemini API with the “Get Contents of URL” action, but you must make the request and read the reply yourself. AI Actions does this for you.
