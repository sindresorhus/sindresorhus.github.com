---
title: Velja
subtitle: Powerful browser picker
date: 2022-04-21
platforms:
  - macOS
appStoreId: 1607635845
---

Open links in a specific browser or a matching native app. Easily switch between browsers.

<br>

#### Example use-cases

- Use Safari as your primary browser but open Google Meet links in Chrome
- Open links to figma.com directly in the Figma desktop app
- Open links to the internal company website in Firefox
- Open Zoom meeting invitations directly in the desktop Zoom app
- Open all links clicked in the Slack app in your Chrome work profile

<br>

#### Help

Please help out by starring these Chrome issues which would help Velja users:

- <https://bugs.chromium.org/p/chromium/issues/detail?id=174117>
- <https://bugs.chromium.org/p/chromium/issues/detail?id=1325557>

<br>

### Tips

#### Prompt

Instead of showing the browser prompt by default, you could make it the alternative browser, which would make it show when you hold the <kbd>Fn</kbd> key while clicking a link.

You could also make a custom rule and select `Prompt` as the browser. For example, you could only show the prompt when clicking links in the Slack app.

#### Prompt shortcuts

While showing the browser prompt, you can press <kbd>Option</kbd> to show buttons to copy or share the link. Or press <kbd>Shift</kbd> or <kbd>Command+C</kbd> to quickly copy the link.

Press <kbd>Option+Tab</kbd>/<kbd>Shift+Option+Tab</kbd> or arrow keys to cycle through browsers. Press <kbd>Return</kbd> or <kbd>Space</kbd> to select one.

#### Copy URL

See the above tip.

You can also have “copy URL” as a browser choice in the prompt by installing [this app](https://github.com/sindresorhus/Copy-URL).

#### Open links clicked in a specific app in a specific browser

For example, to open all links you click in Slack in Chrome:

- Open the Velja settings and go to the “Rules” pane.
- Create a new rule and give it a name.
- Select the browser to open. You can even choose a specific Chrome profile.
- Create a new “Source Apps” matcher and select the app you want. For example, Slack.
- Click “Save”.

#### Open link in private/incognito window

For Safari, [click here](https://github.com/sindresorhus/Safari-Private).

This is especially useful in combination with custom rules. For example, you could make a rule to open links to certain websites in a private window.

*Support for other browsers is planned. Firefox support is not possible until Firefox supports [Web Extensions Manifest v3](https://blog.mozilla.org/addons/2022/05/18/manifest-v3-in-firefox-recap-next-steps/).*

#### Open multiple URLs

If you have a document with many URLs you want to open. Select them, right-click, go to “Services”, and click “Open URLs with Velja”.

*You may have to enable the service in “System Settings › Keyboard › Keyboard Shortcuts › Services”.*

#### Open link in an website-wrapper app

Let's say you have generated a website wrapper app for facebook.com using an app like [Unite](https://www.bzgapps.com/unite) or [Coherence](https://www.bzgapps.com/coherence) and you want all links to Facebook to go to this app instead of your browser:

- Open the Velja settings and go to the “Rules” pane.
- Create a new rule and give it a name.
- Select the website wrapper app in the “Open in” field.
- Create a new “URL Matchers” matcher and write “facebook.com” in the “Match” field.
- Click “Save”.

#### Browser extensions

- Safari — Built-in. Just enable it in the Safari settings.
- [Chrome](https://chrome.google.com/webstore/detail/velja/gpipdgcamiclkcomcnogmlfpalggmcmk) — Also works in Edge, Brave, and other Chromium-based browsers.
- *Firefox support is planned, but will take a while.*

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Velja&referrer=Website-FAQ)

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some menu bar apps to free up space. If this does not solve it, try quitting Bartender if you have it installed.

You may also have enabled the “Hide menu bar icon” setting, which hides the menu bar icon. Launch the app again to reveal the menu bar item for 5 seconds.

#### Velja does not work

**I clicked a link in a browser**

Velja is not able to handle links clicked inside a browser. However, Velja comes with a Safari extension which you can enable in the Safari settings. You can then click the toolbar icon to open the current page with Velja or right-click a link to open it with Velja. There is also a [Chrome extension](https://chrome.google.com/webstore/detail/velja/gpipdgcamiclkcomcnogmlfpalggmcmk) which also works in Edge, Brave, and other Chromium-based browsers. (Firefox support is planned, but will take a while)

If you use a browser where Velja does not have a browser extension, you could also right-click the link and use the share extension \* or copy the link and then click “Open URL from Clipboard” in the Velja menu.

\* *Chrome (and Edge, Brave, etc) does not have a “Share” item in its context menu. Please [star this issue](https://bugs.chromium.org/p/chromium/issues/detail?id=916291).*

Velja also comes with a [system service](https://www.computerworld.com/article/2476298/os-x-a-quick-guide-to-services-on-your-mac.html). However, neither Safari ([issue](https://github.com/feedback-assistant/reports/issues/304)) or Chrome ([issue](https://bugs.chromium.org/p/chromium/issues/detail?id=1325557)) correctly sends links to a system service, so it cannot be used for this purpose.

**I clicked a link in VS Code**

VS Code [does not open the system default browser](https://github.com/microsoft/vscode/issues/96132) when you click a link in the app. Because of this, Velja is not used.

**I clicked a short URL**

If the link is a [short URL](https://en.wikipedia.org/wiki/URL_shortening), make sure the “Expand short URLs” setting is enabled and the URL shortening service is either in the built-in list or added by you. Velja is only able to do its matching when it receives the resolved URL.

**My custom rule did not work**

Make sure it's none of the above cases. Also make sure you have added a “Sample URL” to the rule to confirm your match pattern is correct.

Some apps use a redirect URL for tracking purposes. Velja has built-in support for a lot of redirect services and it also tries to resolve URLs to their final destination. However, some redirects cannot be resolved by Velja. This is the case with some links clicked in Slack as they require the login token to be able to redirect. There is unfortunately nothing I can do about that.

See [this](#debug) for how to debug what URLs Velja receive.

If the redirect URL contains the destination URL (usually in a search parameter), contact me and I will add support for it.

#### What are tracking parameters and why would I want to remove them?

Removing tracking parameters improve privacy and also make URLs more aesthetically pleasing. Tracking parameters are used by many websites to track your browsing activity across websites. [Read more.](https://en.wikipedia.org/wiki/UTM_parameters)

Velja supports 200+ common tracking parameters (e.g. Google UTM) and it has special support for removing tracking from links to Twitter, Facebook, and TikTok.

Before: `https://foo.com?utm_content=buffercf3b2&utm_source=snapchat.com`\
After: `https://foo.com`

Did you know that if you click a TikTok link that someone shared with you, they will be able to see that you watched it? Velja anonymizes TikTok links so that you will not be tracked.

#### Tracking parameters are not removed {#tracking-parameters-not-removed}

First, make sure the setting to remove tracking parameters is enabled.

If the clicked/copied link is a short URL, Velja is only able to remove the tracking parameters if the “Expand short URLs” setting is enabled and it's a known short URL service or you added the short URL service in the “Advanced” settings pane.

The app contains a list of tracking parameters to remove, but there may be site-specific tracking parameters it doesn't know about. If you encounter any tracking parameters not being removed, [let me know](https://sindresorhus.com/feedback?product=Velja&referrer=Website-FAQ) and I'll add support for them.

#### Can you add another app to the “Apps” settings? {#builtin-apps-requests}

I'm happy to consider requests (but read the below first). [Submit here.](https://sindresorhus.com/feedback?product=Velja&referrer=Website-FAQ)

*If this is about opening a specific website (for example, Google Sheets) in a specific browser, you should use the rules feature instead (the “Rules” tab in the settings). You can easily make a rule for any website.*

*If this is about opening a specific website like Facebook in an app-wrapped website generated with something like Unite or Coherence, it's better to just add support yourself. You can use the rules feature for this. For example, write “facebook.com” as the domain and select the website-wrapper app you generated.*

**Note:** This is about opening a link in a specific app. If you want to open a link **from** a specific app, just use the rules feature (it supports any app).

However, some apps are not possible:
- Slack
  + *The Slack app does not accept a normal deep link (example: `https://team-name.slack.com/archives/CKPE4C/p161643063559`). It only accepts a special Slack-specific URL. To be able to convert a normal Slack link to one that the desktop app accepts, we would need get the team ID from the Slack API and that requires authentication. It's simply not feasible to do this. __Please do send feedback to Slack asking them to accept a normal link, like most other apps support.__*
- Cisco Webex
  + *[Comment here](https://github.com/johnste/finicky/discussions/228) if you know how to do this.*
- [MURAL](https://mural.co)
  + The app has no support for opening URLs from the web version.
- [GitHub Desktop](https://github.com/desktop/desktop)
  + The app only accepts a link to a repo to clone. This is not very useful in practice.

If your favorite service is in the above list, I would recommend contacting them and asking them to support opening a link directly in their app. That means being able to run the command `open -a AppName https://foo.com/link-to-project-or-meeting`.

#### Can you support [Firefox Multi-Account Containers](https://github.com/mozilla/multi-account-containers)? {#firefox-containers}

It's not feasible to support it built-in because of missing features:

- <https://bugzilla.mozilla.org/show_bug.cgi?id=1774127>
- <https://bugzilla.mozilla.org/show_bug.cgi?id=1774128>
- <https://github.com/honsiorovskyi/open-url-in-container/issues/109>

*(Vote them up)*

However, I do plan to make it possible to achieve it using custom rules. The missing feature in Velja is the ability to transform a URL. When that is supported **(not yet)**, you will be able to achieve it like this:

- Install: <https://github.com/mozilla/multi-account-containers>
- Install: <https://github.com/honsiorovskyi/open-url-in-container>
- Transform the input URL, for example, `https://a.com` to `ext+container:name=MyContainer&url=https://a.com&signature=ea7214f675398e93764ba44504070221633b0d5dce6c4263715f1cca89ab5f86`

#### Can you support Firefox profiles? {#firefox-profiles}

I don't have any immediate plans to support this. There is currently very little demand for it and it's complicated to implement. I will consider it if there is more demand for it.

I would recommend trying out containers instead (see above). *(Containers are not currently supported, but will be)*

#### Can the default browser change based on the active [focus mode](https://support.apple.com/guide/mac-help/set-up-a-focus-to-stay-on-task-mchl613dc43f/mac)? {#focus-mode}

You can use the Shortcuts app for this. Make a shortcut for each focus mode you want to handle, where you use the “Set Default Browser” action that Velja provides. You will need the [Shortery app](https://apps.apple.com/app/id1594183810) to automatically run these shortcuts when the focus mode changes.

#### Can you add iCloud syncing for the rules? {#icloud}

iCloud syncing has been quite unreliable in the past year (hearing it from other app developers). Because of this, I don't plan to support iCloud syncing right now. I don't want my users to have a subpar experience and I don't want to deal with all the support that comes with it. I will reevaluate it again next year.

Velja does support exporting and importing rules manually.

#### Can you add a vertical or circular browser prompt?

I don't have any immediate plans to add this. I recommend giving the horizontal prompt a try. A lot of users found it to work better than vertical/circular.

#### How can I see what URL Velja received? {#debug}

Quit Velja if it's open. Press <kbd>Shift</kbd> + <kbd>Control</kbd> while launching Velja, click the menu bar icon, click “Debug”, and then go to “Logs”.

#### Velja does not show browsers from the user “~/Applications” folder?

Apple generally recommends putting apps in the global “/Applications” folder. Third-party apps like Velja get automatic access to this one, but not to the user “~/Applications” folder.

Velja does prompt for permission to the user “~/Applications” folder on the first launch if it exists. But if you created it later on or did not get the prompt for some reason, you can force it. Quit Velja, then launch Velja while pressing <kbd>Control</kbd> + <kbd>Option</kbd>.

#### How can I export, import, sync, or backup the settings?

You can export/import rules in the settings.

For all settings, [see this guide.](https://github.com/sindresorhus/guides/blob/main/backup-app-settings.md)

#### Can you support browser profiles for the [Arc](https://thebrowser.company) browser? {#arc}

The Arc browser is based on Chrome, so you may think that it should just work with browser profiles in Velja. Unfortunately, Arc doesn't yet support the `--profile-directory` command-line flag. So while Velja is able to fetch the profiles, it's not able to actually use them.

I recommend sending them feedback about this. Either through the feedback button in Arc or at [hello@thebrowser.company](mailto:hello@thebrowser.company).

For example, this command should have opened the URL in the given profile:

```sh
open -b company.thebrowser.Browser --new --args --profile-directory "User Data/Profile 1" https://sindresorhus.com
```

#### Can you support browser profiles for the [Orion](https://browser.kagi.com) browser? {#orion}

This can be resolved by the Orion browser itself. [Vote up this issue.](https://orionfeedback.org/d/3445-profile-proxy-app-should-identify-itself-as-a-browser)

#### How do I disable Velja?

[Change the system default browser back to Safari.](https://support.apple.com/en-us/HT201607)

#### What does “Velja” mean?

It means [“to choose”](https://en.wiktionary.org/wiki/velja) in [Old Norse](https://www.discovermagazine.com/planet-earth/what-language-did-the-vikings-speak) (also Icelandic and Faroese). Hence the viking hat.

#### How does it compare to [Choosy](https://www.choosyosx.com)? {#choosy}

Velja benefits:

- Free
- It can [open links to certain services](https://twitter.com/sindresorhus/status/1519020970027401216) in their desktop app (Zoom, Microsoft Teams, Figma, etc.)
- It can open Google Meet links in Chrome without any manual setup
- Browser profile support for Chrome, Chromium, Edge, Vivaldi, and all their beta, dev, etc, editions (Choosy only supports Chrome stable)
- Removes tracking parameters on clicked and copied links
- You can open copied links from the menu bar menu
- You can press a keyboard shortcut to use an alternative browser for a specific link
- Open link in private Safari window
- Available in the App Store
- Sandboxed (more secure)
- Shortcuts support
- Handoff support
- Services support
- Share extension

Choosy benefits:

- More options for custom rules

#### How does it compare to [Bumpr](https://www.getbumpr.com)? {#bumpr}

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
- Open link in private Safari window
- Shortcuts support
- Handoff support
- Services support
- Share extension

Bumpr benefits:

- Supports configuring primary email app

#### How does it compare to [OpenIn](https://loshadki.app/openin/)? {#openin}

Velja benefits:

- Free
- It can [open links to certain services](https://twitter.com/sindresorhus/status/1519020970027401216) in their desktop app (Zoom, Microsoft Teams, Figma, etc.)
- It can open Google Meet links in Chrome without any manual setup
- Better user interface for browser profiles (OpenIn requires you to manually find the browser profile ID)
- The user interface is more macOS-like and better follows the [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos/overview/themes/)
- You can open copied links from the menu bar menu
- You can quickly switch the primary browser
- You can press a keyboard shortcut to use an alternative browser for a specific link
- Open link in private Safari window
- Browser extensions
- Shortcuts support
- Services support

OpenIn benefits:

- Supports configuring the primary app for more types, like email clients

#### How does it compare to [Browserosaurus](https://github.com/will-stone/browserosaurus)? {#browserosaurus}

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
- Open link in private Safari window
- Browser extensions
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

<br>

### Scripting {#scripting}

The app can be automated using the Shortcuts app or with a custom URL scheme.

#### Custom URL scheme

You can open a URL using Velja from any tool that support opening a URL. This includes, a website, Bash, Node.js, Python, Swift, etc.

For example, in your terminal:

```sh
open --background 'velja:open?url=https%3A%2F%2Fsindresorhus.com&prompt'
```

Leave out `&prompt` to not show the browser prompt.

*Don't forget to [URL encode](https://www.urlencoder.org) the value for the `url=` search parameter. For example, using [this](https://gist.github.com/cdown/1163649) Bash function.*

<br>

### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive updates.

[Download](https://dsc.cloud/sindresorhus/Velja-1.10.1-1661932791) *(1.10.1)*

*Requires macOS 12 or later*
