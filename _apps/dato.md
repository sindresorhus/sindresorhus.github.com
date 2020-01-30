---
title: Dato
subtitle: Better menu bar clock with calendar and time zones
description: Dato is a replacement for the system menu bar clock. By default, it looks exactly the same, but when you click it, you get a small calendar, calendar events, the current time in various time zones, and more.
type: macOS
date: 2019-07-13
mac_app_store_url: https://apps.apple.com/us/app/dato/id1470584107?mt=12
---

Dato supports all the locales and languages that macOS supports for dates, times, and the calendar, but the menus are English-only.

<br>

### Features

- Calendar, optionally with week numbers and event indicators.
- Your upcoming events for the next week (customizable) at a glance.
- Time zones, optionally with custom names.
- Fully customizable.
- Search time zones by city (15k cities included offline).
- Supports all calendar services that the built-in Calendar app supports (iCloud, Google, Outlook, etc).
- Lots of in-app keyboard shortcuts for power users.
- Global keyboard shortcut to open/close the app. *(macOS 10.15 and later)*
- Supports calendar events with HTML formatted notes.
- Show seconds in the menu bar clock. (Optional)
- "Join Zoom Meeting" button on Zoom meeting calendar invites.
- Custom date & time format.
- Highlight certain days of the week in the calendar.
- Open calendar events from Google Calendar directly in Google Calendar.

<br>

### Roadmap

- Time slider for the time zones.
- Show the time for multiple time zones in the menu bar.
- A setting to increase text size.
- How much time until next event.

<br>

<h3 id="tips">Tips</h3>
<table>
	<tr>
		<td>
			Double-click a day in the calendar to open that day in the default calendar app.
		</td>
	</tr>
	<tr>
		<td>
			Hold <kbd>option</kbd> while clicking the calendar arrows to jump a year instead of a month.
		</td>
	</tr>
</table>

<br>

<h3 id="keyboard-shortcuts">Keyboard shortcuts</h3>
<table>
	<tr>
		<td>
			<kbd>◀</kbd>
			/
			<kbd>▶</kbd>
		</td>
		<td>Previous/next day in the calendar</td>
	</tr>
	<tr>
		<td>
			<kbd>▲</kbd>
			/
			<kbd>▼</kbd>
		</td>
		<td>Same day in the previous/next week in the calendar</td>
	</tr>
	<tr>
		<td>
			<kbd>option</kbd> <kbd>◀</kbd>
			<br>
			<kbd>option</kbd> <kbd>▶</kbd>
		</td>
		<td>Previous/next month in the calendar</td>
	</tr>
	<tr>
		<td>
			<kbd>shift</kbd> <kbd>option</kbd> <kbd>◀</kbd>
			<br>
			<kbd>shift</kbd> <kbd>option</kbd> <kbd>▶</kbd>
		</td>
		<td>Previous/next year in the calendar</td>
	</tr>
	<tr>
		<td>
			<kbd>space</kbd>
		</td>
		<td>Select today in the calendar</td>
	</tr>
	<tr>
		<td>
			<kbd>command</kbd> <kbd>o</kbd>
		</td>
		<td>Open the default calendar app</td>
	</tr>
	<tr>
		<td>
			<kbd>command</kbd> <kbd>q</kbd>
		</td>
		<td>Quit the app</td>
	</tr>
</table>

<br>

<h3 id="gestures">Gestures</h3>
<table>
	<tr>
		<td>
			Swipe left/right
		</td>
		<td>Previous/next month in the calendar</td>
	</tr>
	<tr>
		<td>
			<kbd>option</kbd> + Swipe left/right
		</td>
		<td>Previous/next year in the calendar</td>
	</tr>
</table>

<br>


<h3 id="faq">Frequently Asked Questions</h3>

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback/?product=Dato&referrer=Website-FAQ)

#### How can I toggle AM/PM for the time?

Dato adheres to what you have set in “System Preferences › Language and Region”.

#### How can I change the first day of the week?

Dato adheres to what you have set in “System Preferences › Language and Region”.

#### Can you localize the app into my language?

All the date and time output and the calendar adhere to your locale preferences. I have no plans to localize the app itself.

#### I added a calendar to the Calendar app but it doesn't show up in Dato

You need to enable the calendar in “Dato › Preferences › Events”.

#### Dato doesn't show up in the menu bar

When the menu bar grows too large, macOS hides overflowing items, so Dato might have been hidden. Try to close some of your other menu bar apps. There’s, unfortunately, no way for apps to detect this and warn the user.

#### Can you add support for Google Calendar?

It's already supported. Just add your Google calendars to the Calendar app and then enable the calendars in the Dato preferences.

#### How can I customize the menu bar date and time format?

If you just want to toggle a certain component, like date or time, use the checkboxes in the “General” preferences.

If you want something more custom, go to “Dato › Preferences › Advanced”, and in the “Date & Time Format” text field, you can specify a [datetime pattern](https://nsdateformatter.com).

For example, you could display the full month name, the year, or the day of the year.

#### How can I show the menu bar date and time in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format?

Go to “Dato › Preferences › Advanced”, and in the “Date & Time Format” text field, write `YYYY-MM-DD  hh:mm:ss`.

#### How can I open a calendar event in my favorite calendar app (Fantastical, BusyCal, etc.) instead of the built-in Calendar app?

Dato uses the system default calendar app. To change the default calendar app, open the built-in Calendar app, open “Preferences…”, and in the “Default calendar app” preference, select the app you want.

Dato supports opening calendar events directly in Calendar, Fantastical, BusyCal, and Google Calendar (web). For other apps, Dato will just open the app.

#### How can I make my calendar refresh more often?

Open the Calendar app, open its “Preferences”, go to the “Accounts” tab, choose the relevant calendar service in the left sidebar, and then change the “Refresh Calendars” preference. Ideally, it should be set to “Push”, but not all services support that, like Google.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/us/app/dato/id1470584107?mt=12) and click “Version History”.

#### Can you add support for showing an analog clock like the system clock?

I have no plans to add that, but you can make it work by unchecking the "Time" preference in Dato and keep the system clock.

#### Can you add support for flashing the time separator like the system clock?

I have no plans to add that, but you can make it work by unchecking the "Time" preference in Dato and keep the system clock.

#### Is it possible to pin Dato so it's always visible?

This is unfortunately not possible as Dato uses a menu, not a popover, which can’t be pinned.

#### How can I copy a link from the event notes? I need to open it in a specific browser profile.

If it's a plain URL, you can select the URL and choose “Copy Selected Text”. Otherwise, activate the correct browser profile and then drag and drop the link into the browser window.

#### So this is like iStat Menus?

iStat Menus does all the things. Dato is focused on date and time only. Dato also looks better.

#### How is it different from Itsycal?

Itsycal is a great app too. While Itsycal has more advanced calendar functionality, Dato is not just a calendar app, but also includes menu bar clock replacement, time zones, and more.

#### Why the name "Dato"?

It means "date" in Norwegian. I just wanted a short, unique, and relevant name.

#### Do you plan to open-source it?

I open-source [most things](https://github.com/sindresorhus) I make, but I don’t intend to open-source this app. Many open-source apps have problems with someone using the source to [publish clones](https://twitter.com/sindresorhus/status/1202144430477627394) and it’s a hassle to get Apple to take down such clones. I also have my own private framework that makes it faster for me to build apps, but I don’t want to open-source it as then I would have to maintain it.

#### Can you add support for macOS 10.13 or older?

No, there were several bugs in 10.13 I could not work around.

#### Is this a native app?

Yes, it’s a native app written in Swift.

#### Can you port it to Windows/Linux?

No, I’m a Mac developer.
