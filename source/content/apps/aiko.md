---
title: Aiko
subtitle: AI-powered audio transcription
pubDate: 2023-03-03
platforms:
  - macOS
  - iOS
appStoreId: 1672085276
---

High-quality on-device transcription. Easily convert speech to text from meetings, lectures, and more.

The transcription is powered by OpenAI's [Whisper model](https://openai.com/research/whisper) running locally on your device.

The app also includes support for Shortcuts.

My goal is to keep the app simple. If you have more advanced needs, check out [MacWhisper](https://goodsnooze.gumroad.com/l/macwhisper).

**Upcoming features**

- Batch conversion
- Significantly improved performance on iOS thanks to CoreML
- Export to karaoke file
- ChatGPT integration

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

<br>

### Tips

#### Divide text into paragraphs

Aiko divides the transcription text by sentences. If you want the text divided into paragraps, copy the text from Aiko, go to [ChatGPT](https://chat.openai.com), and use the following prompt.

GPT-4: `Divide the text into paragraphs. Don't change the text otherwise: TRANSCRIPTION TEXT`
GPT-3.5: `Remove newlines and divide the text into paragraphs. Don't change the text otherwise: TRANSCRIPTION TEXT`

#### Fix missing punctation

A flaw of the Whisper model is that transcriptions can sometimes be missing punctation. To fix missing punctation, copy the text from Aiko, go to [ChatGPT](https://chat.openai.com), and use this prompt: `Fix the missing punctation. Don't change the text otherwise: TRANSCRIPTION TEXT`

#### Quickly record and transcribe (macOS)

You can use [this shortcut](https://www.icloud.com/shortcuts/d2f19692f9674e03a8f4319d2a3e9dc2) to be able to quickly record, transcribe, and have the result copied to the clipboard. The shortcut can be triggered from the menu bar or you can set a global keyboard shortcut for it.

Known issue: The shortcut has to momentarily show the Aiko app and then hide it again. This is a limitation of how Shortcuts works.

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Aiko&referrer=Website-FAQ)

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

#### Why must I keep the iOS app open while it transcribes?

iOS apps are fundamentally restricted from operating in the background for extended periods. This ironically even [affects Apple's official apps](https://twitter.com/bzamayo/status/1661133704792621059).

#### What file formats does it support?

Any audio and video format that macOS and iOS supports. For example: `.m4a`, `.wav`, `.mp3`, `.mp4`, `.mov`. It does not support `.ogg`.

#### How can I transcribe audio from the Voice Memos app?

**macOS:** Drag and drop the memo into the Aiko window. Note that because of a macOS bug, this can sometimes crash Aiko. If this happens, try sharing the memo from the Voice Memos app to Aiko instead.

**iOS:** In the Voice Memos app, tap the memo, tap the `…` button, tap `Share`, and choose Aiko in the app list.

#### Why does it take so long to generate?

Several factors can affect the transcription speed, including the performance of your device and the amount of available memory and CPU. Try closing down other apps or restarting your device before transcribing.

That being said, it's likely Aiko will become significantly faster in the coming months.

#### Why does the app take up so much space on disk and memory?

The app delivers the highest quality transcription on the market for 100 different languages. Rather than asking why it's so large, the real question is how is it so small.

#### Can I delete some of the languages to save space?

This is unfortunately not possible. The model has all the languages stored together in a way that makes it impossible to remove just some languages.

#### Can you support real-time transcription?

This is something I plan to look into, but I have more popular requests I need to prioritize first.

#### Can you support naming the people in the audio? {#diarization}

This is called [Diarization](https://en.wikipedia.org/wiki/Speaker_diarisation). It's something I would like to support, but it has to first be [implemented in the library](https://github.com/ggerganov/whisper.cpp/issues/64) the app uses.

#### How can I transcribe a Zoom meeting? {#zoom}

The app does not yet support live transcription, but you could record the Zoom meeting, and after the meeting is finished, drop the recording into the Aiko window to transcribe.

#### How can I transcribe a Telegram voice note? {#telegram}

Telegram voice notes are stored in the format [Ogg](https://en.wikipedia.org/wiki/Ogg), which macOS/iOS cannot handle.

Workaround for iOS:
1. Download [this app](https://apps.apple.com/app/id889643660).
2. In Telegram, share the voice note to “Audio Converter”.
3. Select “AAC” as output format and tap the convert button.
4. Tap the share button and then choose Aiko.

Workaround for macOS:
1. Download [this app](https://apps.apple.com/appid1081480270)
2. In Telegram, right-click the voice note and save it.
3. Open the saved voice note with the “Audio Converter” app.
4. Select “AAC” as output format and tap the convert button.
5. Save the converted file and open it with Aiko.

*I would also recommend sending feedback to Telegram that they should support M4A for voice notes.*

#### How can I export the transcription as subtitles (SRT)?

When the transcription is done, click the share button in the toolbar, and choose “SRT”.

#### How can I transcribe a YouTube video?

Download the audio using a service like [dirpy](https://dirpy.com) and then open the file in Aiko.

#### The app supports translating to English, can it support more languages?

The translation support is built into the AI model and it only supports translating to English. You could copy-paste the result into ChatGPT or Google Translate.

#### Is the app native?

Yes, it's native and written in Swift and SwiftUI.

#### Why is this free without ads?

I just enjoy making apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1672085276) and click “Version History”.

#### Can you localize the app into my language?

I don't plan to localize the app.

<br>

### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://drive.google.com/file/d/12XOL8GeiqM4N3EFuw-ZZU_Hh-nXfYQLB/view?usp=sharing) *(1.2.0 · 3 GB)*

*Requires macOS 13 or later*
