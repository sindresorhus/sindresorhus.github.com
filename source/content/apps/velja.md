---
title: Velja
subtitle: Powerful browser picker
pubDate: 2022-04-21
platforms:
  - macOS
isMenuBarApp: true
appStoreId: 1607635845
olderMacOSVersions:
  - '12'
  - '13'
---

Open links in a specific browser or a matching native app. Easily switch between browsers.

[In-depth review of Velja.](https://www.podfeet.com/blog/2022/11/velja/)

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

Instead of showing the browser prompt by default, you could set it as the alternative browser, which would make it show when you hold the <kbd>Fn</kbd> key while clicking a link.

You could also create a custom rule and select `Prompt` as the browser. For example, you could only show the prompt when clicking links in the Slack app.

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

#### Open links in a private/incognito window

For Safari, [click here](https://github.com/sindresorhus/Safari-Private).

This is especially useful in combination with custom rules. For example, you could make a rule to open links to certain websites in a private window.

*Support for other browsers is planned.*

#### Open multiple URLs

If you have a document with many URLs you want to open, select them, right-click, go to “Services”, and click “Open URLs with Velja”.

*You may have to enable the service in “System Settings › Keyboard › Keyboard Shortcuts › Services”.*

#### Open links in a website-wrapper app

Let's say you have generated a website wrapper app for facebook.com using an app like [Unite](https://www.bzgapps.com/unite) or [Coherence](https://www.bzgapps.com/coherence), and you want all links to Facebook to go to this app instead of your browser:

- Open the Velja settings and go to the “Rules” pane.
- Create a new rule and give it a name.
- Select the website wrapper app in the “Open in” field.
- Create a new “URL Matchers” matcher and write “facebook.com” in the “Match” field.
- Click “Save”.

#### Browser extensions

- Safari — Built-in. Just enable it in the Safari settings.
- [Chrome](https://chrome.google.com/webstore/detail/velja/gpipdgcamiclkcomcnogmlfpalggmcmk) — Also works in Edge, Brave, and other Chromium-based browsers.
- [Firefox](https://addons.mozilla.org/en-GB/firefox/addon/velja/)

#### Open the current website in a different browser

For example, you are surfing a website in Safari and want to open it in Chrome.

You could enable the Velja browser extension and then click the toolbar icon in your browser to show the Velja browser prompt.

You could also show the browser prompt when pressing a keyboard shortcut:
- Add [this shortcut](https://www.icloud.com/shortcuts/6c2d3793f101447dad449e83bde8d967).
	- If your browser is not Safari, change the app name in the shortcut.
- Add a keyboard shortcut to the shortcut config.
- Pressing the configured keyboard shortcut will now show the browser prompt.

If you want to open the website in a specific browser directly instead of showing the browser prompt, add [this shortcut](https://www.icloud.com/shortcuts/d3f833d1a1334d169ccefe26fa0ec240) instead.

#### Open links clicked in a browser or PWA in a specific browser

Velja generally cannot handle links clicked in a browser because browsers don't notify the system about it. However, there is a workaround. Install the [Redirector browser extension](https://chromewebstore.google.com/detail/redirector/ocgpenflpmgnfapjedencafcfakcekcd) and make a rule in that extension to open links in Velja. Here's an [example rule](https://www.dropbox.com/scl/fi/s99bdxvbypar0nj2v8pj5/Redirector-1702989917.json?rlkey=fey4cs3wxuln528wkb5ai75u5&raw=1) (import it into the Redirector extension) that opens all links clicked in a browser in Velja. This could be useful if you need to open all links from a browser PWA in a specific browser.

For Chrome, you can run the following commands in the Terminal app to ensure that these types of links always open in the associated app:

```sh
defaults write com.google.Chrome URLAllowlist -array-add 'velja:*'
defaults write com.google.Chrome ExternalProtocolDialogShowAlwaysOpenCheckbox -bool true
```

And for Edge:

```sh
defaults write com.microsoft.Edge URLAllowlist -array-add 'velja:*'
defaults write com.microsoft.Edge ExternalProtocolDialogShowAlwaysOpenCheckbox -bool true
```

For other Chrome-based browsers, replace `com.google.Chrome` with their bundle identifier in the above commands.

#### Launch browsers from Velja menu

Hold the <kbd>Option</kbd> key when clicking a browser in the Velja menu to launch it instead of setting it as the current browser.

#### Open certain URLs in a specific browser profile

- Open the Velja settings.
- Go to the “Browsers” tab and grant access to browser profiles.
- Go to the “Rules” tab.
- Click “+”.
- Choose a browser profile in “Open in”.
- Click “+” for the “URL Matchers”.
- Define a pattern that matches the URLs you want to match.
- Click “Save”.

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Velja&referrer=Website-FAQ)

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is not enough space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some other menu bar apps to free up space. If this does not solve it, try quitting Bartender if you have it installed.

You may also have enabled the “Hide menu bar icon” setting, which hides the menu bar icon. Launch the app again to reveal the menu bar item for 5 seconds.

#### Velja does not work

First, make sure that the problem is Velja. Go to “System Settings › Desktop & Dock” and change the “Default web browser” setting to Safari. Then try clicking the link again. If the problem persists, it's not caused by Velja.

**I clicked a link in a browser**

Velja is not able to handle links clicked inside a browser. However, Velja comes with a Safari extension which you can enable in the Safari settings. You can then click the toolbar icon to open the current page with Velja or right-click a link to open it with Velja. There are also [extensions for other browsers](#browser-extensions).

If you use a browser where Velja does not have a browser extension, you could also right-click the link and use the share extension \* or copy the link and then click “Open URL from Clipboard” in the Velja menu.

\* *Chrome (and Edge, Brave, etc) does not have a “Share” item in its context menu. Please [star this issue](https://bugs.chromium.org/p/chromium/issues/detail?id=916291).*

Velja also comes with a [system service](https://www.computerworld.com/article/2476298/os-x-a-quick-guide-to-services-on-your-mac.html). However, neither Safari ([issue](https://github.com/feedback-assistant/reports/issues/304)) or Chrome ([issue](https://bugs.chromium.org/p/chromium/issues/detail?id=1325557)) correctly sends links to a system service, so it cannot be used for this purpose.

**The prompt does not show**

Make sure you didn't click the link in a browser. See above.

**I clicked a link in VS Code**

VS Code [does not open the system default browser](https://github.com/microsoft/vscode/issues/96132) when you click a link in the app. Because of this, Velja is not used.

**I clicked a short URL**

If the link is a [short URL](https://en.wikipedia.org/wiki/URL_shortening), make sure the “Expand short URLs” setting is enabled and the URL shortening service is either in the built-in list or added by you. Velja is only able to do its matching when it receives the resolved URL.

**I clicked a button in the Dropbox app**

This is either a macOS or Dropbox bug. Velja simply opens what it receives, but what it receives has incorrect permission. When you click a button in Dropbox to open it on the web, it doesn't actually open the URL directly but instead writes an HTML file (which redirects to the final URL) to a temporary directory. I have no idea why it does this, but it's likely this is what causes the issue.

<a id="custom-rule-problem"></a>
**My custom rule did not work**

Make sure it's none of the above cases. Also make sure you have added a “Sample URL” to the rule to confirm your match pattern is correct.

Some apps use a redirect URL for tracking purposes. Velja has built-in support for a lot of redirect services and it also tries to resolve URLs to their final destination. However, some redirects cannot be resolved by Velja. This is the case with some links clicked in Slack as they require the login token to be able to redirect. There is unfortunately nothing I can do about that.

See [this](#debug) for how to debug what URLs Velja receives.

If the redirect URL contains the destination URL (usually in a search parameter), contact me and I will add support for it.

#### What are tracking parameters and why would I want to remove them?

Removing tracking parameters improve privacy and also make URLs more aesthetically pleasing. Tracking parameters are used by many websites to track your browsing activity across websites. [Learn more.](https://en.wikipedia.org/wiki/UTM_parameters)

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

*If this is about opening a specific website like Facebook in an app-wrapped website generated with something like Unite or Coherence, it's better to just add support yourself. You can use the rules feature for this. For example, write “facebook.com” as the domain and select the website wrapper app you generated.*

**Note:** This is about opening a link in a specific app. If you want to open a link **from** a specific app, just use the rules feature (it supports any app).

However, some apps are not feasible:
- Slack
	+ [Explanation.](#slack)
- Cisco Webex
	+ *[Comment here](https://github.com/johnste/finicky/discussions/228) if you know how to do this.*
- [MURAL](https://mural.co)
	+ The app has no support for opening URLs from the web version.
- [GitHub Desktop](https://github.com/desktop/desktop)
	+ The app only accepts a link to a repo to clone. This is not very useful in practice.
- Monday.com
	+ The app does not accept any links.
- Todoist
	+ Only supports opening links to a todo item and it only works when the app is already running.
- Craft.do
	+ The app does not accept any links. It does accept [custom URL scheme](https://support.craft.do/hc/en-us/articles/360020168838-Using-URL-Scheme) links, but I'm not interested having to maintain more code to transform URLs in Velja when the services should just handle it themselves in their desktop apps.

And some apps do not need special support because they already support [universal links](https://developer.apple.com/ios/universal-links/):
- [Quip](https://quip.com)

If your favorite service is in the above list, I would recommend contacting them and asking them to support opening a link directly in their app. That means being able to run the command `open -a AppName https://foo.com/link-to-project-or-meeting`.

#### Can Velja override Universal Links?

No. There is a way to do it, but it requires a special entitlement from Apple. I applied for it a year ago and haven't heard anything.

There are some ways to [disable Universal Links](https://mjtsai.com/blog/2022/04/19/disabling-universal-links/).

#### How can I add a browser profile to the prompt?

First, make sure you grant access to profiles in the settings and then enable them in the “Shown Browsers” setting.

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

I don't plan to support this. There is simply not enough demand for it. In addition, Firefox profiles also have some bugs that would increase my support burden. However, there is a way to [make it work with Velja](https://superuser.com/questions/75271/starting-firefox-with-a-specified-profile-from-the-dock-mac-os-x) (Ensure they have different bundle identifiers; `CFBundleIdentifier` in Info.plist).

I would recommend trying out containers instead (see above). *(Containers are not currently supported, but will be)*

#### I opened a link in the background but it brought Chrome to the foreground

Chrome does not properly respect opening URLs in the background (it generally does not respect platform conventions). This can be reproduced even without Velja by setting Chrome as the system default browser in the System Settings and then running the following in the Terminal:

```sh
open --background 'https://sindresorhus.com'
```

#### The link takes a long time to open

This is most likely not caused by Velja. Some users reported it was a problem with Microsoft Office and happened without Velja too.

Also try to disable the “Expand redirect and short URLs” setting.

To confirm Velja is not the problem: Go to “System Settings › Desktop & Dock” and change the “Default web browser” setting to Safari. Then try clicking the link again. If the problem persists, it's not caused by Velja.

#### Can you add support for opening Slack links in the Slack desktop app? {#slack}

This is currently not possible. The Slack app does not accept a normal deep link (example: `https://team-name.slack.com/archives/CKPE4C/p161643063559`). It only accepts a special Slack-specific URL. To be able to convert a normal Slack link to one that the desktop app accepts, we would need to get the team ID from the Slack API and that requires authentication. It's simply not feasible to do this. **Please do send feedback to Slack asking them to accept a normal link, like most other apps support.**

#### Can the default browser change based on the active [focus mode](https://support.apple.com/guide/mac-help/set-up-a-focus-to-stay-on-task-mchl613dc43f/mac)? {#focus-mode}

You can use the Shortcuts app for this. Make a shortcut for each focus mode you want to handle, where you use the “Set Default Browser” action that Velja provides. You will need the [Shortery app](https://apps.apple.com/app/id1594183810) to automatically run these shortcuts when the focus mode changes. (Shortery will most likely not be needed in macOS 14 as it's very likely it will have support for [automations](https://support.apple.com/en-gb/guide/shortcuts/apd690170742/6.0/ios/16.0))

#### Can the default browser change depending on whether I'm at work or not?

See the above answer. You just create a work focus mode.

#### Can the default browser change depending on whether the computer is on battery?

See the above answer. Use the “Power Status” trigger in Shortery.

#### Can you support [Focus filters](https://support.apple.com/en-us/HT212608)? {#focus-filters}

Focus filters are meant for filtering content when a specific focus is enabled. Changing settings are better done using Shortcuts, as shown above.

#### Can you add iCloud syncing for the rules? {#icloud}

iCloud syncing has been quite unreliable in the past year (hearing it from other app developers). Because of this, I don't plan to support iCloud syncing right now. I don't want my users to have a subpar experience and I don't want to deal with all the support that comes with it. I will reevaluate it again next year.

Velja does support exporting and importing rules manually.

#### Can you add a vertical or circular browser prompt?

I don't plan to add this. I recommend giving the horizontal prompt a try. A lot of users found it to work better than vertical/circular.

#### How can I see what URL Velja received? {#debug}

In the advanced settings, enable the link history setting, and then click the link. The URL will show up there.

To see more detailed debug info on how Velja handled the URL: Quit Velja if it's open. Press <kbd>Shift</kbd> + <kbd>Control</kbd> while launching Velja, click the menu bar icon, click “Debug”, and then go to “Logs”.

#### How can I open a URL in a specific Safari Tab Group? {#safari-tab-group}

Safari does not provide any way to achieve this. You will have to send a feature request to Apple.

#### Velja does not show browsers from the user “~/Applications” folder

Apple generally recommends putting apps in the global “/Applications” folder. Third-party apps like Velja get automatic access to this one, but not to the user “~/Applications” folder.

Velja does prompt for permission to the user “~/Applications” folder on the first launch if it exists. But if you created it later on or did not get the prompt for some reason, you can force it. Quit Velja, then launch Velja while pressing <kbd>Control</kbd> + <kbd>Option</kbd>.

#### I have Mastodon links set to open in a specific browser, but it opens in the Ivory app {#ivory-mastodon}

Ivory supports [Universal Links](https://developer.apple.com/ios/universal-links/) for some Mastodon instances and Velja cannot override Universal Links. Universal Links is an annoying feature as it gives users (and other developers) no control over how it works.

As of Ivory 1.0.0, it supports [these Mastodon instances](https://github.com/sindresorhus/meta/assets/170270/e256c5e1-5048-4cbc-8df2-aa09c969b639).

#### How can I export, import, sync, or back up the settings?

You can export/import rules in the settings.

For all settings, [see this guide.](https://github.com/sindresorhus/guides/blob/main/backup-app-settings.md)

#### Can you support Safari profiles? {#safari-profiles}

Apple does not expose any way to open URLs in a specific profile. I recommend [sending feedback](https://feedbackassistant.apple.com) to Apple that they should add Shortcuts and AppleScript support for this.

Feel free to duplicate my feedback reports:

- [FB12320822](https://github.com/feedback-assistant/reports/issues/398)
- [FB12320895](https://github.com/feedback-assistant/reports/issues/399)

#### Can you support spaces for the [Arc](https://thebrowser.company) browser? {#arc}

I would love to support Arc, but it's currently missing some required functionality.

**Note that they now support [something similar to Velja built in](https://twitter.com/browsercompany/status/1654525608305491984).**

Arc supports fetching the spaces of a specific Arc window using AppleScript. However, Velja needs to be able to fetch the spaces even when Arc has no open windows, so that it can show a list of spaces in the Velja settings.

I recommend sending them feedback about this. Either through the feedback button in Arc or at [hello@thebrowser.company](mailto:hello@thebrowser.company).

I have prepared a ready-made feature request text you can use:

> It would be great if Arc could support getting a list of all the spaces with AppleScript. Currently, it's possible to get the spaces of a specific window, but this only works when Arc has any windows open. Being able to get all spaces regardless of whether any Arc window is open is required for integration with apps like browser pickers (for example, Velja), which need to fetch all spaces and store them, so users can pick which space to use for different situations. I imagine it would be a top-level command like `tabs` and `windows`.

If you want to help out more. This is another feature request. Nice to have, but not required:

> It would be useful if it were possible to open a URL in a specific Arc space from the command-line. This would make it easier to integrate Arc with things like browser pickers and scripts. I imagine it could be something like this: `open -b company.thebrowser.Browser --new --args --space "F0366664-F475-40EC-9530-45CC511CE9A6" https://arc.net` Where the `--space` argument would accept a space identifier.

*It's true that it would be possible to implement a somewhat working solution with the current functionality, but that would not be a great user-experience and I don't want to ship something that is not great.*

#### Can you support browser profiles for the [Arc](https://thebrowser.company) browser? {#arc-profiles}

The Arc browser is based on Chrome, so you may think that it should just work with browser profiles in Velja. However, Arc doesn't support the `--profile-directory` command-line flag. So while Velja can fetch the profiles, it's not able to actually use them.

**Arc works differently from other browsers. In Arc, you use spaces. Each space can be assigned a certain profile. So it makes more sense to support spaces rather than profiles in Velja. See the above FAQ.**

#### Can it open a specific browser when I double-click a file in the Google Drive folder in Finder?

You can use the rules feature in the settings for this.
1. Create a rule with the source app set to `Finder` and the “URL Prefix” set to `google.com/open`.
2. Create a second rule with the source app set to `Google Drive` and the “URL Prefix” set to `docs.google.com/open`.

#### How can I open a website from Spotlight results in a specific browser? {#spotlight}

Create a custom rule where you set the Spotlight app as “Source Apps”. The app is located at `/System/Library/CoreServices/Spotlight.app`.

#### How can I open Google Meet links in a desktop app?

You can choose an app to open Google Meet links with in the “Apps” tab in the settings. The app needs to support opening such links though. The Google Meet PWA (created in Chrome) does not accept opening such URLs.

#### I have both Firefox and Firefox Beta installed, but only one of them is showing up in Velja

Firefox and Firefox Beta use the same [identifier](https://cocoacasts.com/what-are-app-ids-and-bundle-identifiers/). Velja uses the identifier to uniquely identify different apps. This means there cannot be multiple apps with the same identifier in Velja. This is not a problem with Velja. It's just how macOS works.

#### How do I disable Velja?

[Change the system default browser back to Safari.](https://support.apple.com/en-us/HT201607)

#### Can you add another menu bar icon option?

Sure! Find an icon you like in the [SF Symbols app](https://developer.apple.com/sf-symbols/) or [here](https://thenounproject.com/icons/), and send me the name or link to it.

#### Why do I sometimes see a cog icon in the menu bar when opening a link? {#url-support-infoplist}

Some apps support opening a URL but they don't declare support for it. Velja must then use an alternative method to open the URL, which causes the cog icon to appear.

If you notice the cog icon when opening a URL with an app, I recommend sending feedback to the developer of the app. Right-click and copy [this link](#url-support-infoplist) to send to them.

**To the developer. You must include this in the Info.plist of your app:**

```xml
<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleTypeRole</key>
		<string>Viewer</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>https</string>
			<string>http</string>
		</array>
	</dict>
</array>
```

*You can optionally drop the `http` item if your app does not need to support that.*

#### What does “Velja” mean?

It means [“to choose”](https://en.wiktionary.org/wiki/velja) in [Old Norse](https://www.discovermagazine.com/planet-earth/what-language-did-the-vikings-speak) (also Icelandic and Faroese). Hence the Viking hat.

#### How does it compare to [Choosy](https://www.choosyosx.com)? {#choosy}

Velja benefits:

- Free
- It can open Google Meet links in Chrome without any manual setup
- It can open Mastodon links directly in a native Mastodon app
- It can [open links to certain services](https://twitter.com/sindresorhus/status/1519020970027401216) in their desktop app (Zoom, Microsoft Teams, Figma, etc.) without any manual setup and without those apps supporting such links directly
- Can show the icon of the active default browser in the menu bar
- Removes tracking parameters on clicked and copied links
- Open links in a private Safari window
- Available in the App Store
- Sandboxed (more secure)
- Shortcuts support
- Services support
- Can choose menu bar icon
- Convert copied links to [Songlink](https://odesli.co) for easy sharing

Choosy benefits:

- More options for custom rules

#### How does it compare to [Bumpr](https://www.getbumpr.com)? {#bumpr}

Velja benefits:

- Free
- It can open Google Meet links in Chrome without any manual setup
- It can open Mastodon links directly in a native Mastodon app
- It can [open links to certain services](https://twitter.com/sindresorhus/status/1519020970027401216) in their desktop app (Zoom, Microsoft Teams, Figma, etc.) without any manual setup and without those apps supporting such links directly
- Browser profile support
- More advanced custom rules, like the ability to open a certain link based on what app the link was clicked in
- Expands [short URLs](https://en.wikipedia.org/wiki/URL_shortening) for better matching
- Can show the icon of the active default browser in the menu bar
- Removes tracking parameters on clicked and copied links
- macOS-like user interface (Bumpr has a custom non-macOS-like user interface)
- You can open copied links from the menu bar menu
- You can quickly switch the primary browser
- You can press a keyboard shortcut to use an alternative browser for a specific link
- Setting to hide the menu bar icon
- Open links in a private Safari window
- Shortcuts support
- Handoff support
- Services support
- Share extension
- Can choose menu bar icon
- Convert copied links to [Songlink](https://odesli.co) for easy sharing

Bumpr benefits:

- Supports configuring the primary email app

#### How does it compare to [OpenIn](https://loshadki.app/openin/)? {#openin}

Velja benefits:

- Free
- It can open Google Meet links in Chrome without any manual setup
- It can open Mastodon links directly in a native Mastodon app
- It can [open links to certain services](https://twitter.com/sindresorhus/status/1519020970027401216) in their desktop app (Zoom, Microsoft Teams, Figma, etc.) without any manual setup and without those apps supporting such links directly
- Can show the icon of the active default browser in the menu bar
- Better user interface for browser profiles (OpenIn requires you to manually find the browser profile ID)
- The user interface is more macOS-like and better follows the [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos/overview/themes/)
- You can open copied links from the menu bar menu
- You can quickly switch the primary browser
- You can press a keyboard shortcut to use an alternative browser for a specific link
- Open links in a private Safari window
- Browser extensions
- Shortcuts support
- Services support
- Can choose menu bar icon
- Convert copied links to [Songlink](https://odesli.co) for easy sharing

OpenIn benefits:

- Supports configuring the primary app for more types, like email clients

#### How does it compare to [Browserosaurus](https://github.com/will-stone/browserosaurus)? {#browserosaurus}

Velja benefits:

- Native app written in Swift (Browsersaurus is an Electron app — a web app)
- Lower memory usage (Velja uses 36 MB and Browsersaurus uses 300 MB)
- Lower CPU usage (Velja uses 0% CPU when idle and Browsersaurus uses 0.1-0.2%)
- Available in the App Store
- Sandboxed (more secure)
- It can open Google Meet links in Chrome without any manual setup
- It can open Mastodon links directly in a native Mastodon app
- It can [open links to certain services](https://twitter.com/sindresorhus/status/1519020970027401216) in their desktop app (Zoom, Microsoft Teams, Figma, etc.) without any manual setup and without those apps supporting such links directly
- Browser profile support
- Can show the icon of the active default browser in the menu bar
- Custom rules, like the ability to open a certain link based on what app the link was clicked in
- Expands [short URLs](https://en.wikipedia.org/wiki/URL_shortening) for better matching
- Removes tracking parameters on clicked and copied links
- The user interface is more macOS-like and follows the [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos/overview/themes/)
- You can open copied links from the menu bar menu
- You can quickly switch the primary browser
- You can press a keyboard shortcut to use an alternative browser for a specific link
- Finds new browsers automatically (Browsersaurus has to manually scan for new browsers)
- Setting to hide the menu bar icon
- Open links in a private Safari window
- Browser extensions
- Shortcuts support
- Handoff support
- Services support
- Share extension
- Can choose menu bar icon
- Convert copied links to [Songlink](https://odesli.co) for easy sharing

Browserosaurus benefits:

- Open source

#### Why is this free without ads?

I just enjoy making Mac apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1607635845) and click “Version History”.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### [More FAQs…](/apps/faq)

<br>

### Scripting {#scripting}

The app can be automated using the Shortcuts app or with a custom URL scheme.

#### Custom URL scheme

You can open a URL using Velja from any tool that supports opening a URL. This includes a website, Bash, Node.js, Python, Swift, etc.

For example, in your terminal:

```sh
open --background 'velja:open?url=https%3A%2F%2Fsindresorhus.com&prompt'
```

Leave out `&prompt` to not show the browser prompt.

*Don't forget to [URL encode](https://www.urlencoder.org) the value for the `url=` search parameter. For example, using [this](https://gist.github.com/cdown/1163649) Bash function.*

Tip: You can specify the `url` search parameter multiple times to open multiple URLs.

#### Change default browser in Velja from the command-line

Run this command:

```sh
defaults write com.sindresorhus.Velja defaultBrowser com.apple.Safari
```

Replace `com.apple.Safari` with the bundle identifier of the browser you want.

To get the bundle identifier of an app, you can run:

```sh
osascript -e 'id of app "Safari"'
```

You can also use this trick to change the alternative browser by using `alternativeBrowser` instead of `defaultBrowser`.

Use the special bundle identifier `com.sindresorhus.Velja.promptMarker` to set the prompt as the browser.

<br>

### Older Versions

- [1.16.4](https://github.com/sindresorhus/meta/files/14577839/Velja.1.16.4.-.macOS.13.zip) for macOS 13+
- [1.12.4](https://github.com/sindresorhus/meta/files/10895250/Velja.1.12.4.-.macOS.12.zip) for macOS 12+

<br>

### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/8r0aij7ya4dtm0a1sse1x/Velja-2.0.0-1710312275.zip?rlkey=lxg22hq2rjrlic4mi43p480az&raw=1) *(2.0.0)*

*Requires macOS 14 or later*
