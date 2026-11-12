---
title: 'How to Use Ollama and Local AI Models in Shortcuts on Mac'
description: 'Use the AI models of Ollama, LM Studio, or llama.cpp in the Shortcuts app with the Ask AI action of AI Actions, so your text stays on your Mac.'
publicationDate: 2026-11-12
topic: 'shortcuts'
apps: [
	'ai-actions'
]
---

@QuickAnswer {
	In [AI Actions](../apps/ai-actions/index.md), set “Ask AI Base URL” to `http://localhost:11434`, and enter any text as the API key. Then add the “Ask AI” action to a shortcut, choose the “Custom” model, and type the name of an Ollama model. Without an app, the built-in “Use Model” action can use the model of Apple on the device.
}

## With AI Actions

@Steps {
1. [Install Ollama](https://ollama.com/download), and download a model, like with `ollama pull llama3.2` in the Terminal app. Keep Ollama open.
1. Open [AI Actions](../apps/ai-actions/index.md), and open its settings (the first time, click “Set API key (required)”).
1. In “Ask AI Base URL”, enter `http://localhost:11434`.
1. Ollama needs no API key, but the field must have text. Enter any text, like `ollama`, in “OpenAI API Key”.
1. In the Shortcuts app, make a new shortcut, and add the “Ask AI” action.
1. Type your prompt. Expand the action, set “Model” to “Custom”, and type the name of the model, like `llama3.2`, in the field for the model name. The command `ollama list` shows the names of your models.
1. Run the shortcut. The result, “AI Reply”, is text that the next action can use.
}

AI Actions is free, and Ollama is free. The model runs on your Mac, so your text does not go to a server, and there are no API costs.

@Tips {
- For Ollama on another computer, first set Ollama on that computer to accept connections from the network (set `OLLAMA_HOST` to `0.0.0.0`). Then enter its network address, like `http://192.168.1.20:11434`. AI Actions asks for access to the local network. `http://` works only with IP addresses, “.local” hosts, and single-word hosts like “localhost”.
- For LM Studio, start its server, and enter `http://localhost:1234`. For llama.cpp, start `llama-server`, and enter `http://localhost:8080`.
- The base URL is for all “Ask AI” actions, so they all use Ollama until you click “Reset”.
- For Gemini, see [how to use Gemini in Shortcuts](gemini-in-shortcuts.md).
}

## Without an app

On macOS 26 or later with Apple Intelligence, the built-in “Use Model” action can use the model of Apple on your Mac:

@Steps {
1. In the Shortcuts app, make a new shortcut.
1. Add the “Use Model” action, and choose the model on the device (“On-Device” in macOS 27).
1. Type your prompt in the action, and run the shortcut.
}

It is free, and it works offline. If it does what you need, use it.

To use Ollama itself without an app, send a request to the [Ollama API](https://docs.ollama.com/api) with the “Get Contents of URL” action. You must make the request and read the reply yourself. AI Actions does this for you.
