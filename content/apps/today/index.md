---
title: 'Today'
subtitle: 'Today’s schedule in your menu bar'
publicationDate: 2022-10-27
platforms: [
	'macOS'
]
isMenuBarApp: true
appStoreID: 6443714928
hasSentry: true
nonAppStoreVersion: {
	version: '1.8.0'
	macOS: 26
	url: 'https://www.dropbox.com/scl/fi/06fgch1tc9yp87n44203e/Today-1.8.0-1770891350.zip?rlkey=8kgvpzcdme7bq917h717nlbk5&raw=1'
}
sharedQuestions: [
	'randomly-quits'
	'menu-bar-icons'
	'blurry-secondary-display'
	'backup-settings'
	'any-video-call-link'
]
olderVersions: [
	{
		version: '1.7.1'
		macOS: '15'
		url: 'https://www.dropbox.com/scl/fi/ca9u8j9b563svmshjh37j/Today-1.7.1-macOS-15-1770891871.zip?rlkey=80exyjq71aemdfagycis82u3w&raw=1'
	}
	{
		version: '1.6.2'
		macOS: '14'
		url: 'https://github.com/user-attachments/files/18873369/Today.1.6.2.-.macOS.14.zip'
	}
	{
		version: '1.5.0'
		macOS: '13'
		url: 'https://github.com/sindresorhus/meta/files/13997505/Today.1.5.0.-.macOS.13.zip'
	}
]
pressQuotes: [
	{
		quote: 'Sindre Sorhus, an independent Mac app developer, has built Today, a simple tool that lives in the menu bar. With a single click, you get a view of the day’s appointments.'
		source: 'Compétence Mac'
		translatedFrom: 'French'
		url: 'https://competencemac.com/mac-vos-rendez-vous-du-jour-toujours-sous-les-yeux/'
		year: 2023
	}
]
feedbackNote: '[The app randomly disappears/quits](/today#randomly-quits)'
---

See today’s events in your menu bar, and nothing else. Click an event to show it in the Calendar app, or join an upcoming video call directly from the menu.

This app is intentionally simple. For more advanced needs, check out [Dato](/dato).

It integrates with Calendar, Fantastical, and BusyCal.

With the “Next up” setting, the menu can also show your first event after today. You can set global keyboard shortcuts to show Today, create a new event, and open your calendar.

## Frequently Asked Questions {#faq}

### How do I get back to the settings if I have hidden the `…` menu item? {#how-do-i-get-back-to-the-settings-if-i-have-hidden-the--menu-item}

Press the ++Option++ key while opening the Today menu.

### It does not support the video call service I use {#it-does-not-support-the-video-call-service-i-use}

I’m happy to add support for more services. Just [send me](/feedback?product=Today&referrer=Website-FAQ) an invitation link (replace a few characters at the end to anonymize it).

The app can also [detect the link of any video call service](#any-video-call-link).

### How do I add a calendar? {#how-do-i-add-a-calendar}

[Add the calendar to the built-in Calendar app](https://support.apple.com/guide/calendar/add-or-delete-calendar-accounts-icl4308d6701/mac) and then enable it in the Today settings.

### Can you add support for Google Calendar / Outlook 365 / Exchange? {#google-calendar}

It’s already supported. Just add your calendars to the built-in Calendar app and then enable those calendars in the app settings.

### How can I open meeting links (Google Meet, Zoom, Microsoft Teams, etc.) in a specific browser? {#how-can-i-open-meeting-links-google-meet-zoom-microsoft-teams-etc-in-a-specific-browser}

Check out my [Velja app](/velja). It has built-in support for this without any setup. It can even open links to Zoom and Microsoft Teams directly in their desktop app.

### I have Fantastical set as my default calendar app but Today still opens Calendar {#i-have-fantastical-set-as-my-default-calendar-app-but-today-still-opens-calendar}

There is a [macOS bug](https://github.com/feedback-assistant/reports/issues/290) that makes the default calendar app setting not work. To work around this, drag an event from the Calendar app into Finder, right-click on it, select “Get Info”, select your calendar in the “Open with” field, and click “Change All”.

### Can you add x feature? {#can-you-add-x-feature}

This app is a personal experiment to make the simplest calendar app possible. I’m happy to consider requests, but I’m also trying hard to keep the app simple.

### Can the app show notifications for events? {#notifications}

You can set up notifications for events in the Calendar app.

### Can the app show notifications with a “Join” button for video calls? {#can-the-app-show-notifications-with-a-join-button-for-video-calls}

I don’t plan to add this. You can get this feature in my [Dato app](/dato).

### Can the app show the upcoming event in the menu bar? {#can-the-app-show-the-upcoming-event-in-the-menu-bar}

I don’t plan to add this. You can get this feature in my [Dato app](/dato) (with a lot of customizability).

### Can the app support showing reminders? {#can-the-app-support-showing-reminders}

I don’t plan to add this. You can get this feature in my [Dato app](/dato).

### Can you make the app show events for more days? {#can-you-make-the-app-show-events-for-more-days}

No, the app is for today. But with the “Next up” setting, the menu can also show your first event after today. For more days, see [Dato](/dato).

### I added a calendar to the Calendar app but it doesn’t show up in the app {#i-added-a-calendar-to-the-calendar-app-but-it-doesnt-show-up-in-the-app}

You need to enable the calendar in the app settings.

### My Google Calendar does not update in the app {#my-google-calendar-does-not-update-in-the-app}

You might have to re-authenticate your Google account. Open the Calendar app’s settings, go to the “Accounts” pane, and try to remove and re-add the Google account.

### How can I make my calendar refresh more often? {#how-can-i-make-my-calendar-refresh-more-often}

Open the Calendar app’s settings, go to the “Accounts” pane, choose the relevant calendar service in the left sidebar, and then change the “Refresh Calendars” setting. Ideally, it should be set to “Push”, but not all services support that, like Google.

### Can you add some widgets? {#can-you-add-some-widgets}

I don’t plan to add this. Very few users use widgets on macOS, so it’s not worth the effort for a free app. macOS already has some built-in calendar widgets. And you can get more widgets with my [Dato app](/dato).

### Can you support iOS? {#can-you-support-ios}

I plan to do that at some point when the app is more mature.

### How does it compare to MeetingBar? {#meetingbar}

MeetingBar is mainly for video calls and has a gazillion settings and features around that. Today has a cleaner look and is opinionated so you don’t have to make so many choices. If all you need is a quick way to join video calls, Today is probably what you want. If you need more advanced features, MeetingBar or [Dato](/dato) may be a better choice.

