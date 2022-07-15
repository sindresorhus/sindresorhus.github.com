---
title: Velja
subtitle: Powerful browser picker
date: 2022-04-21
platforms:
  - macOS
app_store_app_id: 1607635845
mac_app_store_url: https://apps.apple.com/app/id1607635845
---

Open links in a specific browser or a matching native app. Easily switch between browsers.

<br>

<h3 id="help">Help</h3>

Please help out by starring these Chrome issues which would help Velja users:

- <https://bugs.chromium.org/p/chromium/issues/detail?id=174117>
- <https://bugs.chromium.org/p/chromium/issues/detail?id=1325557>

<br>

<h3 id="tips">Tips</h3>

#### Open multiple URLs

If you have a document with many URLs you want to open. Select them, right-click, go to “Services”, and click “Open URLs with Velja”.

*You may have to enable the service in “System Preferences › Keyboard › Shortcuts › Services”.*

#### Prompt

Instead of showing the browser prompt by default, you could make it the alternative browser, which would make it show when you hold the <kbd>Fn</kbd> key while clicking a link.

You could also make a custom rule and select `Prompt` as the browser. For example, you could only show the prompt when clicking links in the Slack app.

#### Open links clicked in a specific app in a specific browser

For example, to open all links you click in Slack in Chrome:

- Open the Velja settings and go to the “Rules” pane.
- Create a new rule and give it a name.
- Select the browser to open. You can even choose a specific Chrome profile.
- Create a new “Source Apps” matcher and select the app you want. For example, Slack.
- Click “Save”.

#### Prompt shortcuts

While showing the browser prompt, you can press <kbd>Option</kbd> to show buttons to copy or share the link. Or press <kbd>Shift</kbd> or <kbd>Command+C</kbd> to quickly copy the link.

<br>

<h3 id="faq">Frequently Asked Questions</h3>

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback/?product=Velja&referrer=Website-FAQ)

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some menu bar apps to free up space. If this does not solve it, try quitting Bartender if you have it installed.

You may also have enabled the “Hide menu bar icon” setting, which hides the menu bar icon. Launch the app again to reveal the menu bar item for 5 seconds.

#### Velja does not work

**I clicked a link in a browser**

Velja is not able to handle links clicked inside a browser. You can either right-click the link and use the share extension \* or copy the link and then click “Open URL from Clipboard” in the Velja menu.

\* Chrome (and Edge, Brave, etc) does not have a “Share” item in its context menu. Please [star this issue](https://bugs.chromium.org/p/chromium/issues/detail?id=916291).

Velja also comes with a [system service](https://www.computerworld.com/article/2476298/os-x-a-quick-guide-to-services-on-your-mac.html). However, neither Safari ([issue](https://github.com/feedback-assistant/reports/issues/304)) or Chrome ([issue](https://bugs.chromium.org/p/chromium/issues/detail?id=1325557)) correctly sends links to a system service, so it cannot be used for this purpose.

**I clicked a short URL**

If the link is a [short URL](https://en.wikipedia.org/wiki/URL_shortening), make sure the “Expand short URLs” setting is enabled and the URL shortening service is either in the built-in list or added by you. Velja is only able to do its matching when it receives the resolved URL.

**My custom rule did not work**

Make sure it's none of the above cases. Also make sure you have added a “Sample URL” to the rule to confirm your match pattern is correct.

#### What are tracking parameters and why would I want to remove them?

Removing tracking parameters improve privacy and also make URLs more aesthetically pleasing. Tracking parameters are used by many websites to track your browsing activity across websites. [Read more.](https://en.wikipedia.org/wiki/UTM_parameters)

Before: `https://foo.com?utm_content=buffercf3b2&utm_source=snapchat.com`\
After: `https://foo.com`

<a id="tracking-parameters-not-removed"></a>
#### Tracking parameters are not removed

First, make sure the setting to remove tracking parameters is enabled.

If the clicked/copied link is a short URL, Velja is only able to remove the tracking parameters if the “Expand short URLs” setting is enabled and it's a known short URL service or you added the short URL service in the “Advanced” preferences pane.

The app contains a list of tracking parameters to remove, but there may be site-specific tracking parameters it doesn't know about. If you encounter any tracking parameters not being removed, [let me know](https://sindresorhus.com/feedback/?product=Velja&referrer=Website-FAQ) and I'll add support for them.

#### Can you add a visual picker that shows when clicking a link?

This is planned.

<a id="builtin-apps-requests"></a>
#### Can you add another app to the “Apps” preferences?

I'm happy to consider requests. [Submit here.](https://sindresorhus.com/feedback/?product=Velja&referrer=Website-FAQ)

However, some apps are not possible:
- Slack
  + *The Slack app does not accept a normal deep link (example: `https://team-name.slack.com/archives/CKPE4C/p161643063559`). It only accepts a special Slack-specific URL. To be able to convert a normal Slack link to one that the desktop app accepts, we would need get the team ID from the Slack API and that requires authentication. It's simply not feasible to do this. __Please do send feedback to Slack asking them to accept a normal link, like most other apps support.__*
- Cisco Webex
  + *[Comment here](https://github.com/johnste/finicky/discussions/228) if you know how to do this.*

If your favorite service is in the above list, I would recommend contacting them and asking them to support opening a link directly in their app. That means being able to run the command `open -a AppName https://foo.com/link-to-project-or-meeting`.

<a id="firefox-containers"></a>
#### Can you support [Firefox Multi-Account Containers](https://github.com/mozilla/multi-account-containers)?

It's not feasible to support it built-in because of missing features:

- <https://bugzilla.mozilla.org/show_bug.cgi?id=1774127>
- <https://bugzilla.mozilla.org/show_bug.cgi?id=1774128>
- <https://github.com/honsiorovskyi/open-url-in-container/issues/109>

*(Vote them up)*

However, I do plan to make it possible to achieve it using custom rules. The missing feature in Velja is the ability to transform a URL. When that is supported **(not yet)**, you will be able to achieve it like this:

- Install: <https://github.com/mozilla/multi-account-containers>
- Install: <https://github.com/honsiorovskyi/open-url-in-container>
- Transform the input URL, for example, `https://a.com` to `ext+container:name=MyContainer&url=https://a.com&signature=ea7214f675398e93764ba44504070221633b0d5dce6c4263715f1cca89ab5f86`

<a id="firefox-profiles"></a>
#### Can you support Firefox profiles?

I don't have any immediate plans to support this. There is currently very little demand for it and it's complicated to implement. I will consider it if there is more demand for it.

I would recommend trying out containers instead (see above). *(Containers are not currently supported, but will be)*

<a id="focus-mode"></a>
#### Can the default browser change based on the active [focus mode](https://support.apple.com/guide/mac-help/set-up-a-focus-to-stay-on-task-mchl613dc43f/mac)?

You can use the Shortcuts app for this. Make a shortcut for each focus mode you want to handle, where you use the “Set Default Browser” action that Velja provides. You will need the [Shortery app](https://apps.apple.com/app/id1594183810) to automatically run these shortcuts when the focus mode changes.

#### How do I disable Velja?

[Change the system default browser back to Safari.](https://support.apple.com/en-us/HT201607)

#### What does “Velja” mean?

It means [“to choose”](https://en.wiktionary.org/wiki/velja) in [Old Norse](https://www.discovermagazine.com/planet-earth/what-language-did-the-vikings-speak) (also Icelandic and Faroese). Hence the viking hat.

<a id="choosy"><a>
#### How does it compare to [Choosy](https://www.choosyosx.com)?

Velja benefits:

- Free
- It can [open links to certain services](https://twitter.com/sindresorhus/status/1519020970027401216) in their desktop app (Zoom, Microsoft Teams, Figma, etc.)
- It can open Google Meet links in Chrome without any manual setup
- Browser profile support for Chrome, Chromium, Edge, Vivaldi, and all their beta, dev, etc, editions (Choosy only supports Chrome stable)
- Removes tracking parameters on clicked and copied links
- You can open copied links from the menu bar menu
- You can press a keyboard shortcut to use an alternative browser for a specific link
- Available in the App Store
- Sandboxed (more secure)
- Shortcuts support
- Handoff support
- Services support
- Share extension

Choosy benefits:

- Browser extension
- More options for custom rules

<a id="bumpr"><a>
#### How does it compare to [Bumpr](https://www.getbumpr.com)?

Velja benefits:

- Free
- It can [open links to certain services](https://twitter.com/sindresorhus/status/1519020970027401216) in their desktop app (Zoom, Microsoft Teams, Figma, etc.)
- It can open Google Meet links in Chrome without any manual setup
- Browser profile support
- More advanced custom rules, like the ability open a certain link based on what app the link was clicked in
- Expands [short URLs](https://en.wikipedia.org/wiki/URL_shortening) for better matching
- Removes tracking parameters on clicked and copied links
- macOS-like user interface (Bumpr has a custom non-macOS-like user interface)
- You can open copied links from the menu bar menu
- You can quickly switch the primary browser
- You can press a keyboard shortcut to use an alternative browser for a specific link
- Setting to hide the menu bar icon
- Shortcuts support
- Handoff support
- Services support
- Share extension

Bumpr benefits:

- Browser extension
- Supports configuring primary email app

<a id="openin"><a>
#### How does it compare to [OpenIn](https://loshadki.app/openin/)?

Velja benefits:

- Free
- It can [open links to certain services](https://twitter.com/sindresorhus/status/1519020970027401216) in their desktop app (Zoom, Microsoft Teams, Figma, etc.)
- It can open Google Meet links in Chrome without any manual setup
- Better user interface for browser profiles (OpenIn requires you to manually find the browser profile ID)
- The user interface is more macOS-like and better follows the [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos/overview/themes/)
- You can open copied links from the menu bar menu
- You can quickly switch the primary browser
- You can press a keyboard shortcut to use an alternative browser for a specific link
- Shortcuts support
- Services support

OpenIn benefits:

- Supports configuring the primary app for more types, like email clients.

<a id="browserosaurus"><a>
#### How does it compare to [Browserosaurus](https://github.com/will-stone/browserosaurus)?

Velja benefits:

- Native app written in Swift (Browsersaurus is an Electron app — a web app)
- Lower memory usage (Velja uses 36 MB and Browsersaurus uses 300 MB)
- Lower CPU usage (Velja uses 0% CPU when idle and Browsersaurus uses 0.1-0.2%)
- Available in the App Store
- Sandboxed (more secure)
- It can [open links to certain services](https://twitter.com/sindresorhus/status/1519020970027401216) in their desktop app (Zoom, Microsoft Teams, Figma, etc.)
- It can open Google Meet links in Chrome without any manual setup
- Browser profile support
- Custom rules, like the ability open a certain link based on what app the link was clicked in
- Expands [short URLs](https://en.wikipedia.org/wiki/URL_shortening) for better matching
- Removes tracking parameters on clicked and copied links
- The user interface is more macOS-like and follows the [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos/overview/themes/)
- You can open copied links from the menu bar menu
- You can quickly switch the primary browser
- You can press a keyboard shortcut to use an alternative browser for a specific link
- Finds new browsers automatically (Browsersaurus has to manually scan for new browsers)
- Setting to hide the menu bar icon
- Shortcuts support
- Handoff support
- Services support
- Share extension

Browserosaurus benefits:

- Open source
- Available outside the App Store (can be useful if the App Store is blocked on a work Mac)

#### Why is this free without ads?

I just enjoy making Mac apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1607635845) and click “Version History”.

#### Can you localize the app into my language?

I don't have any immediate plans to localize the app.
