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

**Note that the app was just recently launched. I'm quickly iterating based on feedback.**

<br>

<h3 id="faq">Frequently Asked Questions</h3>

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback/?product=Velja&referrer=Website-FAQ)

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some menu bar apps to free up space. If this does not solve it, try quitting Bartender if you have it installed.

You may also have enabled the “Hide menu bar icon” preference, which hides the menu bar icon. Launch the app again to reveal the menu bar item for 5 seconds.

#### What are tracking parameters and why would I want to remove them?

Removing tracking parameters improve privacy and also make URLs more aesthetically pleasing. Tracking parameters are used by many websites to track your browsing activity across websites. [Read more.](https://en.wikipedia.org/wiki/UTM_parameters)

Before: `https://foo.com?utm_content=buffercf3b2&utm_source=snapchat.com`\
After: `https://foo.com`

#### Can you add a visual picker that shows when clicking a link?

I will consider it if there is demand for it. [Let me know](https://sindresorhus.com/feedback/?product=Velja&referrer=Website-FAQ) if you want this.

<a id="builtin-apps-requests"></a>
#### Can you add another app to the “Apps” preferences?

I'm happy to consider requests. [Submit here.](https://sindresorhus.com/feedback/?product=Velja&referrer=Website-FAQ)

However, some apps are not possible:
- Slack
  + *The Slack app does not accept a normal deep link (example: `https://team-name.slack.com/archives/CKPE4C/p161643063559`). It only accepts a special Slack-specific URL. To be able to convert a normal Slack link to one that the desktop app accepts, we would need get the team ID from the Slack API and that requires authentication. It's simply not feasible to do this. __Please do send feedback to Slack asking them to accept a normal link, like most other apps support.__*
- Asana
  + *They [claim](https://forum.asana.com/t/when-using-the-desktop-mac-app-i-would-like-all-links-to-open-in-the-browser/135360/4) you can configure it in your profile, but I could not get it to work. I recommend asking in their support channels about it.*
- Cisco Webex
  + *[Comment here](https://github.com/johnste/finicky/discussions/228) if you know how to do this.*

If your favorite service is in the above list, I would recommend contacting them and asking them to support opening a link directly in their app. That means being able to run the command `open -a AppName https://foo.com/link-to-project-or-meeting`.

<a id="focus-mode"></a>
#### Can the default browser change based on the active [focus mode](https://support.apple.com/guide/mac-help/set-up-a-focus-to-stay-on-task-mchl613dc43f/mac)?

You can use the Shortcuts app for this. Make a shortcut for each focus mode you want to handle, where you use the “Set Default Browser” action that Velja provides. You will need the [Shortery app](https://apps.apple.com/app/id1594183810) to automatically run these shortcuts when the focus mode changes.

#### How do I disable Velja?

[Change the system default browser back to Safari.](https://support.apple.com/en-us/HT201607)

#### What does “Velja” mean?

It means [“to choose”](https://en.wiktionary.org/wiki/velja) in [Old Norse](https://www.discovermagazine.com/planet-earth/what-language-did-the-vikings-speak) (also Icelandic and Faroese). Hence the viking hat.

#### How does it compare to [Choosy](https://www.choosyosx.com)?

Velja benefits:

- It can [open links to certain services](https://twitter.com/sindresorhus/status/1519020970027401216) in their desktop app (Zoom, Microsoft Teams, Figma, etc.)
- It can open Google Meet links in Chrome without any manual setup
- Removes tracking parameters on clicked and copied links
- You can open copied links from the menu bar menu
- You can press a keyboard shortcut to use an alternative browser for a specific link
- Shortcuts support
- Available in the App Store
- Sandboxed (more secure)
- Free

Choosy benefits:

- Browser selector when clicking a link
- Browser extension
- More mature
- More options for custom rules

#### Why is this free without ads?

I just enjoy making Mac apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1607635845) and click “Version History”.

#### Can you localize the app into my language?

I don't have any immediate plans to localize the app.
