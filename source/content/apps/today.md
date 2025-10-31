---
title: Today
subtitle: Today’s schedule in your menu bar
pubDate: 2022-10-27
platforms:
  - macOS
isMenuBarApp: true
appStoreId: 6443714928
hasSentry: true
olderMacOSVersions:
  - '13'
  - '14'
feedbackNote: |
  [The app randomly disappears/quits](/apps/faq#randomly-quits)
---

The perfect companion to the built-in Calendar app. Just the events for today. Click an event to show it in the Calendar app. It also gives you a quick way to directly join an upcoming video call.

This app is intentionally simple. For more advanced needs, check out [Dato](/dato).

It integrates with Calendar, Fantastical, and BusyCal.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Today&referrer=Website-FAQ)

#### The app does not show up in the menu bar

[Try this](/apps/faq#app-not-showing-in-menu-bar)

#### How do I get back to the settings if I have hidden the `…` menu item?

Press the <kbd>Option</kbd> key while opening the Today menu.

#### It does not support the video call service I use

I'm happy to add support for more services. Just [send me](https://sindresorhus.com/feedback?product=Today&referrer=Website-FAQ) an invitation link (replace a few characters at the end to anonymize it).

The app can also detect the link of any video call service if you correctly add it in the Calendar app:
- Create a new event.
- Paste the video call link into the location field.
- Accept the dropdown suggestion about it being a video call.

If you don't use the Calendar app, you can add the following to the notes field of an event:

```
----( Video Call )----
https://some-video-call-service.com/join/23423
---===---
```

#### How do I add a calendar

[Add the calendar to the built-in Calendar app](https://support.apple.com/guide/calendar/add-or-delete-calendar-accounts-icl4308d6701/mac) and then enable it in the Today settings.

#### How can I open meeting links (Google Meet, Zoom, Microsoft Teams, etc.) in a specific browser?

Check out my [Velja app](https://sindresorhus.com/velja). It has built-in support for this without any setup. It can even open links to Zoom and Microsoft Teams directly in their desktop app.

#### I have Fantastical set as my default calendar app but Today still opens Calendar

There is a [macOS bug](https://github.com/feedback-assistant/reports/issues/290) that makes the default calendar app setting not work. To work around this, drag an event from the Calendar app into Finder, right-click on it, select “Get Info”, select your calendar in the “Open with” field, and click “Change All”.

#### Can you add x feature?

This app is a personal experiment to make the simplest calendar app possible. I'm happy to consider requests, but I'm also trying hard to keep the app simple.

#### Can the app show notifications for events? {#notifications}

You can set up notifications for events in the Calendar app.

#### Can the app show notifications with a “Join” button for video calls?

I don't plan to add this. You can get this feature in my [Dato app](/dato).

#### Can the app show the upcoming event in the menu bar?

I don't plan to add this. You can get this feature in my [Dato app](/dato) (with a lot of customizability).

#### Can the app support showing reminders?

I don't plan to add this. You can get this feature in my [Dato app](/dato).

#### Can you make the app show events for more days?

“Today” 😁

#### Can you add more menu bar icons?

I'm happy to consider requests. You can find icons [here](https://developer.apple.com/sf-symbols/) and [here](https://thenounproject.com).

#### I added a calendar to the Calendar app but it doesn't show up in the app

You need to enable the calendar in the app settings.

#### Can you add support for Google Calendar / Outlook 365 / Exchange?

It's already supported. Just add your calendars to the built-in Calendar app and then enable those calendars in the app settings.

#### My Google Calendar does not update in the app

You might have to re-authenticate your Google account. Open the Calendar app's settings, go to the “Accounts” pane, and try to remove and re-add the Google account.

#### How can I make my calendar refresh more often?

Open the Calendar app's settings, go to the “Accounts” pane, choose the relevant calendar service in the left sidebar, and then change the “Refresh Calendars” setting. Ideally, it should be set to “Push”, but not all services support that, like Google.

#### Can you add some widgets?

I don't plan to add this. Very few users use widgets on macOS, so it's not worth the effort for a free app. macOS already has some built-in calendar widgets. And you can get more widgets with my [Dato app](/dato).

#### Can you support iOS?

I plan to do that at some point when the app is more mature.

#### How does it compare to MeetingBar? {#meetingbar}

MeetingBar is mainly for video calls and has a gadzillion settings and features around that. Today has a cleaner look and is opinionated so you don't have to make so many choices. If all you need is a quick way to join video calls, Today is probably what you want. If you need more advanced features, MeetingBar or [Dato](/dato) may be a better choice.

#### How does it compare to Meeter? {#meeter}

Meeter is mainly for video calls. It's also quite buggy and does not follow macOS conventions. Today has a cleaner look and is opinionated so you don't have to make so many choices. If all you need is a quick way to join video calls, Today is probably what you want. If you need more advanced features, MeetingBar or [Dato](/dato) may be a better choice.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### [More FAQs…](/apps/faq)

## Older Versions

- [1.6.2](https://github.com/user-attachments/files/18873369/Today.1.6.2.-.macOS.14.zip) for macOS 14+
- [1.5.0](https://github.com/sindresorhus/meta/files/13997505/Today.1.5.0.-.macOS.13.zip) for macOS 13+

## Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/r87w55w9hy6j2i54srg5c/Today-1.7.1-1749995609.zip?rlkey=4tv1ovsun17asiyfkgopp3fn8&raw=1) *(1.7.1)*

*Requires macOS 15 or later*
