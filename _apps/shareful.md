---
title: Shareful
subtitle: Give the macOS share menu superpowers
date: 2020-09-08
platforms:
  - macOS
app_store_app_id: 1522267256
mac_app_store_url: https://apps.apple.com/app/id1522267256
---

<a align="center" style="display:block" href="https://www.producthunt.com/posts/shareful?utm_source=badge-featured&utm_medium=badge&utm_souce=badge-shareful" target="_blank"><img src="https://api.producthunt.com/widgets/embed-image/v1/featured.svg?post_id=282336&theme=light" alt="Shareful - Supercharge the macOS share menu | Product Hunt" style="width: 250px; height: 54px;" width="250" height="54"/></a>

<br>

### Older versions

- [Last macOS 11 compatible version](https://github.com/sindresorhus/meta/files/8800088/Shareful.1.6.0.-.macOS.11.zip) *(1.6.0)*
- [Last macOS 10.15 compatible version](https://github.com/sindresorhus/meta/files/7119520/Shareful.1.4.0.-.macOS.10.15.zip) *(1.4.0)*

<br>

<h3 id="tips">Tips</h3>
<table>
	<tr>
		<td>
			For apps with a “Share” menu item, you can trigger one of the share services directly with a global keyboard shortcut. To enable this, go to “System Preferences › Keyboard › Shortcuts › App Shortcuts”, click the plus button, choose “All Applications”, write the name of the share service in the “Menu Title” field (for example, “Save to Downloads”), set the keyboard shortcut, and then click “Add”.
		</td>
	</tr>
</table>

<br>

<h3 id="faq">Frequently Asked Questions</h3>

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback/?product=Shareful&referrer=Website-FAQ)

#### The share services do not show up in System Settings

Shareful provides share services (Copy, Open In, etc) which macOS is supposed to pick up. Shareful has no control over how it works. In some rare cases, macOS can fail to pick up these share services. This is a problem with macOS not Shareful.

Here are some things you could try:
- Restart your computer
- [Reset NVRAM](https://support.apple.com/en-us/HT204063)
- [Reset the share services registry](https://web.archive.org/web/20180711015728/https://support.apple.com/en-us/HT203129)

If you are on a work computer, it could also be that your company has blocked third-party share services.

#### Can you also add a “Move” action?

This is unfortunately not possible. [Share extensions](https://developer.apple.com/design/human-interface-guidelines/macos/extensions/share-extensions/), like the "Copy" action, only receive a copy of the file. They have no access to the original file.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1522267256) and click “Version History”.

#### Why is this free without ads?

I just enjoy making apps. Consider leaving a nice review on the App Store.
