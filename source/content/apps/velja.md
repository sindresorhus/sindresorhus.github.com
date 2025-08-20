---
title: Velja
subtitle: Powerful browser picker
pubDate: 2022-04-21
platforms:
  - macOS
isPaid: true
isMenuBarApp: true
hasSentry: true
appStoreId: 1607635845
olderMacOSVersions:
  - '12'
  - '13'
  - '14'
feedbackNote: |
  [Can you support Safari profiles?](/velja#safari-profiles)

  [Can you support Arc/Dia spaces/profiles?](/velja#arc)

  [Support for opening links directly in Slack is not possible.](https://sindresorhus.com/velja#slack)

  **If you're requesting an addition to the “Apps” list, [please read this](https://sindresorhus.com/velja#builtin-apps-requests).**

  If you are missing a browser in the browser prompt, ensure you have enabled it in the “Shown browsers” setting. Also try restarting your computer.
---

Open links in a specific browser or a matching native app. Easily switch between browsers.

[In-depth review of Velja.](https://www.podfeet.com/blog/2022/11/velja/)

[*Trusted by almost 130K users.*](https://github.com/user-attachments/assets/011c6bda-186c-4ee7-868a-b71cc6f49a0b)

---

*You may also like my [Default Browser](/default-browser) app.*

---

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

- <https://issues.chromium.org/issues/40581582>
- <https://issues.chromium.org/issues/40962200>
- <https://issues.chromium.org/issues/40839891>

#### Supported browsers

Any browser.

#### Supported browsers for profiles

- Chrome *(and Beta, Canary, Dev)*
- Edge *(and Beta, Canary, Dev)*
- Brave *(and Beta, Nightly)*
- Vivaldi *(and Snapshot)*
- Chromium
- [Comet](https://comet.perplexity.ai)
- Thorium
- Wavebox

## Trial

Try the fully functional trial [here](https://www.dropbox.com/scl/fi/2fqy5lbg3kkcs9o4nhbqn/Velja-2.1.3-trial-1753136519.zip?rlkey=z68yp3a1rbeto863qeq1grw7e&raw=1). The only limitation is a reminder to buy the app every 12 hours, and no automatic updates. All data and settings carry over if you buy it.

*Download it to the Downloads folder, double-click to unzip, and then move it to the `/Applications` folder.*

**Requires macOS 15.4**

## Tips

### Prompt

Instead of showing the browser prompt by default, you could set it as the alternative browser, which would make it show when you hold the <kbd>Fn</kbd> key while clicking a link.

You could also create a custom rule and select `Prompt` as the browser. For example, you could only show the prompt when clicking links in the Slack app.

If you want to open a link in the background, press <kbd>Control</kbd> when selecting a browser in the prompt. [Known issue.](#chrome-background-bug)

### Prompt shortcuts

While showing the browser prompt, you can press <kbd>Option</kbd> to show buttons to copy or share the link. Or press <kbd>Shift</kbd> or <kbd>Command+C</kbd> to quickly copy the link.

Press <kbd>Option+Tab</kbd>/<kbd>Shift+Option+Tab</kbd> or arrow keys to cycle through browsers. Press <kbd>Return</kbd> or <kbd>Space</kbd> to select one.

### Copy URL

See the above tip.

You can also have “copy URL” as a browser choice in the prompt by installing [this app](https://github.com/sindresorhus/Copy-URL).

### Open links clicked in a specific app in a specific browser

For example, to open all links you click in Slack in Chrome:

- Open the Velja settings and go to the “Rules” pane.
- Create a new rule and give it a name.
- Select the browser to open. You can even choose a specific Chrome profile.
- Create a new “Source Apps” matcher and select the app you want. For example, Slack.
- Click “Save”.

### Using the Velja browser extension to open links directly in another browser

To open links from one browser to another when clicking the Velja browser extension icon without seeing a prompt:

1. Go to Velja's Advanced settings and disable "Force show prompt when opening from browser extension"
2. Create a new rule:
	- Choose your target browser in “Open in”
	- Add your source browser in “Source Apps”

For example, clicking the Velja extension icon in Safari should now open the link directly in Firefox.

### Open links in a private/incognito window

For Safari, [click here](https://github.com/sindresorhus/Safari-Private).

This is especially useful in combination with custom rules. For example, you could make a rule to open links to certain websites in a private window.

*Support for other browsers is planned.*

### Open multiple URLs

If you have a document with many URLs you want to open, select them, right-click, go to “Services”, and click “Open URLs with Velja”. [Learn more.](#macos-services)

### Open links in a website-wrapper app

Let's say you have generated a website wrapper app for facebook.com using an app like [Unite](https://www.bzgapps.com/unite) or [Coherence](https://www.bzgapps.com/coherence), and you want all links to Facebook to go to this app instead of your browser:

- Open the Velja settings and go to the “Rules” pane.
- Create a new rule and give it a name.
- Select the website wrapper app in the “Open in” field.
- Create a new “URL Matchers” matcher and write “facebook.com” in the “Match” field.
- Click “Save”.

### System services {#macos-services}

The app comes with [system services](https://macreports.com/what-is-the-services-menu-in-macos/?utm_source=chatgpt.com) to open URLs with Velja. This lets you open URLs with Velja from anywhere.

For example, select some text with URLs, right-click, go to “Services”, and click “Open URLs with Velja”.

If you want to force the browser prompt, you can either press <kbd>Option</kbd> when activating the service or use the “Open URLs with Velja Prompt” service.

If you want to force the link to open in the background, press <kbd>Shift</kbd> when activating the service. [Known issue.](#chrome-background-bug)

*You may have to enable the service in “System Settings › Keyboard › Keyboard Shortcuts › Services”.*

### Browser extensions

- Safari — Built-in. Just enable it in the Safari settings.
- [Chrome](https://chrome.google.com/webstore/detail/velja/gpipdgcamiclkcomcnogmlfpalggmcmk) — Also works in Edge, Brave, and other Chromium-based browsers.
- [Firefox](https://addons.mozilla.org/firefox/addon/velja/)

### Open the current website in a different browser

For example, you are surfing a website in Safari and want to open it in Chrome.

You could enable the Velja browser extension and then click the toolbar icon in your browser to show the Velja browser prompt.

You could also show the browser prompt when pressing a keyboard shortcut:
- Add [this shortcut](https://www.icloud.com/shortcuts/6c2d3793f101447dad449e83bde8d967).
	- If your browser is not Safari, change the app name in the shortcut.
- Add a keyboard shortcut to the shortcut config.
- Pressing the configured keyboard shortcut will now show the browser prompt.

If you want to open the website in a specific browser directly instead of showing the browser prompt, add [this shortcut](https://www.icloud.com/shortcuts/d3f833d1a1334d169ccefe26fa0ec240) instead.

### Open links clicked in a browser or PWA in a specific browser

Velja generally cannot handle links clicked in a browser because browsers don't notify the system about it. However, there is a workaround. Install the [Redirector browser extension](https://rxliuli.com/project/redirector/) and make a rule in that extension to open links in Velja. Here's an [example rule](https://www.dropbox.com/scl/fi/nlfz76zbfd2fy0sg2ebz1/rules-1750189056.json?rlkey=32vbyznt3051ibd1lhbafbhtb&raw=1) (import it into the Redirector extension) that opens certain URLs clicked in a browser in Velja.

<!-- Velja generally cannot handle links clicked in a browser because browsers don't notify the system about it. However, there is a workaround. Install the [Redirector browser extension](https://rxliuli.com/project/redirector/) and make a rule in that extension to open links in Velja. Here's an [example rule](https://www.dropbox.com/scl/fi/s99bdxvbypar0nj2v8pj5/Redirector-1702989917.json?rlkey=fey4cs3wxuln528wkb5ai75u5&raw=1) (import it into the Redirector extension) that opens all links clicked in a browser in Velja. This could be useful if you need to open all links from a browser PWA in a specific browser. -->

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

### Launch browsers from Velja menu

Hold the <kbd>Option</kbd> key when clicking a browser in the Velja menu to launch it instead of setting it as the current browser. This even works with browser profiles.

### Open certain URLs in a specific browser profile

- Open the Velja settings.
- Go to the “Browsers” tab and grant access to browser profiles.
- Go to the “Rules” tab.
- Click “+”.
- Choose a browser profile in “Open in”.
- Click “+” for the “URL Matchers”.
- Define a pattern that matches the URLs you want to match.
- Click “Save”.

### Automatically switch browser or browser profile based on time, location, or Focus mode

Say you use different browser profiles for work and home and want them to switch automatically. This is a good use for the Shortcuts app. Create a shortcut with the "Set Default Browser" action that sets the browser profile to the one you want at home and another for work. You will then need the [Shortery](https://apps.apple.com/app/id1594183810) app to trigger these shortcuts at specific times, or based on your Focus mode if you have one for work. You could even trigger the shortcuts based on Wi-Fi name, which may be easier than defining work times if you work from an office.

### Miscellaneous

- In the Velja menu, you can click “History” to directly open the history window.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](/feedback?product=Velja&referrer=Website-FAQ)

#### The app does not show up in the menu bar

[Try this](/apps/faq#app-not-showing-in-menu-bar)

You may also have disabled the “Show menu bar icon” setting, which hides the menu bar icon. Launch the app again to reveal the menu bar item for 5 seconds.

#### Why is the app suddenly paid? It used to be free.

While I love making free apps that are available to anyone, the high volume of support requests became unsustainable. After providing Velja for free for 3 years with nearly 130K downloads, I made the decision to make it paid. This isn't about revenue - it's about managing my time more effectively by reducing the support burden to a sustainable level.

#### Can this app be available on Setapp? {#setapp}

Setapp curates apps based on demand, so if you'd like to see this app on Setapp, [email them](https://support.setapp.com/hc/articles/4950254561052-How-to-contact-Setapp-team#:~:text=to%20your%20issue.-,Send%20an%20email,%3A%20support%40setapp.com.) and request its inclusion.

#### Velja does not work

First, make sure that the problem is Velja. Go to “System Settings › Desktop & Dock” and change the “Default web browser” setting to Safari. Then try clicking the link again. If the problem persists, it's not caused by Velja.

**I clicked a link in a browser**

Velja is not able to handle links clicked inside a browser. However, Velja comes with a Safari extension which you can enable in the Safari settings. You can then click the toolbar icon to open the current page with Velja or right-click a link to open it with Velja. There are also [extensions for other browsers](#browser-extensions).

If you use a browser where Velja does not have a browser extension, you could also right-click the link and use the share extension \* or copy the link and then click “Open URL from Clipboard” in the Velja menu.

\* *Chrome (and Edge, Brave, etc.) does not have a “Share” item in its context menu. Please [star this issue](https://bugs.chromium.org/p/chromium/issues/detail?id=916291).*

Velja also comes with a [system service](https://www.computerworld.com/article/2476298/os-x-a-quick-guide-to-services-on-your-mac.html). However, neither Safari ([issue](https://github.com/feedback-assistant/reports/issues/304)) or Chrome ([issue](https://bugs.chromium.org/p/chromium/issues/detail?id=1325557)) correctly sends links to a system service, so it cannot be used for this purpose.

**The prompt does not show**

Make sure you didn't click the link in a browser. See above.

**I clicked a link in VS Code**

By default, VS Code does not open the system default browser when you click a link in the app. Because of this, Velja is not used. You can change this with the `workbench.externalBrowser` setting in VS Code.

**I clicked a short URL**

If the link is a [short URL](https://en.wikipedia.org/wiki/URL_shortening), make sure the “Expand short URLs” setting is enabled and the URL shortening service is either in the built-in list or added by you. Velja is only able to do its matching when it receives the resolved URL.

**I clicked a button in the Dropbox app**

This is either a macOS or Dropbox bug. Velja simply opens what it receives, but what it receives has incorrect permissions. When you click a button in Dropbox to open it on the web, it doesn't actually open the URL directly, but instead writes an HTML file (which redirects to the final URL) to a temporary directory. I’m not sure why it does this, but it’s likely the cause of the issue.

**It did not respect my rule that uses a "source app" condition**

Ensure Velja correctly identifies the source app where the link was clicked. To check, enable the history setting (in the “Advanced” settings tab), click a link, and confirm the correct source app appears in the history screen.

If the URL was opened using the `open` command-line tool, it may not work as expected because `open` closes before Velja can capture the app name. To work around this, use the following command:

```sh
timeout 0.5 open --wait-apps "https://sindresorhus.com/velja"
```

<a id="custom-rule-problem"></a>
**My custom rule did not work**

Make sure it's none of the above cases. Also make sure you have added a “Sample URL” to the rule to confirm your match pattern is correct.

Some apps use a redirect URL for tracking purposes. Velja has built-in support for a lot of redirect services and it also tries to resolve URLs to their final destination. However, some redirects cannot be resolved by Velja. This is the case with some links clicked in Slack as they require the login token to be able to redirect. There is unfortunately nothing I can do about that.

See [this](#debug) for how to debug what URLs Velja receives.

If the redirect URL contains the destination URL (usually in a search parameter), contact me and I will add support for it.

#### What are tracking parameters and why would I want to remove them?

Removing tracking parameters improve privacy and also make URLs more aesthetically pleasing. Tracking parameters are used by many websites to track your browsing activity across websites. [Learn more.](https://en.wikipedia.org/wiki/UTM_parameters)

Velja supports 200+ common tracking parameters (e.g. Google UTM) and it has special support for removing tracking from links to X (Twitter), Facebook, and TikTok.

Before: `https://foo.com?utm_content=buffercf3b2&utm_source=snapchat.com`\
After: `https://foo.com`

Did you know that if you click a TikTok link that someone shared with you, they will be able to see that you watched it? Velja anonymizes TikTok links so that you will not be tracked.

#### Tracking parameters are not removed {#tracking-parameters-not-removed}

First, make sure the setting to remove tracking parameters is enabled.

If the clicked/copied link is a short URL, Velja is only able to remove the tracking parameters if the “Expand short URLs” setting is enabled and it's a known short URL service or you added the short URL service in the “Advanced” settings pane.

The app contains a list of tracking parameters to remove, but there may be site-specific tracking parameters it doesn't know about. If you encounter any tracking parameters not being removed, [let me know](/feedback?product=Velja&referrer=Website-FAQ) and I'll add support for them.

#### Can you add support for this browser? {#add-browser}

Velja automatically retrieves all browsers on your computer. There is no manual list of browsers. If some browser is not showing up, make sure it's in the `/Applications` folder and not in the `~/Applications` folder.

#### Can you add another app to the “Apps” settings? {#builtin-apps-requests}

**I'm not currently accepting more apps. I'm working on a way for users to add apps themselves.**

I'm happy to consider requests (but read the below first). [Submit here.](/feedback?product=Velja&referrer=Website-FAQ) *(Include a link to the app and what behavior you expected)*

**Note:** This is about opening a link in a specific app. If you want to open a link **from** a specific app, just use the rules feature in the settings (it supports any app).

*If this is about opening a specific website (for example, Google Sheets) in a specific browser, you should use the rules feature instead (the “Rules” tab in the settings). You can easily make a rule for any website.*

*If this is about opening a specific website like Facebook in an app-wrapped website generated with something like Unite or Coherence, it's better to just add support yourself. You can use the rules feature for this. For example, write “facebook.com” as the domain and select the website wrapper app you generated.*

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
	+ The app does not accept any links. It does accept [custom URL scheme](https://support.craft.do/hc/articles/360020168838-Using-URL-Scheme) links, but I'm not interested having to maintain more code to transform URLs in Velja when the services should just handle it themselves in their desktop apps.

And some apps do not need special support because they already support [universal links](https://developer.apple.com/ios/universal-links/):
- [Quip](https://quip.com)
- Maps (the built-in app)
- Overcast

*Universal links also prevent Velja from letting you open a link in the browser instead of the app. [Possible workaround.](https://lapcatsoftware.com/articles/universal-links2.html)*

If your favorite service is in the above list, I would recommend contacting them and asking them to support opening a link directly in their app. That means being able to run the command `open -a AppName https://foo.com/link-to-project-or-meeting`.

#### Can Velja override Universal Links?

No. There is a way to do it, but it requires a special entitlement from Apple. I applied for it a year ago and haven't heard anything.

There are some ways to [disable Universal Links](https://mjtsai.com/blog/2022/04/19/disabling-universal-links/).

#### How can I add a browser profile to the prompt?

First, make sure you grant access to profiles in the settings and then enable them in the “Shown Browsers” setting.

#### How can I open specific URLs in a Safari PWA (website added to the Dock)? {#safari-dock-app}

Websites added to the Dock from Safari are just normal apps located in `~/Applications`. You could create a custom rule to match certain URLs and have them open in one of these web-wrapper apps.

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

#### I opened a link in the background but it brought Chrome to the foreground {#chrome-background-bug}

Chrome (and Chrome-based browsers) does not properly respect opening URLs in the background (it generally does not respect platform conventions). This can be reproduced even without Velja by setting Chrome as the system default browser in the System Settings and then running the following in the Terminal:

```sh
open --background 'https://sindresorhus.com'
```

[Star this issue](https://issues.chromium.org/issues/41182587)

#### The link takes a long time to open

This is most likely not caused by Velja. Some users reported it was a problem with Microsoft Office and happened without Velja too.

Also try to disable the “Expand redirect and short URLs” setting.

To confirm Velja is not the problem: Go to “System Settings › Desktop & Dock” and change the “Default web browser” setting to Safari. Then try clicking the link again. If the problem persists, it's not caused by Velja.

#### Can you add support for opening Slack links in the Slack desktop app? {#slack}

This is currently not possible. The Slack app does not accept a normal deep link (example: `https://team-name.slack.com/archives/CKPE4C/p161643063559`). It only accepts a special Slack-specific URL. To be able to convert a normal Slack link to one that the desktop app accepts, we would need to get the team ID from the Slack API and that requires authentication. It's simply not feasible to do this. **Please do send feedback to Slack asking them to accept a normal link, like most other apps support.**

#### Can the default browser change based on the active [focus mode](https://support.apple.com/guide/mac-help/set-up-a-focus-to-stay-on-task-mchl613dc43f/mac)? {#focus-mode}

You can use the [Focus Filter](https://support.apple.com/HT212608) that comes with the app.

Alternatively, you can use the Shortcuts app for this. Make a shortcut for each focus mode you want to handle, where you use the “Set Default Browser” action that Velja provides. You will need the [Shortery app](https://apps.apple.com/app/id1594183810) to automatically run these shortcuts when the focus mode changes.

#### Can the default browser change depending on whether I'm at work or not?

See the above answer. You just create a work focus mode.

#### Can the default browser change depending on whether the computer is on battery?

See the above answer. Use the “Power Status” trigger in Shortery.

#### Can you support [Focus filters](https://support.apple.com/HT212608)? {#focus-filters}

It is supported.

#### Can you add iCloud syncing for the rules? {#icloud}

No. iCloud syncing is unreliable, opaque, and significantly increases my support burden. Very few users request it, and for such a niche feature, the effort and ongoing cost are not worth it.

You can already export and import rules manually.

#### Can you add a vertical or circular browser prompt?

I don't plan to add this. I recommend giving the horizontal prompt a try. A lot of users found it to work better than vertical/circular.

#### Does it support [Handoff](https://support.apple.com/en-vn/102426)? {#handoff-support}

Yes. It will open the handoff in the chosen primary browser.

Note that it shows the Velja app icon for Handoff, not the chosen primary browser. There is no way to work around this.

#### How can I set the last active browser as the default browser?

You can use the [Shortery](https://apps.apple.com/app/id1594183810) and Shortcuts apps for this. Create a shortcut ([example](https://www.icloud.com/shortcuts/cca638ad5d8548dca7f2cbc8e7eb967b)) for each browser you use. The shortcut should use the “Set Default Browser” action to set the default browser in Velja. In Shortery, create an “Application” trigger for each browser, where you choose the corresponding shortcut and app in the “Application” field ([screenshot](https://www.dropbox.com/scl/fi/pjbimgvq3wtuvp0265vk6/Screenshot-2024-06-30-at-17.41.45-1719762112.png?rlkey=7qgwyxq2woz4zaeib1cs2r5w0&raw=1)). The default browser in Velja will now change when you focus one of those browsers.

#### How can I see what URL Velja received? {#debug}

In the advanced settings, enable the link history setting, and then click the link. The URL will show up there.

To see more detailed debug info on how Velja handled the URL: Quit Velja if it's open. Press <kbd>Shift</kbd> + <kbd>Control</kbd> while launching Velja, click the menu bar icon, click “Debug”, and then go to “Logs”.

#### How can I open a URL in a specific Safari Tab Group? {#safari-tab-group}

Safari does not provide any way to achieve this. You will have to send a [feature request to Apple](https://feedbackassistant.apple.com). Tell them they need to add support for opening a URL in a specific Safari Tab Group from AppleScript and Shortcuts.

#### Some browsers are missing

If the browsers are in the “~/Applications” folder or are browser profiles, see below.

#### Velja does not show browsers from the user “~/Applications” folder

Apple generally recommends putting apps in the global “/Applications” folder. Third-party apps like Velja get automatic access to this one, but not to the user “~/Applications” folder.

Try clicking the “More › Reset Access” button in the Velja menu.

#### I have Mastodon links set to open in a specific browser, but it opens in the Ivory app {#ivory-mastodon}

Ivory supports [Universal Links](https://developer.apple.com/ios/universal-links/) for some Mastodon instances and Velja cannot override Universal Links. Universal Links is an annoying feature as it gives users (and other developers) no control over how it works.

As of Ivory 1.0.0, it supports [these Mastodon instances](https://github.com/sindresorhus/meta/assets/170270/e256c5e1-5048-4cbc-8df2-aa09c969b639).

#### How can I export, import, sync, transfer, or back up the settings?

You can export and import rules in the settings. See the bottom of the “Rules” settings tab.

For all settings, [see this](/apps/faq#export-settings).

#### Can you support Safari profiles? {#safari-profiles}

Safari does not expose any way to open URLs in a specific profile. I recommend [sending feedback](https://feedbackassistant.apple.com) to Apple that they should add Shortcuts and AppleScript support for this. More feedback increases the chances of it happening.

*This is still the case on macOS 15 and macOS 26.*

Feel free to duplicate my feedback reports:

- [FB12320822](https://github.com/feedback-assistant/reports/issues/398)
- [FB12320895](https://github.com/feedback-assistant/reports/issues/399)

You can submit it [here](https://feedbackassistant.apple.com).

#### Can you support spaces for the [Arc](https://thebrowser.company) browser? {#arc}

I would love to support Arc, but it's currently missing some required functionality.

**Note that they now support [something similar to Velja built in](https://x.com/browsercompany/status/1654525608305491984).**

Arc supports fetching the spaces of a specific Arc window using AppleScript. However, Velja needs to be able to fetch the spaces even when Arc has no open windows, so that it can show a list of spaces in the Velja settings.

I recommend sending them feedback about this. Either through the feedback button in Arc or at [hello@thebrowser.company](mailto:hello@thebrowser.company).

I have prepared a ready-made feature request text you can use:

> It would be great if Arc could support getting a list of all the spaces with AppleScript. Currently, it's possible to get the spaces of a specific window, but this only works when Arc has any windows open. Being able to get all spaces regardless of whether any Arc window is open is required for integration with apps like browser pickers (for example, Velja), which need to fetch all spaces and store them, so users can pick which space to use for different situations. I imagine it would be a top-level command like `tabs` and `windows`.

If you want to help out more. This is another feature request. Nice to have, but not required:

> It would be useful if it were possible to open a URL in a specific Arc space from the command-line. This would make it easier to integrate Arc with things like browser pickers and scripts. I imagine it could be something like this: `open -b company.thebrowser.Browser --new --args --space "F0366664-F475-40EC-9530-45CC511CE9A6" https://arc.net` Where the `--space` argument would accept a space identifier.

*It's true that it would be possible to implement a somewhat working solution with the current functionality, but that would not be a great user-experience and I don't want to ship something that is not great.*

#### Can you support browser profiles for the [Arc](https://thebrowser.company)/[Dia](https://www.diabrowser.com) browser? {#arc-profiles}

The Arc/Dia browser is based on Chrome, so you may think that it should just work with browser profiles in Velja. However, Arc/Dia doesn't support the `--profile-directory` command-line flag. So while Velja can fetch the profiles, it's not able to actually use them.

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

[Change the system default browser back to Safari.](https://support.apple.com/HT201607)

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

#### Can you support iOS? {#ios}

No:

1. **Not allowed:** Velja works by being the default browser, but iOS only [allows full browsers](https://developer.apple.com/documentation/xcode/preparing-your-app-to-be-the-default-browser) (like Safari or Chrome) to be set as default.
2. **Too slow:** Each link would first open Velja, then the actual browser. This is fast on macOS because Velja runs in the background, but not on iOS.

#### How does it compare to [Choosy](https://www.choosyosx.com)? {#choosy}

Velja benefits:

- It can open Google Meet links in Chrome without any manual setup
- It can open Mastodon links directly in a native Mastodon app
- It can [open links to certain services](https://x.com/sindresorhus/status/1519020970027401216) in their desktop app (Zoom, Microsoft Teams, Figma, etc.) without any manual setup and without those apps supporting such links directly
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

- It can open Google Meet links in Chrome without any manual setup
- It can open Mastodon links directly in a native Mastodon app
- It can [open links to certain services](https://x.com/sindresorhus/status/1519020970027401216) in their desktop app (Zoom, Microsoft Teams, Figma, etc.) without any manual setup and without those apps supporting such links directly
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

- It can open Google Meet links in Chrome without any manual setup
- It can open Mastodon links directly in a native Mastodon app
- It can [open links to certain services](https://x.com/sindresorhus/status/1519020970027401216) in their desktop app (Zoom, Microsoft Teams, Figma, etc.) without any manual setup and without those apps supporting such links directly
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
- It can [open links to certain services](https://x.com/sindresorhus/status/1519020970027401216) in their desktop app (Zoom, Microsoft Teams, Figma, etc.) without any manual setup and without those apps supporting such links directly
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

#### Can you localize the app into my language?

I don't plan to localize the app.

#### [More FAQs…](/apps/faq)

## Scripting {#scripting}

The app can be automated using the Shortcuts app or with a custom URL scheme.

### Custom URL scheme

You can open a URL using Velja from any tool that supports opening a URL. This includes a website, Bash, Node.js, Python, Swift, etc.

For example, in your terminal:

```sh
open 'velja:open?url=https%3A%2F%2Fsindresorhus.com&prompt'
```

Leave out `&prompt` to not show the browser prompt.

*Don't forget to [URL encode](https://www.urlencoder.org) the value for the `url=` parameter. For example, using [this](https://gist.github.com/cdown/1163649) Bash function.*

Tip: You can specify the `url` parameter multiple times to open multiple URLs.

You can force the use of a specific browser by specifying an `app` parameter:

```sh
open 'velja:open?url=https%3A%2F%2Fsindresorhus.com&app=org.mozilla.firefox'
```

It expects the [bundle identifier](/apps/faq#find-bundle-identifier) of an app. Rules will be ignored when this is specified.

You can also specify a browser profile by adding the `profile` parameter (Velja 2.1.0 and later):

```sh
open 'velja:open?url=https%3A%2F%2Fsindresorhus.com&app=com.google.Chrome&profile=Work'
```

The `profile` parameter must be used together with the `app` parameter and expects the profile name (not ID). See the Velja settings for supported browsers.

### Change default browser in Velja from the command-line

Run this command:

```sh
defaults write com.sindresorhus.Velja defaultBrowser com.apple.Safari
```

Replace `com.apple.Safari` with the [bundle identifier](/apps/faq#find-bundle-identifier) of the browser you want.

You can also use this trick to change the alternative browser by using `alternativeBrowser` instead of `defaultBrowser`.

Use the special bundle identifier `com.sindresorhus.Velja.promptMarker` to set the prompt as the browser.

## Older Versions

- [2.0.14](https://github.com/user-attachments/files/18629080/Velja.2.0.14.-.macOS.14.zip) for macOS 14
- [1.16.4](https://github.com/sindresorhus/meta/files/14577839/Velja.1.16.4.-.macOS.13.zip) for macOS 13
- [1.12.4](https://github.com/sindresorhus/meta/files/10895250/Velja.1.12.4.-.macOS.12.zip) for macOS 12

These are free for everyone but they will not run on newer macOS versions.
