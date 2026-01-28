---
title: AI Actions
subtitle: AI actions for the Shortcuts app
pubDate: 2023-09-26
platforms:
  - macOS
  - iOS
  - visionOS
appStoreId: 6465250302
forceHasIosAppIcon: true
olderMacOSVersions:
  - '14'
  - '15'
feedbackNote: |
  I cannot provide support for general Shortcuts questions. Use [Reddit](https://www.reddit.com/r/shortcuts) for that.
---

The app provides additional AI-related actions (GPT 5.2, Claude Sonnet/Opus 4.5, etc.) for the Shortcuts app.

For example, an action to interact with the ChatGPT API.

> [!NOTE]
> The app requires you to specify your own OpenAI / Anthropic API key.
> Note that ChatGPT Plus or an Anthropic paid account does not give you free API access.

Your API key is securely stored in your keychain, not in a shortcut.

It also supports many more models through [Ollama and Groq](#alternative-providers).

> [!NOTE]
> The macOS version on the App Store requires an Apple silicon Mac. For Intel Macs, use the [non-App Store version](#non-app-store-version).
> *(This is because Apple only accepted the iOS version and not the macOS version, so on macOS, the iOS version of the app is used, which only runs on Apple silicon Macs)*

<!-- **Apple is currently blocking updates for the iOS app, so I won't be able to submit an update for some time... I plan to get it [published to an alternative App Store](https://appleinsider.com/articles/23/08/15/setapp-plans-to-launch-eu-only-alternative-ios-app-store) in 2024.** -->

<br>

> [!TIP]
> You may also like my [Actions](/actions) app.

## Tips

#### Ollama and Groq support {#alternative-providers}

The app also supports [Ollama](https://ollama.com/blog/openai-compatibility) (local models like GGUF) and [Groq](https://console.groq.com/docs/openai) (because they have OpenAI API compatibility), making it possible to use it with a lot more models.

For Ollama, you need to specify a local URL like `http://localhost:11434` in the “Base URL” setting in the app.

For Groq, specify `https://api.groq.com/openai`. In the “Ask AI” action, select the “Custom” model and provide the name of the desired model.

For OpenRouter, specify `https://openrouter.ai/api`.

For [Gemini](https://ai.google.dev/gemini-api/docs/openai), specify `https://generativelanguage.googleapis.com/v1beta/openai/`. In the “Ask AI” action, select the “Custom” model and provide the name of the desired model.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=AI%20Actions&referrer=Website-FAQ)

#### The actions do not show up in the Shortcuts app

This is an iOS/macOS bug. Launch the app once and then restart your device. If that doesn't work, [try this.](https://webtrickz.com/third-party-lock-screen-widgets-not-showing-ios-16/)

#### Why are these actions not just part of your [Actions](/actions) app?

Apple prevents any app that includes AI-related functionality from being available in China. I didn't want the Actions app to be unavailable in China just because of one action.

#### How is this better than the “Ask ChatGPT” action provided by the official ChatGPT app?

This one works on macOS too, supports longer text, has customizability options for power-users, supports DALL·E, and will support more AI APIs in the future.

#### How is this better than just calling the OpenAI API directly from Shortcuts?

This makes it simpler, but more importantly, it stores your API key securely in the keychain. This means you can share your shortcuts with others without exposing your API key. The API key is not stored in the shortcut.

#### Can you support the OpenAI Whisper API?

No, the Whisper API isn't suitable for this app due to Shortcuts' 30-second limit on third-party actions on iOS, making long transcriptions impossible. Instead, use my app [Aiko](/aiko). It runs Whisper locally on your device and supports Shortcuts by performing transcriptions in the foreground, bypassing the time constraint (on macOS, it runs in the background).

#### Can you add built-in support for the Google Gemini API? {#gemini}

No. I don’t want to keep adding more providers, and I especially don’t want to take on Google-specific APIs and auth quirks. More providers means a larger API surface, more edge-cases, and more maintenance.

Workaround: Gemini already offers an OpenAI-compatible endpoint, which this app supports. Set the Base URL to `https://generativelanguage.googleapis.com/v1beta/openai/`, then choose “Custom” and enter the Gemini model name. You can also use an OpenAI-compatible proxy like [OpenRouter](https://openrouter.ai) if you prefer one unified endpoint.

#### Why is this free without ads?

I just enjoy making apps. Consider leaving a nice review on the App Store.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### [More FAQs…](/apps/faq)

## Older Versions

- [1.4.5](https://www.dropbox.com/scl/fi/o80d948mabpohlip3je6m/AI-Actions-1.4.5-macOS-15-1769233269.zip?rlkey=lgxnxyzv75g6r82b4c3fitwuz&raw=1) for macOS 15+
- [1.3.3](https://github.com/user-attachments/files/18376675/AI.Actions.1.3.3.-.macOS.14.zip) for macOS 14+

## Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/6l6e13n3v01nywhx532cp/AI-Actions-1.5.0-1769231336.zip?rlkey=hv3jek3xtx0l3sv7m8oip1y78&raw=1) *(1.5.0)*

*Requires macOS 26 or later*
