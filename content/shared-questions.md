<!--
Questions that some apps share. An app adds a question to its FAQ with the ID of its heading in its frontmatter:

sharedQuestions: [
	'suggested-filenames'
]

Each question is a level 3 heading with a short ID, followed by its answer. Link to pages with site paths, like `/apps/faq#refund`, as the answers are shown on the app pages.

The questions go after the questions of the app. A question about a problem has the `@faq.first` directive below its heading, so it goes before them.
-->

### How can I turn off automatic filename suggestions when saving? {#suggested-filenames}
<!-- @faq.keywords file name suggest generated title -->

On macOS:

1. Open Finder.
2. Click Finder in the menu bar, then Settings.
3. Go to the General tab.
4. Uncheck “Suggest file names”.

### Is the app native? {#native}

Yes, it’s native and written in Swift and SwiftUI.

### Why is this not in the App Store? {#not-in-app-store}

Much of the functionality would not be possible in the App Store because of [sandboxing](/apps/faq#macos-sandbox).

### How can I export, import, sync, transfer, or back up the settings? {#backup-settings}

[See this answer](/apps/faq#export-settings)

### The app randomly quits {#randomly-quits}
<!-- @faq.first -->
<!-- @faq.keywords disappears vanishes closes -->

If there is no [crash report](/apps/faq#crash-report), macOS most likely quit the app to free up memory or disk space. Keep at least 10–20 GB of free disk space, and do not use tools that “free up purgeable space”, like CleanMyMac, as they make macOS quit apps too. A restart of the computer can also help. This is a [common problem for macOS apps](https://bitsplitting.org/2022/06/18/purgeable-mac-apps/).

### Can you add sync? {#sync}

No. iCloud sync is unreliable and causes a huge support burden. It’s not worth the effort for this app.

### The text sometimes jumps when I write fast {#text-jumps}
<!-- @faq.first -->

This is a macOS bug. There is unfortunately nothing I can do about it.

### Why is it suddenly showing a scrollbar? {#why-is-it-suddenly-showing-a-scrollbar}

You either have a system setting set to always show scrollbars or you have an external mouse connected. This is simply how macOS works. You can see the behavior in other text editing apps too. See the “Appearance › Show scroll bars” system setting.

### Can you add another menu bar icon option? {#menu-bar-icons}
<!-- @faq.keywords emoji symbol -->

Sure! Find an icon you like in the [SF Symbols app](https://developer.apple.com/sf-symbols/) or on [The Noun Project](https://thenounproject.com/icons/), and send me the name or a link.

### The menu bar item looks blurry or is not dimmed on my secondary display {#blurry-secondary-display}
<!-- @faq.first -->

[See this answer](/apps/faq#menu-bar-secondary-display)

### Why does it not show week 53? {#week-53}

You are probably expecting [ISO week-numbering](https://en.wikipedia.org/wiki/ISO_week_date) while having your system set to [Gregorian week numbering](https://en.wikipedia.org/wiki/ISO_week_date#Relation_with_the_Gregorian_calendar). You can change it in “[System Settings › General › Language & Region](x-apple.systempreferences:com.apple.Localization-Settings.extension)”: set “Calendar” to ISO 8601 for ISO week numbers, or to Gregorian for Gregorian week numbers. With Gregorian, the “First Day of Week” setting in the same pane also changes the week numbers.

### Why does it show the last days of December as week 1? {#december-week-1}

That is called [ISO week-numbering](https://en.wikipedia.org/wiki/ISO_week_date).

### It shows the incorrect week number {#incorrect-week-number}

You are probably expecting [ISO week-numbering](https://en.wikipedia.org/wiki/ISO_week_date) while having your system set to [Gregorian week numbering](https://en.wikipedia.org/wiki/ISO_week_date#Relation_with_the_Gregorian_calendar), or the inverse. You can change it in “[System Settings › General › Language & Region](x-apple.systempreferences:com.apple.Localization-Settings.extension)”: set “Calendar” to ISO 8601 for ISO week numbers, or to Gregorian for Gregorian week numbers. With Gregorian, the “First Day of Week” setting in the same pane also changes the week numbers.

### How can I change the week number to ISO 8601 format? {#iso-week-number}

Go to “[System Settings › General › Language & Region](x-apple.systempreferences:com.apple.Localization-Settings.extension)”, and set “Calendar” to [ISO 8601](https://en.wikipedia.org/wiki/ISO_week_date).

### The widget does not show up in the widget picker, is stuck, or is missing {#widget-missing}
<!-- @faq.keywords home lock screen -->
<!-- @faq.first -->

The iOS widget system is quite buggy and can fail a lot. This is not a problem with the app and is out of my control. See [how to fix a widget that does not show up](/apps/faq#widget-not-showing).

### Can you make the widget background transparent? {#widget-transparent-background}

This is not possible.

### When using the “Run Shortcut” action, why does tapping the widget first open the main app and then the Shortcuts app? {#widget-run-shortcut}

This is because of iOS limitations. A widget can only open its own app when a user taps it. And the only way to run a shortcut is to open the Shortcuts app using a special URL. So when you tap the widget, the widget opens the main app, and the main app then opens the Shortcuts app. It’s not a very good user experience, but only Apple can fix this.

If you work at Apple, you know what to do:
- [FB9745173](https://github.com/feedback-assistant/reports/issues/240)
- [FB11516334](https://github.com/feedback-assistant/reports/issues/357)
- [FB11516273](https://github.com/feedback-assistant/reports/issues/356)

### Can I make the widget horizontally centered on the Lock Screen? {#lock-screen-centered}

This is unfortunately not possible. Apple has decided that the rectangular widget can only appear on the left or right side.

### Can I pick a color for the text on the Lock Screen? {#lock-screen-text-color}

Lock Screen widgets cannot have colors. You can set a custom text color for the normal widgets though.

### Can I pick a background color for the Lock Screen widgets? {#lock-screen-background-color}

Lock Screen widgets cannot have colors.

### Can the Lock Screen widgets be full-colored? {#lock-screen-full-color}

This is unfortunately not possible. iOS enforces that Lock Screen widgets are single-colored.

### The widget does not update if I write some text in the app and then reveal the Lock Screen {#lock-screen-update}

You need to first close the app. This is an iOS bug.

If you work at Apple → [FB11522275](https://github.com/feedback-assistant/reports/issues/360)

<!-- Apps that pick this question also pick `lock-screen-delayed-update` directly after it, as its question refers to this one. -->

### The widget does not update even if I do the above {#lock-screen-delayed-update}

The app tells iOS to update the widget. Unfortunately, iOS can decide to delay an update for various reasons (low battery, Low Power Mode, etc.). This is completely out of my control.

### The Lock Screen widget does not show the text after restarting the device, before unlocking it {#lock-screen-after-restart}

This is an iOS limitation and is out of my control. It shows a placeholder until the first unlock. This is how all Lock Screen widgets work.

### The Lock Screen widget sometimes disappears {#lock-screen-widget-disappears}
<!-- @faq.first -->

Make sure Lock Screen widgets are allowed when locked: “Settings › Face ID & Passcode › Allow Access When Locked › Lock Screen Widgets”. If it’s “off”, iOS may hide the widget until you unlock.

### Can you support custom models? {#ai-custom-models}

I don’t plan to support this. This app is intentionally simple. There are many other apps that support custom models.

### Can you support inpainting/outpainting? {#ai-inpainting}

I don’t plan to support this. [Draw Things](https://drawthings.ai) supports inpainting, outpainting, and custom models.

### Why can it not generate adult images? {#ai-adult-images}

The app would not be allowed on the App Store if it allowed creating such images.

### Why does it take so long to generate? {#ai-slow}

Several factors can affect the speed of image generation, including the performance of your device and the amount of available memory and CPU. Try closing down other apps or restarting your device before generating images.

### Why does the app take up so much space on disk and memory? {#ai-model-size}

The AI model used to generate images is large. This is reasonable given the model’s capabilities.

### Are the generated images marked as AI-generated? {#ai-marking}

Yes. Images that you save, share, drag out, or get from Shortcuts have the [IPTC digital source type](https://cv.iptc.org/newscodes/digitalsourcetype/trainedAlgorithmicMedia) “trainedAlgorithmicMedia” in their metadata (the XMP property `Iptc4xmpExt:DigitalSourceType`). This machine-readable mark tells other software that the image was made by AI. It is there because of the EU AI Act (Article 50(2)). The app adds it even when “Include prompt in image metadata” is off. To see it, use a metadata viewer such as [ExifTool](https://exiftool.org): `exiftool -DigitalSourceType image.png`.

The mark is metadata only. Copied images do not have it. It is lost when you take a screenshot of the image, and it can be lost when you convert the image to a different format or upload it to a website that removes metadata. The app does not add C2PA Content Credentials or an invisible watermark.

### How can I make the app detect the link of any video call service? {#any-video-call-link}

The app can detect the link of any video call service if you correctly add it in the Calendar app:
- Create a new event.
- Paste the video call link into the location field.
- Accept the dropdown suggestion about it being a video call.

If you don’t use the Calendar app, you can add the following to the notes field of an event:

```
----( Video Call )----
https://some-video-call-service.com/join/23423
---===---
```

### What are tracking parameters and why would I want to remove them? {#tracking-parameters}

Removing tracking parameters improves privacy and also makes URLs more aesthetically pleasing. Tracking parameters are used by many websites to track your browsing activity across websites. [Learn more about UTM parameters.](https://en.wikipedia.org/wiki/UTM_parameters)

The app supports 200+ common tracking parameters (e.g. Google UTM) and it has special support for removing tracking from links to X (Twitter), Facebook, and TikTok.

Before: `https://foo.com?utm_content=buffercf3b2&utm_source=snapchat.com`\
After: `https://foo.com`

Did you know that if you click a TikTok link that someone shared with you, they will be able to see that you watched it? The app anonymizes TikTok links so that you will not be tracked.

### Why ++Command+X++? I can already move files with ++Command+C++ and ++Option+Command+V++ {#why-cut-and-paste}

- It’s more logical to cut & paste than copy & move.
- Consistency and muscle memory benefits if you also use Linux or Windows.
