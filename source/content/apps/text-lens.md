---
title: Text Lens
subtitle: Copy unselectable text on screen
pubDate: 2025-03-29
platforms:
  - macOS
isPaid: true
isMenuBarApp: true
appStoreId: 6743369285
# olderMacOSVersions:
#   - '15'
feedbackNote: |
  [It made a mistake or the detection quality could be improved.](/text-lens#quality)
---

Extract text from anywhere on your screen. Select any area containing text - from images, videos, PDFs, or presentations - and instantly convert it to editable text.

<details>
<summary><b>Supported languages</b></summary>

- English
- French
- Italian
- German
- Spanish
- Portuguese
- Chinese, Simplified
- Chinese, Traditional
- Cantonese, Simplified
- Cantonese, Traditional
- Korean
- Japanese
- Russian
- Ukrainian
- Thai
- Vietnamese
- Arabic
- Arabic, Najdi

</details>

## Tips

- When in capturing mode, simply click again to exit. You could also press <kbd>Esc</kbd>.
- Right-click menu bar icon to capture.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Text%20Lens&referrer=Website-FAQ)

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some other menu bar apps to free up space. If this does not solve it, try quitting Bartender or Ice if you have it installed.

#### Why does the app require screen recording permission?

macOS requires screen recording permission for any app that reads pixels from the screen. The app needs this to extract text from the areas you manually select. It only captures those specific regions — never your entire screen, never continuously. Nothing ever leaves your device. The app has no network access and cannot connect to the internet.

#### Why do I keep seeing screen recording permission reminders? {#screen-recording-reminders}

This is a macOS 15 bug. Apple added a system that occasionally reminds you which apps have screen recording access. It’s supposed to appear every 90 days, but some users see it constantly due to a bug in macOS 15.3 and later. This affects many apps, not just this app.

Workaround:
- Open the Terminal app.
- Run this command:
```sh
defaults write ~/Library/Group\ Containers/group.com.apple.replayd/ScreenCaptureApprovals.plist com.sindresorhus.Text-Lens -dict-add kScreenCapturePrivacyHintPolicy 7776000 kScreenCapturePrivacyHintDate -date 2035-12-31; /usr/bin/killall -HUP replayd
```

#### How is this different from macOS built-in Live Text?

While macOS Live Text works well for images and photos in supported apps, Text Lens works everywhere on your screen. You can capture text from videos, webpages, presentations, or any app - even when Live Text is not available. Text Lens also works with non-image content like UI elements and rendered text that Live Text can't detect.

#### Can I use the app offline?

Yes. Text recognition runs locally on your Mac. No internet connection is required.

#### Does the app preserve text formatting when copying?

No, only plain text is captured. Formatting like italics, bold, or underlines is not preserved when copying text.

#### Can you add support for more languages?

The app uses macOS's text recognition system, so language support is determined by your operating system.

#### Can you improve the text detection quality? {#quality}

The app uses macOS's text recognition engine, so detection quality is determined by your operating system. Since this is handled by macOS, I cannot modify or improve it.

#### Can you add support for capturing text like this to Supercharge too?

This is planned, but I want to perfect it here first.

#### How does this compare to TextSniper? {#textsniper}

The app's advantages:
- Universal capture: Extract text, QR codes, and barcodes with a single action
- Capture by simply clicking the menu bar icon
- Extract text from clipboard and files
- Drag and drop images onto the menu bar icon to extract text
- Choice of menu bar icon
- Cheaper ($6 vs. $12)

TextSniper advantages:
- Text-to-speech
- Additive clipboard feature
- More keyboard shortcuts
- More mature

#### [More FAQs…](/apps/faq)

<!-- ## Older Versions

- []() for macOS 15+ -->
