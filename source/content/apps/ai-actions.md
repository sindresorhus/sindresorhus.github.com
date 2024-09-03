---
title: AI Actions
subtitle: AI actions for the Shortcuts app
pubDate: 2023-09-26
platforms:
  - macOS
  - iOS
  - visionOS
appStoreId: 6465250302
# olderMacOSVersions:
#   - '14'
---

The app provides additional AI-related actions (o1 Preview, o1 mini, GPT-4o, GPT-4o mini, GPT-4, GPT 3.5) for the Shortcuts app.

For example, an action to interact with the ChatGPT API.

**The app requires you to specify your own OpenAI API key.**\
Note that ChatGPT Plus does not give you free API access.

Your API key is securely stored in your keychain, not in a shortcut.

It also supports many more models through [Ollama and Groq](#alternative-providers).

**The macOS version on the App Store requires an Apple silicon Mac.** For Intel Macs, use the [non-App Store version](#non-app-store-version).\
*(This is because Apple only accepted the iOS version and not the macOS version, so on macOS, the iOS version of the app is used, which only runs on Apple silicon Macs)*

<!-- **If you are getting a `Missing response` error, it's most likely that the OpenAI safety system prevented your prompt. Try something else.** -->

<!-- **Apple is currently blocking updates for the iOS app, so I won't be able to submit an update for some time... I plan to get it [published to an alternative App Store](https://appleinsider.com/articles/23/08/15/setapp-plans-to-launch-eu-only-alternative-ios-app-store) in 2024.** -->

<br>

*You may also like my [Actions](/actions) app.*

### Tips

#### Ollama and Groq support {#alternative-providers}

The app also supports [Ollama](https://ollama.com/blog/openai-compatibility) (local models like GGUF) and [Groq](https://console.groq.com/docs/openai) (because they have OpenAI API compatibility), making it possible to use it with a lot more models.

For Ollama, you need to specify a local URL like `http://localhost:11434` in the “Base URL” setting in the app. For Groq, specify `https://api.groq.com/openai`. In the “Ask AI” action, select the “Custom” model and provide the name of the desired model.

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=AI%20Actions&referrer=Website-FAQ)

#### The actions do not show up in the Shortcuts app

This is a iOS/macOS bug. Launch the app once and then restart your device. If that doesn't work, [try this.](https://webtrickz.com/third-party-lock-screen-widgets-not-showing-ios-16/)

#### Why are these actions not just part of your [Actions](/actions) app?

Apple prevents any app that includes AI-related functionality from being available in China. I didn't want the Actions app to be unavailable in China just because of one action.

#### How is this better than the “Ask ChatGPT” action provided by the official ChatGPT app?

This one works on macOS too, supports longer text, has customizability options for power-users, supports DALL·E, and will support more AI APIs in the future.

#### How is this better than just calling the OpenAI API directly from Shortcuts?

This makes it simpler, but more importantly, it stores your API key securely in the keychain. This means you can share your shortcuts to others without exposing your API key. The API key is not stored in the shortcut.

#### Can you support the OpenAI Whisper API?

No, the Whisper API isn't suitable for this app due to Shortcuts' 30-second limit on third-party actions on iOS, making long transcriptions impossible. Instead, use my app [Aiko](/aiko). It runs Whisper locally on your device and supports Shortcuts by performing transcriptions in the foreground, bypassing the time constraint (on macOS, it runs in the background).

#### Why is this free without ads?

I just enjoy making apps. Consider leaving a nice review on the App Store.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### [More FAQs…](/apps/faq)

<!--

### Older Versions

- []() for macOS 14+ -->

### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/ynshza7kwswtqni305rlv/AI-Actions-1.3.2-1729497370.zip?rlkey=5rslkkuknr5sr6bphf9asrgsc&raw=1) *(1.3.2)*

*Requires macOS 14 or later*
