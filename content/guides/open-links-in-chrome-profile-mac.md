---
title: 'How to Open Links in a Specific Chrome Profile on Mac'
description: 'Chrome opens links in the profile that you used last. With Velja, links always open in the Chrome profile that you choose, or in one for each website.'
publicationDate: 2026-11-19
topic: 'browsers-links-and-email'
apps: [
	'velja'
]
---

@QuickAnswer {
	Chrome opens a link in the profile of the window that you used last, and it has no setting for a default profile. Make [Velja](/velja) the default browser, and choose the Chrome profile in “Browser” in its settings. Then all links open in that profile.
}

## With Velja

@Steps {
1. Open [Velja](/velja), click “Continue”, and then “Get Started”. Velja works by being the default browser, so it asks to become it.
1. Open the settings, go to “Browsers”, click “Grant Access…” for “Browser profiles”, and click “Allow”. Each profile of Chrome now shows as a browser of its own.
1. In “Browser”, choose the Chrome profile, like your personal profile.
1. Click a link in another app. It opens in that profile, also when a window of another profile is in front.
}

If Velja says that macOS blocks the browser profiles, turn on Chrome in “[System Settings › Privacy & Security › Files & Folders › Velja](x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_FilesAndFolders)”.

To open some links in another profile, like the links to your company tools in your work profile, make a rule: go to “Rules”, click “Add Rule”, choose the other profile in “Open in”, and add the domain in “URL Matchers”. A rule can also use the app that you click the link in. [How to open Slack links in your work profile.](guide:open-slack-links-in-chrome-mac)

Velja also supports the profiles of Edge, Brave, Vivaldi, Firefox, and other browsers. [Supported browsers.](/velja#supported-browsers-for-profiles)

## Without an app

Chrome has no setting for this. It opens each link in the profile that you used last. So, before you click a link in another app, click a window of the profile that you want. Or close the windows of the other profiles.

Microsoft Edge has a setting for it, when you have more than one profile: in Edge, open “Settings › Profiles › Profile preferences”, and choose the profile in “Default profile for external links”.
