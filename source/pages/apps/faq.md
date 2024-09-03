---
layout: ~/layouts/MarkdownLayout.astro
title: Frequently Asked Questions
---

# Frequently Asked Questions

*See the page of each app for app-specific FAQs.*

### How can I report a bug or suggest a feature?

Tap the feedback button in the app or the support link on the app's page. I prioritize bug fixes and consider feature suggestions that align with the app's vision and user demand.

### Do your apps collect any personal data?

My apps prioritize user privacy and do not collect any personal data.

### How can I get a refund?

For apps purchased on the Apple App Store, you can [request a refund](https://support.apple.com/en-us/HT204084). However, I would appreciate if you [reached out](/feedback) first. I may be able to resolve any problems you are having.

### How many devices can I install an app on?

Apps purchased on the Apple App Store can be installed on up to 10 devices, with a maximum of 5 computers. [Learn more.](https://support.apple.com/en-us/HT204074)

### How can I transfer an app bought on the Apple App Store to a different account?

This is unfortunately [not possible](https://apple.stackexchange.com/a/444878). App developers have no control over the purchase process on the Apple App Store.

### Are your apps native?

Yes, all my apps are native. They are built using Swift and SwiftUI and are designed to provide the best performance and integration with the operating systems. I put a lot of effort into adhering to Apple's [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines).

### Why are most of your apps free?

I love making apps and I want them to be available to as many people as possible. I don't care much about money and I earn enough on my paid apps.

### Why should I trust you?

Free apps often raise doubts about privacy and intentions. Your trust matters deeply to me. Unlike others, I don't engage in data-selling or bombard you with pesky ads. Your privacy is sacred; you are not my product. I make apps because I enjoy it. I don't care about profits.

With over 3 million users placing their confidence in me, I take pride in safeguarding their devices and respecting their privacy. Moreover, my reputation speaks volumes. Tens of thousands of developers also rely on [my code](https://github.com/sindresorhus).

Trust is earned. Don't just take my word for it; delve into the reviews on the App Store. Your peace of mind matters, and I'm committed to upholding it every step of the way. Feel free to [contact me](/contact) if you have any questions.

### What's your policy on ads in your apps?

I hate ads. None of my apps have ads.

### How can I support your work?

Rate and review my apps on the App Store. Your ratings and reviews greatly aid in increasing the apps' visibility and discoverability, helping more users find them.

### Who makes your app icons?

I make them myself in Sketch, sometimes using AI as a starting point.

### How do you prioritize bug fixes?

User-reported bugs are prioritized based on their impact on the app's functionality and the number of users affected. My goal is to fix **all** bugs.

### What's the best way to learn about new apps?

Subscribe to my [“new apps” RSS feed](/rss-apps.xml) and follow me on [Twitter](https://twitter.com/sindresorhus) and [Mastodon](https://mastodon.social/@sindresorhus).

### Do you actively maintain all your apps?

Yes, I actively maintain all my apps to ensure they remain awesome and bug free. Every year, I make sure they take advantage of Apple's latest technologies.

### The app hasn't been updated in a while, is it still maintained?

Yes, if an app has not been updated for months, it's still actively maintained. A lack of recent updates indicates that the app has reached a mature and stable state.

### Why do you only support the latest macOS/iOS version?

I make apps for fun and supporting older operating system versions is simply no fun. It adds a lot of overhead with having to test each update on the older versions, work around bugs Apple will never fix, etc. As a compromise, I provide [older versions](/apps/older-versions) of my apps for older operating system versions.

### Why do you create multiple mini menu bar apps instead of one comprehensive “menu bar app”?

- **Focus:** Easier to make a high-quality app when it's focused on one thing.
- **Marketing:** Challenging to market an app that does too many different things.
- **Customization:** Users can install only what they need.
- **Isolation:** Issues in one app don’t affect others.
- **Satisfaction:** I like the satisfaction of completing an app.

### How can I export, import, sync, or back up the settings in a Mac app?

[See this guide.](https://github.com/sindresorhus/guides/blob/main/backup-app-settings.md)

### Can I contribute localizations to your apps?

No, I don't plan to localize my apps. Localization adds complexity and maintenance demands that detract from my focus on app quality and performance.

### Can you make your apps available on Homebrew? {#homebrew}

For App Store apps, unfortunately not. Supporting Homebrew requires distributing apps outside the App Store, and that involves significant overhead: hosting, auto-updating, and dual publishing. The demand simply doesn't justify these efforts.

For non-App Store apps, anyone can add to Homebrew. Feel free to [add one of my apps](https://docs.brew.sh/Adding-Software-to-Homebrew). I personally don't use Homebrew for apps, so it's not something I plan to do.

### You are doing a lot of open source, why are only some of your apps open source? {#why-not-oss}

I open source [some of my apps](https://github.com/search?q=user%3Asindresorhus+language%3Aswift+topic%3Aapp+archived%3Afalse), but not all, for a few key reasons. First, I use specialized tools (internal framework) to speed up app development, which are not suitable for sharing. Additionally, past experiences with open sourcing apps have led to clones of my apps appearing on the App Store, which is problematic. Also, community contributions, though well-intentioned, often don't match the high quality standards I set for my apps. As a compromise, I tend to open source the [reusable building blocks](https://github.com/search?q=user%3Asindresorhus+topic%3Aswift-package+archived%3Afalse), allowing community involvement while maintaining the quality and uniqueness of my apps.

### How can I uninstall your app? {#uninstall-app}

macOS: Ensure the app is not running. Open Finder, go to the “Go” menu, and select “Applications”. Find the app and drag it into the trash.

iOS: Tap and hold the app on the Home Screen and select “Remove App”.

*If you're uninstalling due to issues, please [contact me](/feedback) first; I resolve problems quickly.*

### I'm getting a “The application can’t be opened” error when trying to launch your app

Make sure the app is in the “/Applications” folder, then right-click the app and select "Open" from the context menu.

If it still doesn't work, the app may be quarantined, and the system is not showing the proper dialog. To fix this, open Terminal and run:

```sh
xattr -d com.apple.quarantine -r /Applications/AppName.app
```

Replace `AppName` with the name of the app. [Learn more.](https://superuser.com/a/28400/6877)

### How do I find the bundle identifier of a Mac app? {#find-bundle-identifier}

To get the bundle identifier of an app, run the following in the Terminal app:

```sh
osascript -e 'id of app "AppName"'
```

Replace `AppName` with the name of the app.

### What is a bundle identifier? {#bundle-identifier}

A bundle identifier (or bundle ID) uniquely identifies an app in Apple's ecosystem, using a reverse-domain format like `com.companyname.appname`. For example, `com.sindresorhus.Dato` for [Dato](/dato).

### I have enabled “launch at login” but the app does not launch when I start my computer {#launch-at-login-not-working}

When you enable that setting, the app simply tells macOS to launch it at login, so if it's not working, it's a problem with macOS or your system. As a workaround, you can manually add it: Open System Settings, go to “General › Login Items”, and click the “+” button, and choose the app.

### I'm having a problem with your app {#app-problem}

Here are some things you could try:

- Restart your device.
- Ensure you are on the latest version of the app.
- Ensure you are on the latest operating system version.
- Check the FAQ on the app's page in case it's already answered there.
- If the app requires an internet connection, make sure you are online. Try disabling any VPN.
- macOS: Close all other apps (including menu bar items) to make sure the problem is not caused by another app.
- macOS: [Reset permissions.](#mac-reset-permissions)
- [Reset the app.](#reset-app)

If you have tried all of this, [contact me](/feedback).

### How can I send you debug info for one of your apps? {#debug-info}

macOS: Make sure the app is not running (you can force-quit it from the Activity Monitor app) and then press <kbd>Shift</kbd>+<kbd>Control</kbd>+<kbd>Option</kbd> while launching the app.

iOS: In the app, tap the “Share App” button (usually found in settings), triple tap on the QR code, and then tap “Send Debug Info to Developer”.

### How can I delete all settings and data to start over in one of your apps? {#reset-app}

macOS: Make sure the app is not running (you can force-quit it from the Activity Monitor app) and then press <kbd>Shift</kbd>+<kbd>Control</kbd>+<kbd>Option</kbd>+<kbd>Command</kbd> while launching the app.

iOS: Open the Settings app, go to “General › iPhone/iPad Storage”, tap the app in the list, tap “Delete App”, then go to the App Store and install the app again.

### How can I reset all permissions for your Mac app? {#mac-reset-permissions}

*(This is only necessary if the app asked for any permissions the first time you launched it)*

First, quit the app.

Copy the following, open the Terminal app, paste it into the Terminal window, replace `<app-name>` with the name of the app, and then press the <kbd>Return</kbd> key:

```sh
osascript -e 'id of app "<app-name>"'
```

Example:

```sh
osascript -e 'id of app "Dato"'
```

You now have the app's identifier.

Next, copy the following, and paste it into the Terminal window, replace `<app-identifier>` with the app's identifier, and then press the <kbd>Return</kbd> key:

```sh
tccutil reset All <app-identifier>
```

Example:

```sh
tccutil reset All com.sindresorhus.Dato
```

You can now launch the app again.

### How can I send you a crash report for one of your apps? {#crash-report}

**macOS**
- Open Finder
- Select `Go to Folder…` from the `Go` menu
- Enter: `~/Library/Logs/DiagnosticReports`
- In the resulting list, select all files that starts with the app name, ZIP them, and [send me](/feedback)

**iOS**
- In the Settings app, go to “Privacy & Security › Analytics & Improvements › Analytics Data”
- Tap the first item that starts with the app name
	- If there is no such item, tap the first item that starts with `JetsamEvent`
- Tap the share button, tap a mail app, and send it to `sindresorhus@gmail.com`

### How can I send you a **spindump** for one of your Mac apps? {#spindump}

- Make sure the app in question is running.
- Open the Activity Monitor app.
- In the search bar in the toolbar, write the name of the app.
- Select the app.
- In the “View” menu (in the menu bar), click “Run Spindump”.
- Click the “Save” button.
- Send me the file.

### How can I send you a **process sample** for one of your Mac apps? {#sample-process}

- Make sure the app in question is running.
- Open the Activity Monitor app.
- In the search bar in the toolbar, write the name of the app.
- Select the app.
- In the “View” menu (in the menu bar), click “Sample Process”.
- Click the “Save” button.
- Send me the file.

### Can you support non-Apple platforms?

No, my expertise is exclusively in macOS, iOS, watchOS, and visionOS. Focus is key to high-quality apps.

### Can I hire you to build me an app?

I am not available for hire.

### Can I acquire your app?

No. I make apps because I enjoy it. Your money is of no interest to me.

### My question is not answered here

[Ask me.](/contact)

*You could also try to [ask my AI bot](https://chat.openai.com/g/g-df0ZoBF9N-sindregpt).*
