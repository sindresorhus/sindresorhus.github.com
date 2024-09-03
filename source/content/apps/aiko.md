---
title: Aiko
subtitle: AI-powered audio transcription
pubDate: 2023-03-03
platforms:
  - macOS
  - iOS
  - visionOS
appStoreId: 1672085276
olderMacOSVersions:
  - '13'
feedbackNote: |
  Any problems with the output are unfortunately out of my control. The app uses the OpenAI Whisper AI model to transcribe. The model has some flaws with certain recordings like repetition, hallucination, and refusal to produce text.
---

High-quality on-device transcription. Easily convert speech to text from meetings, lectures, and more.

The transcription is powered by OpenAI's [Whisper model](https://openai.com/research/whisper) running locally on your device.

The app also includes [support for Shortcuts](#tips).

<details>
<summary><b>Supports audio in 100 languages</b></summary>

- Afrikaans
- Albanian
- Amharic
- Arabic
- Armenian
- Assamese
- Azerbaijani
- Bangla
- Bashkir
- Basque
- Belarusian
- Bosnian
- Breton
- Bulgarian
- Burmese
- Catalan
- Chinese
- Croatian
- Czech
- Danish
- Dutch
- English
- Estonian
- Faroese
- Finnish
- French
- Galician
- Georgian
- German
- Greek
- Gujarati
- Haitian Creole
- Hausa
- Hawaiian
- Hebrew
- Hindi
- Hungarian
- Icelandic
- Indonesian
- Italian
- Japanese
- Javanese
- Kannada
- Kazakh
- Khmer
- Korean
- Lao
- Latin
- Latvian
- Lingala
- Lithuanian
- Luxembourgish
- Macedonian
- Malagasy
- Malay
- Malayalam
- Maltese
- Marathi
- Mongolian
- Māori
- Nepali
- Norwegian
- Norwegian Nynorsk
- Occitan
- Pashto
- Persian
- Polish
- Portuguese
- Punjabi
- Romanian
- Russian
- Sanskrit
- Serbian
- Shona
- Sindhi
- Sinhala
- Slovak
- Slovenian
- Somali
- Spanish
- Swahili
- Swedish
- Tagalog
- Tajik
- Tamil
- Tatar
- Telugu
- Thai
- Tibetan
- Turkish
- Turkmen
- Ukrainian
- Urdu
- Uzbek
- Vietnamese
- Welsh
- Yiddish
- Yoruba

</details>

#### Privacy

Aiko transcribes audio directly on your device, ensuring complete privacy. It's perfect for sensitive recordings.

#### Technical details

The app uses the Whisper large v2 model on macOS and the medium or small model on iOS depending on available memory.

### Tips

#### Divide text into paragraphs

Aiko divides the transcription text by sentences. If you want the text divided into paragraphs, copy the text from Aiko, go to [ChatGPT](https://chat.openai.com), and use the following prompt.

GPT-4: `Divide the text into paragraphs. Don't change the text otherwise: TRANSCRIPTION TEXT`

GPT-3.5: `Remove newlines and divide the text into paragraphs. Don't change the text otherwise: TRANSCRIPTION TEXT`

#### Fix missing punctation

A flaw of the Whisper model is that transcriptions can sometimes be missing punctation. Try setting the “Prompt” setting (requires macOS 14 / iOS 17) to, for example:

> Hello. I like cake.

If that still doesn't fix it, try copying the text from Aiko, go to [ChatGPT](https://chat.openai.com), and use this prompt: `Fix the missing punctation. Don't change the text otherwise: TRANSCRIPTION TEXT`

#### Batch transcribe {#batch}

Aiko does not yet support batch transcription built-in, but you can achieve it with shortcuts.

Get [this (iOS)](https://www.icloud.com/shortcuts/f790a41e23ae4222920277b4fe9d1217) or [this (macOS)](https://www.icloud.com/shortcuts/0be44e478b9e472192cae2e0dfc327ed) shortcut and then share the audio files you want to transcribe (e.g. from Voice Memos or Files/Finder) and choose the shortcut in the share sheet. You can also run the shortcut directly from the Shortcuts app or even add the shortcut to the Home Screen.

#### Transcribe files directly in Finder

On macOS, you can transcribe files simply by right-clicking audio files in Finder and choosing [this shortcut](https://www.icloud.com/shortcuts/a9b68a1291c44795ae236a3a02322bf6) (add it first) in "Quick Actions". [Preview.](https://twitter.com/sindresorhus/status/1789957043912093954) In the shortcut you can choose whether you want text or subtitles.

#### Record and transcribe by pressing the iPhone action button

[This](https://www.icloud.com/shortcuts/62a62ef967b74ffb897d72ee6a881746) shortcut records, transcribes, and then shows the result in the Aiko app. Save the shortcut and then select it in the action button settings.

If you want to record, transcribe, and then do something with the transcription in your shortcut workflow, check out [this shortcut](https://www.icloud.com/shortcuts/00198bd63c094540ba25fe066245319d). You could, for example, pass the transcription to the ChatGPT shortcut action for further processing.

#### Quickly record and transcribe (iOS)

Do the same as the above, but instead add the shortcut to the Home Screen (can be done in the shortcut settings).

#### Quickly record, transcribe, and add transcription to the Notes app (iOS)

Use [this shortcut](https://www.icloud.com/shortcuts/806ab945539d42acb79354805c50d9d5).

#### Quickly record and transcribe (macOS)

You can use [this shortcut](https://www.icloud.com/shortcuts/e43220d72f3343659e0fda36fee52d72) to be able to quickly record, transcribe, and have the result copied to the clipboard. The shortcut can be triggered from the menu bar or you can set a global keyboard shortcut for it.

#### Start recording in Aiko when tapping the Home Screen icon

[Get this shortcut](https://www.icloud.com/shortcuts/7c3031aa674c405fa69093d1f6c184a6) and add it to the Home Screen. Then tap it instead of the original Aiko app icon.

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Aiko&referrer=Website-FAQ)

#### Can you use the large v3 model for the Mac app?

The v3 model is [worse](https://github.com/openai/whisper/discussions/1762#discussioncomment-7532295) than v2 in too many cases. I tried releasing v3, but got a lot of emails about the quality being worse, so I ended up reverting it.

#### Can you include the large model on iOS?

Even the latest iPhone is not powerful enough to run the large model. It can maybe be done when the [Whisper Distilled](https://github.com/huggingface/distil-whisper) project supports multiple languages.

#### Can I edit the text in the app?

I don't plan to support any editing. Export the transcription and edit it in a proper text editor.

#### How is this better than the built-in transcription on Apple devices?

- Much better accuracy.
- Support for more languages.
- Transcribe audio and video files.
- Export to many different formats, like JSON, CSV, and subtitles.

#### I found a mistake in the transcription

The app uses the OpenAI Whisper model and I have no control over the quality of its output. You could provide feedback about the problem [here](https://github.com/openai/whisper/discussions/categories/general).

#### My language is not in the list of supported languages. Can you support it?

I have no control over the supported languages. You could try to request it [here](https://github.com/openai/whisper/discussions/categories/general).

#### The transcription repeats itself many times

This is unfortunately a flaw in the Whisper model and out of my control.

#### The transcription is missing punctation

This is unfortunately a flaw in the Whisper model. [Workaround.](#tips)

#### The transcription includes a sentence at the end that was not in the audio

This is unfortunately a flaw in the Whisper model. It can sometimes add a sentence like “Thanks for watching!” to the end. There is not much I can do about this.

This issue arises from quirks in the AI's processing, where it sometimes generates off-topic content, often due to data remnants or misinterpreted context. These are not messages or 'whispers' with any underlying meaning; they're random anomalies that OpenAI is actively working to correct.

#### The transcription is not in the same language as the source audio

Ensure the "Translate to English" setting is disabled.

The language used in the "Prompt" setting may also affect the transcription language.

#### The transcription is in Traditional Chinese while the audio was in Simplified Chinese or the inverse

The [Whisper AI model](https://github.com/openai/whisper) used by the app does not differentiate between Traditional Chinese and Simplified Chinese, so the result could unfortunately end up with either. [Learn more.](https://github.com/openai/whisper/discussions/277)

Try writing a sentence in Traditional Chinese or Simplified Chinese in the “Prompt” setting in the app to steer the model into using the right one.

#### Why must I keep the iOS app open while it transcribes?

iOS apps are fundamentally restricted from operating in the background for extended periods. This ironically even [affects Apple's official apps](https://twitter.com/bzamayo/status/1661133704792621059).

#### What file formats does it support?

Any audio and video format that macOS and iOS supports. For example: `.m4a`, `.wav`, `.mp3`, `.mp4`, `.mov`. It does not support `.ogg`.

#### How can I delete audio recordings?

The audio recordings can be deleted in the Files app.

#### How can I transcribe audio from the Voice Memos app?

**macOS:** Drag and drop the memo into the Aiko window. Note that because of a macOS bug, this can sometimes crash Aiko. If this happens, try sharing the memo from the Voice Memos app to Aiko instead.

**iOS:** In the Voice Memos app, tap the memo, tap the `…` button, tap `Share`, and choose Aiko in the app list.

#### Why does it take so long to generate?

Several factors can affect the transcription speed, including the performance of your device and the amount of available memory and CPU. Try closing down other apps or restarting your device before transcribing.

That being said, it's likely Aiko will become significantly faster in the coming months.

#### Why does the app take up so much space on disk and memory?

The app delivers the highest quality transcription on the market for 100 different languages. Rather than asking why it's so large, the real question is how is it so small.

#### The app is overheating my device

The role of the operating system (iOS/macOS) is to effectively manage the system's resources and to safeguard against overheating. Apps are designed to utilize as many resources as they need to function optimally. In the event that resource consumption reaches a point that threatens to overheat the device, it's the operating system's job to limit such usage automatically.

If your device is experiencing overheating while using the app, it's important to understand that the issue likely originates either from the operating system's inability to manage resources effectively, or from an underlying hardware problem. In either case, the app itself is not responsible for the overheating.

#### Can I delete some of the languages to save space?

This is unfortunately not possible. The model has all the languages stored together in a way that makes it impossible to remove just some languages.

#### Can you support real-time transcription?

This is something I plan to look into, but I have more popular requests I need to prioritize first.

#### Can you support naming the people in the audio? {#diarization}

This is called [Diarization](https://en.wikipedia.org/wiki/Speaker_diarisation). It's something I would like to support, but it has to first be [implemented in the library](https://github.com/ggerganov/whisper.cpp/issues/64) the app uses.

#### How can I transcribe a Zoom meeting? {#zoom}

The app does not yet support live transcription, but you could record the Zoom meeting, and after the meeting is finished, drop the recording into the Aiko window to transcribe.

#### How can I transcribe a Messages voice note? {#messages}

Drag and drop the voice note into Aiko.

[How to drag and drop on iPhone.](https://www.imore.com/how-use-drag-and-drop-iphone)

#### How can I transcribe a Telegram voice note? {#telegram}

Telegram voice notes are stored in the format [Ogg](https://en.wikipedia.org/wiki/Ogg), which macOS/iOS cannot handle.

Workaround for iOS:
1. Download [this app](https://apps.apple.com/app/id889643660).
2. In Telegram, share the voice note to “Audio Converter”.
3. Select “AAC” as output format and tap the convert button.
4. Tap the share button and then choose Aiko.

Workaround for macOS:
1. Download [this app](https://apps.apple.com/app/id1081480270)
2. In Telegram, right-click the voice note and save it.
3. Open the saved voice note with the “Audio Converter” app.
4. Select “AAC” as output format and tap the convert button.
5. Save the converted file and open it with Aiko.

*I would also recommend sending feedback to Telegram that they should support M4A for voice notes.*

#### How can I export the transcription as subtitles (SRT)?

When the transcription is done, click the save button in the toolbar, and choose “SRT”.

#### How can I transcribe a YouTube video?

Download the audio using a service like [dirpy](https://dirpy.com) or the macOS app [Downie](https://software.charliemonroe.net/downie/) and then open the file in Aiko.

This cannot be supported built-in as downloading videos from YouTube is against their Terms of Service and Apple would likely reject such a feature.

#### The app supports translating to English, can it support more languages?

The translation support is built into the AI model and it only supports translating to English. You could copy-paste the result into ChatGPT or Google Translate.

#### How can I trigger Aiko with a custom URL scheme?

Aiko does not have a custom URL scheme, but you can trigger Aiko from the Shortcuts app, and the Shortcuts app does have a [custom URL scheme](https://support.apple.com/guide/shortcuts/run-a-shortcut-from-a-url-apd624386f42/ios).

#### How is Aiko pronounced?

IPA (International Phonetic Alphabet): `[a.i.ko̞]`

English approximation: `ah-ee-ko`

#### Is the app native?

Yes, it's native and written in Swift and SwiftUI.

#### Why is this free without ads?

I just enjoy making apps. Consider leaving a nice review on the App Store.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### [More FAQs…](/apps/faq)

### Older Versions

- [1.5.3](https://drive.google.com/file/d/15NOcj4fyX58I3_NlQyCziL87Ru89yFRx/view?usp=sharing) for macOS 13+

### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://drive.google.com/file/d/18BE9Pn8QVsVQ-FOT_Q2aMEkpLJahbhC9/view?usp=sharing) *(1.6.0 · 3 GB)*

*Requires macOS 14 or later*
